-- Migration: 20261005000010_create_recipe_creation_engine.sql
-- Description: Automated recipe creation function that calculates nutrition from ingredients and inherits allergens

CREATE OR REPLACE FUNCTION public.create_recipe_with_nutrition(
    p_title VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_servings INT DEFAULT 4,
    p_prep_time_minutes INT DEFAULT 15,
    p_cook_time_minutes INT DEFAULT 30,
    p_category VARCHAR DEFAULT 'mon_man',
    p_difficulty VARCHAR DEFAULT 'easy',
    p_image_url TEXT DEFAULT NULL,
    p_video_url TEXT DEFAULT NULL,
    p_instructions JSONB DEFAULT '[]'::jsonb,
    p_ingredients JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_recipe_id UUID;
    v_slug VARCHAR;
    v_ing_elem JSONB;
    v_ing_id UUID;
    v_ing_name_raw VARCHAR;
    v_raw_text TEXT;
    v_amount NUMERIC;
    v_unit VARCHAR;
    v_amount_g NUMERIC;
    
    v_cal_100 NUMERIC;
    v_prot_100 NUMERIC;
    v_fat_100 NUMERIC;
    v_carbs_100 NUMERIC;
    v_fiber_100 NUMERIC;
    v_sod_100 NUMERIC;
    
    v_total_cal NUMERIC := 0;
    v_total_prot NUMERIC := 0;
    v_total_fat NUMERIC := 0;
    v_total_carbs NUMERIC := 0;
    v_total_fiber NUMERIC := 0;
    v_total_sod NUMERIC := 0;
    
    v_factor NUMERIC;
    v_order_idx INT := 1;
    v_aid INT;
    v_result JSONB;
    v_created_allergens INT[] := '{}'::INT[];
BEGIN
    -- 1. Tạo slug chuẩn hóa từ title
    v_slug := lower(regexp_replace(p_title, '[^a-zA-Z0-9]+', '-', 'g'));
    v_slug := trim(both '-' from v_slug) || '-' || substr(md5(random()::text), 1, 6);

    -- 2. Duyệt qua danh sách nguyên liệu và tích lũy giá trị dinh dưỡng
    FOR v_ing_elem IN SELECT * FROM jsonb_array_elements(p_ingredients)
    LOOP
        v_ing_id := (v_ing_elem->>'ingredient_id')::UUID;
        v_ing_name_raw := COALESCE(v_ing_elem->>'ingredient_name_raw', 'Nguyên liệu');
        v_raw_text := COALESCE(v_ing_elem->>'raw_text', v_ing_name_raw);
        v_amount := COALESCE((v_ing_elem->>'amount')::NUMERIC, 1);
        v_unit := COALESCE(v_ing_elem->>'unit', 'phần');
        v_amount_g := COALESCE((v_ing_elem->>'amount_g')::NUMERIC, 100);

        v_cal_100 := 0; v_prot_100 := 0; v_fat_100 := 0;
        v_carbs_100 := 0; v_fiber_100 := 0; v_sod_100 := 0;

        IF v_ing_id IS NOT NULL THEN
            SELECT 
                COALESCE(calories_per_100g, 0),
                COALESCE(protein_per_100g, 0),
                COALESCE(fat_per_100g, 0),
                COALESCE(carbs_per_100g, 0),
                COALESCE(fiber_per_100g, 0),
                COALESCE(sodium_mg, 0)
            INTO 
                v_cal_100, v_prot_100, v_fat_100, v_carbs_100, v_fiber_100, v_sod_100
            FROM public.ingredients
            WHERE id = v_ing_id;
        END IF;

        v_factor := v_amount_g / 100.0;
        v_total_cal := v_total_cal + (v_cal_100 * v_factor);
        v_total_prot := v_total_prot + (v_prot_100 * v_factor);
        v_total_fat := v_total_fat + (v_fat_100 * v_factor);
        v_total_carbs := v_total_carbs + (v_carbs_100 * v_factor);
        v_total_fiber := v_total_fiber + (v_fiber_100 * v_factor);
        v_total_sod := v_total_sod + (v_sod_100 * v_factor);
    END LOOP;

    -- 3. Tạo bản ghi Recipe trong bảng public.recipes
    INSERT INTO public.recipes (
        title, slug, description, category, cuisine,
        servings, prep_time_minutes, cook_time_minutes, difficulty,
        image_url, video_url, instructions,
        total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg,
        calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving
    ) VALUES (
        p_title, v_slug, p_description, p_category, 'vietnamese',
        p_servings, p_prep_time_minutes, p_cook_time_minutes, p_difficulty,
        p_image_url, p_video_url, p_instructions,
        round(v_total_cal, 1), round(v_total_prot, 1), round(v_total_fat, 1), round(v_total_carbs, 1), round(v_total_fiber, 1), round(v_total_sod, 1),
        round(v_total_cal / p_servings, 1), round(v_total_prot / p_servings, 1), round(v_total_fat / p_servings, 1),
        round(v_total_carbs / p_servings, 1), round(v_total_fiber / p_servings, 1), round(v_total_sod / p_servings, 1)
    )
    RETURNING id INTO v_recipe_id;

    -- 4. Thêm từng dòng nguyên liệu vào recipe_ingredients
    v_order_idx := 1;
    FOR v_ing_elem IN SELECT * FROM jsonb_array_elements(p_ingredients)
    LOOP
        v_ing_id := (v_ing_elem->>'ingredient_id')::UUID;
        v_ing_name_raw := COALESCE(v_ing_elem->>'ingredient_name_raw', 'Nguyên liệu');
        v_raw_text := COALESCE(v_ing_elem->>'raw_text', v_ing_name_raw);
        v_amount := COALESCE((v_ing_elem->>'amount')::NUMERIC, 1);
        v_unit := COALESCE(v_ing_elem->>'unit', 'phần');
        v_amount_g := COALESCE((v_ing_elem->>'amount_g')::NUMERIC, 100);

        v_cal_100 := 0; v_prot_100 := 0; v_fat_100 := 0;
        v_carbs_100 := 0; v_fiber_100 := 0; v_sod_100 := 0;

        IF v_ing_id IS NOT NULL THEN
            SELECT 
                COALESCE(calories_per_100g, 0), COALESCE(protein_per_100g, 0), COALESCE(fat_per_100g, 0),
                COALESCE(carbs_per_100g, 0), COALESCE(fiber_per_100g, 0), COALESCE(sodium_mg, 0)
            INTO 
                v_cal_100, v_prot_100, v_fat_100, v_carbs_100, v_fiber_100, v_sod_100
            FROM public.ingredients
            WHERE id = v_ing_id;

            -- Kế thừa tác nhân dị ứng từ ingredient_allergens
            FOR v_aid IN 
                SELECT allergen_id FROM public.ingredient_allergens WHERE ingredient_id = v_ing_id
            LOOP
                INSERT INTO public.recipe_allergens (recipe_id, allergen_id)
                VALUES (v_recipe_id, v_aid)
                ON CONFLICT DO NOTHING;

                IF NOT (v_aid = ANY(v_created_allergens)) THEN
                    v_created_allergens := array_append(v_created_allergens, v_aid);
                END IF;
            END LOOP;
        END IF;

        INSERT INTO public.recipe_ingredients (
            recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
            amount, unit, amount_g,
            calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
        ) VALUES (
            v_recipe_id, v_ing_id, v_order_idx, v_raw_text, v_ing_name_raw,
            v_amount, v_unit, v_amount_g,
            v_cal_100, v_prot_100, v_fat_100, v_carbs_100, v_fiber_100, v_sod_100
        );

        v_order_idx := v_order_idx + 1;
    END LOOP;

    -- 5. Trả về kết quả JSON chi tiết
    SELECT jsonb_build_object(
        'id', r.id,
        'title', r.title,
        'slug', r.slug,
        'servings', r.servings,
        'calories_per_serving', r.calories_per_serving,
        'protein_g_per_serving', r.protein_g_per_serving,
        'fat_g_per_serving', r.fat_g_per_serving,
        'carbs_g_per_serving', r.carbs_g_per_serving,
        'total_calories', r.total_calories,
        'inherited_allergens', v_created_allergens,
        'ingredients_count', v_order_idx - 1
    ) INTO v_result
    FROM public.recipes r
    WHERE r.id = v_recipe_id;

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_recipe_with_nutrition(VARCHAR, TEXT, INT, INT, INT, VARCHAR, VARCHAR, TEXT, TEXT, JSONB, JSONB) TO anon, authenticated, service_role;
