// Unit test Edge Function recommend-ai (decision.ts, chat.ts) với fetch giả: không gọi API thật, không cần key.
// Chạy: node supabase/scripts/test_recommend_ai_unit.mjs   (Node ≥ 23 chạy thẳng .ts)
import assert from "node:assert/strict";
import { classifyIntent, decideDish, rankByDecision } from "../functions/recommend-ai/decision.ts";
import { askGemini, fallbackHowToCook, fallbackNutrition, fallbackRecommend } from "../functions/recommend-ai/chat.ts";

const dish = (id, title, kcal) => ({ id, title, slug: id, category: "mon_man", image_url: null, servings: 1,
  prep_time_minutes: 10, cook_time_minutes: 20, calories_per_serving: kcal, protein_g_per_serving: 30,
  fat_g_per_serving: 10, carbs_g_per_serving: 50, score: 0.8, match_reason: "x" });
const sql = [dish("a", "Phở bò", 500), dish("b", "Cơm gà", 600), dish("c", "Bún chả", 650)];
const ok = (body) => async () => ({ ok: true, json: async () => body });
const http = (status) => async () => ({ ok: false, status, text: async () => "quota" });
const boom = async () => { throw new Error("network"); };
console.warn = () => {}; // im log cảnh báo của các ca lỗi cố ý

// 1. Chọn món: request đúng định dạng Decisions API, xác suất map ngược về recipe id, xếp lại theo xác suất
let sent;
const probs = await decideDish("KEY", { goal: "lose_weight" }, sql, "lunch", async (url, init) => {
  sent = { url, init, body: JSON.parse(init.body) };
  return ok({ answers: { dish: { type: "choice", choice: "r2", probabilities: { r0: 0.1, r1: 0.2, r2: 0.7 } } } })();
});
assert.equal(sent.url, "https://generativelanguage.googleapis.com/v1beta/decisions");
assert.equal(sent.init.headers["x-goog-api-key"], "KEY", "key ở header, không ở URL");
assert.equal(sent.body.model, "models/gemini-decision-1");
assert.equal(sent.body.questions.dish.type, "choice");
assert.deepEqual(Object.keys(sent.body.questions.dish.criteria), ["r0", "r1", "r2"]);
assert.match(sent.body.questions.dish.criteria.r0, /Phở bò/);
assert.deepEqual(probs, { a: 0.1, b: 0.2, c: 0.7 });
assert.deepEqual(rankByDecision(sql, probs).map((r) => r.id), ["c", "b", "a"]);

// 2. Lỗi HTTP / mạng / thiếu answers → null → giữ nguyên thứ tự SQL
assert.equal(await decideDish("KEY", {}, sql, "lunch", http(429)), null);
assert.equal(await decideDish("KEY", {}, sql, "lunch", boom), null);
assert.equal(await decideDish("KEY", {}, sql, "lunch", ok({})), null);
const kept = rankByDecision(sql, null);
assert.deepEqual(kept.map((r) => r.id), ["a", "b", "c"]);
assert.equal(kept[0].decision_probability, null);

// 3. < 2 ứng viên thì không gọi API; > 10 ứng viên chỉ gửi 10 (khóa r10 sẽ xếp trước r2)
let called = false;
assert.equal(await decideDish("KEY", {}, [sql[0]], "lunch", async () => { called = true; }), null);
assert.equal(called, false);
const many = Array.from({ length: 12 }, (_, i) => dish("d" + i, "Món " + i, 500));
await decideDish("KEY", {}, many, "lunch", async (_u, init) => { sent = JSON.parse(init.body); return ok({})(); });
assert.equal(Object.keys(sent.questions.dish.criteria).length, 10);

