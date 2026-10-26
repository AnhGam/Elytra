import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface BMRRequest {
  gender: "male" | "female" | "other";
  age: number;
  height_cm: number;
  weight_kg: number;
  activity_level: "sedentary" | "light" | "moderate" | "active" | "very_active";
  goal: "lose_weight" | "maintain" | "gain_weight";
  save_to_profile?: boolean;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed. Use POST." }), {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body: BMRRequest = await req.json();
    const { gender, age, height_cm, weight_kg, activity_level, goal, save_to_profile } = body;

    // Validate inputs
    if (!gender || !age || !height_cm || !weight_kg || !activity_level || !goal) {
      return new Response(
        JSON.stringify({
          error: "Missing required parameters: gender, age, height_cm, weight_kg, activity_level, goal.",
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (age < 10 || age > 100 || height_cm < 50 || height_cm > 250 || weight_kg < 20 || weight_kg > 300) {
      return new Response(
        JSON.stringify({ error: "Input values are out of physical realistic ranges." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. BMI calculation (WHO Asia-Pacific WPRO standard)
    const height_m = height_cm / 100.0;
    const bmi = Number((weight_kg / (height_m * height_m)).toFixed(1));
    let bmi_classification = "Bình thường";
    if (bmi < 18.5) {
      bmi_classification = "Thiếu cân";
    } else if (bmi >= 18.5 && bmi < 23.0) {
      bmi_classification = "Bình thường (Chuẩn Châu Á)";
    } else if (bmi >= 23.0 && bmi < 25.0) {
      bmi_classification = "Tiền béo phì (Thừa cân)";
    } else {
      bmi_classification = "Béo phì";
    }

    // 2. BMR calculation (Mifflin-St Jeor)
    let bmr = 0;
    if (gender === "female") {
      bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161;
    } else {
      bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5;
    }
    bmr = Number(bmr.toFixed(1));

    // 3. Physical Activity Level (PAL) Multiplier
    const palMap: Record<string, number> = {
      sedentary: 1.2,
      light: 1.375,
      moderate: 1.55,
      active: 1.725,
      very_active: 1.9,
    };
    const pal = palMap[activity_level] || 1.375;
    const tdee = Number((bmr * pal).toFixed(1));

    // 4. Target Calories & Caloric Deficit/Surplus
    let target_calories = tdee;
    let calorie_difference = 0;

    if (goal === "lose_weight") {
      calorie_difference = -500;
      target_calories = tdee - 500;
      // Metabolic safety floor
      const minSafeCalories = gender === "female" ? 1200 : 1500;
      if (target_calories < minSafeCalories) {
        target_calories = minSafeCalories;
        calorie_difference = target_calories - tdee;
      }
    } else if (goal === "gain_weight") {
      calorie_difference = 400;
      target_calories = tdee + 400;
    }
    target_calories = Number(target_calories.toFixed(1));

    // 5. Macronutrients Distribution
    let proteinFactor = 1.6;
    if (goal === "lose_weight") proteinFactor = 2.0; // Preserve lean mass during deficit
    if (goal === "gain_weight") proteinFactor = 1.8; // Build muscle

    const protein_g = Number((weight_kg * proteinFactor).toFixed(1));
    const protein_kcal = protein_g * 4.0;

    // Fat: 25% of target calories
    const fat_kcal = target_calories * 0.25;
    const fat_g = Number((fat_kcal / 9.0).toFixed(1));

    // Carbs: Remaining calories
    const carbs_kcal = Math.max(0, target_calories - protein_kcal - fat_kcal);
    const carbs_g = Number((carbs_kcal / 4.0).toFixed(1));

    // Fiber: 14g / 1000 kcal
    const fiber_g = Number(Math.max(25.0, (target_calories / 1000.0) * 14.0).toFixed(1));

    // Daily Water recommendation: 35ml / kg
    const water_ml = Math.round(weight_kg * 35);

    // Percentage splits
    const macro_percentages = {
      protein_pct: Number(((protein_kcal / target_calories) * 100).toFixed(1)),
      fat_pct: Number(((fat_kcal / target_calories) * 100).toFixed(1)),
      carbs_pct: Number(((carbs_kcal / target_calories) * 100).toFixed(1)),
    };

    // Clinical / Nutritionist Advice Summary
    let advice = "";
    if (goal === "lose_weight") {
      advice = `Mục tiêu giảm cân khoa học với mức thâm hụt ${Math.abs(calorie_difference)} kcal/ngày. Ưu tiên đạm cao (${protein_g}g) để duy trì khối cơ nạc và tạo cảm giác no lâu. Hạn chế đường đơn và dầu mỡ bão hòa.`;
    } else if (goal === "gain_weight") {
      advice = `Mục tiêu tăng cân/tăng cơ nạc với mức thặng dư ${calorie_difference} kcal/ngày kết hợp tập luyện kháng lực. Bổ sung ${protein_g}g đạm và chất béo tốt từ các loại hạt, quả bơ, dầu thực vật.`;
    } else {
      advice = `Mục tiêu duy trì vóc dáng và sức khỏe toàn diện. Duy trì chế độ ăn cân bằng đa lượng, uống đủ ${water_ml}ml nước mỗi ngày và bổ sung nhiều rau củ quả giàu chất xơ (${fiber_g}g/ngày).`;
    }

    const result = {
      bmi,
      bmi_classification,
      bmr,
      tdee,
      target_calories,
      calorie_difference,
      macros: {
        protein_g,
        fat_g,
        carbs_g,
        fiber_g,
        water_ml,
      },
      macro_percentages,
      advice,
    };

    // 6. Optional: Persist to profiles if user is authenticated
    const authHeader = req.headers.get("Authorization");
    if (save_to_profile && authHeader) {
      const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
      const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
      const supabase = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: authHeader } },
      });

      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (!userError && user) {
        await supabase
          .from("profiles")
          .update({
            gender,
            age,
            height_cm,
            weight_kg,
            activity_level,
            goal,
            bmi,
            bmr,
            tdee,
            target_calories,
            target_protein_g: protein_g,
            target_fat_g: fat_g,
            target_carbs_g: carbs_g,
            target_fiber_g: fiber_g,
            target_water_ml: water_ml,
            updated_at: new Date().toISOString(),
          })
          .eq("id", user.id);
      }
    }

    return new Response(JSON.stringify({ success: true, data: result }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
