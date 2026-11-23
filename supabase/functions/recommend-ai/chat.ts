// Gemini chat: CHỈ diễn đạt lại dữ liệu đã có (món đã chọn, bước nấu, số liệu dinh dưỡng từ DB).
// Lỗi / timeout / trả rỗng → text "" (người gọi dùng câu mẫu bên dưới) + error để ghi vào lịch sử chat. Không import Deno để test bằng Node.
import { GEMINI_API, type RecipeCandidate } from "../_shared/decision.ts";

export const CHAT_MODEL = "gemini-flash-lite-latest";

export const MEAL_NAMES_VI: Record<string, string> = { breakfast: "sáng", lunch: "trưa", dinner: "tối", snack: "phụ" };

export async function askGemini(
  apiKey: string,
  systemPrompt: string,
  userMessage: string,
  fetchFn: typeof fetch = fetch,
): Promise<{ text: string; error: string | null }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 6500);
  try {
    const res = await fetchFn(`${GEMINI_API}/models/${CHAT_MODEL}:generateContent`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      signal: controller.signal,
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: userMessage }] }],
        systemInstruction: { parts: [{ text: systemPrompt }] },
        // Suy nghĩ ở mức thấp nhất: chỉ diễn đạt lại dữ liệu có sẵn (thinkingBudget bị từ chối HTTP 400, đo 12/11/2026)
        generationConfig: { temperature: 0.6, maxOutputTokens: 800, thinkingConfig: { thinkingLevel: "minimal" } },
      }),
    });
    if (!res.ok) {
      console.warn(`Gemini chat HTTP ${res.status}, dùng câu mẫu`);
      return { text: "", error: `HTTP ${res.status}: ${(await res.text().catch(() => "")).slice(0, 200)}` };
    }
    const body = await res.json();
    // Bỏ phần "thought" (model có suy nghĩ), chỉ lấy câu trả lời
    // deno-lint-ignore no-explicit-any
    const parts: any[] = body?.candidates?.[0]?.content?.parts ?? [];
    const text = parts.filter((p) => !p.thought).map((p) => p.text ?? "").join("").trim();
    return text ? { text, error: null } : { text: "", error: `empty (finishReason ${body?.candidates?.[0]?.finishReason ?? "none"})` };
  } catch (e) {
    console.warn("Gemini chat lỗi/timeout, dùng câu mẫu:", e);
    return { text: "", error: controller.signal.aborted ? "timeout" : String(e) };
  } finally {
    clearTimeout(timer);
  }
}

// OmniRoute (gateway OpenAI-compatible trên máy nhóm, mở ra ngoài bằng Tailscale Funnel): model mạnh hơn, không chịu hạn mức free tier.
// shortcut: chỉ chạy khi máy nhóm bật (cấu hình demo), máy tắt → askChat tự chuyển sang Gemini trực tiếp.
export type OmniConfig = { url: string; key: string; model: string };

export const OMNI_DEFAULT_MODEL = "agy/gemini-3-flash";

export function omniConfigFromEnv(get: (name: string) => string | undefined): OmniConfig | null {
  const url = get("OMNIROUTE_URL")?.trim().replace(/\/+$/, "");
  const key = get("OMNIROUTE_API_KEY")?.trim();
  if (!url || !key) return null;
  return { url, key, model: get("OMNIROUTE_MODEL")?.trim() || OMNI_DEFAULT_MODEL };
}

