// Mô hình quyết định (Gemini Decision 1, kiểu Jev): không sinh chữ, trả xác suất cho từng lựa chọn.
// Dùng để (1) chọn món trong các ứng viên SQL, (2) phân loại câu người dùng gõ tự do.
// Không import gì của Deno để test được bằng Node (supabase/scripts/test_recommend_ai_unit.mjs).

export const GEMINI_API = "https://generativelanguage.googleapis.com/v1beta";
export const DECISION_MODEL = "models/gemini-decision-1";

export interface RecipeCandidate {
  id: string;
  title: string;
  slug: string;
  category: string;
  image_url: string | null;
  servings: number;
  prep_time_minutes: number;
  cook_time_minutes: number;
  calories_per_serving: number;
  protein_g_per_serving: number;
  fat_g_per_serving: number;
  carbs_g_per_serving: number;
  score: number;
  match_reason: string;
  is_favorite?: boolean;
  decision_probability?: number | null;
}

// Gọi Decisions API (POST /v1beta/decisions). Trả answers hoặc null khi lỗi/timeout (người gọi tự fallback).
async function decide(
  apiKey: string,
  input: string,
  questions: Record<string, unknown>,
  fetchFn: typeof fetch,
): Promise<Record<string, { probabilities?: Record<string, number> }> | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 3000);
  try {
    const res = await fetchFn(`${GEMINI_API}/decisions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      signal: controller.signal,
      body: JSON.stringify({ model: DECISION_MODEL, input, questions }),
    });
    if (!res.ok) {
      console.warn(`Decision API HTTP ${res.status}, dùng fallback`);
      return null;
    }
    return (await res.json())?.answers ?? null;
  } catch (e) {
    console.warn("Decision API lỗi/timeout, dùng fallback:", e);
    return null;
  } finally {
    clearTimeout(timer);
  }
}

// Chọn món: xác suất theo recipe id, hoặc null khi lỗi (khi đó giữ thứ tự điểm SQL).
export async function decideDish(
  apiKey: string,
  state: Record<string, unknown>,
  candidates: RecipeCandidate[],
  mealType: string,
  fetchFn: typeof fetch = fetch,
): Promise<Record<string, number> | null> {
  if (candidates.length < 2) return null; // choice cần ít nhất 2 lựa chọn
  // Khóa r0..r9: API sắp xếp khóa theo bảng chữ cái, giữ ≤ 10 để không có r10 xếp trước r2
  const list = candidates.slice(0, 10);
  const criteria: Record<string, string> = {};
  list.forEach((r, i) => {
    criteria[`r${i}`] = `${r.title} (${r.category}): ${Math.round(r.calories_per_serving)} kcal, ` +
      `${r.protein_g_per_serving} g protein, ${r.carbs_g_per_serving} g carbs, ${r.fat_g_per_serving} g fat, ` +
      `${r.prep_time_minutes + r.cook_time_minutes} min`;
  });
  const answers = await decide(apiKey, JSON.stringify(state), {
    dish: {
      type: "choice",
      // Tiếng Anh: mô hình quyết định giảm độ chính xác khi tiêu chí không phải tiếng Anh
      instructions: `Which Vietnamese dish should this user eat for ${mealType}? Fit their goal and the ` +
        `calories they have left today, avoid dishes eaten in the last 3 days or rejected, and follow ` +
        `their message if any.`,
      criteria,
    },
  }, fetchFn);
  const probs = answers?.dish?.probabilities;
  if (!probs) return null;
  const byId: Record<string, number> = {};
  list.forEach((r, i) => byId[r.id] = probs[`r${i}`] ?? 0);
  return byId;
}

// Xếp lại theo xác suất của mô hình; không có xác suất thì giữ nguyên thứ tự SQL (sort ổn định).
export function rankByDecision(candidates: RecipeCandidate[], probs: Record<string, number> | null): RecipeCandidate[] {
  if (!probs) return candidates.map((r) => ({ ...r, decision_probability: null }));
  return candidates
    .map((r) => ({ ...r, decision_probability: probs[r.id] ?? 0 }))
    .sort((a, b) => b.decision_probability! - a.decision_probability!);
}

export type Intent = "recommend" | "how_to_cook" | "nutrition" | "out_of_scope";

// Phân loại câu gõ tự do. Lỗi → "recommend" (an toàn: vẫn gợi ý món).
// out_of_scope chỉ khi chắc ≥ 0,7, tránh từ chối nhầm câu hỏi về ăn uống.
export async function classifyIntent(apiKey: string, message: string, fetchFn: typeof fetch = fetch): Promise<Intent> {
  const answers = await decide(apiKey, message, {
    intent: {
      type: "choice",
      instructions: "What does this Vietnamese user message to a nutrition assistant ask for?",
      criteria: {
        how_to_cook: "How to cook or prepare a dish: steps, ingredients, cooking time.",
        nutrition: "Nutrition facts of a dish: calories, protein, fat, carbs, allergens, whether it is healthy.",
        out_of_scope: "Not about food, meals, cooking or nutrition.",
        recommend: "Wants a dish suggestion, another dish, or says what they feel like eating.",
      },
    },
  }, fetchFn);
  const p = answers?.intent?.probabilities;
  if (!p) return "recommend";
  const best = (Object.keys(p) as Intent[]).reduce((a, b) => (p[b] > p[a] ? b : a));
  if (best === "out_of_scope" && p.out_of_scope < 0.7) return "recommend";
  return best;
}
