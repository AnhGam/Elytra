-- Sửa các mục review PR #4 (docs/week7-8/AUDIT_REPORT.md mục "Review PR #4").

-- B1: mục tiêu calo < 800 làm lưu hồ sơ vi phạm CHECK. Nguyên nhân: sàn an toàn chỉ áp cho giảm cân,
-- người nhỏ con/lớn tuổi duy trì hoặc tăng cân có TDEE dưới 800. Áp sàn 1200 nữ / 1500 nam cho MỌI mục tiêu
-- (NutritionCalculator trong app sửa giống hệt).
CREATE OR REPLACE FUNCTION public.calculate_nutrition_targets(
    p_gender VARCHAR,
    p_age INT,
    p_height_cm NUMERIC,
    p_weight_kg NUMERIC,
    p_activity_level VARCHAR,
    p_goal VARCHAR
)
RETURNS JSONB LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
DECLARE
    v_bmi NUMERIC; v_bmi_class TEXT; v_bmr NUMERIC; v_factor NUMERIC; v_tdee NUMERIC; v_target_calories NUMERIC;
    v_protein_factor NUMERIC; v_protein_g NUMERIC; v_protein_kcal NUMERIC; v_fat_kcal NUMERIC; v_fat_g NUMERIC;
    v_carbs_kcal NUMERIC; v_carbs_g NUMERIC; v_fiber_g NUMERIC; v_water_ml NUMERIC;
BEGIN
    v_bmi := ROUND(p_weight_kg / ((p_height_cm / 100.0) * (p_height_cm / 100.0)), 1);
    IF v_bmi < 18.5 THEN v_bmi_class := 'Thiếu cân';
    ELSIF v_bmi < 23.0 THEN v_bmi_class := 'Bình thường';
    ELSIF v_bmi < 25.0 THEN v_bmi_class := 'Tiền béo phì (Thừa cân)';
    ELSE v_bmi_class := 'Béo phì';
    END IF;

    IF LOWER(p_gender) = 'female' THEN
        v_bmr := ROUND((10.0 * p_weight_kg) + (6.25 * p_height_cm) - (5.0 * p_age) - 161.0, 1);
    ELSE
        v_bmr := ROUND((10.0 * p_weight_kg) + (6.25 * p_height_cm) - (5.0 * p_age) + 5.0, 1);
    END IF;

    CASE LOWER(p_activity_level)
        WHEN 'sedentary' THEN v_factor := 1.200;
        WHEN 'light' THEN v_factor := 1.375;
        WHEN 'moderate' THEN v_factor := 1.550;
        WHEN 'active' THEN v_factor := 1.725;
        WHEN 'very_active' THEN v_factor := 1.900;
        ELSE v_factor := 1.375;
    END CASE;
    v_tdee := ROUND(v_bmr * v_factor, 1);

    CASE LOWER(p_goal)
        WHEN 'lose_weight' THEN v_target_calories := v_tdee - 500.0;
        WHEN 'gain_weight' THEN v_target_calories := v_tdee + 400.0;
        ELSE v_target_calories := v_tdee;
    END CASE;
    -- Sàn an toàn chuyển hóa cho mọi mục tiêu
    IF LOWER(p_gender) = 'female' AND v_target_calories < 1200.0 THEN
        v_target_calories := 1200.0;
    ELSIF LOWER(p_gender) != 'female' AND v_target_calories < 1500.0 THEN
        v_target_calories := 1500.0;
    END IF;

    CASE LOWER(p_goal)
        WHEN 'lose_weight' THEN v_protein_factor := 2.0;
        WHEN 'gain_weight' THEN v_protein_factor := 1.8;
        ELSE v_protein_factor := 1.6;
    END CASE;
    v_protein_g := ROUND(p_weight_kg * v_protein_factor, 1);
    v_protein_kcal := v_protein_g * 4.0;
    v_fat_kcal := v_target_calories * 0.25;
    v_fat_g := ROUND(v_fat_kcal / 9.0, 1);
    v_carbs_kcal := GREATEST(v_target_calories - v_protein_kcal - v_fat_kcal, 0);
    v_carbs_g := ROUND(v_carbs_kcal / 4.0, 1);
    v_fiber_g := GREATEST(ROUND((v_target_calories / 1000.0) * 14.0, 1), 25.0);
    v_water_ml := ROUND(p_weight_kg * 35.0, 0);

    RETURN jsonb_build_object(
        'bmi', v_bmi, 'bmi_classification', v_bmi_class, 'bmr', v_bmr, 'tdee', v_tdee,
        'target_calories', v_target_calories, 'calorie_difference', v_target_calories - v_tdee,
        'protein_g', v_protein_g, 'fat_g', v_fat_g, 'carbs_g', v_carbs_g, 'fiber_g', v_fiber_g, 'water_ml', v_water_ml,
        'macro_percentages', jsonb_build_object(
            'protein_pct', ROUND((v_protein_kcal / v_target_calories) * 100.0, 1),
            'fat_pct', ROUND((v_fat_kcal / v_target_calories) * 100.0, 1),
            'carbs_pct', ROUND((v_carbs_kcal / v_target_calories) * 100.0, 1)));