export async function askOmni(
  omni: OmniConfig,
  systemPrompt: string,
  userMessage: string,
  fetchFn: typeof fetch = fetch,
): Promise<{ text: string; error: string | null }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetchFn(`${omni.url}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${omni.key}` },
      signal: controller.signal,
      body: JSON.stringify({
        model: omni.model,
        messages: [{ role: "system", content: systemPrompt }, { role: "user", content: userMessage }],
        temperature: 0.6,
        max_tokens: 800,
        stream: false,
      }),
    });
    if (!res.ok) return { text: "", error: `HTTP ${res.status}: ${(await res.text().catch(() => "")).slice(0, 200)}` };
    const body = await res.json();
    const text = String(body?.choices?.[0]?.message?.content ?? "").trim();
    return text ? { text, error: null } : { text: "", error: `empty (finish_reason ${body?.choices?.[0]?.finish_reason ?? "none"})` };
  } catch (e) {
    return { text: "", error: controller.signal.aborted ? "timeout" : String(e) };
  } finally {
    clearTimeout(timer);
  }
}

// OmniRoute lỗi đường truyền 2 lần liên tiếp (máy nhóm tắt) → bỏ qua 5 phút. 1 lần chậm lẻ (model chậm lúc đầu) không tính.
// Biến cấp module: sống theo từng instance Edge Function (instance mới thì thử lại ngay).
const OMNI_COOLDOWN_MS = 5 * 60 * 1000;
let omniDownUntil = 0;
let omniFailStreak = 0; // số lần lỗi đường truyền liên tiếp
export function resetOmniCooldown() { omniDownUntil = 0; omniFailStreak = 0; } // cho unit test

// Thứ tự: OmniRoute → Gemini trực tiếp. `model` cho biết ai đã trả lời (ghi vào metadata để theo dõi), null = cả hai lỗi → câu mẫu.
export async function askChat(
  apiKey: string,
  omni: OmniConfig | null,
  systemPrompt: string,
  userMessage: string,
  fetchFn: typeof fetch = fetch,
): Promise<{ text: string; error: string | null; model: string | null }> {
  let omniError: string | null = null;
  if (omni && Date.now() >= omniDownUntil) {
    const r = await askOmni(omni, systemPrompt, userMessage, fetchFn);
    if (r.text) { omniFailStreak = 0; return { text: r.text, error: null, model: `omniroute/${omni.model}` }; }
    omniError = r.error;
    // Chỉ lỗi đường truyền mới tạm bỏ qua; lỗi HTTP / trả rỗng là OmniRoute vẫn chạy → lượt sau thử lại
    if (omniError === "timeout" || !/^(HTTP |empty)/.test(String(omniError))) {
      omniFailStreak++;
      if (omniFailStreak >= 2) { omniDownUntil = Date.now() + OMNI_COOLDOWN_MS; omniFailStreak = 0; }
    } else {
      omniFailStreak = 0;
    }
    console.warn("OmniRoute lỗi, chuyển sang Gemini trực tiếp:", omniError);
  }
  if (omni && omniError === null && Date.now() < omniDownUntil) omniError = "skipped (cooldown)";
  const g = await askGemini(apiKey, systemPrompt, userMessage, fetchFn);
  const error = omniError ? `omniroute: ${omniError}` : null;
  if (g.text) return { text: g.text, error, model: CHAT_MODEL };
  return { text: "", error: error ? `${error}; gemini: ${g.error}` : g.error, model: null };
}

// Dòng nhắc khi calo bữa đã bị chặn ngưỡng (meal_calorie_budget)
export const BUDGET_NOTES: Record<string, string> = {
  low: "Hôm nay bạn đã ăn khá nhiều, mình chọn món nhẹ để không vượt mục tiêu.",
  capped: "Các bữa trước bạn ăn ít, nhưng mình vẫn giữ bữa này ở mức vừa phải thay vì dồn hết calo còn lại.",
};

