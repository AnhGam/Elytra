// Chấm sẵn món cộng đồng chờ duyệt bằng Gemini Decision 1 (kiểu Jev). Chỉ để HỖ TRỢ admin:
// không tự duyệt, không sửa món, không gỡ dị ứng (admin duyệt 100% tới khi đo xong bộ ~100 món gắn nhãn).
// Không import gì của Deno để test được bằng Node (supabase/scripts/test_recipe_review_unit.mjs).
import { DECISION_MODEL, decide } from "../_shared/decision.ts";

export interface ReviewInput {
  title: string;
  category: string;
  servings: number;
  ingredients: { name: string; grams: number }[];
  steps: string[];
  calories_per_serving: number;
  protein_g_per_serving: number;
  fat_g_per_serving: number;
  carbs_g_per_serving: number;
  allergen_codes: string[]; // dị ứng hệ thống đã tính từ nguyên liệu
}

export interface AiReview {
  model: string;
  reviewed_at: string;
  is_dish: number;
  category: { suggested: string; probability: number; matches_submitted: boolean };
  kcal_plausibility: { level: number; probabilities: Record<string, number> };
  allergens: Record<string, number>;
  warnings: string[];
}

// Tiếng Anh: mô hình quyết định giảm độ chính xác khi tiêu chí không phải tiếng Anh
const CATEGORIES: Record<string, string> = {
  gia_vi_an_kem: "Dipping sauce, pickles or condiment eaten alongside a meal, not a dish on its own.",
  mon_an_sang: "Vietnamese breakfast or noodle/rice dish such as pho, bun, banh mi, xoi, chao.",
  mon_canh: "Soup or broth dish (canh, sup, lau).",
  mon_chay: "Vegetarian dish without meat or seafood.",
  mon_kho: "Braised or caramel-simmered dish (kho).",
  mon_man: "Savory main dish eaten with rice that does not fit the other groups.",
  mon_nuong: "Grilled or roasted dish (nuong).",
  mon_xao: "Stir-fried dish (xao).",
};

export const ALLERGENS: Record<string, { en: string; vi: string }> = {
  seafood: { en: "fish, shrimp, crab, squid or other seafood (including fish sauce)", vi: "Hải sản" },
  egg: { en: "eggs", vi: "Trứng" },
  dairy: { en: "milk or dairy products", vi: "Sữa" },
  peanut: { en: "peanuts", vi: "Đậu phộng" },
  tree_nut: { en: "tree nuts such as cashew, almond, walnut", vi: "Hạt cây" },
  soy: { en: "soy, tofu, soy sauce or other soy products", vi: "Đậu nành" },
  gluten: { en: "wheat, barley or other gluten grains", vi: "Gluten" },
  sesame: { en: "sesame", vi: "Mè" },
};

const KCAL_LEVELS = [
  "Implausibly low for one adult serving (likely wrong amounts or too many servings)",
  "Low but possible (light dish or side)",
  "Typical for one adult serving",
  "High but possible (heavy dish)",
  "Implausibly high for one serving (likely wrong amounts or too few servings)",
];

export async function reviewRecipe(apiKey: string, r: ReviewInput, fetchFn: typeof fetch = fetch): Promise<AiReview | null> {
  const questions: Record<string, unknown> = {
    is_dish: { type: "noul", instructions: "Is this a real, edible cooking recipe (not spam, a joke, or a non-food item)?" },
    category: { type: "choice", instructions: "Which group does this Vietnamese dish belong to?", criteria: CATEGORIES },
    kcal: {
      type: "score",
      instructions: "How plausible are the calories per serving for this dish, given its ingredients, amounts and number of servings?",
      criteria: KCAL_LEVELS,
    },
  };
  for (const [code, a] of Object.entries(ALLERGENS)) {
    questions[`allergen_${code}`] = { type: "noul", instructions: `Does this dish contain ${a.en}?` };
  }
  const input = JSON.stringify({
    title: r.title,
    servings: r.servings,
    ingredients: r.ingredients.map((i) => `${i.name}: ${Math.round(i.grams)} g`),
    steps: r.steps,
    per_serving: {
      kcal: Math.round(r.calories_per_serving),
      protein_g: r.protein_g_per_serving,
      fat_g: r.fat_g_per_serving,
      carbs_g: r.carbs_g_per_serving,
    },
  });
  // deno-lint-ignore no-explicit-any
  const a = (await decide(apiKey, input, questions, fetchFn)) as any;
  if (!a?.is_dish || !a?.category?.probabilities || !a?.kcal?.probabilities) return null;

  const catProbs: Record<string, number> = a.category.probabilities;
  const suggested = Object.keys(catProbs).reduce((x, y) => (catProbs[y] > catProbs[x] ? y : x));
  const kcalProbs: Record<string, number> = a.kcal.probabilities;
  const level = Number(Object.keys(kcalProbs).reduce((x, y) => (kcalProbs[y] > kcalProbs[x] ? y : x)));
  const allergens: Record<string, number> = {};
  for (const code of Object.keys(ALLERGENS)) allergens[code] = a[`allergen_${code}`]?.noul ?? 0;

  const warnings: string[] = [];
  if (a.is_dish.noul < 0.5) warnings.push("Có thể không phải công thức món ăn thật");
  if (suggested !== r.category && catProbs[suggested] >= 0.6) {
    warnings.push(`Danh mục có thể là "${suggested}" thay vì "${r.category}"`);
  }
  if ((level === 0 || level === 4) && kcalProbs[String(level)] >= 0.5) {
    warnings.push(`Calo/khẩu phần (${Math.round(r.calories_per_serving)} kcal) có vẻ bất thường: kiểm tra số khẩu phần và khối lượng`);
  }
  for (const [code, p] of Object.entries(allergens)) {
    if (p >= 0.7 && !r.allergen_codes.includes(code)) {
      warnings.push(`Có thể chứa ${ALLERGENS[code].vi} nhưng nguyên liệu chưa gắn dị ứng này`);
    }
  }

  return {
    model: DECISION_MODEL,
    reviewed_at: new Date().toISOString(),
    is_dish: a.is_dish.noul,
    category: { suggested, probability: catProbs[suggested], matches_submitted: suggested === r.category },
    kcal_plausibility: { level, probabilities: kcalProbs },
    allergens,
    warnings,
  };
}
