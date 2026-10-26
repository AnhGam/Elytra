-- Sprint 5: Ghi nhận bữa ăn, tổng hợp dinh dưỡng đã nạp/còn lại theo ngày, lịch sử.
-- Dinh dưỡng được chụp (snapshot) lúc ghi, nên sửa recipe/ingredient sau này không làm đổi lịch sử.
-- Lỗi nghiệp vụ được RAISE với MESSAGE = mã lỗi trong api-contract.md, HINT = tên trường.

CREATE TABLE IF NOT EXISTS public.meal_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    meal_type VARCHAR(10) NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    target_kcal NUMERIC(6,1) NOT NULL, -- mục tiêu lúc ghi, để lịch sử không đổi khi user sửa hồ sơ
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, log_date, meal_type)
);

CREATE TABLE IF NOT EXISTS public.meal_log_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_log_id UUID NOT NULL REFERENCES public.meal_logs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE SET NULL,
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    image_url TEXT,
    servings NUMERIC(5,2) CHECK (servings > 0),
    amount_g NUMERIC(7,1) CHECK (amount_g > 0),
    kcal NUMERIC(8,2) NOT NULL,
    protein_g NUMERIC(8,2) NOT NULL,
    carbs_g NUMERIC(8,2) NOT NULL,
    fat_g NUMERIC(8,2) NOT NULL,
    fiber_g NUMERIC(8,2) NOT NULL,
    client_request_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- recipe ghi theo khẩu phần, ingredient ghi theo gam; recipe_id có thể bị SET NULL nên phân biệt bằng cột này
    CHECK ((servings IS NULL) <> (amount_g IS NULL)),
    UNIQUE (user_id, client_request_id)
);

CREATE INDEX IF NOT EXISTS idx_meal_log_items_meal_log_id ON public.meal_log_items(meal_log_id);

ALTER TABLE public.meal_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_log_items ENABLE ROW LEVEL SECURITY;

-- Chỉ đọc/xóa dữ liệu của mình. Không có policy INSERT/UPDATE: ghi chỉ qua log_meal để số liệu không bị giả.
CREATE POLICY "Users can view own meal logs" ON public.meal_logs
    FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can view own meal log items" ON public.meal_log_items
    FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meal log items" ON public.meal_log_items
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Ngày "hôm nay" theo giờ Việt Nam.
-- shortcut: cố định Asia/Ho_Chi_Minh, đổi sang múi giờ lưu trong profiles nếu có user nước ngoài.
CREATE OR REPLACE FUNCTION public.vn_today()
RETURNS DATE LANGUAGE sql STABLE AS $$
    SELECT (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
$$;

-- Dạng MealLogItem trong api-contract.md
CREATE OR REPLACE FUNCTION public.meal_item_json(i public.meal_log_items)
RETURNS JSONB LANGUAGE sql IMMUTABLE AS $$
    SELECT jsonb_build_object(
        'id', i.id,
        'source', CASE WHEN i.servings IS NOT NULL THEN 'recipe' ELSE 'ingredient' END,
        'recipe_id', i.recipe_id,
        'ingredient_id', i.ingredient_id,
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

-- Tổng hợp 1 ngày: mục tiêu, đã nạp, còn lại (có thể âm = vượt) và danh sách món theo bữa.
CREATE OR REPLACE FUNCTION public.get_daily_nutrition(p_date DATE DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_date DATE := COALESCE(p_date, vn_today());
    v_p profiles%ROWTYPE;
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
            'target', jsonb_build_object('kcal', ROUND(v_p.target_calories), 'protein_g', v_p.target_protein_g,
                                         'carbs_g', v_p.target_carbs_g, 'fat_g', v_p.target_fat_g),
            'consumed', jsonb_build_object('kcal', ROUND(v_kcal), 'protein_g', ROUND(v_protein, 1),
                                           'carbs_g', ROUND(v_carbs, 1), 'fat_g', ROUND(v_fat, 1)),
            'remaining', jsonb_build_object('kcal', ROUND(v_p.target_calories - v_kcal),
                                            'protein_g', ROUND(v_p.target_protein_g - v_protein, 1),
                                            'carbs_g', ROUND(v_p.target_carbs_g - v_carbs, 1),
                                            'fat_g', ROUND(v_p.target_fat_g - v_fat, 1))),
        'meals', v_meals
    );
END;
$$;

-- Ghi 1 món vào bữa: recipe theo khẩu phần HOẶC ingredient theo gam.
-- p_client_request_id: app sinh 1 lần cho mỗi lần bấm "Thêm", gửi lại y nguyên khi retry -> không ghi trùng.
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
    v_log_id UUID;
    v_item meal_log_items%ROWTYPE;
    v_replayed BOOLEAN := false;
    v_target NUMERIC;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
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
    -- Cho ghi bù tối đa 30 ngày trước, không cho ghi tương lai
    IF v_date > vn_today() OR v_date < vn_today() - 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'date';
    END IF;
    SELECT target_calories INTO v_target FROM profiles WHERE id = v_uid;
    IF v_target IS NULL THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;
    IF p_recipe_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM recipes WHERE id = p_recipe_id AND is_verified) THEN
        RAISE EXCEPTION 'RECIPE_NOT_FOUND' USING HINT = 'recipe_id';
    END IF;
    IF p_ingredient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ingredients WHERE id = p_ingredient_id AND is_active) THEN
        RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'ingredient_id';
    END IF;

    INSERT INTO meal_logs (user_id, log_date, meal_type, target_kcal) VALUES (v_uid, v_date, p_meal_type, v_target)
    ON CONFLICT (user_id, log_date, meal_type) DO UPDATE SET meal_type = EXCLUDED.meal_type
    RETURNING id INTO v_log_id;

    -- Unique constraint quyết định request nào thắng; request trùng đang chạy song song sẽ chờ rồi rơi vào nhánh replay.
    IF p_recipe_id IS NOT NULL THEN
        INSERT INTO meal_log_items (meal_log_id, user_id, recipe_id, name, image_url, servings,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id)
        SELECT v_log_id, v_uid, r.id, r.title, r.image_url, v_servings,
               r.calories_per_serving * v_servings, r.protein_g_per_serving * v_servings,
               r.carbs_g_per_serving * v_servings, r.fat_g_per_serving * v_servings,
               r.fiber_g_per_serving * v_servings, p_client_request_id
          FROM recipes r WHERE r.id = p_recipe_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    ELSE
        INSERT INTO meal_log_items (meal_log_id, user_id, ingredient_id, name, amount_g,
                                    kcal, protein_g, carbs_g, fat_g, fiber_g, client_request_id)
        SELECT v_log_id, v_uid, g.id, g.name_vi, v_amount_g,
               g.calories_per_100g * v_amount_g / 100, g.protein_per_100g * v_amount_g / 100,
               g.carbs_per_100g * v_amount_g / 100, g.fat_per_100g * v_amount_g / 100,
               COALESCE(g.fiber_per_100g, 0) * v_amount_g / 100, p_client_request_id
          FROM ingredients g WHERE g.id = p_ingredient_id
        ON CONFLICT (user_id, client_request_id) DO NOTHING
        RETURNING * INTO v_item;
    END IF;

    IF v_item.id IS NULL THEN
        SELECT * INTO v_item FROM meal_log_items WHERE user_id = v_uid AND client_request_id = p_client_request_id;
        -- Cùng key nhưng khác nội dung là lỗi của app, không được trả nhầm kết quả cũ
        IF v_item.meal_log_id <> v_log_id
           OR v_item.recipe_id IS DISTINCT FROM p_recipe_id
           OR v_item.ingredient_id IS DISTINCT FROM p_ingredient_id
           OR v_item.servings IS DISTINCT FROM v_servings
           OR v_item.amount_g IS DISTINCT FROM v_amount_g THEN
            RAISE EXCEPTION 'IDEMPOTENCY_CONFLICT' USING HINT = 'client_request_id';
        END IF;
        v_replayed := true;
    END IF;

    RETURN jsonb_build_object(
        'item', meal_item_json(v_item) || jsonb_build_object('meal_type', p_meal_type, 'date', v_date),
        'replayed', v_replayed,
        'budget', get_daily_nutrition(v_date)->'budget'
    );