END;
$$;
GRANT EXECUTE ON FUNCTION public.calculate_nutrition_targets(VARCHAR, INT, NUMERIC, NUMERIC, VARCHAR, VARCHAR) TO anon, authenticated;

-- R2: ngày đã qua chỉ snapshot kcal, macro vẫn theo hồ sơ mới -> snapshot cả macro.
-- R1: idempotency so trạng thái hiện tại của món (đã PATCH) và ngày suy ra lúc gửi lại -> lưu dấu vân tay của request gốc.
ALTER TABLE public.meal_logs
    ADD COLUMN IF NOT EXISTS target_protein_g NUMERIC(6,1),
    ADD COLUMN IF NOT EXISTS target_carbs_g NUMERIC(6,1),
    ADD COLUMN IF NOT EXISTS target_fat_g NUMERIC(6,1);
ALTER TABLE public.meal_log_items ADD COLUMN IF NOT EXISTS request_hash TEXT;

-- Snapshot của 1 ngày = mục tiêu lúc ghi bữa đầu tiên trong ngày; hôm nay luôn dùng hồ sơ hiện tại.
CREATE OR REPLACE FUNCTION public.day_target_kcal(p_uid UUID, p_date DATE, p_current NUMERIC)
RETURNS NUMERIC LANGUAGE sql STABLE SET search_path = public AS $$
    SELECT CASE WHEN p_date < vn_today()
                THEN COALESCE((SELECT target_kcal FROM meal_logs WHERE user_id = p_uid AND log_date = p_date
                                ORDER BY created_at LIMIT 1), p_current)
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
    v_snap meal_logs%ROWTYPE;
    v_t_kcal NUMERIC; v_t_protein NUMERIC; v_t_carbs NUMERIC; v_t_fat NUMERIC;
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

    IF v_date < vn_today() THEN
        SELECT * INTO v_snap FROM meal_logs WHERE user_id = v_uid AND log_date = v_date ORDER BY created_at LIMIT 1;
    END IF;
    v_t_kcal := COALESCE(v_snap.target_kcal, v_p.target_calories);
    v_t_protein := COALESCE(v_snap.target_protein_g, v_p.target_protein_g);
    v_t_carbs := COALESCE(v_snap.target_carbs_g, v_p.target_carbs_g);
    v_t_fat := COALESCE(v_snap.target_fat_g, v_p.target_fat_g);

    SELECT COALESCE(SUM(i.kcal), 0), COALESCE(SUM(i.protein_g), 0), COALESCE(SUM(i.carbs_g), 0), COALESCE(SUM(i.fat_g), 0)
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
            'target', jsonb_build_object('kcal', ROUND(v_t_kcal), 'protein_g', v_t_protein, 'carbs_g', v_t_carbs, 'fat_g', v_t_fat),
            'consumed', jsonb_build_object('kcal', ROUND(v_kcal), 'protein_g', ROUND(v_protein, 1),
                                           'carbs_g', ROUND(v_carbs, 1), 'fat_g', ROUND(v_fat, 1)),
            'remaining', jsonb_build_object('kcal', ROUND(v_t_kcal - v_kcal), 'protein_g', ROUND(v_t_protein - v_protein, 1),
                                            'carbs_g', ROUND(v_t_carbs - v_carbs, 1), 'fat_g', ROUND(v_t_fat - v_fat, 1))),
        'meals', v_meals
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.log_meal(
    p_meal_type TEXT,
    p_recipe_id UUID DEFAULT NULL,
    p_servings NUMERIC DEFAULT NULL,
    p_ingredient_id UUID DEFAULT NULL,
    p_amount_g NUMERIC DEFAULT NULL,
    p_date DATE DEFAULT NULL,
    p_client_request_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_date DATE := COALESCE(p_date, vn_today());
    v_servings NUMERIC := CASE WHEN p_recipe_id IS NOT NULL THEN ROUND(COALESCE(p_servings, 1), 2) END;
    v_amount_g NUMERIC := ROUND(p_amount_g, 1);
    -- Dấu vân tay theo request GỬI LÊN (p_date gốc, không phải ngày suy ra), để gửi lại sau khi món bị PATCH
    -- hoặc sau 0h vẫn nhận ra là cùng một request
    v_hash TEXT := md5(concat_ws('|', p_meal_type, p_recipe_id, v_servings, p_ingredient_id, v_amount_g, p_date));
    v_p profiles%ROWTYPE;
    v_log meal_logs%ROWTYPE;
    v_item meal_log_items%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    -- Gửi lại: trả món đã ghi (trạng thái hiện tại), không tạo thêm gì
    IF p_client_request_id IS NOT NULL THEN
        SELECT * INTO v_item FROM meal_log_items WHERE user_id = v_uid AND client_request_id = p_client_request_id;
        IF FOUND THEN
            IF v_item.request_hash IS DISTINCT FROM v_hash THEN
                RAISE EXCEPTION 'IDEMPOTENCY_CONFLICT' USING HINT = 'client_request_id';
            END IF;
            SELECT * INTO v_log FROM meal_logs WHERE id = v_item.meal_log_id;
            RETURN jsonb_build_object(
                'item', meal_item_json(v_item) || jsonb_build_object('meal_type', v_log.meal_type, 'date', v_log.log_date),
                'replayed', true,
                'budget', get_daily_nutrition(v_log.log_date)->'budget');
        END IF;
    END IF;

    IF p_meal_type IS NULL OR p_meal_type NOT IN ('breakfast', 'lunch', 'dinner', 'snack') THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'meal_type';
    END IF;
    IF (p_recipe_id IS NULL) = (p_ingredient_id IS NULL) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'recipe_id';
    END IF;
    IF p_recipe_id IS NOT NULL AND (p_amount_g IS NOT NULL OR v_servings < 0.25 OR v_servings > 10) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'servings';
    END IF;
    IF p_ingredient_id IS NOT NULL AND (p_servings IS NOT NULL OR v_amount_g IS NULL OR v_amount_g < 1 OR v_amount_g > 2000) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'amount_g';
    END IF;
    IF v_date > vn_today() OR v_date < vn_today() - 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'date';
    END IF;
    SELECT * INTO v_p FROM profiles WHERE id = v_uid;
    IF v_p.target_calories IS NULL THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;
    IF p_recipe_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM recipes WHERE id = p_recipe_id AND is_verified) THEN
        RAISE EXCEPTION 'RECIPE_NOT_FOUND' USING HINT = 'recipe_id';
    END IF;
    IF p_ingredient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ingredients WHERE id = p_ingredient_id AND is_active) THEN
        RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'ingredient_id';
    END IF;

    INSERT INTO meal_logs (user_id, log_date, meal_type, target_kcal, target_protein_g, target_carbs_g, target_fat_g)
    VALUES (v_uid, v_date, p_meal_type, v_p.target_calories, v_p.target_protein_g, v_p.target_carbs_g, v_p.target_fat_g)
    ON CONFLICT (user_id, log_date, meal_type) DO UPDATE SET meal_type = EXCLUDED.meal_type
    RETURNING * INTO v_log;

    IF p_recipe_id IS NOT NULL THEN
        INSERT INTO meal_log_items (meal_log_id, user_id, recipe_id, name, image_url, servings,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id, request_hash)
        SELECT v_log.id, v_uid, r.id, r.title, r.image_url, v_servings,
               r.calories_per_serving * v_servings, r.protein_g_per_serving * v_servings,
               r.carbs_g_per_serving * v_servings, r.fat_g_per_serving * v_servings,
               r.fiber_g_per_serving * v_servings, p_client_request_id, v_hash
          FROM recipes r WHERE r.id = p_recipe_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    ELSE
        INSERT INTO meal_log_items (meal_log_id, user_id, ingredient_id, name, amount_g,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id, request_hash)
        SELECT v_log.id, v_uid, g.id, g.name_vi, v_amount_g,
               g.calories_per_100g * v_amount_g / 100, g.protein_per_100g * v_amount_g / 100,
               g.carbs_per_100g * v_amount_g / 100, g.fat_per_100g * v_amount_g / 100,
               COALESCE(g.fiber_per_100g, 0) * v_amount_g / 100, p_client_request_id, v_hash
          FROM ingredients g WHERE g.id = p_ingredient_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    END IF;

    -- Hai request cùng key chạy song song: request thua rơi vào đây sau khi request thắng commit
    IF v_item.id IS NULL AND p_client_request_id IS NOT NULL THEN
        RETURN log_meal(p_meal_type, p_recipe_id, p_servings, p_ingredient_id, p_amount_g, p_date, p_client_request_id);
    ELSIF v_item.id IS NULL THEN
        -- món/nguyên liệu vừa bị xóa giữa lúc kiểm tra và lúc ghi
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'recipe_id';
    END IF;

    RETURN jsonb_build_object(
        'item', meal_item_json(v_item) || jsonb_build_object('meal_type', p_meal_type, 'date', v_date),
        'replayed', false,
        'budget', get_daily_nutrition(v_date)->'budget');
