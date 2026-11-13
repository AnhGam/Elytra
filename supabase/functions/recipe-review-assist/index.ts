import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { reviewRecipe } from "./review.ts";

// Sprint 7: admin bấm "AI chấm" trên món chờ duyệt → Gemini Decision 1 chấm sẵn → lưu recipes.ai_review.
//   POST /recipe-review-assist  { "recipe_id": uuid }
// Quyền: kiểm is_admin() TRONG DB bằng token người gọi; chỉ sau đó mới dùng service_role để ghi ai_review.
// Chỉ hỗ trợ admin: không tự duyệt, không sửa món.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
const fail = (status: number, code: string, message: string, field?: string) =>
  json({ error: { code, message, ...(field ? { field } : {}) } }, status);

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return fail(405, "METHOD_NOT_ALLOWED", "Chỉ hỗ trợ POST");

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return fail(401, "UNAUTHORIZED", "Phiên đăng nhập không hợp lệ");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return fail(401, "UNAUTHORIZED", "Phiên đăng nhập không hợp lệ");

  // Kiểm quyền admin trong DB (không tin app)
  const { data: isAdmin, error: adminErr } = await supabase.rpc("is_admin");
  if (adminErr) {
    console.error(adminErr);
    return fail(500, "INTERNAL_ERROR", "Lỗi hệ thống, vui lòng thử lại");
  }
  if (isAdmin !== true) return fail(403, "FORBIDDEN", "Chỉ quản trị viên được dùng chức năng này");

  let body: { recipe_id?: unknown } = {};
  try {
    body = await req.json();
  } catch { /* body rỗng → báo thiếu recipe_id bên dưới */ }
  const recipeId = String(body?.recipe_id ?? "");
  if (!UUID_RE.test(recipeId)) return fail(400, "VALIDATION_ERROR", "recipe_id không hợp lệ", "recipe_id");

  // Admin đọc được mọi món nhờ RLS "Admins read all recipes"
  const { data: r } = await supabase
    .from("recipes")
    .select(`id, title, category, servings, status, submitted_at, instructions,
      calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving,
      recipe_ingredients(ingredient_name_raw, amount_g, order_index), recipe_allergens(allergens(code))`)
    .eq("id", recipeId)
    .maybeSingle();
  if (!r) return fail(404, "RECIPE_NOT_FOUND", "Không tìm thấy món ăn", "recipe_id");
  if (r.status !== "pending") return fail(409, "RECIPE_NOT_PENDING", "Món không còn ở trạng thái chờ duyệt", "recipe_id");

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  // deno-lint-ignore no-explicit-any
  const rr = r as any;
  const review = apiKey
    ? await reviewRecipe(apiKey, {
      title: rr.title,
      category: rr.category,
      servings: rr.servings,
      // deno-lint-ignore no-explicit-any
      ingredients: [...(rr.recipe_ingredients ?? [])].sort((a: any, b: any) => a.order_index - b.order_index)
        // deno-lint-ignore no-explicit-any
        .map((i: any) => ({ name: i.ingredient_name_raw, grams: Number(i.amount_g) })),
      // deno-lint-ignore no-explicit-any
      steps: (Array.isArray(rr.instructions) ? rr.instructions : []).map((s: any) => [s.title, s.description].filter(Boolean).join(": ")),
      calories_per_serving: Number(rr.calories_per_serving),
      protein_g_per_serving: Number(rr.protein_g_per_serving),
      fat_g_per_serving: Number(rr.fat_g_per_serving),
      carbs_g_per_serving: Number(rr.carbs_g_per_serving),
      // deno-lint-ignore no-explicit-any
      allergen_codes: (rr.recipe_allergens ?? []).map((x: any) => x.allergens?.code).filter(Boolean),
    })
    : null;
  // AI lỗi / hết hạn mức → vẫn 200: admin duyệt tay như bình thường
  if (!review) return json({ recipe_id: recipeId, ai_review: null, message: "AI tạm thời không chấm được, admin duyệt tay" });

  // Đã kiểm quyền admin ở trên; service_role chỉ dùng để ghi ai_review của món đang chờ duyệt
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  // Chỉ ghi nếu món chưa bị gửi lại trong lúc AI đang chấm (điểm phải khớp đúng bản đã chấm)
  const { error: saveErr } = await admin.from("recipes").update({ ai_review: review })
    .eq("id", recipeId).eq("status", "pending").eq("submitted_at", rr.submitted_at);
  if (saveErr) console.error("Không lưu được ai_review:", saveErr);
  return json({ recipe_id: recipeId, ai_review: review });
});