END;
$$;

-- Lịch sử theo ngày (cho biểu đồ). Trả đủ mọi ngày trong khoảng, ngày không ghi = 0. Tối đa 31 ngày/lần.
-- target_kcal của mỗi ngày = mục tiêu lúc ghi; ngày chưa ghi dùng mục tiêu hiện tại.
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
               'target_kcal', ROUND(COALESCE(t.target_kcal, v_target))) ORDER BY d.day)
      INTO v_days
      FROM generate_series(p_from, p_to, interval '1 day') AS d(day)
      LEFT JOIN (
          SELECT l.log_date, SUM(i.kcal) AS kcal, SUM(i.protein_g) AS protein_g,
                 SUM(i.carbs_g) AS carbs_g, SUM(i.fat_g) AS fat_g, COUNT(*) AS item_count,
                 MAX(l.target_kcal) AS target_kcal
            FROM meal_logs l JOIN meal_log_items i ON i.meal_log_id = l.id
           WHERE l.user_id = v_uid AND l.log_date BETWEEN p_from AND p_to
           GROUP BY l.log_date
      ) t ON t.log_date = d.day::date;

    RETURN jsonb_build_object('from', p_from, 'to', p_to, 'target_kcal', ROUND(v_target), 'days', v_days);
END;
$$;

-- Sửa khẩu phần/khối lượng 1 món. Nhân theo tỉ lệ trên snapshot cũ, không đọc lại recipe/ingredient
-- (có thể đã đổi hoặc bị xóa). Đặt giá trị tuyệt đối nên gọi lại nhiều lần vẫn cho cùng kết quả.
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

    SELECT * INTO v_log FROM meal_logs WHERE id = v_item.meal_log_id;
    RETURN jsonb_build_object(
        'item', meal_item_json(v_item) || jsonb_build_object('meal_type', v_log.meal_type, 'date', v_log.log_date),
        'budget', get_daily_nutrition(v_log.log_date)->'budget'
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_daily_nutrition(DATE) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.log_meal(TEXT, UUID, NUMERIC, UUID, NUMERIC, DATE, UUID) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_nutrition_history(DATE, DATE) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_meal_log_item(UUID, NUMERIC, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_daily_nutrition(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_meal(TEXT, UUID, NUMERIC, UUID, NUMERIC, DATE, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_nutrition_history(DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_meal_log_item(UUID, NUMERIC, NUMERIC) TO authenticated;