// 4. Phân loại câu gõ tự do
const intentOf = (p) => ok({ answers: { intent: { probabilities: p } } });
assert.equal(await classifyIntent("KEY", "nấu sao", intentOf({ how_to_cook: 0.8, nutrition: 0.1, recommend: 0.05, out_of_scope: 0.05 })), "how_to_cook");
assert.equal(await classifyIntent("KEY", "bao nhiêu calo", intentOf({ how_to_cook: 0.1, nutrition: 0.7, recommend: 0.1, out_of_scope: 0.1 })), "nutrition");
assert.equal(await classifyIntent("KEY", "thời tiết?", intentOf({ how_to_cook: 0, nutrition: 0, recommend: 0.1, out_of_scope: 0.9 })), "out_of_scope");
assert.equal(await classifyIntent("KEY", "hmm", intentOf({ how_to_cook: 0.1, nutrition: 0.1, recommend: 0.2, out_of_scope: 0.6 })), "recommend",
  "out_of_scope < 0,7 → vẫn gợi ý, tránh từ chối nhầm");
assert.equal(await classifyIntent("KEY", "x", http(500)), "recommend", "lỗi → gợi ý món");
assert.equal(await classifyIntent("KEY", "x", boom), "recommend");
assert.equal(await classifyIntent("KEY", "x", intentOf({})), "recommend", "probabilities rỗng không ném lỗi");

// 5. Gemini chat: lỗi 429 / mạng / trả rỗng → "" (người gọi dùng câu mẫu)
assert.deepEqual(await askGemini("KEY", "sys", "hi", ok({ candidates: [{ content: { parts: [{ text: " Chào bạn " }] } }] })), { text: "Chào bạn", error: null });
assert.equal((await askGemini("KEY", "sys", "hi", ok({ candidates: [{ content: { parts: [{ text: "nghĩ...", thought: true }, { text: "Trả lời" }] } }] }))).text, "Trả lời", "bỏ phần thought");
assert.match((await askGemini("KEY", "sys", "hi", http(429))).error, /^HTTP 429/);
assert.equal((await askGemini("KEY", "sys", "hi", boom)).text, "");
assert.match((await askGemini("KEY", "sys", "hi", ok({ candidates: [] }))).error, /^empty/);
assert.equal((await askGemini("KEY", "sys", "hi", async (_u, { signal }) => {
  await new Promise((_, rej) => signal.addEventListener("abort", () => rej(new Error("aborted"))));
})).error, "timeout", "timeout 6,5 s → câu mẫu"); // chạy hết 6,5 s thật

// 6. Câu mẫu: lấy đúng số liệu, đúng thứ tự bước, không bịa
const fb = fallbackRecommend("lunch", 700, sql, true, "low");
assert.match(fb, /Đã ghi nhận bạn không chọn món/);
assert.match(fb, /món nhẹ/, "nhắc ngưỡng calo low");
assert.match(fb, /\*\*Phở bò\*\* \(500 kcal/);
assert.match(fallbackRecommend("lunch", 700, [], false, "ok"), /chưa tìm thấy/);
const recipe = { id: "a", title: "Phở bò", servings: 4, prep_time_minutes: 20, cook_time_minutes: 60, video_url: null,
  instructions: [{ step_number: 2, title: "Nấu nước dùng", description: "Hầm xương 2 giờ" }, { step_number: 1, title: "Sơ chế" }],
  ingredients: ["Xương bò: 1 kg", "Bánh phở: 800 g"], calories_per_serving: 520, protein_g_per_serving: 30,
  fat_g_per_serving: 12, carbs_g_per_serving: 70, fiber_g_per_serving: 2, sodium_mg_per_serving: 900, allergens: [] };
const cook = fallbackHowToCook(recipe);
assert.ok(cook.indexOf("1. Sơ chế") < cook.indexOf("2. Nấu nước dùng: Hầm xương 2 giờ"), "bước theo thứ tự");
assert.match(cook, /• Xương bò: 1 kg/);
assert.match(cook, /~80 phút/);
const nut = fallbackNutrition({ ...recipe, allergens: ["Đậu nành"] });
assert.match(nut, /520 kcal/);
assert.match(nut, /Natri: 900 mg/);
assert.match(nut, /Chất gây dị ứng: Đậu nành/);

console.log("OK: recommend-ai unit (chọn món, phân loại câu, Gemini chat fallback, câu mẫu)");
