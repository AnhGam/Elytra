// Đo chất lượng AI kiểm duyệt món (Gemini Decision 1) trên bộ 100 ca offline.
// Chạy: GEMINI_API_KEY=... node supabase/scripts/eval_moderation.mjs supabase/data/moderation_eval_set.json docs/report/moderation_eval.md
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { ALLERGENS, reviewRecipe } from "../functions/recipe-review-assist/review.ts";
import { DECISION_MODEL } from "../functions/_shared/decision.ts";

async function main() {
  const [, , evalSetPath, outMdPath] = process.argv;
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || !evalSetPath || !outMdPath) {
    console.error(
      "Thiếu GEMINI_API_KEY hoặc tham số.\n" +
        "Cách dùng: GEMINI_API_KEY=... node supabase/scripts/eval_moderation.mjs supabase/data/moderation_eval_set.json docs/report/moderation_eval.md"
    );
    process.exitCode = 1;
    return;
  }

  const THRESHOLDS = [0.5, 0.7, 0.8, 0.9, 0.95];
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  const pct = (num, den) =>
    den === 0 ? "0.0%" : `${((num / den) * 100).toFixed(1)}%`;

  const evalSet = JSON.parse(readFileSync(evalSetPath, "utf8"));
  const cases = Array.isArray(evalSet.cases) ? evalSet.cases : [];
  if (cases.length === 0) {
    console.error("Bộ test rỗng hoặc sai định dạng.");
    process.exitCode = 1;
    return;
  }

  const measuredAt = new Date().toISOString();
  const records = [];

  for (let i = 0; i < cases.length; i++) {
    const c = cases[i];
    let review = await reviewRecipe(apiKey, c.input);
    if (review === null) {
      await sleep(5000);
      review = await reviewRecipe(apiKey, c.input);
    }
    records.push({
      caseItem: c,
      raw: {
        id: c.id,
        group: c.group,
        flaw: c.flaw,
        expected: c.expected,
        review,
      },
    });
    if ((i + 1) % 10 === 0 || i + 1 === cases.length) {
      console.log(`${i + 1}/${cases.length}`);
    }
    if (i < cases.length - 1) {
      await sleep(1500);
    }
  }

  const outDir = dirname(outMdPath);
  mkdirSync(outDir, { recursive: true });
  const rawPath = join(outDir, "moderation_eval_raw.json");
  writeFileSync(
    rawPath,
    `${JSON.stringify(records.map((r) => r.raw), null, 2)}\n`,
    "utf8"
  );

  const valid = records.filter((r) => r.raw.review !== null);
  const errorCount = records.length - valid.length;

  // 1. Có phải món thật (ngưỡng 0,5)
  const dishCorrect = valid.filter(
    (r) => (r.raw.review.is_dish >= 0.5) === r.raw.expected.is_dish
  ).length;
  const spamCases = valid.filter((r) => r.raw.group === "spam");
  const spamAsDish = spamCases.filter((r) => r.raw.review.is_dish >= 0.5);

  // 2. Danh mục
  const catCases = valid.filter(
    (r) => r.raw.group === "real" || r.raw.group === "wrong_category"
  );
  const catCorrect = catCases.filter(
    (r) => r.raw.review.category.suggested === r.raw.expected.category
  ).length;
  const wrongCatCases = valid.filter((r) => r.raw.group === "wrong_category");
  const wrongCatWarned = wrongCatCases.filter((r) =>
    r.raw.review.warnings.some((w) => w.startsWith("Danh mục có thể là"))
  ).length;

  // 3. Calo (bad = level 0 hoặc 4, trên mọi ca không phải spam)
  const nonSpam = valid.filter((r) => r.raw.group !== "spam");
  const isKcalBad = (r) =>
    r.raw.review.kcal_plausibility.level === 0 ||
    r.raw.review.kcal_plausibility.level === 4;
  const kcalBadCases = nonSpam.filter((r) => !r.raw.expected.kcal_ok);
  const kcalBadCaught = kcalBadCases.filter(isKcalBad).length;
  const kcalOkCases = nonSpam.filter((r) => r.raw.expected.kcal_ok);
  const kcalFalseAlarm = kcalOkCases.filter(isKcalBad).length;

  // 4. Dị ứng (ngưỡng 0,7)
  const missingAllergenCases = valid.filter(
    (r) => r.raw.group === "missing_allergen"
  );
  const missingAllergenCaught = missingAllergenCases.filter((r) => {
    const removedCode = r.raw.expected.allergens.find(
      (code) => !r.caseItem.input.allergen_codes.includes(code)
    );
    if (!removedCode) return false;
    const viName = ALLERGENS[removedCode]?.vi;
    return (
      r.raw.review.warnings.some((w) => viName && w.includes(viName)) ||
      (r.raw.review.allergens[removedCode] ?? 0) >= 0.7
    );
  }).length;

  const realCases = valid.filter((r) => r.raw.group === "real");
  const realAllergenAlerts = [];
  let totalRealAllergenAlerts = 0;
  for (const r of realCases) {
    const warnings = r.raw.review.warnings.filter((w) =>
      w.startsWith("Có thể chứa ")
    );
    if (warnings.length > 0) {
      totalRealAllergenAlerts += warnings.length;
      realAllergenAlerts.push({ id: r.raw.id, warnings });
    }
  }

  // 5. Mô phỏng tự duyệt
  const goodCases = valid.filter(
    (r) => r.raw.group === "real" && r.raw.expected.kcal_ok === true
  );
  const badCases = valid.filter(
    (r) => r.raw.group !== "real" || r.raw.expected.kcal_ok === false
  );
  const simRows = THRESHOLDS.map((t) => {
    const isApproved = (r) =>
      r.raw.review.is_dish >= t && r.raw.review.warnings.length === 0;
    const goodApproved = goodCases.filter(isApproved).length;
    const badApprovedIds = badCases.filter(isApproved).map((r) => r.raw.id);
    return { t, goodApproved, badApprovedIds };
  });
  const safeRow = simRows.find((row) => row.badApprovedIds.length === 0) ?? null;

  const lines = [
    "# Đo AI kiểm duyệt món (Gemini Decision 1)",
    "",
    `Thời gian đo: ${measuredAt} · Model: \`${DECISION_MODEL}\` · Số ca hợp lệ: ${valid.length}/${records.length} · Số ca lỗi (error): ${errorCount}`,
    "",
    "## 1. Có phải món thật (ngưỡng 0,5)",
    "| Chỉ số | Giá trị |",
    "| --- | --- |",
    `| Accuracy toàn bộ ca hợp lệ | ${dishCorrect}/${valid.length} (${pct(dishCorrect, valid.length)}) |`,
    `| Nhóm spam bị nhận nhầm là món | ${spamAsDish.length}/${spamCases.length} (${spamAsDish.map((r) => r.raw.id).join(", ") || "không"}) |`,
    "",
    `Kết luận: Mô hình đạt độ chính xác ${pct(dishCorrect, valid.length)} khi phân biệt món ăn và nhận nhầm ${spamAsDish.length}/${spamCases.length} ca spam là món thật.`,
    "",
    "## 2. Danh mục",
    "| Chỉ số | Giá trị |",
    "| --- | --- |",
    `| Accuracy (real + wrong_category) | ${catCorrect}/${catCases.length} (${pct(catCorrect, catCases.length)}) |`,
    `| Nhóm wrong_category có cảnh báo danh mục | ${wrongCatWarned}/${wrongCatCases.length} (${pct(wrongCatWarned, wrongCatCases.length)}) |`,
    "",
    `Kết luận: Mô hình phân loại đúng ${catCorrect}/${catCases.length} (${pct(catCorrect, catCases.length)}) ca và phát cảnh báo sai danh mục cho ${wrongCatWarned}/${wrongCatCases.length} ca cố tình khai sai.`,
    "",
    "## 3. Calo (level 0 hoặc 4 là bất thường, bỏ qua spam)",
    "| Chỉ số | Giá trị |",
    "| --- | --- |",
    `| Recall (bắt được ca kcal_ok=false) | ${kcalBadCaught}/${kcalBadCases.length} (${pct(kcalBadCaught, kcalBadCases.length)}) |`,
    `| Tỉ lệ báo nhầm (ca kcal_ok=true bị đánh level 0/4) | ${kcalFalseAlarm}/${kcalOkCases.length} (${pct(kcalFalseAlarm, kcalOkCases.length)}) |`,
    "",
    `Kết luận: Mô hình bắt được ${kcalBadCaught}/${kcalBadCases.length} (${pct(kcalBadCaught, kcalBadCases.length)}) ca bất thường calo và báo nhầm ${kcalFalseAlarm}/${kcalOkCases.length} (${pct(kcalFalseAlarm, kcalOkCases.length)}) ca bình thường.`,
    "",
    "## 4. Dị ứng (ngưỡng 0,7)",
    "| Chỉ số | Giá trị |",
    "| --- | --- |",
    `| Nhóm missing_allergen có cảnh báo đúng mã bị bỏ | ${missingAllergenCaught}/${missingAllergenCases.length} (${pct(missingAllergenCaught, missingAllergenCases.length)}) |`,
    `| Tổng số cảnh báo dị ứng (báo nhầm) trên nhóm real | ${totalRealAllergenAlerts} trên ${realAllergenAlerts.length}/${realCases.length} ca |`,
    "",
    realAllergenAlerts.length > 0
      ? `Chi tiết cảnh báo dị ứng trên nhóm real: ${realAllergenAlerts
          .map((a) => `${a.id} (${a.warnings.join("; ")})`)
          .join(" · ")}.`
      : "Chi tiết cảnh báo dị ứng trên nhóm real: không có cảnh báo nào.",
    "",
    `Kết luận: Mô hình phát hiện đúng ${missingAllergenCaught}/${missingAllergenCases.length} (${pct(missingAllergenCaught, missingAllergenCases.length)}) ca thiếu tag dị ứng và phát ${totalRealAllergenAlerts} cảnh báo dị ứng thêm trên nhóm real.`,
    "",
    "## 5. Mô phỏng tự duyệt (is_dish >= ngưỡng và warnings rỗng)",
    "| Ngưỡng is_dish | Ca tốt được tự duyệt | Ca lỗi bị tự duyệt | Danh sách id ca lỗi bị tự duyệt |",
    "| --- | --- | --- | --- |",
    ...simRows.map(
      (row) =>
        `| ${row.t} | ${row.goodApproved}/${goodCases.length} (${pct(row.goodApproved, goodCases.length)}) | ${row.badApprovedIds.length}/${badCases.length} | ${row.badApprovedIds.join(", ") || "không"} |`
    ),
    "",
    `Kết luận: Ở ngưỡng 0.5 tự duyệt được ${simRows[0].goodApproved}/${goodCases.length} ca tốt nhưng lọt ${simRows[0].badApprovedIds.length} ca lỗi; ở ngưỡng 0.95 tự duyệt ${simRows[4].goodApproved}/${goodCases.length} ca tốt và lọt ${simRows[4].badApprovedIds.length} ca lỗi.`,
    "",
    "## Kết luận ngưỡng tự duyệt",
    safeRow
      ? `- Ngưỡng an toàn (0 ca lỗi bị tự duyệt): **${safeRow.t}** — tỉ lệ ca tốt được tự duyệt ở ngưỡng này: **${safeRow.goodApproved}/${goodCases.length} (${pct(safeRow.goodApproved, goodCases.length)})**.`
      : `- Ngưỡng an toàn: **không có ngưỡng an toàn** (mọi ngưỡng thử nghiệm đều còn ca lỗi bị tự duyệt; tỉ lệ ca tốt ở ngưỡng cao nhất 0.95 là ${simRows[4].goodApproved}/${goodCases.length} (${pct(simRows[4].goodApproved, goodCases.length)})).`,
    "",
  ];

  writeFileSync(outMdPath, lines.join("\n"), "utf8");
  console.log(`moderation eval: ${valid.length}/${records.length} ca hợp lệ → ${outMdPath}`);
}

await main();
