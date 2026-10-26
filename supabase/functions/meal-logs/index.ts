import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Logic + kiểm tra dữ liệu nằm trong RPC (log_meal, get_daily_nutrition, get_nutrition_history)
// để Edge Function `chat` (intent accept) dùng lại. File này chỉ định tuyến và đổi lỗi sang format của api-contract.md.
//   POST   /meal-logs              ghi 1 món
//   GET    /meal-logs?date=        tổng hợp 1 ngày (Dashboard)
//   GET    /meal-logs/history?from=&to=   tổng theo ngày (biểu đồ)
//   PATCH  /meal-logs/items/:id    sửa khẩu phần / khối lượng
//   DELETE /meal-logs/items/:id    xóa 1 món

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE, OPTIONS",
};

const STATUS: Record<string, number> = {
  VALIDATION_ERROR: 400,
  UNAUTHORIZED: 401,
  PROFILE_NOT_FOUND: 404,
  RECIPE_NOT_FOUND: 404,
  INGREDIENT_NOT_FOUND: 404,
  ITEM_NOT_FOUND: 404,
  IDEMPOTENCY_CONFLICT: 422,
  NOT_FOUND: 404,
};

function json(body: unknown, status = 200) {
  return new Response(body === null ? null : JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function fail(code: string, message: string, field?: string) {
  return json({ error: { code, message, ...(field ? { field } : {}) } }, STATUS[code] ?? 500);
}

const MESSAGES: Record<string, string> = {
  VALIDATION_ERROR: "Dữ liệu không hợp lệ",
  UNAUTHORIZED: "Phiên đăng nhập không hợp lệ",
  PROFILE_NOT_FOUND: "Chưa hoàn tất hồ sơ thể trạng",
  RECIPE_NOT_FOUND: "Không tìm thấy món ăn",
  INGREDIENT_NOT_FOUND: "Không tìm thấy nguyên liệu",
  ITEM_NOT_FOUND: "Không tìm thấy món trong nhật ký",
  IDEMPOTENCY_CONFLICT: "client_request_id đã dùng cho một món khác",
};

// deno-lint-ignore no-explicit-any
function fromDbError(err: any) {
  if (MESSAGES[err.message]) return fail(err.message, MESSAGES[err.message], err.hint ?? undefined);
  // 22P02 sai uuid/số, 22007/22008 sai ngày: lỗi do input chứ không phải server
  if (["22P02", "22007", "22008"].includes(err.code)) return fail("VALIDATION_ERROR", MESSAGES.VALIDATION_ERROR);
  if (String(err.code).startsWith("PGRST3")) return fail("UNAUTHORIZED", MESSAGES.UNAUTHORIZED);
  console.error(err);
  return fail("INTERNAL_ERROR", "Lỗi hệ thống, vui lòng thử lại");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return fail("UNAUTHORIZED", MESSAGES.UNAUTHORIZED);

  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });

  const url = new URL(req.url);
  const path = url.pathname.split("/meal-logs")[1]?.replace(/\/$/, "") ?? "";
  const q = url.searchParams;

  try {
    const item = path.match(/^\/items\/([^/]+)$/);
    let b;
    if (req.method === "POST" || req.method === "PATCH") {
      try {
        b = await req.json();
      } catch {
        return fail("VALIDATION_ERROR", "Body phải là JSON");
      }
    }

    if (req.method === "POST" && path === "") {
      const { data, error } = await supabase.rpc("log_meal", {
        p_meal_type: b.meal_type ?? null,
        p_recipe_id: b.recipe_id ?? null,
        p_servings: b.servings ?? null,
        p_ingredient_id: b.ingredient_id ?? null,
        p_amount_g: b.amount_g ?? null,
        p_date: b.date ?? null,
        p_client_request_id: b.client_request_id ?? null,
      });
      if (error) return fromDbError(error);
      return json(data, data.replayed ? 200 : 201);
    }

    if (req.method === "GET" && path === "") {
      const { data, error } = await supabase.rpc("get_daily_nutrition", { p_date: q.get("date") });
      return error ? fromDbError(error) : json(data);
    }

    if (req.method === "GET" && path === "/history") {
      const { data, error } = await supabase.rpc("get_nutrition_history", { p_from: q.get("from"), p_to: q.get("to") });
      return error ? fromDbError(error) : json(data);
    }

    if (req.method === "PATCH" && item) {
      const { data, error } = await supabase.rpc("update_meal_log_item", {
        p_item_id: item[1],
        p_servings: b.servings ?? null,
        p_amount_g: b.amount_g ?? null,
      });
      return error ? fromDbError(error) : json(data);
    }

    if (req.method === "DELETE" && item) {
      // Xóa idempotent: món không tồn tại hoặc của người khác (RLS lọc) vẫn trả 204
      const { error } = await supabase.from("meal_log_items").delete().eq("id", item[1]);
      return error ? fromDbError(error) : json(null, 204);
    }

    return fail("NOT_FOUND", "Không có endpoint này");
  } catch (err) {
    return fromDbError(err);
  }
});
