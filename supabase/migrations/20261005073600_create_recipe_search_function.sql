-- Migration: 20261005000009_create_recipe_search_function.sql
-- Description: RPC function for searching and filtering recipes with allergen exclusion, calorie cap, and pagination

CREATE OR REPLACE FUNCTION public.search_recipes(
    p_query TEXT DEFAULT NULL,
    p_category VARCHAR DEFAULT NULL,
    p_is_vegetarian BOOLEAN DEFAULT NULL,
    p_max_calories NUMERIC DEFAULT NULL,
    p_exclude_allergen_ids INT[] DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    slug VARCHAR,
    description TEXT,
    image_url TEXT,
    video_url TEXT,
    category VARCHAR,
    cuisine VARCHAR,
    servings INT,
    prep_time_minutes INT,
    cook_time_minutes INT,
    difficulty VARCHAR,
    calories_per_serving NUMERIC,
    protein_g_per_serving NUMERIC,
    fat_g_per_serving NUMERIC,
    carbs_g_per_serving NUMERIC,
    fiber_g_per_serving NUMERIC,
    sodium_mg_per_serving NUMERIC,
    is_vegetarian BOOLEAN,
    allergens INT[]
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.title,
        r.slug,
        r.description,
        r.image_url,
        r.video_url,
        r.category,
        r.cuisine,
        r.servings,
        r.prep_time_minutes,
        r.cook_time_minutes,
        r.difficulty,
        r.calories_per_serving,
        r.protein_g_per_serving,
        r.fat_g_per_serving,
        r.carbs_g_per_serving,
        r.fiber_g_per_serving,
        r.sodium_mg_per_serving,
        (r.category = 'mon_chay') AS is_vegetarian,
        COALESCE(ARRAY_AGG(ra.allergen_id) FILTER (WHERE ra.allergen_id IS NOT NULL), '{}'::INT[]) as allergens
    FROM public.recipes r
    LEFT JOIN public.recipe_allergens ra ON r.id = ra.recipe_id
    WHERE 
        -- Filter by search query
        (p_query IS NULL OR r.title ILIKE '%' || p_query || '%' OR r.slug ILIKE '%' || p_query || '%')
        -- Filter by category
        AND (p_category IS NULL OR r.category = p_category)
        -- Filter by vegetarian (either explicitly mon_chay or not)
        AND (p_is_vegetarian IS NULL OR (p_is_vegetarian = true AND r.category = 'mon_chay') OR (p_is_vegetarian = false AND r.category != 'mon_chay'))
        -- Filter by calorie budget
        AND (p_max_calories IS NULL OR r.calories_per_serving <= p_max_calories)
        -- Exclude allergens if specified
        AND (
            p_exclude_allergen_ids IS NULL 
            OR NOT EXISTS (
                SELECT 1 FROM public.recipe_allergens sub_ra 
                WHERE sub_ra.recipe_id = r.id 
                  AND sub_ra.allergen_id = ANY(p_exclude_allergen_ids)
            )
        )
    GROUP BY r.id
    ORDER BY r.title ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Grant execute to anon and authenticated
GRANT EXECUTE ON FUNCTION public.search_recipes(TEXT, VARCHAR, BOOLEAN, NUMERIC, INT[], INT, INT) TO anon, authenticated, service_role;
