-- Sửa các lỗi đã xác nhận trong docs/week7-8/AUDIT_REPORT.md.

-- V14: món chưa duyệt không được lộ ra. Nguyên nhân: policy SELECT USING (true) và search_recipes không lọc is_verified.
DROP POLICY IF EXISTS "Allow public read-only access on recipes" ON public.recipes;
CREATE POLICY "Allow public read verified recipes" ON public.recipes FOR SELECT USING (is_verified);
DROP POLICY IF EXISTS "Allow public read-only access on recipe_ingredients" ON public.recipe_ingredients;
CREATE POLICY "Allow public read ingredients of verified recipes" ON public.recipe_ingredients FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.is_verified));
DROP POLICY IF EXISTS "Allow public read-only access on recipe_allergens" ON public.recipe_allergens;
CREATE POLICY "Allow public read allergens of verified recipes" ON public.recipe_allergens FOR SELECT
    USING (EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.is_verified));

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
    id UUID, title VARCHAR, slug VARCHAR, description TEXT, image_url TEXT, video_url TEXT, category VARCHAR, cuisine VARCHAR,
    servings INT, prep_time_minutes INT, cook_time_minutes INT, difficulty VARCHAR,
    calories_per_serving NUMERIC, protein_g_per_serving NUMERIC, fat_g_per_serving NUMERIC, carbs_g_per_serving NUMERIC,
    fiber_g_per_serving NUMERIC, sodium_mg_per_serving NUMERIC, is_vegetarian BOOLEAN, allergens INT[]
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
           COALESCE(ARRAY_AGG(ra.allergen_id) FILTER (WHERE ra.allergen_id IS NOT NULL), '{}'::INT[]) AS allergens
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

-- Món demo do script test engine cũ tạo ra rồi không dọn, đang hiện cho người dùng.
DELETE FROM public.recipes WHERE slug = 'tr-ng-chi-n-h-nh-l-demo-2c1566';

-- V12: nguyên liệu đã vô hiệu không được trả về (RLS và search_ingredients đều đã lọc is_active).
DO $$
DECLARE
    v_old TEXT := pg_get_functiondef('public.get_ingredient_details(uuid)'::regprocedure);
    v_new TEXT := replace(v_old, 'WHERE i.id = p_ingredient_id', 'WHERE i.id = p_ingredient_id AND i.is_active');
BEGIN
    IF v_new = v_old THEN
        RAISE EXCEPTION 'get_ingredient_details: không tìm thấy điều kiện WHERE để sửa';
    END IF;
    EXECUTE v_new;
END $$;

-- V1 (tái phát): recipe mới phải gắn nguyên liệu có thật trong bảng gốc; nguyên liệu NULL = 0 kcal + không kế thừa dị ứng.
-- Chỉ chặn khi INSERT để không đụng các dòng crawl cũ cố ý để trống (nước, gia vị không có trong FCT).
CREATE OR REPLACE FUNCTION public.require_known_ingredient()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
    IF NEW.ingredient_id IS NULL OR NOT EXISTS (SELECT 1 FROM ingredients WHERE id = NEW.ingredient_id AND is_active) THEN
        RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'ingredient_id';
    END IF;
    IF NEW.amount_g IS NULL OR NEW.amount_g <= 0 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'amount_g';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.require_known_ingredient() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_recipe_ingredients_require_known ON public.recipe_ingredients;
CREATE TRIGGER trg_recipe_ingredients_require_known BEFORE INSERT ON public.recipe_ingredients
    FOR EACH ROW EXECUTE FUNCTION public.require_known_ingredient();

-- V7: profiles không có ràng buộc giá trị (app ghi thẳng). Đã kiểm production: không dòng nào vi phạm.
ALTER TABLE public.profiles
    ADD CONSTRAINT profiles_age_range CHECK (age IS NULL OR age BETWEEN 10 AND 100),
    ADD CONSTRAINT profiles_targets_range CHECK (
        (target_calories IS NULL OR target_calories BETWEEN 800 AND 10000) AND
        (target_protein_g IS NULL OR target_protein_g BETWEEN 0 AND 1000) AND
        (target_fat_g IS NULL OR target_fat_g BETWEEN 0 AND 1000) AND
        (target_carbs_g IS NULL OR target_carbs_g BETWEEN 0 AND 2000) AND
        (bmr IS NULL OR bmr BETWEEN 0 AND 10000) AND
        (tdee IS NULL OR tdee BETWEEN 0 AND 20000));

