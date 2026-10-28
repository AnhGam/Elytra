-- 73 món "Thức ăn truyền thống" (chương XV của Bảng TPTP 2017: phở, bún chả, xôi, chè...) là MÓN ĂN,
-- nhưng lúc import bị nạp chung vào bảng nguyên liệu. Tách sang prepared_dishes (giữ nguyên id và số liệu đo trên 100 g).
-- Vẫn ghi bữa được (log_meal p_dish_id), nhưng không còn là nguyên liệu để chọn khi tạo công thức.
-- Đã kiểm production: 0 dòng recipe_ingredients và 0 meal_log_items dùng nhóm này.

CREATE TABLE IF NOT EXISTS public.prepared_dishes (LIKE public.ingredients INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES);
INSERT INTO public.prepared_dishes SELECT * FROM public.ingredients WHERE category_id = 15 ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.prepared_dish_allergens (
    dish_id UUID NOT NULL REFERENCES public.prepared_dishes(id) ON DELETE CASCADE,
    allergen_id INT NOT NULL REFERENCES public.allergens(id) ON DELETE CASCADE,
    PRIMARY KEY (dish_id, allergen_id)
);
INSERT INTO public.prepared_dish_allergens (dish_id, allergen_id)
SELECT ia.ingredient_id, ia.allergen_id FROM public.ingredient_allergens ia
  JOIN public.prepared_dishes d ON d.id = ia.ingredient_id
ON CONFLICT DO NOTHING;

ALTER TABLE public.prepared_dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prepared_dish_allergens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read on prepared_dishes" ON public.prepared_dishes FOR SELECT USING (is_active);
CREATE POLICY "Allow public read on prepared_dish_allergens" ON public.prepared_dish_allergens FOR SELECT USING (true);

DELETE FROM public.ingredients WHERE category_id = 15;
-- Bảng nguyên liệu không được chứa món ăn nữa (kể cả qua create_custom_ingredient)
ALTER TABLE public.ingredients ADD CONSTRAINT ingredients_not_prepared_dish CHECK (category_id <> 15);

