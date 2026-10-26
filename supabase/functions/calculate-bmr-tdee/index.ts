import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Công thức BMR/TDEE/macro chỉ nằm ở RPC calculate_nutrition_targets (app Dart khớp 100% với RPC).
// Bản cũ tự tính lại bằng số thực JS nên lệch 0,1 ở ~5% trường hợp, và nhận cả input rác.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } });
const fail = (status: number, code: string, message: string, field?: string) =>
  json({ error: { code, message, ...(field ? { field } : {}) } }, status);

const ENUMS: Record<string, string[]> = {
  gender: ["male", "female", "other"],
  activity_level: ["sedentary", "light", "moderate", "active", "very_active"],
  goal: ["lose_weight", "maintain", "gain_weight"],
};
const RANGES: Record<string, [number, number]> = { age: [10, 100], height_cm: [50, 250], weight_kg: [20, 300] };

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return fail(405, "METHOD_NOT_ALLOWED", "Chỉ hỗ trợ POST");

  let body;
  try {
    body = await req.json();
  } catch {
    return fail(400, "VALIDATION_ERROR", "Body phải là JSON");
  }
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    return fail(400, "VALIDATION_ERROR", "Body phải là JSON object");
  }
  for (const [field, allowed] of Object.entries(ENUMS)) {
    if (!allowed.includes(body[field])) return fail(400, "VALIDATION_ERROR", `${field} không hợp lệ`, field);
  }
  for (const [field, [min, max]] of Object.entries(RANGES)) {
    const v = body[field];
    if (typeof v !== "number" || !Number.isFinite(v) || v < min || v > max) {
      return fail(400, "VALIDATION_ERROR", `${field} phải là số trong khoảng ${min}–${max}`, field);
    }
  }
  if (!Number.isInteger(body.age)) return fail(400, "VALIDATION_ERROR", "age phải là số nguyên", "age");

  const authHeader = req.headers.get("Authorization");
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: authHeader ? { Authorization: authHeader } : {} },
  });

  const { gender, age, height_cm, weight_kg, activity_level, goal } = body;
  const { data: r, error } = await supabase.rpc("calculate_nutrition_targets", {
    p_gender: gender, p_age: age, p_height_cm: height_cm, p_weight_kg: weight_kg,
    p_activity_level: activity_level, p_goal: goal,
  });
  if (error) {
    console.error(error);
    return fail(500, "INTERNAL_ERROR", "Lỗi hệ thống, vui lòng thử lại");
  }

  let advice;
  if (goal === "lose_weight") {
    advice = `Mục tiêu giảm cân khoa học với mức thâm hụt ${Math.abs(r.calorie_difference)} kcal/ngày. Ưu tiên đạm cao (${r.protein_g}g) để duy trì khối cơ nạc và tạo cảm giác no lâu. Hạn chế đường đơn và dầu mỡ bão hòa.`;
  } else if (goal === "gain_weight") {
    advice = `Mục tiêu tăng cân/tăng cơ nạc với mức thặng dư ${r.calorie_difference} kcal/ngày kết hợp tập luyện kháng lực. Bổ sung ${r.protein_g}g đạm và chất béo tốt từ các loại hạt, quả bơ, dầu thực vật.`;
  } else {
    advice = `Mục tiêu duy trì vóc dáng và sức khỏe toàn diện. Duy trì chế độ ăn cân bằng đa lượng, uống đủ ${r.water_ml}ml nước mỗi ngày và bổ sung nhiều rau củ quả giàu chất xơ (${r.fiber_g}g/ngày).`;
  }

  let saved = false;
  if (body.save_to_profile === true) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return fail(401, "UNAUTHORIZED", "Cần đăng nhập để lưu hồ sơ");
    const { error: saveError } = await supabase.from("profiles").update({
      gender, age, height_cm, weight_kg, activity_level, goal,
      bmi: r.bmi, bmr: r.bmr, tdee: r.tdee, target_calories: r.target_calories,
      target_protein_g: r.protein_g, target_fat_g: r.fat_g, target_carbs_g: r.carbs_g,
      target_fiber_g: r.fiber_g, target_water_ml: r.water_ml,
      updated_at: new Date().toISOString(),
    }).eq("id", user.id);
    // Bản cũ bỏ qua lỗi này và vẫn báo success
    if (saveError) {
      console.error(saveError);
      return fail(500, "INTERNAL_ERROR", "Không lưu được hồ sơ");
    }
    saved = true;
  }

  return json({
    success: true,
    saved,
    data: {
      bmi: r.bmi,
      bmi_classification: r.bmi_classification,
      bmr: r.bmr,
      tdee: r.tdee,
      target_calories: r.target_calories,
      calorie_difference: r.calorie_difference,
      macros: { protein_g: r.protein_g, fat_g: r.fat_g, carbs_g: r.carbs_g, fiber_g: r.fiber_g, water_ml: r.water_ml },
      macro_percentages: r.macro_percentages,
      advice,
    },
  });
});