-- V6: sửa khẩu phần nhiều lần làm số trôi. Nguyên nhân: nhân tỉ lệ trên giá trị đã làm tròn NUMERIC(8,2).
-- Lưu 6 chữ số thập phân (sai số ~1e-6 kcal mỗi lần sửa); JSON trả ra vẫn làm tròn như cũ.
ALTER TABLE public.meal_log_items
    ALTER COLUMN kcal TYPE NUMERIC(14,6), ALTER COLUMN protein_g TYPE NUMERIC(14,6), ALTER COLUMN carbs_g TYPE NUMERIC(14,6),
    ALTER COLUMN fat_g TYPE NUMERIC(14,6), ALTER COLUMN fiber_g TYPE NUMERIC(14,6);

-- V4: Dashboard và biểu đồ lệch mục tiêu cho cùng một ngày. Nguyên nhân: Dashboard dùng mục tiêu hiện tại,
-- lịch sử dùng snapshot. Quy tắc chung: ngày đã qua = snapshot lúc ghi (nếu có), hôm nay = mục tiêu hiện tại.
CREATE OR REPLACE FUNCTION public.day_target_kcal(p_uid UUID, p_date DATE, p_current NUMERIC)
RETURNS NUMERIC LANGUAGE sql STABLE SET search_path = public AS $$
    SELECT CASE WHEN p_date < vn_today()
                THEN COALESCE((SELECT MAX(target_kcal) FROM meal_logs WHERE user_id = p_uid AND log_date = p_date), p_current)
                ELSE p_current END;
