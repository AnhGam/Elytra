-- Migration: 20261005000011_create_ingredient_management_functions.sql
-- Description: RPC functions for ingredient search, autocomplete, detail retrieval, and management

-- 1. Tìm kiếm và lọc nguyên liệu (hỗ trợ autocomplete, tìm theo tên tiếng Việt/không dấu/mã/danh mục)
CREATE OR REPLACE FUNCTION public.search_ingredients(
    p_query TEXT DEFAULT NULL,
    p_category_id INT DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    code VARCHAR,
    name_vi VARCHAR,
    name_en VARCHAR,
    category_id INT,
    category_name VARCHAR,
    calories_per_100g NUMERIC,
    protein_per_100g NUMERIC,
    fat_per_100g NUMERIC,
    carbs_per_100g NUMERIC,
    fiber_per_100g NUMERIC,
    sodium_mg NUMERIC,
    edible_portion_pct NUMERIC,
    density_g_per_ml NUMERIC,
    is_featured BOOLEAN,
    allergens JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.code,
        i.name_vi,
        i.name_en,
        i.category_id,
        ic.name_vi AS category_name,
        i.calories_per_100g,
        i.protein_per_100g,
        i.fat_per_100g,
        i.carbs_per_100g,
        i.fiber_per_100g,
        i.sodium_mg,
        i.edible_portion_pct,
        i.density_g_per_ml,
        i.is_featured,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'id', a.id,
                    'code', a.code,
                    'name_vi', a.name_vi
                )
            ) FILTER (WHERE a.id IS NOT NULL),
            '[]'::jsonb
        ) AS allergens
    FROM public.ingredients i
    JOIN public.ingredient_categories ic ON i.category_id = ic.id
    LEFT JOIN public.ingredient_allergens ia ON i.id = ia.ingredient_id
    LEFT JOIN public.allergens a ON ia.allergen_id = a.id
    WHERE i.is_active = TRUE
      AND (
          p_query IS NULL 
          OR p_query = '' 
          OR i.name_vi ILIKE '%' || p_query || '%' 
          OR i.name_unaccented ILIKE '%' || p_query || '%'
          OR i.name_en ILIKE '%' || p_query || '%'
          OR i.code ILIKE '%' || p_query || '%'
      )
      AND (p_category_id IS NULL OR i.category_id = p_category_id)
      AND (p_is_featured IS NULL OR i.is_featured = p_is_featured)
    GROUP BY i.id, ic.name_vi
    ORDER BY 
      CASE WHEN p_query IS NOT NULL AND i.name_vi ILIKE p_query || '%' THEN 1 ELSE 2 END,
      i.is_featured DESC,
      i.name_vi ASC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 2. Lấy thông tin chi tiết đầy đủ của một nguyên liệu (bao gồm cả vi chất, vitamin, khoáng chất, dị ứng)
