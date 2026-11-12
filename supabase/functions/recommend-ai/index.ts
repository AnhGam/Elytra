import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { classifyIntent, decideDish, type Intent, rankByDecision, type RecipeCandidate } from "./decision.ts";
import {
  askGemini,
  BUDGET_NOTES,
  fallbackHowToCook,
  fallbackNutrition,
  fallbackRecommend,
  MEAL_NAMES_VI,
  OUT_OF_SCOPE_MESSAGE,
  type RecipeDetail,
} from "./chat.ts";

// Sprint 6 (Tuần 9-10): Trợ lý dinh dưỡng. Một endpoint, 5 việc (xem docs/api-contract.md mục 3):
//   accepted_recipe_id         → "Ăn món này": log_meal (cùng logic POST /meal-logs)
//   intent = recommend         → meal_calorie_budget → SQL recommend_dishes_for_user (10 ứng viên)
//                                → Gemini Decision 1 chọn món → Gemini chat giải thích
//   intent = how_to_cook       → bước nấu + nguyên liệu từ DB → Gemini chat diễn đạt lại
//   intent = nutrition         → số liệu dinh dưỡng + dị ứng từ DB → Gemini chat diễn đạt lại
//   không gửi intent, có message → Gemini Decision 1 phân loại câu (thêm out_of_scope)
// Mọi số liệu/món đều từ DB; AI lỗi → thứ tự SQL / câu mẫu, vẫn trả 200.
// Món nhận/từ chối + xác suất lưu vào chat_messages để sau này hiệu chỉnh ngưỡng / tự train mô hình.

const CANDIDATE_LIMIT = 10;
const MEAL_TYPES = ["breakfast", "lunch", "dinner", "snack"];
const INTENTS = ["recommend", "how_to_cook", "nutrition"];
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface RecommendRequest {
  session_id?: string;
  intent?: string;
  recipe_id?: string;
  message?: string;
  meal_type?: string;
  target_calories?: number;
  rejected_recipe_ids?: string[];
  accepted_recipe_id?: string;
  servings?: number;
  client_request_id?: string;
}

interface Budget {
  status: "ok" | "low" | "capped" | "goal_reached";
  target_kcal: number | null;
  base_kcal: number;
  remaining_kcal: number;
  daily_kcal: number;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });

const STATUS: Record<string, number> = {
  VALIDATION_ERROR: 400,
  UNAUTHORIZED: 401,
  PROFILE_NOT_FOUND: 404,
  RECIPE_NOT_FOUND: 404,
  IDEMPOTENCY_CONFLICT: 422,
};

const MESSAGES: Record<string, string> = {
  VALIDATION_ERROR: "Dữ liệu không hợp lệ",
  UNAUTHORIZED: "Phiên đăng nhập không hợp lệ hoặc đã hết hạn",
  PROFILE_NOT_FOUND: "Chưa hoàn tất hồ sơ thể trạng",
  RECIPE_NOT_FOUND: "Không tìm thấy món ăn",
  IDEMPOTENCY_CONFLICT: "client_request_id đã dùng cho một món khác",
};

const fail = (code: string, message = MESSAGES[code], field?: string) =>
  json({ error: { code, message, ...(field ? { field } : {}) } }, STATUS[code] ?? 500);

// deno-lint-ignore no-explicit-any
function fromDbError(err: any) {
  if (MESSAGES[err.message]) return fail(err.message, MESSAGES[err.message], err.hint ?? undefined);
  if (err.code === "22P02") return fail("VALIDATION_ERROR");
  if (String(err.code).startsWith("PGRST3") || err.code === "42501") return fail("UNAUTHORIZED");
  console.error(err);
  return fail("INTERNAL_ERROR", "Lỗi hệ thống, vui lòng thử lại");
}