-- Nhật ký bữa ăn: thêm nguồn 'dish'. source lưu thẳng vì dish_id/ingredient_id có thể bị SET NULL khi món gốc bị xóa.
ALTER TABLE public.meal_log_items
    ADD COLUMN IF NOT EXISTS dish_id UUID REFERENCES public.prepared_dishes(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS source TEXT CHECK (source IN ('recipe', 'ingredient', 'dish'));
UPDATE public.meal_log_items SET source = CASE WHEN servings IS NOT NULL THEN 'recipe' ELSE 'ingredient' END WHERE source IS NULL;

CREATE OR REPLACE FUNCTION public.meal_item_json(i public.meal_log_items)
RETURNS JSONB LANGUAGE sql IMMUTABLE SET search_path = public AS $$
    SELECT jsonb_build_object(
        'id', i.id,
        'source', COALESCE(i.source, CASE WHEN i.servings IS NOT NULL THEN 'recipe' ELSE 'ingredient' END),
        'recipe_id', i.recipe_id,
        'ingredient_id', i.ingredient_id,
        'dish_id', i.dish_id,
        'name', i.name,
        'image_url', i.image_url,
        'servings', i.servings,
        'amount_g', i.amount_g,
        'kcal', ROUND(i.kcal),
        'protein_g', ROUND(i.protein_g, 1),
        'carbs_g', ROUND(i.carbs_g, 1),
        'fat_g', ROUND(i.fat_g, 1),
        'created_at', i.created_at);
$$;

-- Thêm tham số làm đổi chữ ký -> phải DROP bản cũ (CREATE OR REPLACE sẽ tạo thêm 1 hàm trùng tên)
DROP FUNCTION IF EXISTS public.log_meal(TEXT, UUID, NUMERIC, UUID, NUMERIC, DATE, UUID);
CREATE FUNCTION public.log_meal(
    p_meal_type TEXT,
    p_recipe_id UUID DEFAULT NULL,
    p_servings NUMERIC DEFAULT NULL,
    p_ingredient_id UUID DEFAULT NULL,
    p_amount_g NUMERIC DEFAULT NULL,
    p_date DATE DEFAULT NULL,
    p_client_request_id UUID DEFAULT NULL,
    p_dish_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_date DATE := COALESCE(p_date, vn_today());
    v_servings NUMERIC := CASE WHEN p_recipe_id IS NOT NULL THEN ROUND(COALESCE(p_servings, 1), 2) END;
    v_amount_g NUMERIC := ROUND(p_amount_g, 1);
    v_by_weight BOOLEAN := p_ingredient_id IS NOT NULL OR p_dish_id IS NOT NULL;
    -- Dấu vân tay theo request GỬI LÊN (p_date gốc), để gửi lại sau khi món bị PATCH hoặc sau 0h vẫn nhận ra
    v_hash TEXT := md5(concat_ws('|', p_meal_type, p_recipe_id, v_servings, p_ingredient_id, v_amount_g, p_date)
                       || CASE WHEN p_dish_id IS NOT NULL THEN '|dish:' || p_dish_id ELSE '' END);
    v_p profiles%ROWTYPE;
    v_log meal_logs%ROWTYPE;
    v_item meal_log_items%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

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
    -- Đúng 1 nguồn: recipe | ingredient | dish
    IF (p_recipe_id IS NOT NULL)::int + (p_ingredient_id IS NOT NULL)::int + (p_dish_id IS NOT NULL)::int <> 1 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'recipe_id';
    END IF;
    IF p_recipe_id IS NOT NULL AND (p_amount_g IS NOT NULL OR v_servings < 0.25 OR v_servings > 10) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'servings';
    END IF;
    IF v_by_weight AND (p_servings IS NOT NULL OR v_amount_g IS NULL OR v_amount_g < 1 OR v_amount_g > 2000) THEN
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
    IF p_dish_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM prepared_dishes WHERE id = p_dish_id AND is_active) THEN
        RAISE EXCEPTION 'DISH_NOT_FOUND' USING HINT = 'dish_id';
    END IF;

    INSERT INTO meal_logs (user_id, log_date, meal_type, target_kcal, target_protein_g, target_carbs_g, target_fat_g)
    VALUES (v_uid, v_date, p_meal_type, v_p.target_calories, v_p.target_protein_g, v_p.target_carbs_g, v_p.target_fat_g)
    ON CONFLICT (user_id, log_date, meal_type) DO UPDATE SET meal_type = EXCLUDED.meal_type
    RETURNING * INTO v_log;

    IF p_recipe_id IS NOT NULL THEN
        INSERT INTO meal_log_items (meal_log_id, user_id, recipe_id, source, name, image_url, servings,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id, request_hash)
        SELECT v_log.id, v_uid, r.id, 'recipe', r.title, r.image_url, v_servings,
               r.calories_per_serving * v_servings, r.protein_g_per_serving * v_servings,
               r.carbs_g_per_serving * v_servings, r.fat_g_per_serving * v_servings,
               r.fiber_g_per_serving * v_servings, p_client_request_id, v_hash
          FROM recipes r WHERE r.id = p_recipe_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    ELSIF p_ingredient_id IS NOT NULL THEN
        INSERT INTO meal_log_items (meal_log_id, user_id, ingredient_id, source, name, amount_g,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id, request_hash)
        SELECT v_log.id, v_uid, g.id, 'ingredient', g.name_vi, v_amount_g,
               g.calories_per_100g * v_amount_g / 100, g.protein_per_100g * v_amount_g / 100,
               g.carbs_per_100g * v_amount_g / 100, g.fat_per_100g * v_amount_g / 100,
               COALESCE(g.fiber_per_100g, 0) * v_amount_g / 100, p_client_request_id, v_hash
          FROM ingredients g WHERE g.id = p_ingredient_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    ELSE
        INSERT INTO meal_log_items (meal_log_id, user_id, dish_id, source, name, amount_g,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id, request_hash)
        SELECT v_log.id, v_uid, d.id, 'dish', d.name_vi, v_amount_g,
               d.calories_per_100g * v_amount_g / 100, d.protein_per_100g * v_amount_g / 100,
               d.carbs_per_100g * v_amount_g / 100, d.fat_per_100g * v_amount_g / 100,
               COALESCE(d.fiber_per_100g, 0) * v_amount_g / 100, p_client_request_id, v_hash
          FROM prepared_dishes d WHERE d.id = p_dish_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    END IF;

    -- Hai request cùng key chạy song song: request thua rơi vào đây sau khi request thắng commit
    IF v_item.id IS NULL AND p_client_request_id IS NOT NULL THEN
        RETURN log_meal(p_meal_type, p_recipe_id, p_servings, p_ingredient_id, p_amount_g, p_date, p_client_request_id, p_dish_id);
    ELSIF v_item.id IS NULL THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'recipe_id';
    END IF;

    RETURN jsonb_build_object(
        'item', meal_item_json(v_item) || jsonb_build_object('meal_type', p_meal_type, 'date', v_date),
        'replayed', false,
        'budget', get_daily_nutrition(v_date)->'budget');
END;
$$;
REVOKE EXECUTE ON FUNCTION public.log_meal(TEXT, UUID, NUMERIC, UUID, NUMERIC, DATE, UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_meal(TEXT, UUID, NUMERIC, UUID, NUMERIC, DATE, UUID, UUID) TO authenticated;

-- Tìm món ăn sẵn (để ghi bữa). Cùng cách tìm với search_ingredients: không dấu, % _ là ký tự thường.
CREATE OR REPLACE FUNCTION public.search_dishes(
    p_query TEXT DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID, code VARCHAR, name_vi VARCHAR, name_en VARCHAR,
    calories_per_100g NUMERIC, protein_per_100g NUMERIC, fat_per_100g NUMERIC, carbs_per_100g NUMERIC, fiber_per_100g NUMERIC,
    sodium_mg NUMERIC, allergens JSONB
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_q TEXT := NULLIF(btrim(vn_unaccent(p_query)), '');
BEGIN
    RETURN QUERY
    SELECT d.id, d.code, d.name_vi, d.name_en,
           d.calories_per_100g, d.protein_per_100g, d.fat_per_100g, d.carbs_per_100g, d.fiber_per_100g, d.sodium_mg,
           COALESCE(jsonb_agg(jsonb_build_object('id', a.id, 'code', a.code, 'name_vi', a.name_vi)) FILTER (WHERE a.id IS NOT NULL),
                    '[]'::jsonb)
      FROM prepared_dishes d
      LEFT JOIN prepared_dish_allergens da ON da.dish_id = d.id
      LEFT JOIN allergens a ON a.id = da.allergen_id
     WHERE d.is_active
       AND (v_q IS NULL OR vn_unaccent(d.name_vi) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\'
                        OR lower(d.name_en) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\')
     GROUP BY d.id
     ORDER BY
       CASE WHEN v_q IS NOT NULL AND (' ' || vn_unaccent(d.name_vi) || ' ') LIKE '% ' || like_escape(v_q) || ' %' ESCAPE '\' THEN 0
            WHEN v_q IS NOT NULL AND vn_unaccent(d.name_vi) LIKE like_escape(v_q) || '%' ESCAPE '\' THEN 1 ELSE 2 END,
       d.name_vi
     LIMIT LEAST(GREATEST(p_limit, 0), 100)
    OFFSET GREATEST(p_offset, 0);
END;
$$;
GRANT EXECUTE ON FUNCTION public.search_dishes(TEXT, INT, INT) TO anon, authenticated;