CREATE OR REPLACE FUNCTION public.get_ingredient_details(
    p_ingredient_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'id', i.id,
        'code', i.code,
        'name_vi', i.name_vi,
        'name_en', i.name_en,
        'category_id', i.category_id,
        'category_name', ic.name_vi,
        'is_featured', i.is_featured,
        'edible_portion_pct', i.edible_portion_pct,
        'density_g_per_ml', i.density_g_per_ml,
        'macros_per_100g', jsonb_build_object(
            'calories', i.calories_per_100g,
            'protein_g', i.protein_per_100g,
            'fat_g', i.fat_per_100g,
            'carbs_g', i.carbs_per_100g,
            'fiber_g', i.fiber_per_100g,
            'water_g', i.water_g,
            'ash_g', i.ash_g
        ),
        'minerals_per_100g', jsonb_build_object(
            'calcium_mg', i.calcium_mg,
            'phosphorus_mg', i.phosphorus_mg,
            'iron_mg', i.iron_mg,
            'zinc_mg', i.zinc_mg,
            'sodium_mg', i.sodium_mg,
            'potassium_mg', i.potassium_mg,
            'magnesium_mg', i.magnesium_mg,
            'manganese_mg', i.manganese_mg,
            'copper_mcg', i.copper_mcg,
            'selenium_mcg', i.selenium_mcg
        ),
        'vitamins_per_100g', jsonb_build_object(
            'vit_c_mg', i.vit_c_mg,
            'thiamine_b1_mg', i.thiamine_b1_mg,
            'riboflavin_b2_mg', i.riboflavin_b2_mg,
            'niacin_b3_mg', i.niacin_b3_mg,
            'pantothenic_b5_mg', i.pantothenic_b5_mg,
            'vit_b6_mg', i.vit_b6_mg,
            'folate_b9_mcg', i.folate_b9_mcg,
            'vit_b12_mcg', i.vit_b12_mcg,
            'vit_a_rae_mcg', i.vit_a_rae_mcg,
            'vit_d_mcg', i.vit_d_mcg,
            'vit_e_mg', i.vit_e_mg,
            'vit_k_mcg', i.vit_k_mcg,
            'beta_carotene_mcg', i.beta_carotene_mcg
        ),
        'allergens', COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', a.id,
                        'code', a.code,
                        'name_vi', a.name_vi
                    )
                )
                FROM public.ingredient_allergens ia
                JOIN public.allergens a ON ia.allergen_id = a.id
                WHERE ia.ingredient_id = i.id
            ),
            '[]'::jsonb
        )
    ) INTO v_result
    FROM public.ingredients i
    JOIN public.ingredient_categories ic ON i.category_id = ic.id
    WHERE i.id = p_ingredient_id;

    RETURN v_result;
END;
$$;

-- 3. Tạo nguyên liệu mới (hỗ trợ đóng góp hoặc admin tạo nguyên liệu tùy chỉnh)
CREATE OR REPLACE FUNCTION public.create_custom_ingredient(
    p_name_vi VARCHAR,
    p_category_id INT,
    p_calories_per_100g NUMERIC,
    p_protein_per_100g NUMERIC,
    p_fat_per_100g NUMERIC,
    p_carbs_per_100g NUMERIC,
    p_fiber_per_100g NUMERIC DEFAULT 0,
    p_sodium_mg NUMERIC DEFAULT 0,
    p_edible_portion_pct NUMERIC DEFAULT 100.0,
    p_density_g_per_ml NUMERIC DEFAULT 1.0,
    p_allergen_ids INT[] DEFAULT '{}'::INT[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
    v_code VARCHAR;
    v_aid INT;
    v_result JSONB;
BEGIN
    -- Sinh mã định danh ngẫu nhiên dạng USR_xxxxx
    v_code := 'USR_' || substr(md5(random()::text), 1, 6);

    INSERT INTO public.ingredients (
        code,
        name_vi,
        name_unaccented,
        category_id,
        calories_per_100g,
        protein_per_100g,
        fat_per_100g,
        carbs_per_100g,
        fiber_per_100g,
        sodium_mg,
        edible_portion_pct,
        density_g_per_ml,
        is_featured,
        is_active
    ) VALUES (
        v_code,
        p_name_vi,
        lower(f_unaccent(p_name_vi)),
        p_category_id,
        p_calories_per_100g,
        p_protein_per_100g,
        p_fat_per_100g,
        p_carbs_per_100g,
        COALESCE(p_fiber_per_100g, 0),
        COALESCE(p_sodium_mg, 0),
        COALESCE(p_edible_portion_pct, 100.0),
        COALESCE(p_density_g_per_ml, 1.0),
        FALSE,
        TRUE
    ) RETURNING id INTO v_id;

    -- Thêm liên kết dị ứng nếu có
    IF p_allergen_ids IS NOT NULL AND array_length(p_allergen_ids, 1) > 0 THEN
        FOREACH v_aid IN ARRAY p_allergen_ids
        LOOP
            INSERT INTO public.ingredient_allergens (ingredient_id, allergen_id)
            VALUES (v_id, v_aid)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END IF;

    SELECT jsonb_build_object(
        'success', TRUE,
        'id', v_id,
        'code', v_code,
        'name_vi', p_name_vi
    ) INTO v_result;

    RETURN v_result;
END;
$$;
