-- Hàm tính toán BMR, TDEE, Calo mục tiêu và phân bổ Macro chuẩn khoa học
CREATE OR REPLACE FUNCTION public.calculate_nutrition_targets(
    p_gender VARCHAR,
    p_age INT,
    p_height_cm NUMERIC,
    p_weight_kg NUMERIC,
    p_activity_level VARCHAR,
    p_goal VARCHAR
)
RETURNS JSONB AS $$
DECLARE
    v_bmi NUMERIC;
    v_bmi_class TEXT;
    v_bmr NUMERIC;
    v_factor NUMERIC;
    v_tdee NUMERIC;
    v_target_calories NUMERIC;
    v_protein_factor NUMERIC;
    v_protein_g NUMERIC;
    v_protein_kcal NUMERIC;
    v_fat_kcal NUMERIC;
    v_fat_g NUMERIC;
    v_carbs_kcal NUMERIC;
    v_carbs_g NUMERIC;
    v_fiber_g NUMERIC;
    v_water_ml NUMERIC;
    v_result JSONB;
BEGIN
    -- 1. Tính BMI (Chỉ số khối cơ thể) và phân loại theo WHO WPRO cho người Châu Á
    v_bmi := ROUND(p_weight_kg / ((p_height_cm / 100.0) * (p_height_cm / 100.0)), 1);
    IF v_bmi < 18.5 THEN
        v_bmi_class := 'Thiếu cân';
    ELSIF v_bmi < 23.0 THEN
        v_bmi_class := 'Bình thường';
    ELSIF v_bmi < 25.0 THEN
        v_bmi_class := 'Tiền béo phì (Thừa cân)';
    ELSE
        v_bmi_class := 'Béo phì';
    END IF;

    -- 2. Tính BMR theo công thức Mifflin-St Jeor
    IF LOWER(p_gender) = 'female' THEN
        v_bmr := ROUND((10.0 * p_weight_kg) + (6.25 * p_height_cm) - (5.0 * p_age) - 161.0, 1);
    ELSE
        v_bmr := ROUND((10.0 * p_weight_kg) + (6.25 * p_height_cm) - (5.0 * p_age) + 5.0, 1);
    END IF;

    -- 3. Hệ số hoạt động thể chất (Physical Activity Level)
    CASE LOWER(p_activity_level)
        WHEN 'sedentary' THEN v_factor := 1.200;
        WHEN 'light' THEN v_factor := 1.375;
        WHEN 'moderate' THEN v_factor := 1.550;
        WHEN 'active' THEN v_factor := 1.725;
        WHEN 'very_active' THEN v_factor := 1.900;
        ELSE v_factor := 1.375;
    END CASE;

    -- 4. Tính TDEE (Tổng năng lượng tiêu hao hằng ngày)
    v_tdee := ROUND(v_bmr * v_factor, 1);

    -- 5. Năng lượng mục tiêu (Target Calories) theo mục tiêu thể trạng
    CASE LOWER(p_goal)
        WHEN 'lose_weight' THEN
            v_target_calories := v_tdee - 500.0;
            -- Sàn an toàn chuyển hóa (không bao giờ giảm dưới mức tối thiểu an toàn)
            IF LOWER(p_gender) = 'female' AND v_target_calories < 1200.0 THEN
                v_target_calories := 1200.0;
            ELSIF LOWER(p_gender) != 'female' AND v_target_calories < 1500.0 THEN
                v_target_calories := 1500.0;
            END IF;
        WHEN 'gain_weight' THEN
            v_target_calories := v_tdee + 400.0;
        ELSE -- 'maintain'
            v_target_calories := v_tdee;
    END CASE;

    -- 6. Phân bổ dinh dưỡng đa lượng (Macronutrients Distribution)
    -- Protein: gram/kg theo mục tiêu
    CASE LOWER(p_goal)
        WHEN 'lose_weight' THEN v_protein_factor := 2.0; -- Giữ cơ, no lâu
        WHEN 'gain_weight' THEN v_protein_factor := 1.8; -- Xây dựng cơ nạc
        ELSE v_protein_factor := 1.6; -- Duy trì sức khỏe
    END CASE;

    v_protein_g := ROUND(p_weight_kg * v_protein_factor, 1);
    v_protein_kcal := v_protein_g * 4.0;

    -- Fat: 25% tổng lượng calo
    v_fat_kcal := v_target_calories * 0.25;
    v_fat_g := ROUND(v_fat_kcal / 9.0, 1);

    -- Carbs: Calo còn lại sau khi trừ Protein và Fat
    v_carbs_kcal := v_target_calories - v_protein_kcal - v_fat_kcal;
    IF v_carbs_kcal < 0 THEN
        v_carbs_kcal := 0;
    END IF;
    v_carbs_g := ROUND(v_carbs_kcal / 4.0, 1);

    -- Chất xơ (Fiber): 14g / 1000 kcal, tối thiểu 25g
    v_fiber_g := ROUND((v_target_calories / 1000.0) * 14.0, 1);
    IF v_fiber_g < 25.0 THEN
        v_fiber_g := 25.0;
    END IF;

    -- Nước khuyến nghị (Water): 35ml / kg
    v_water_ml := ROUND(p_weight_kg * 35.0, 0);

    -- Đóng gói kết quả JSONB
    v_result := jsonb_build_object(
        'bmi', v_bmi,
        'bmi_classification', v_bmi_class,
        'bmr', v_bmr,
        'tdee', v_tdee,
        'target_calories', v_target_calories,
        'calorie_difference', v_target_calories - v_tdee,
        'protein_g', v_protein_g,
        'fat_g', v_fat_g,
        'carbs_g', v_carbs_g,
        'fiber_g', v_fiber_g,
        'water_ml', v_water_ml,
        'macro_percentages', jsonb_build_object(
            'protein_pct', ROUND((v_protein_kcal / v_target_calories) * 100.0, 1),
            'fat_pct', ROUND((v_fat_kcal / v_target_calories) * 100.0, 1),
            'carbs_pct', ROUND((v_carbs_kcal / v_target_calories) * 100.0, 1)
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Cho phép gọi hàm qua Supabase RPC từ client
GRANT EXECUTE ON FUNCTION public.calculate_nutrition_targets(VARCHAR, INT, NUMERIC, NUMERIC, VARCHAR, VARCHAR) TO anon, authenticated;;
