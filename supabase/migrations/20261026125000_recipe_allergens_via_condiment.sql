-- Tách "gây dị ứng" khỏi "phân loại món": món nêm nước mắm vẫn gây dị ứng hải sản (phải lọc cho người dị ứng)
-- nhưng không phải "món hải sản". via_condiment = true khi chất dị ứng CHỈ đến từ gia vị chế biến sẵn.
ALTER TABLE public.recipe_allergens ADD COLUMN IF NOT EXISTS via_condiment BOOLEAN NOT NULL DEFAULT false;

-- Kiểu trả về đổi (thêm condiment_allergens) nên phải DROP. allergens giữ nguyên = MỌI chất dị ứng, lọc dị ứng vẫn dùng đủ.
DROP FUNCTION IF EXISTS public.search_recipes(TEXT, VARCHAR, BOOLEAN, NUMERIC, INT[], INT, INT);
CREATE FUNCTION public.search_recipes(
    p_query TEXT DEFAULT NULL,
    p_category VARCHAR DEFAULT NULL,
    p_is_vegetarian BOOLEAN DEFAULT NULL,
    p_max_calories NUMERIC DEFAULT NULL,
    p_exclude_allergen_ids INT[] DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID, title VARCHAR, slug VARCHAR, description TEXT, image_url TEXT, video_url TEXT, category VARCHAR, cuisine VARCHAR,
    servings INT, prep_time_minutes INT, cook_time_minutes INT, difficulty VARCHAR,
    calories_per_serving NUMERIC, protein_g_per_serving NUMERIC, fat_g_per_serving NUMERIC, carbs_g_per_serving NUMERIC,
    fiber_g_per_serving NUMERIC, sodium_mg_per_serving NUMERIC, is_vegetarian BOOLEAN, allergens INT[],
    condiment_allergens INT[]
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.title, r.slug, r.description, r.image_url, r.video_url, r.category, r.cuisine,
           r.servings, r.prep_time_minutes, r.cook_time_minutes, r.difficulty,
           r.calories_per_serving, r.protein_g_per_serving, r.fat_g_per_serving, r.carbs_g_per_serving,
           r.fiber_g_per_serving, r.sodium_mg_per_serving,
           (r.category = 'mon_chay') AS is_vegetarian,
           COALESCE(ARRAY_AGG(ra.allergen_id ORDER BY ra.allergen_id) FILTER (WHERE ra.allergen_id IS NOT NULL), '{}'::INT[]),
           COALESCE(ARRAY_AGG(ra.allergen_id ORDER BY ra.allergen_id) FILTER (WHERE ra.via_condiment), '{}'::INT[])
      FROM public.recipes r
      LEFT JOIN public.recipe_allergens ra ON r.id = ra.recipe_id
     WHERE r.is_verified
       AND (p_query IS NULL OR r.title ILIKE '%' || p_query || '%' OR r.slug ILIKE '%' || p_query || '%')
       AND (p_category IS NULL OR r.category = p_category)
       AND (p_is_vegetarian IS NULL OR (p_is_vegetarian = true AND r.category = 'mon_chay') OR (p_is_vegetarian = false AND r.category != 'mon_chay'))
       AND (p_max_calories IS NULL OR r.calories_per_serving <= p_max_calories)
       AND (p_exclude_allergen_ids IS NULL OR NOT EXISTS (
               SELECT 1 FROM public.recipe_allergens sub_ra
                WHERE sub_ra.recipe_id = r.id AND sub_ra.allergen_id = ANY(p_exclude_allergen_ids)))
     GROUP BY r.id
     ORDER BY r.title ASC
     LIMIT LEAST(GREATEST(p_limit, 0), 100)
    OFFSET GREATEST(p_offset, 0);
END;
$$;
GRANT EXECUTE ON FUNCTION public.search_recipes(TEXT, VARCHAR, BOOLEAN, NUMERIC, INT[], INT, INT) TO anon, authenticated, service_role;