END;
$$;

-- R3: DELETE qua RLS không áp cửa sổ 30 ngày và để lại meal_logs rỗng -> xóa chỉ qua RPC.
DROP POLICY IF EXISTS "Users can delete own meal log items" ON public.meal_log_items;
CREATE OR REPLACE FUNCTION public.delete_meal_log_item(p_item_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_item meal_log_items%ROWTYPE;
    v_log meal_logs%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    SELECT * INTO v_item FROM meal_log_items WHERE id = p_item_id AND user_id = v_uid FOR UPDATE;
    IF NOT FOUND THEN
        RETURN; -- xóa idempotent: không có (hoặc của người khác) thì coi như đã xóa
    END IF;
    SELECT * INTO v_log FROM meal_logs WHERE id = v_item.meal_log_id FOR UPDATE;
    IF v_log.log_date < vn_today() - 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'date';
    END IF;
    DELETE FROM meal_log_items WHERE id = p_item_id;
    DELETE FROM meal_logs l WHERE l.id = v_log.id AND NOT EXISTS (SELECT 1 FROM meal_log_items i WHERE i.meal_log_id = l.id);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.delete_meal_log_item(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_meal_log_item(UUID) TO authenticated;

-- Dọn meal_logs rỗng đã có từ trước
DELETE FROM public.meal_logs l WHERE NOT EXISTS (SELECT 1 FROM public.meal_log_items i WHERE i.meal_log_id = l.id);

-- R4 + tìm không dấu: % và _ trong từ khóa bị hiểu là wildcard; 'bo luc lac' không ra 'bò lúc lắc'.
-- Bỏ dấu bằng translate (không cần extension unaccent), dùng chung cho mọi chỗ tìm kiếm.
CREATE OR REPLACE FUNCTION public.vn_unaccent(p_text TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = public AS $$
    SELECT lower(translate(normalize(p_text, NFC), 'àÀáÁảẢãÃạẠăĂằẰắẮẳẲẵẴặẶâÂầẦấẤẩẨẫẪậẬèÈéÉẻẺẽẼẹẸêÊềỀếẾểỂễỄệỆìÌíÍỉỈĩĨịỊòÒóÓỏỎõÕọỌôÔồỒốỐổỔỗỖộỘơƠờỜớỚởỞỡỠợỢùÙúÚủỦũŨụỤưƯừỪứỨửỬữỮựỰỳỲýÝỷỶỹỸỵỴđĐ', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeeeeeeeeiiiiiiiiiioooooooooooooooooooooooooooooooooouuuuuuuuuuuuuuuuuuuuuuyyyyyyyyyydd'));
$$;
-- create_custom_ingredient gọi f_unaccent nhưng hàm này chưa từng tồn tại trên DB
CREATE OR REPLACE FUNCTION public.f_unaccent(p_text TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path = public AS $$ SELECT vn_unaccent(p_text) $$;
CREATE OR REPLACE FUNCTION public.like_escape(p_text TEXT)
RETURNS TEXT LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $$
    SELECT replace(replace(replace(p_text, '\', '\\'), '%', '\%'), '_', '\_');
$$;

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
    fiber_g_per_serving NUMERIC, sodium_mg_per_serving NUMERIC, is_vegetarian BOOLEAN, allergens INT[],
    condiment_allergens INT[]
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
    v_q TEXT := NULLIF(btrim(vn_unaccent(p_query)), '');
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
       AND (v_q IS NULL OR vn_unaccent(r.title) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\')
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

CREATE OR REPLACE FUNCTION public.search_ingredients(
    p_query TEXT DEFAULT NULL,
    p_category_id INT DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID, code VARCHAR, name_vi VARCHAR, name_en VARCHAR, category_id INT, category_name VARCHAR,
    calories_per_100g NUMERIC, protein_per_100g NUMERIC, fat_per_100g NUMERIC, carbs_per_100g NUMERIC, fiber_per_100g NUMERIC,
    sodium_mg NUMERIC, edible_portion_pct NUMERIC, density_g_per_ml NUMERIC, is_featured BOOLEAN, allergens JSONB
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
    v_q TEXT := NULLIF(btrim(vn_unaccent(p_query)), '');
BEGIN
    RETURN QUERY
    SELECT i.id, i.code, i.name_vi, i.name_en, i.category_id, ic.name_vi AS category_name,
           i.calories_per_100g, i.protein_per_100g, i.fat_per_100g, i.carbs_per_100g, i.fiber_per_100g,
           i.sodium_mg, i.edible_portion_pct, i.density_g_per_ml, i.is_featured,
           COALESCE(jsonb_agg(jsonb_build_object('id', a.id, 'code', a.code, 'name_vi', a.name_vi)) FILTER (WHERE a.id IS NOT NULL),
                    '[]'::jsonb) AS allergens
      FROM public.ingredients i
      JOIN public.ingredient_categories ic ON i.category_id = ic.id
      LEFT JOIN public.ingredient_allergens ia ON i.id = ia.ingredient_id
      LEFT JOIN public.allergens a ON ia.allergen_id = a.id
     WHERE i.is_active = TRUE
       AND (v_q IS NULL
            OR vn_unaccent(i.name_vi) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\'
            OR lower(i.name_en) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\'
            OR lower(i.code) LIKE like_escape(v_q) || '%' ESCAPE '\')
       AND (p_category_id IS NULL OR i.category_id = p_category_id)
       AND (p_is_featured IS NULL OR i.is_featured = p_is_featured)
     GROUP BY i.id, ic.name_vi
     ORDER BY
       -- 'pho' khớp cả 'bánh phồng' (vì gõ dở): đưa khớp nguyên từ lên trước, rồi khớp đầu tên
       CASE WHEN v_q IS NOT NULL AND (' ' || vn_unaccent(i.name_vi) || ' ') LIKE '% ' || like_escape(v_q) || ' %' ESCAPE '\' THEN 0
            WHEN v_q IS NOT NULL AND vn_unaccent(i.name_vi) LIKE like_escape(v_q) || '%' ESCAPE '\' THEN 1 ELSE 2 END,
       i.is_featured DESC,
       i.name_vi ASC
     LIMIT LEAST(GREATEST(p_limit, 0), 100)
    OFFSET GREATEST(p_offset, 0);
END;
$$;
