// Rà soát calo toàn bộ món ăn từ file JSON export và xuất danh sách món bất thường ra Markdown.
// Chạy: node supabase/scripts/audit_recipe_calories.mjs <đường dẫn JSON> <đường dẫn file .md xuất ra>
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

const [, , jsonPath, outPath] = process.argv;
if (!jsonPath || !outPath) {
  console.error(
    "Cách dùng: node supabase/scripts/audit_recipe_calories.mjs <đường dẫn JSON> <đường dẫn file .md xuất ra>"
  );
  process.exit(1);
}

// Chuẩn hoá chuỗi tiếng Việt về NFC, chữ thường, bỏ khoảng trắng hai đầu
const norm = (s) => String(s ?? "").normalize("NFC").toLowerCase().trim();

// Tiền tố gia vị/nước 0 kcal (giữ nguyên dấu cách cuối ở "lá " để không trùng "lạc")
const SEASONING_PREFIXES = [
  "muối",
  "hạt nêm",
  "bột ngọt",
  "bột nêm",
  "nước lọc",
  "nước nóng",
  "nước sôi",
  "nước ấm",
  "nước lạnh",
  "nước đá",
  "đá",
  "sả",
  "tiêu",
  "ớt",
  "hành",
  "tỏi",
  "gừng",
  "riềng",
  "lá ",
  "ngò",
  "rau răm",
  "rau thơm",
  "giấm",
  "ngũ vị hương",
  "vani",
  "quế",
  "hồi",
  "thảo quả",
  "đinh hương",
  "bột cà ri",
  "nghệ",
].map((p) => p.normalize("NFC").toLowerCase());

// Định nghĩa thứ tự và ý nghĩa 10 mã cờ cho bảng tóm tắt
const FLAG_DEFS = [
  { code: "KCAL_LOW", meaning: "Calo/khẩu phần < 150 (trừ gia vị/ăn kèm)" },
  { code: "KCAL_HIGH", meaning: "Calo/khẩu phần > 1000" },
  { code: "MACRO_MISMATCH", meaning: "4P + 4C + 9F lệch > 20% so với calo/khẩu phần" },
  { code: "FAT_HEAVY", meaning: "Năng lượng từ chất béo (9F) > 60% tổng calo" },
  { code: "ONE_INGREDIENT", meaning: "Có nguyên liệu chiếm > 70% tổng calo từ nguyên liệu" },
  { code: "BIG_AMOUNT", meaning: "Có nguyên liệu > 600 g/khẩu phần" },
  { code: "ZERO_ROW", meaning: "Nguyên liệu không phải gia vị nhưng tính 0 g hoặc 0 kcal" },
  { code: "NO_INGREDIENT_ID", meaning: "Nguyên liệu không phải gia vị chưa ánh xạ (đang tính 0 kcal)" },
  { code: "SODIUM_HIGH", meaning: "Natri > 2300 mg/khẩu phần" },
  { code: "TOTAL_MISMATCH", meaning: "total_calories lệch > 2% + 1 so với khẩu phần × số phần" },
];

const fmtInt = (n) => String(Math.round(Number(n) || 0));
const fmtGram = (n) => {
  const rounded = Number(n || 0).toFixed(1);
  return rounded === "-0.0" ? "0.0" : rounded;
};
const fmtPct = (ratio) => String(Math.round((Number(ratio) || 0) * 100));

const isSeasoning = (name) => {
  const n = norm(name);
  return n === "nước" || SEASONING_PREFIXES.some((p) => n.startsWith(p));
};

const raw = readFileSync(jsonPath, "utf8");
const recipes = JSON.parse(raw);
if (!Array.isArray(recipes)) {
  console.error("Dữ liệu JSON đầu vào phải là một mảng món ăn.");
  process.exit(1);
}

const flagCounts = new Map(FLAG_DEFS.map((f) => [f.code, 0]));
const flaggedRecipes = [];
const unmappedByNorm = new Map();