// Món + bước nấu + nguyên liệu + dị ứng. RLS chỉ cho đọc món đã duyệt.
async function loadRecipe(supabase: SupabaseClient, id: string): Promise<RecipeDetail | null> {
  const { data } = await supabase
    .from("recipes")
    .select(`id, title, servings, prep_time_minutes, cook_time_minutes, video_url, instructions,
      calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
      recipe_ingredients(raw_text, order_index), recipe_allergens(allergens(name_vi))`)
    .eq("id", id)
    .maybeSingle();
  if (!data) return null;
  // deno-lint-ignore no-explicit-any
  const { recipe_ingredients, recipe_allergens, ...r } = data as any;
  return {
    ...r,
    instructions: Array.isArray(r.instructions) ? r.instructions : [],
    // deno-lint-ignore no-explicit-any
    ingredients: (recipe_ingredients ?? []).sort((a: any, b: any) => a.order_index - b.order_index).map((x: any) => x.raw_text),
    // deno-lint-ignore no-explicit-any
    allergens: (recipe_allergens ?? []).map((x: any) => x.allergens?.name_vi).filter(Boolean),
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: { code: "METHOD_NOT_ALLOWED", message: "Chỉ hỗ trợ POST" } }, 405);

  // 1. Xác thực (User JWT)
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return fail("UNAUTHORIZED");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return fail("UNAUTHORIZED");

  // 2. Đọc + kiểm tra payload (biên tin cậy: mọi giá trị từ app)
  let payload: RecommendRequest;
  try {
    payload = await req.json();
  } catch {
    payload = {};
  }
  if (typeof payload !== "object" || payload === null || Array.isArray(payload)) payload = {};
  // null = không gửi (Dart hay gửi 'session_id': null ở lượt đầu)
  payload = Object.fromEntries(Object.entries(payload).filter(([, v]) => v !== null)) as RecommendRequest;

  const mealType = payload.meal_type ?? "lunch";
  if (!MEAL_TYPES.includes(mealType)) return fail("VALIDATION_ERROR", "meal_type không hợp lệ", "meal_type");
  if (payload.intent !== undefined && !INTENTS.includes(payload.intent)) {
    return fail("VALIDATION_ERROR", "intent phải là recommend, how_to_cook hoặc nutrition", "intent");
  }
  const rejectedRecipeIds = payload.rejected_recipe_ids ?? [];
  if (!Array.isArray(rejectedRecipeIds) || rejectedRecipeIds.length > 50 || !rejectedRecipeIds.every((x) => UUID_RE.test(String(x)))) {
    return fail("VALIDATION_ERROR", "rejected_recipe_ids phải là mảng uuid (tối đa 50)", "rejected_recipe_ids");
  }
  for (const f of ["session_id", "accepted_recipe_id", "recipe_id", "client_request_id"] as const) {
    if (payload[f] !== undefined && !UUID_RE.test(String(payload[f]))) return fail("VALIDATION_ERROR", `${f} không hợp lệ`, f);
  }
  if (payload.target_calories !== undefined && !(Number(payload.target_calories) >= 100 && Number(payload.target_calories) <= 2000)) {
    return fail("VALIDATION_ERROR", "target_calories phải trong khoảng 100–2000", "target_calories");
  }
  const rawMessage = typeof payload.message === "string" ? payload.message.trim() : "";
  if (rawMessage.length > 500) return fail("VALIDATION_ERROR", "message tối đa 500 ký tự", "message");
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

  // 3. Phiên chat: session_id của người khác bị RLS chặn → tạo phiên mới
  let sessionId: string | undefined = payload.session_id;
  if (sessionId) {
    const { data } = await supabase.from("chat_sessions").select("id").eq("id", sessionId).maybeSingle();
    if (!data) sessionId = undefined;
  }
  if (!sessionId) {
    const { data: newSession, error: sessErr } = await supabase
      .from("chat_sessions")
      .insert({ user_id: user.id, meal_type: mealType, target_kcal: payload.target_calories ?? null })
      .select("id")
      .single();
    if (sessErr) console.error("Không tạo được chat session:", sessErr);
    sessionId = newSession?.id;
  }
  // Ghi lần lượt: cùng 1 lệnh insert thì các dòng trùng created_at, lịch sử chat mất thứ tự
  // deno-lint-ignore no-explicit-any
  const saveMessages = async (...rows: any[]) => {
    if (!sessionId) return;
    for (const r of rows) await supabase.from("chat_messages").insert({ session_id: sessionId, user_id: user.id, ...r });
  };

  // 4. "Ăn món này": ghi nhật ký qua log_meal + lưu lượt nhận món
  if (payload.accepted_recipe_id) {
    const { data: logged, error: logErr } = await supabase.rpc("log_meal", {
      p_meal_type: mealType,
      p_recipe_id: payload.accepted_recipe_id,
      p_servings: payload.servings ?? null,
      p_client_request_id: payload.client_request_id ?? null,
    });
    if (logErr) return fromDbError(logErr);
    const message = `Đã ghi **${logged.item.name}** (${Math.round(logged.item.kcal)} kcal) vào bữa ${MEAL_NAMES_VI[mealType]}.`;
    await saveMessages(
      { role: "user", content: "Ăn món này", metadata: { intent: "accept", accepted_recipe_id: payload.accepted_recipe_id, meal_type: mealType } },
      { role: "assistant", content: message, metadata: { logged_item_id: logged.item.id, replayed: logged.replayed } },
    );
    return json({ session_id: sessionId, intent: "accept", status: "logged", message, logged: logged.item, budget: logged.budget });
  }

  // 5. Xác định ý định: app gửi intent (bấm chip) hoặc mô hình quyết định phân loại câu gõ tự do
  let intent: Intent = (payload.intent as Intent) ??
    (rawMessage && geminiApiKey ? await classifyIntent(geminiApiKey, rawMessage) : "recommend");
  const userMessage = rawMessage || (intent === "how_to_cook" ? "Nấu món này thế nào?"
    : intent === "nutrition" ? "Món này dinh dưỡng thế nào?" : `Gợi ý bữa ${MEAL_NAMES_VI[mealType]}`);

  // Hỏi về món: món app gửi, không thì món đứng đầu lượt gợi ý gần nhất của phiên
  let recipeId = payload.recipe_id;
  if ((intent === "how_to_cook" || intent === "nutrition") && !recipeId && sessionId) {
    const { data } = await supabase.from("chat_messages").select("suggested_recipe_ids")
      .eq("session_id", sessionId).eq("role", "assistant").neq("suggested_recipe_ids", "{}")
      .order("created_at", { ascending: false }).limit(1).maybeSingle();
    recipeId = data?.suggested_recipe_ids?.[0];
  }
  if ((intent === "how_to_cook" || intent === "nutrition") && !recipeId) {
    if (payload.intent) return fail("VALIDATION_ERROR", "Cần recipe_id để hỏi về món", "recipe_id");
    intent = "recommend"; // câu gõ tự do nhưng chưa có món nào để hỏi → gợi ý món
  }

  if (intent === "out_of_scope") {
    await saveMessages(
      { role: "user", content: userMessage, metadata: { intent } },
      { role: "assistant", content: OUT_OF_SCOPE_MESSAGE, metadata: { intent } },
    );
    return json({ session_id: sessionId, intent, status: "out_of_scope", message: OUT_OF_SCOPE_MESSAGE, suggested_recipes: [], fallback: false });
  }

  // 6. Cách nấu / dinh dưỡng: dữ liệu từ DB, Gemini chỉ diễn đạt lại
  if (intent === "how_to_cook" || intent === "nutrition") {
    const recipe = await loadRecipe(supabase, recipeId!);
    if (!recipe) return fail("RECIPE_NOT_FOUND", MESSAGES.RECIPE_NOT_FOUND, "recipe_id");
    const facts = intent === "how_to_cook" ? fallbackHowToCook(recipe) : fallbackNutrition(recipe);
    const task = intent === "how_to_cook"
      ? "Hướng dẫn nấu món dưới đây theo từng bước, ngắn gọn, dễ làm theo. CHỈ dùng nguyên liệu và các bước có trong dữ liệu, không thêm bước hay nguyên liệu, không đổi định lượng."
      : "Giải thích thông tin dinh dưỡng của món dưới đây và món này hợp với người đang ăn kiêng hay không. CHỈ dùng số liệu có trong dữ liệu, không tự tính hay thêm số liệu khác.";
    const reply = geminiApiKey
      ? await askGemini(geminiApiKey, `Bạn là Trợ lý Dinh dưỡng của ứng dụng Elytra, trả lời bằng tiếng Việt, Markdown, tối đa 3 đoạn.\n${task}\n\nDữ liệu món:\n${facts}`, userMessage)
      : "";
    const message = reply || facts;
    await saveMessages(
      { role: "user", content: userMessage, metadata: { intent, recipe_id: recipeId } },
      { role: "assistant", content: message, metadata: { intent, recipe_id: recipeId, fallback: !reply } },
    );
    return json({ session_id: sessionId, intent, status: "answered", message, recipe, fallback: !reply });
  }

  // 7. Gợi ý món. Calo bữa: theo phần còn lại hôm nay, có ngưỡng (bỏ qua nếu app truyền target_calories)
  let budget: Budget | null = null;
  if (payload.target_calories === undefined) {
    const { data, error } = await supabase.rpc("meal_calorie_budget", { p_meal_type: mealType });
    if (error) return fromDbError(error);
    budget = data as Budget;
  }
  const budgetStatus = budget?.status ?? "ok";
  const targetCal = Number(payload.target_calories ?? budget?.target_kcal ?? 0);

  if (budgetStatus === "goal_reached") {
    const message = `Hôm nay bạn đã đạt mục tiêu calo (còn ${budget!.remaining_kcal} kcal). Mình không gợi ý thêm món chính; nếu đói, ưu tiên rau, trái cây hoặc đồ uống không đường nhé.`;
    await saveMessages(
      { role: "user", content: userMessage, rejected_recipe_ids: rejectedRecipeIds, metadata: { intent } },
      { role: "assistant", content: message, metadata: { intent, meal_type: mealType, budget_status: budgetStatus } },
    );
    return json({ session_id: sessionId, intent, status: budgetStatus, budget, message, suggested_recipes: [],
      rejected_recipe_ids: rejectedRecipeIds, fallback: false, decision_mode: null });
  }

  // SQL lọc cứng + chấm điểm → ứng viên
  const { data: candidates, error: rpcErr } = await supabase.rpc("recommend_dishes_for_user", {
    p_uid: user.id,
    p_meal_type: mealType,
    p_target_calories: targetCal,
    p_exclude_recipe_ids: rejectedRecipeIds,
    p_limit: CANDIDATE_LIMIT,
  });
  if (rpcErr) return fromDbError(rpcErr);
  const sqlList: RecipeCandidate[] = candidates || [];

  // Mô hình quyết định chọn món. Chỉ gửi dữ liệu cần để chọn, không gửi cân nặng/tuổi
  let probs: Record<string, number> | null = null;
  if (geminiApiKey && sqlList.length > 1) {
    const since = new Date(Date.now() - 3 * 24 * 3600 * 1000).toISOString();
    const [profile, recent, rejected] = await Promise.all([
      supabase.from("profiles").select("goal").eq("id", user.id).maybeSingle(),
      supabase.from("meal_log_items").select("name").eq("user_id", user.id).gte("created_at", since).limit(30),
      rejectedRecipeIds.length
        ? supabase.from("recipes").select("title").in("id", rejectedRecipeIds)
        : Promise.resolve({ data: [] as { title: string }[] }),
    ]);
    probs = await decideDish(geminiApiKey, {
      goal: profile.data?.goal ?? null,
      meal_type: mealType,
      meal_calorie_target: Math.round(targetCal),
      calories_left_today: budget?.remaining_kcal ?? null,
      eaten_last_3_days: (recent.data ?? []).map((x: { name: string }) => x.name),
      rejected_dishes: (rejected.data ?? []).map((x: { title: string }) => x.title),
      user_message: rawMessage || null,
    }, sqlList, mealType);
  }
  const recipeList = rankByDecision(sqlList, probs);

  // Gemini chat chỉ viết lời giải thích cho món đã chọn
  let reply = "";
  if (geminiApiKey && recipeList.length > 0) {
    const summary = recipeList.slice(0, 3).map((r, i) =>
      `${i + 1}. Món: ${r.title} | ${r.calories_per_serving} kcal | Protein: ${r.protein_g_per_serving}g | Fat: ${r.fat_g_per_serving}g | Carbs: ${r.carbs_g_per_serving}g | Lý do: ${r.match_reason}`
    ).join("\n");
    reply = await askGemini(geminiApiKey, `Bạn là Trợ lý Dinh dưỡng của ứng dụng Elytra. Hệ thống ĐÃ CHỌN món cho người dùng; nhiệm vụ của bạn chỉ là giải thích bằng tiếng Việt thân thiện, súc tích.
Quy tắc:
1. Món số 1 là món hệ thống chọn. Giới thiệu món số 1 và giải thích vì sao hợp với mục tiêu calo của người dùng. Món 2-3 chỉ nhắc ngắn làm phương án khác.
2. TUYỆT ĐỐI không nhắc món ngoài danh sách, không đổi thứ tự, không thay đổi số liệu dinh dưỡng.
3. Nếu người dùng vừa từ chối món trước, xác nhận đã đổi món.
4. Tối đa 2-3 đoạn ngắn, Markdown.
${BUDGET_NOTES[budgetStatus] ? `5. Nhắc người dùng: ${BUDGET_NOTES[budgetStatus]}\n` : ""}
Danh sách món (đã xếp theo lựa chọn của hệ thống):
${summary}
Mục tiêu bữa ăn: Bữa ${MEAL_NAMES_VI[mealType]} (~${Math.round(targetCal)} kcal).`, userMessage);
  }
  const isFallback = !reply;
  const message = reply || fallbackRecommend(mealType, targetCal, recipeList, rejectedRecipeIds.length > 0, budgetStatus);

  // Lưu lượt chat + xác suất của mô hình quyết định (dữ liệu để hiệu chỉnh/tự train sau)
  await saveMessages(
    { role: "user", content: userMessage, rejected_recipe_ids: rejectedRecipeIds, metadata: { intent } },
    {
      role: "assistant",
      content: message,
      suggested_recipe_ids: recipeList.map((r) => r.id),
      metadata: {
        intent,
        fallback: isFallback,
        meal_type: mealType,
        budget_status: budgetStatus,
        decision_mode: probs ? "model" : "sql",
        decision_probabilities: probs,
      },
    },
  );

  return json({
    session_id: sessionId,
    intent,
    status: budgetStatus,
    budget,
    message,
    suggested_recipes: recipeList,
    rejected_recipe_ids: rejectedRecipeIds,
    fallback: isFallback,
    decision_mode: probs ? "model" : "sql",
  });
});