$$;
REVOKE EXECUTE ON FUNCTION public.day_target_kcal(UUID, DATE, NUMERIC) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_daily_nutrition(p_date DATE DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_date DATE := COALESCE(p_date, vn_today());
    v_p profiles%ROWTYPE;
    v_target NUMERIC;
    v_kcal NUMERIC; v_protein NUMERIC; v_carbs NUMERIC; v_fat NUMERIC;
    v_meals JSONB;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    SELECT * INTO v_p FROM profiles WHERE id = v_uid;
    IF v_p.target_calories IS NULL THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;
    v_target := day_target_kcal(v_uid, v_date, v_p.target_calories);

    SELECT COALESCE(SUM(i.kcal), 0), COALESCE(SUM(i.protein_g), 0),
           COALESCE(SUM(i.carbs_g), 0), COALESCE(SUM(i.fat_g), 0)
      INTO v_kcal, v_protein, v_carbs, v_fat
      FROM meal_log_items i JOIN meal_logs l ON l.id = i.meal_log_id
     WHERE l.user_id = v_uid AND l.log_date = v_date;

    SELECT jsonb_object_agg(m.meal_type, jsonb_build_object(
               'kcal', COALESCE((SELECT ROUND(SUM(i.kcal)) FROM meal_log_items i JOIN meal_logs l ON l.id = i.meal_log_id
                                  WHERE l.user_id = v_uid AND l.log_date = v_date AND l.meal_type = m.meal_type), 0),
               'items', COALESCE((SELECT jsonb_agg(meal_item_json(i) ORDER BY i.created_at)
                          FROM meal_log_items i JOIN meal_logs l ON l.id = i.meal_log_id
                         WHERE l.user_id = v_uid AND l.log_date = v_date AND l.meal_type = m.meal_type), '[]'::jsonb)))
      INTO v_meals
      FROM unnest(ARRAY['breakfast', 'lunch', 'dinner', 'snack']) AS m(meal_type);

    RETURN jsonb_build_object(
        'date', v_date,
        'budget', jsonb_build_object(
            'target', jsonb_build_object('kcal', ROUND(v_target), 'protein_g', v_p.target_protein_g,
                                         'carbs_g', v_p.target_carbs_g, 'fat_g', v_p.target_fat_g),
            'consumed', jsonb_build_object('kcal', ROUND(v_kcal), 'protein_g', ROUND(v_protein, 1),
                                           'carbs_g', ROUND(v_carbs, 1), 'fat_g', ROUND(v_fat, 1)),
            'remaining', jsonb_build_object('kcal', ROUND(v_target - v_kcal),
                                            'protein_g', ROUND(v_p.target_protein_g - v_protein, 1),
                                            'carbs_g', ROUND(v_p.target_carbs_g - v_carbs, 1),
                                            'fat_g', ROUND(v_p.target_fat_g - v_fat, 1))),
        'meals', v_meals
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_nutrition_history(p_from DATE, p_to DATE)
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_target NUMERIC;
    v_days JSONB;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    IF p_from IS NULL OR p_to IS NULL OR p_from > p_to OR p_to - p_from > 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'from';
    END IF;
    SELECT target_calories INTO v_target FROM profiles WHERE id = v_uid;
    IF v_target IS NULL THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;

    SELECT jsonb_agg(jsonb_build_object(
               'date', d.day::date,
               'kcal', ROUND(COALESCE(t.kcal, 0)),
               'protein_g', ROUND(COALESCE(t.protein_g, 0), 1),
               'carbs_g', ROUND(COALESCE(t.carbs_g, 0), 1),
               'fat_g', ROUND(COALESCE(t.fat_g, 0), 1),
               'item_count', COALESCE(t.item_count, 0),
               'target_kcal', ROUND(day_target_kcal(v_uid, d.day::date, v_target))) ORDER BY d.day)
      INTO v_days
      FROM generate_series(p_from, p_to, interval '1 day') AS d(day)
      LEFT JOIN (
          SELECT l.log_date, SUM(i.kcal) AS kcal, SUM(i.protein_g) AS protein_g,
                 SUM(i.carbs_g) AS carbs_g, SUM(i.fat_g) AS fat_g, COUNT(*) AS item_count
            FROM meal_logs l JOIN meal_log_items i ON i.meal_log_id = l.id
           WHERE l.user_id = v_uid AND l.log_date BETWEEN p_from AND p_to
           GROUP BY l.log_date
      ) t ON t.log_date = d.day::date;

    RETURN jsonb_build_object('from', p_from, 'to', p_to, 'target_kcal', ROUND(v_target), 'days', v_days);
END;
$$;

-- V5: sửa được món ngoài cửa sổ 30 ngày trong khi ghi mới thì không. Áp cùng cửa sổ với log_meal.
CREATE OR REPLACE FUNCTION public.update_meal_log_item(
    p_item_id UUID,
    p_servings NUMERIC DEFAULT NULL,
    p_amount_g NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_servings NUMERIC := ROUND(p_servings, 2);
    v_amount_g NUMERIC := ROUND(p_amount_g, 1);
    v_item meal_log_items%ROWTYPE;
    v_log meal_logs%ROWTYPE;
    v_ratio NUMERIC;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    SELECT * INTO v_item FROM meal_log_items WHERE id = p_item_id AND user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'ITEM_NOT_FOUND' USING HINT = 'id';
    END IF;
    SELECT * INTO v_log FROM meal_logs WHERE id = v_item.meal_log_id;
    IF v_log.log_date < vn_today() - 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'date';
    END IF;

    IF v_item.servings IS NOT NULL THEN
        IF p_amount_g IS NOT NULL OR v_servings IS NULL OR v_servings < 0.25 OR v_servings > 10 THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'servings';
        END IF;
        v_ratio := v_servings / v_item.servings;
    ELSE
        IF p_servings IS NOT NULL OR v_amount_g IS NULL OR v_amount_g < 1 OR v_amount_g > 2000 THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'amount_g';
        END IF;
        v_ratio := v_amount_g / v_item.amount_g;
    END IF;

    UPDATE meal_log_items
       SET servings = CASE WHEN servings IS NOT NULL THEN v_servings END,
           amount_g = CASE WHEN amount_g IS NOT NULL THEN v_amount_g END,
           kcal = kcal * v_ratio, protein_g = protein_g * v_ratio, carbs_g = carbs_g * v_ratio,
           fat_g = fat_g * v_ratio, fiber_g = fiber_g * v_ratio
     WHERE id = p_item_id
    RETURNING * INTO v_item;

    RETURN jsonb_build_object(
        'item', meal_item_json(v_item) || jsonb_build_object('meal_type', v_log.meal_type, 'date', v_log.log_date),
        'budget', get_daily_nutrition(v_log.log_date)->'budget'
    );
END;
$$;