for (const recipe of recipes) {
  const servings = Number(recipe.servings) || 0;
  const kcal = Number(recipe.calories_per_serving) || 0;
  const protein = Number(recipe.protein_g_per_serving) || 0;
  const fat = Number(recipe.fat_g_per_serving) || 0;
  const carbs = Number(recipe.carbs_g_per_serving) || 0;
  const sodium = Number(recipe.sodium_mg_per_serving) || 0;
  const totalCalories = Number(recipe.total_calories) || 0;
  const rawIngredients = Array.isArray(recipe.recipe_ingredients)
    ? recipe.recipe_ingredients
    : [];

  // Tính khối lượng ăn được và calo cho từng nguyên liệu
  const ingredients = rawIngredients.map((ing) => {
    const amountG = Number(ing.amount_g) || 0;
    const consumedPct = Number(ing.consumed_pct) || 0;
    const kcalPer100g = Number(ing.calories_per_100g) || 0;
    const eatenG = (amountG * consumedPct) / 100;
    const ingKcal = (eatenG * kcalPer100g) / 100;
    return {
      name: ing.ingredient_name_raw || ing.raw_text || "(không tên)",
      ingredientId: ing.ingredient_id,
      amountG,
      kcalPer100g,
      eatenG,
      kcal: ingKcal,
      share: 0,
    };
  });

  const kcalIngTotal = ingredients.reduce((sum, item) => sum + item.kcal, 0);
  if (kcalIngTotal > 0) {
    for (const item of ingredients) {
      item.share = item.kcal / kcalIngTotal;
    }
  }

  const flags = [];

  if (kcal < 150 && recipe.category !== "gia_vi_an_kem") {
    flags.push({
      code: "KCAL_LOW",
      evidence: `${fmtInt(kcal)} kcal/khẩu phần`,
    });
  }

  if (kcal > 1000) {
    flags.push({
      code: "KCAL_HIGH",
      evidence: `${fmtInt(kcal)} kcal/khẩu phần`,
    });
  }

  const macroKcal = 4 * protein + 4 * carbs + 9 * fat;
  if (Math.abs(macroKcal - kcal) > 0.2 * kcal) {
    flags.push({
      code: "MACRO_MISMATCH",
      evidence: `4P+4C+9F = ${fmtInt(macroKcal)} so với ${fmtInt(kcal)}`,
    });
  }

  if (kcal > 0 && (9 * fat) / kcal > 0.6) {
    flags.push({
      code: "FAT_HEAVY",
      evidence: `${fmtPct((9 * fat) / kcal)}% năng lượng từ chất béo`,
    });
  }

  const dominantIngs = ingredients.filter((item) => item.share > 0.7);
  if (dominantIngs.length > 0) {
    flags.push({
      code: "ONE_INGREDIENT",
      evidence: dominantIngs
        .map(
          (item) =>
            `${item.name} chiếm ${fmtPct(item.share)}% calo (${fmtGram(item.eatenG)} g)`
        )
        .join("; "),
    });
  }

  const bigIngs =
    servings > 0
      ? ingredients.filter((item) => item.eatenG / servings > 600)
      : [];
  if (bigIngs.length > 0) {
    flags.push({
      code: "BIG_AMOUNT",
      evidence: bigIngs
        .map((item) => `${item.name}: ${fmtGram(item.eatenG / servings)} g/khẩu phần`)
        .join("; "),
    });
  }

  const zeroIngs = ingredients.filter(
    (item) =>
      (item.eatenG === 0 || item.kcalPer100g === 0) && !isSeasoning(item.name)
  );
  if (zeroIngs.length > 0) {
    flags.push({
      code: "ZERO_ROW",
      evidence: zeroIngs
        .map((item) => `${item.name} (${fmtGram(item.eatenG)} g)`)
        .join(", "),
    });
  }

  const unmappedIngs = ingredients.filter(
    (item) => item.ingredientId === null && !isSeasoning(item.name)
  );
  if (unmappedIngs.length > 0) {
    flags.push({
      code: "NO_INGREDIENT_ID",
      evidence: unmappedIngs
        .map((item) => `${item.name} (${fmtGram(item.eatenG)} g)`)
        .join(", "),
    });
    for (const item of unmappedIngs) {
      const key = norm(item.name);
      let entry = unmappedByNorm.get(key);
      if (!entry) {
        entry = { normName: key, totalEatenG: 0, recipes: new Set() };
        unmappedByNorm.set(key, entry);
      }
      entry.totalEatenG += item.eatenG;
      entry.recipes.add(recipe.title);
    }
  }

  if (sodium > 2300) {
    flags.push({
      code: "SODIUM_HIGH",
      evidence: `${fmtInt(sodium)} mg natri/khẩu phần (khuyến nghị cả ngày < 2300)`,
    });
  }

  const byServings = kcal * servings;
  if (Math.abs(totalCalories - byServings) > 0.02 * totalCalories + 1) {
    flags.push({
      code: "TOTAL_MISMATCH",
      evidence: `tổng ${fmtInt(totalCalories)}, khẩu phần × số phần = ${fmtInt(byServings)}`,
    });
  }

  if (flags.length > 0) {
    for (const f of flags) {
      flagCounts.set(f.code, (flagCounts.get(f.code) || 0) + 1);
    }
    const topIngredients = [...ingredients]
      .sort((a, b) => b.kcal - a.kcal)
      .slice(0, 3);
    flaggedRecipes.push({
      title: recipe.title,
      slug: recipe.slug,
      category: recipe.category,
      servings,
      kcal,
      protein,
      fat,
      carbs,
      sodium,
      flags,
      topIngredients,
    });
  }
}