export function fallbackRecommend(
  mealType: string,
  targetCal: number,
  candidates: RecipeCandidate[],
  hasRejected: boolean,
  budgetStatus: string,
): string {
  const mealVi = MEAL_NAMES_VI[mealType] || "trưa";
  if (candidates.length === 0) {
    return `Hiện tại hệ thống chưa tìm thấy thêm món ăn nào phù hợp với các tiêu chí hạn chế của bạn cho bữa ${mealVi}. Bạn thử nới lỏng bộ lọc hoặc tăng giảm calo một chút nhé!`;
  }
  const top = candidates[0];
  let text = hasRejected
    ? `Đã ghi nhận bạn không chọn món trước đó. Mình đã đổi sang phương án khác phù hợp hơn cho bữa ${mealVi} (~${Math.round(targetCal)} kcal):\n\n`
    : `Dựa trên mục tiêu dinh dưỡng hôm nay (bữa ${mealVi} cần khoảng ~${Math.round(targetCal)} kcal), mình gợi ý cho bạn:\n\n`;
  if (BUDGET_NOTES[budgetStatus]) text += `${BUDGET_NOTES[budgetStatus]}\n\n`;
  text += `⭐ **${top.title}** (${top.calories_per_serving} kcal | ${top.protein_g_per_serving}g Đạm | ${top.carbs_g_per_serving}g Carbs)\n`;
  text += `👉 *${top.match_reason}*.\n`;
  const others = candidates.slice(1, 3);
  if (others.length > 0) {
    text += `\nNếu muốn đổi vị, bạn có thể tham khảo thêm:\n`;
    for (const r of others) text += `• **${r.title}**: ${r.calories_per_serving} kcal, ${r.protein_g_per_serving}g protein\n`;
  }
  return text + `\nChúc bạn có một bữa ăn ngon miệng và cân đối dinh dưỡng!`;
}

export interface RecipeDetail {
  id: string;
  title: string;
  servings: number;
  prep_time_minutes: number | null;
  cook_time_minutes: number | null;
  video_url: string | null;
  instructions: { step_number: number; title?: string; description?: string }[];
  ingredients: string[];
  calories_per_serving: number;
  protein_g_per_serving: number;
  fat_g_per_serving: number;
  carbs_g_per_serving: number;
  fiber_g_per_serving: number;
  sodium_mg_per_serving: number;
  allergens: string[];
}

// Cách nấu nguyên văn từ DB (dùng khi Gemini lỗi, và làm dữ liệu gốc cho Gemini diễn đạt)
export function fallbackHowToCook(r: RecipeDetail): string {
  const time = (r.prep_time_minutes ?? 0) + (r.cook_time_minutes ?? 0);
  let text = `**${r.title}** (${r.servings} khẩu phần${time ? `, ~${time} phút` : ""})\n\n`;
  if (r.ingredients.length) text += `**Nguyên liệu:**\n${r.ingredients.map((x) => `• ${x}`).join("\n")}\n\n`;
  const steps = [...r.instructions].sort((a, b) => a.step_number - b.step_number);
  text += steps.length
    ? `**Cách làm:**\n${steps.map((s) => `${s.step_number}. ${[s.title, s.description].filter(Boolean).join(": ")}`).join("\n")}`
    : "Món này chưa có hướng dẫn chi tiết.";
  if (r.video_url) text += `\n\nVideo: ${r.video_url}`;
  return text;
}

export function fallbackNutrition(r: RecipeDetail): string {
  let text = `**${r.title}**, 1 khẩu phần:\n` +
    `• Năng lượng: ${r.calories_per_serving} kcal\n` +
    `• Đạm: ${r.protein_g_per_serving} g | Chất béo: ${r.fat_g_per_serving} g | Tinh bột: ${r.carbs_g_per_serving} g\n` +
    `• Chất xơ: ${r.fiber_g_per_serving} g | Natri: ${r.sodium_mg_per_serving} mg`;
  text += r.allergens.length ? `\n• Chất gây dị ứng: ${r.allergens.join(", ")}` : `\n• Không có chất gây dị ứng đã biết`;
  return text;
}

export const OUT_OF_SCOPE_MESSAGE =
  "Mình là trợ lý dinh dưỡng nên chỉ hỗ trợ gợi ý món ăn, cách nấu và thông tin dinh dưỡng thôi. Bạn muốn mình gợi ý món cho bữa tới không?";
