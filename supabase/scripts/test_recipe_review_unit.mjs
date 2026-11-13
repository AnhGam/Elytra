// Unit test Edge Function recipe-review-assist (review.ts) với fetch giả: không gọi API thật, không cần key.
// Chạy: node supabase/scripts/test_recipe_review_unit.mjs   (Node ≥ 23 chạy thẳng .ts)
import assert from "node:assert/strict";
import { ALLERGENS, reviewRecipe } from "../functions/recipe-review-assist/review.ts";

console.warn = () => {};
const recipe = {
  title: "Trứng chiên nước mắm", category: "mon_man", servings: 2,
  ingredients: [{ name: "Trứng gà", grams: 200 }, { name: "Nước mắm", grams: 15 }], steps: ["Đánh trứng", "Chiên"],
  calories_per_serving: 165, protein_g_per_serving: 13, fat_g_per_serving: 11, carbs_g_per_serving: 1, allergen_codes: ["egg"],
};
const answers = (over = {}) => ({
  is_dish: { noul: 0.98 },
  category: { probabilities: { mon_man: 0.8, mon_xao: 0.2 } },
  kcal: { probabilities: { 0: 0.01, 1: 0.1, 2: 0.8, 3: 0.08, 4: 0.01 } },
  ...Object.fromEntries(Object.keys(ALLERGENS).map((c) => [`allergen_${c}`, { noul: c === "egg" ? 0.99 : 0.02 }])),
  ...over,
});
const fake = (a) => async (url, init) => {
  fake.sent = { url, body: JSON.parse(init.body) };
  return { ok: true, json: async () => ({ answers: a }) };
};

// 1. Request: đủ câu hỏi, đúng loại
let r = await reviewRecipe("KEY", recipe, fake(answers()));
const q = fake.sent.body.questions;
assert.equal(fake.sent.url, "https://generativelanguage.googleapis.com/v1beta/decisions");
assert.deepEqual([q.is_dish.type, q.category.type, q.kcal.type], ["noul", "choice", "score"]);
assert.equal(Object.keys(q).filter((k) => k.startsWith("allergen_")).length, 8);
assert.match(JSON.parse(fake.sent.body.input).ingredients[0], /Trứng gà: 200 g/);

// 2. Món bình thường: không cảnh báo
assert.deepEqual(r.warnings, []);
assert.equal(r.category.suggested, "mon_man");
assert.equal(r.kcal_plausibility.level, 2);

// 3. Cảnh báo: không phải món, sai danh mục, calo bất thường, dị ứng chưa gắn (hải sản từ nước mắm)
r = await reviewRecipe("KEY", recipe, fake(answers({
  is_dish: { noul: 0.2 },
  category: { probabilities: { mon_man: 0.1, mon_xao: 0.9 } },
  kcal: { probabilities: { 0: 0.05, 1: 0.05, 2: 0.1, 3: 0.1, 4: 0.7 } },
  allergen_seafood: { noul: 0.9 },
})));
assert.equal(r.warnings.length, 4, JSON.stringify(r.warnings));
assert.ok(r.warnings.some((w) => w.includes("Hải sản")));
assert.ok(!r.warnings.some((w) => w.includes("Trứng")), "dị ứng đã gắn thì không cảnh báo");

// 4. AI lỗi / thiếu câu trả lời → null (admin duyệt tay)
assert.equal(await reviewRecipe("KEY", recipe, async () => ({ ok: false, status: 503 })), null);
assert.equal(await reviewRecipe("KEY", recipe, async () => { throw new Error("net"); }), null);
assert.equal(await reviewRecipe("KEY", recipe, fake({ is_dish: { noul: 0.9 } })), null);

console.log("OK: recipe-review-assist unit (câu hỏi, cảnh báo, AI lỗi)");