flaggedRecipes.sort((a, b) => {
  if (b.flags.length !== a.flags.length) {
    return b.flags.length - a.flags.length;
  }
  return String(a.title).localeCompare(String(b.title), "vi");
});

const totalCount = recipes.length;
const cleanCount = totalCount - flaggedRecipes.length;

const lines = [
  "# Rà soát calo toàn bộ món (dữ liệu 23/11/2026)",
  "",
  `Nguồn: ${jsonPath}, ${totalCount} món đã duyệt. Chỉ là danh sách để xem, CHƯA sửa gì trong DB.`,
  "",
  "## Tóm tắt",
  "| Cờ | Ý nghĩa | Số món |",
  "| --- | --- | --- |",
  ...FLAG_DEFS.map(
    (f) => `| \`${f.code}\` | ${f.meaning} | ${flagCounts.get(f.code) || 0} |`
  ),
  "",
  `Món không có cờ nào: ${cleanCount}/${totalCount}`,
  "",
  "## Danh sách món có cờ (nhiều cờ nhất trước, cùng số cờ thì theo tên)",
];

for (const item of flaggedRecipes) {
  lines.push("");
  lines.push(`### ${item.title} (\`${item.slug}\`)`);
  lines.push(
    `- Danh mục: ${item.category} · ${item.servings} khẩu phần · ${fmtInt(item.kcal)} kcal/khẩu phần · Đạm ${fmtGram(item.protein)} g · Béo ${fmtGram(item.fat)} g · Bột ${fmtGram(item.carbs)} g · Natri ${fmtInt(item.sodium)} mg`
  );
  lines.push("- Cờ:");
  for (const f of item.flags) {
    lines.push(`  - \`${f.code}\`: ${f.evidence}`);
  }
  const topText = item.topIngredients
    .map(
      (ing) =>
        `${ing.name} ${fmtGram(ing.eatenG)} g → ${fmtInt(ing.kcal)} kcal (${fmtPct(ing.share)}%)`
    )
    .join("; ");
  lines.push(`- 3 nguyên liệu nhiều calo nhất: ${topText}`);
}

const unmappedRows = [...unmappedByNorm.values()].sort((a, b) => {
  if (b.recipes.size !== a.recipes.size) {
    return b.recipes.size - a.recipes.size;
  }
  if (b.totalEatenG !== a.totalEatenG) {
    return b.totalEatenG - a.totalEatenG;
  }
  return a.normName.localeCompare(b.normName, "vi");
});

const escCell = (s) => String(s).replace(/\|/g, "\\|");

lines.push("");
lines.push("## Nguyên liệu chưa ánh xạ (không phải gia vị) — gộp toàn bộ món");
lines.push("| Tên (đã chuẩn hóa) | Số món | Tổng g | Món |");
lines.push("| --- | --- | --- | --- |");
for (const row of unmappedRows) {
  lines.push(
    `| ${escCell(row.normName)} | ${row.recipes.size} | ${fmtGram(row.totalEatenG)} | ${escCell([...row.recipes].join(", "))} |`
  );
}
lines.push("");

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, lines.join("\n"), "utf8");

console.log(
  `calorie audit: ${totalCount} món, ${flaggedRecipes.length} món có cờ → ${outPath}`
);
