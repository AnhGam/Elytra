-- Sprint 8: sở thích ăn uống (none | vegetarian) + điểm chất béo trong gợi ý món (đề cương: ràng buộc calo, protein, fat).

UPDATE public.profiles SET dietary_preference = 'none'
 WHERE dietary_preference IS NULL OR dietary_preference NOT IN ('none', 'vegetarian');
ALTER TABLE public.profiles ALTER COLUMN dietary_preference SET DEFAULT 'none';
ALTER TABLE public.profiles ALTER COLUMN dietary_preference SET NOT NULL;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_dietary_preference_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_dietary_preference_check CHECK (dietary_preference IN ('none', 'vegetarian'));

CREATE OR REPLACE FUNCTION public.recommend_dishes_for_user(
    p_uid UUID,
    p_meal_type VARCHAR DEFAULT 'lunch',
    p_target_calories NUMERIC DEFAULT NULL,
    p_exclude_recipe_ids UUID[] DEFAULT '{}'::UUID[],
    p_limit INT DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    slug VARCHAR,
    category VARCHAR,
    image_url TEXT,
    servings INT,
    prep_time_minutes INT,
    cook_time_minutes INT,
    calories_per_serving NUMERIC,
    protein_g_per_serving NUMERIC,
    fat_g_per_serving NUMERIC,
    carbs_g_per_serving NUMERIC,
    score NUMERIC,
    match_reason TEXT,
    is_favorite BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, extensions
AS $$
#variable_conflict use_column -- cột RETURNS TABLE (id, title...) trùng tên cột bảng
DECLARE
    v_target_cal NUMERIC;
    v_target_prot NUMERIC;
    v_daily_prot NUMERIC;
    v_daily_cal NUMERIC;
    v_daily_fat NUMERIC;
    v_target_fat NUMERIC;
    v_diet TEXT;
BEGIN
    -- SECURITY DEFINER bỏ qua RLS: chặn gọi bằng uid của người khác (lộ mục tiêu calo + suy ra dị ứng)
    IF p_uid IS NULL OR p_uid IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    SELECT target_calories, target_protein_g, target_fat_g, dietary_preference
      INTO v_daily_cal, v_daily_prot, v_daily_fat, v_diet
      FROM public.profiles WHERE id = p_uid;

    -- Calo bữa: truyền vào thì dùng, không thì lấy theo ngân sách còn lại (đã chặn 2 đầu); goal_reached → không gợi ý
    IF p_target_calories IS NOT NULL AND p_target_calories > 0 THEN
        v_target_cal := p_target_calories;
    ELSIF v_daily_cal IS NULL THEN
        v_target_cal := 600;
    ELSE
        v_target_cal := (public.meal_calorie_budget(p_meal_type) ->> 'target_kcal')::NUMERIC;
        IF v_target_cal IS NULL THEN
            RETURN;
        END IF;
    END IF;

    -- Đạm bữa tỉ lệ theo calo bữa so với calo ngày
    v_target_prot := ROUND(COALESCE(v_daily_prot * v_target_cal / NULLIF(v_daily_cal, 0), 25));
    -- Chất béo bữa tỉ lệ theo calo bữa; chỉ phạt khi món vượt mức này
    v_target_fat := ROUND(COALESCE(v_daily_fat * v_target_cal / NULLIF(v_daily_cal, 0), 20));

    RETURN QUERY
    WITH candidates AS (
        SELECT r.id, r.title, r.slug, r.category, r.image_url, r.servings,
               COALESCE(r.prep_time_minutes, 15) AS prep_time_minutes,
               COALESCE(r.cook_time_minutes, 20) AS cook_time_minutes,
               r.calories_per_serving, r.protein_g_per_serving, r.fat_g_per_serving, r.carbs_g_per_serving,
               EXISTS (SELECT 1 FROM public.user_favorite_recipes f WHERE f.user_id = p_uid AND f.recipe_id = r.id) AS is_favorite
          FROM public.recipes r
         WHERE r.is_verified
           AND r.category <> 'gia_vi_an_kem'
           -- Ăn chay: chỉ gợi ý món chay
           AND (v_diet IS DISTINCT FROM 'vegetarian' OR r.category = 'mon_chay')
           -- Loại bỏ món đã từ chối
           AND (p_exclude_recipe_ids IS NULL OR r.id <> ALL(p_exclude_recipe_ids))
           -- Loại bỏ món chứa chất dị ứng của người dùng (kể cả dị ứng đến từ gia vị)
           AND NOT EXISTS (
               SELECT 1
                 FROM public.recipe_allergens ra
                 JOIN public.user_allergens ua ON ua.allergen_id = ra.allergen_id
                WHERE ra.recipe_id = r.id AND ua.user_id = p_uid
           )
    ),
    scored AS (
        SELECT c.*,
               GREATEST(0, 1.0 - ABS(c.calories_per_serving - v_target_cal) / GREATEST(v_target_cal, 100)) AS cal_score,
               GREATEST(0, 1.0 - ABS(c.protein_g_per_serving - v_target_prot) / GREATEST(v_target_prot, 10)) AS prot_score,
               CASE WHEN c.fat_g_per_serving <= v_target_fat THEN 1.0
                    ELSE GREATEST(0, 1.0 - (c.fat_g_per_serving - v_target_fat) / GREATEST(v_target_fat, 10)) END AS fat_score,
               CASE WHEN (c.prep_time_minutes + c.cook_time_minutes) <= 30 THEN 1.0
                    WHEN (c.prep_time_minutes + c.cook_time_minutes) <= 45 THEN 0.8
                    ELSE 0.6 END AS time_score
          FROM candidates c
    )
    SELECT s.id, s.title, s.slug, s.category, s.image_url, s.servings,
           s.prep_time_minutes, s.cook_time_minutes,
           s.calories_per_serving, s.protein_g_per_serving, s.fat_g_per_serving, s.carbs_g_per_serving,
           -- Món yêu thích +0,1 (tối đa 1): ưu tiên nhẹ, không lấn át món hợp calo hơn
           LEAST(1, ROUND((0.40 * s.cal_score + 0.30 * s.prot_score + 0.15 * s.fat_score + 0.15 * s.time_score
                           + CASE WHEN s.is_favorite THEN 0.10 ELSE 0 END)::NUMERIC, 2)) AS score,
           CASE
               WHEN ABS(s.calories_per_serving - v_target_cal) <= 50 AND s.protein_g_per_serving >= v_target_prot
                   THEN 'Rất chuẩn calo (~' || ROUND(s.calories_per_serving) || ' kcal) và dồi dào đạm (' || ROUND(s.protein_g_per_serving, 1) || 'g protein)'
               WHEN s.protein_g_per_serving >= v_target_prot * 1.2
                   THEN 'Giàu protein (' || ROUND(s.protein_g_per_serving, 1) || 'g), phù hợp phục hồi cơ bắp'
               WHEN (s.prep_time_minutes + s.cook_time_minutes) <= 30
                   THEN 'Nhanh gọn (~' || (s.prep_time_minutes + s.cook_time_minutes) || ' phút), calo vừa vặn'
               ELSE 'Cân đối dinh dưỡng (' || ROUND(s.calories_per_serving) || ' kcal, ' || ROUND(s.protein_g_per_serving, 1) || 'g đạm)'
           END AS match_reason,
           s.is_favorite
      FROM scored s
     ORDER BY score DESC, ABS(s.calories_per_serving - v_target_cal) ASC
     LIMIT LEAST(GREATEST(COALESCE(p_limit, 5), 1), 20);
END;
$$;
-- CREATE OR REPLACE giữ nguyên quyền EXECUTE đã cấp trước đó
