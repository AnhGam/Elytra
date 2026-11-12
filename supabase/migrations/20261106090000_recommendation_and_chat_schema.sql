-- Migration cho Tuần 9-10 (Sprint 6): Hệ thống gợi ý dinh dưỡng, Chat AI, phân trang và chuẩn hóa calo/dataset
-- 1. Chuẩn hóa khẩu phần (servings), danh mục gia vị ăn kèm và dầu ngấm khi chiên
-- 2. Nâng cấp RPC search_recipes hỗ trợ Pagination, Sort, Filter và total_count
-- 3. Tạo bảng chat_sessions và chat_messages phục vụ lưu ngữ cảnh hội thoại AI
-- 4. Xây dựng RPC recommend_dishes_for_user chấm điểm gợi ý món ăn theo dinh dưỡng còn lại

-- ============================================================================
-- PHẦN 1: CHUẨN HÓA DATASET & TÍNH LẠI CALO HỢP LÝ
-- ============================================================================

-- 1.1. Cập nhật số khẩu phần thực tế cho các món nấu nồi lớn
UPDATE public.recipes
   SET servings = 6, updated_at = now()
 WHERE slug = 'cach-nau-sup-nui-ga-xe-dac-biet-thom-ngon-dinh-duong';

UPDATE public.recipes
   SET servings = 10, updated_at = now()
 WHERE slug = 'cach-nau-che-dau-trang-deo-thom-ngot-ngao';

-- 1.2. Phân loại lại 2 món gia vị/đồ chấm để không bị gợi ý nhầm làm bữa ăn chính
UPDATE public.recipes
   SET category = 'gia_vi_an_kem', updated_at = now()
 WHERE slug IN (
    'cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon',
    'cach-lam-toi-ngam-giam-chua-ngot-trang-gion'
 );

-- 1.3. Hiệu chỉnh dòng nguyên liệu Chè đậu trắng:
-- Dừa nạo 500g vắt lấy 200g nước cốt dừa (X03001), không tính 500g bã dừa nạo khô
UPDATE public.recipe_ingredients ri
   SET ingredient_id = (SELECT id FROM public.ingredients WHERE code = 'X03001'),
       amount_g = 200, consumed_pct = 100,
       calories_per_100g = 230, protein_per_100g = 2.3, fat_per_100g = 23.8, carbs_per_100g = 5.5
  FROM public.recipes r
 WHERE ri.recipe_id = r.id
   AND r.slug = 'cach-nau-che-dau-trang-deo-thom-ngot-ngao'
   AND ri.order_index = 3;

-- Lá dứa 1 bó: đun lấy mùi thơm rồi vớt bỏ, không ăn
UPDATE public.recipe_ingredients ri
   SET amount_g = 0, consumed_pct = 100, calories_per_100g = 0 -- consumed_pct có CHECK > 0; amount_g = 0 đã đủ ra 0 kcal
  FROM public.recipes r
 WHERE ri.recipe_id = r.id
   AND r.slug = 'cach-nau-che-dau-trang-deo-thom-ngot-ngao'
   AND ri.order_index = 4;

-- Bột năng 2 muỗng canh: map đúng Bột sắn FCT 02022 (thay vì Bánh đa nem)
UPDATE public.recipe_ingredients ri
   SET ingredient_id = (SELECT id FROM public.ingredients WHERE code = '02022'),
       amount_g = 30, consumed_pct = 100,
       calories_per_100g = 340, protein_per_100g = 0.9, fat_per_100g = 0.2, carbs_per_100g = 84.3
  FROM public.recipes r
 WHERE ri.recipe_id = r.id
   AND r.slug = 'cach-nau-che-dau-trang-deo-thom-ngot-ngao'
   AND ri.order_index = 9;

-- 1.4. Bổ sung lượng dầu ăn ngấm cho các món chiên ngập (~10% trọng lượng thực phẩm chiên)
-- Gà rang muối: dòng Dầu ăn tăng lên 60g dầu ngấm vào gà tẩm bột
UPDATE public.recipe_ingredients ri
   SET ingredient_id = (SELECT id FROM public.ingredients WHERE code = '12001'),
       amount_g = 60, consumed_pct = 100,
       calories_per_100g = 897, fat_per_100g = 99.7
  FROM public.recipes r
 WHERE ri.recipe_id = r.id
   AND r.slug = 'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc'
   AND ri.ingredient_name_raw ILIKE '%dầu ăn%';

-- Cá bống chay chiên sả: thêm 30g dầu ngấm
INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, ingredient_name_raw, raw_text,
    amount, unit, amount_g, consumed_pct,
    calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
)
SELECT r.id, i.id, 99, 'Dầu ăn (ngấm khi chiên)', 'Dầu ăn ngấm khi chiên ngập (~10% nguyên liệu)',
       1, 'phần ngấm', 30, 100,
       i.calories_per_100g, i.protein_per_100g, i.fat_per_100g, i.carbs_per_100g, i.fiber_per_100g, i.sodium_mg
  FROM public.recipes r
 CROSS JOIN public.ingredients i
 WHERE r.slug = 'cach-lam-ca-bong-chay-chien-sa-gion-gion-cuc-ngon'
   AND i.code = '12001'
   AND NOT EXISTS (
       SELECT 1 FROM public.recipe_ingredients ri
        WHERE ri.recipe_id = r.id AND ri.ingredient_name_raw ILIKE '%ngấm khi chiên%'
   );

-- Sườn chiên sả ớt: thêm 40g dầu ngấm
INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, ingredient_name_raw, raw_text,
    amount, unit, amount_g, consumed_pct,
    calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
)
SELECT r.id, i.id, 99, 'Dầu ăn (ngấm khi chiên)', 'Dầu ăn ngấm khi chiên sườn (~8% nguyên liệu)',
       1, 'phần ngấm', 40, 100,
       i.calories_per_100g, i.protein_per_100g, i.fat_per_100g, i.carbs_per_100g, i.fiber_per_100g, i.sodium_mg
  FROM public.recipes r
 CROSS JOIN public.ingredients i
 WHERE r.slug = 'cach-lam-suon-chien-sa-ot-ngon-het-y'
   AND i.code = '12001'
   AND NOT EXISTS (
       SELECT 1 FROM public.recipe_ingredients ri
        WHERE ri.recipe_id = r.id AND ri.ingredient_name_raw ILIKE '%ngấm khi chiên%'
   );

-- 1.5. Cập nhật lại toàn bộ dinh dưỡng món ăn theo servings và nguyên liệu mới
UPDATE public.recipes r
   SET total_calories = t.cal, total_protein_g = t.prot, total_fat_g = t.fat, total_carbs_g = t.carbs,
       total_fiber_g = t.fiber, total_sodium_mg = t.sod,
       calories_per_serving = round(t.cal / r.servings, 1),
       protein_g_per_serving = round(t.prot / r.servings, 1),
       fat_g_per_serving = round(t.fat / r.servings, 1),
       carbs_g_per_serving = round(t.carbs / r.servings, 1),
       fiber_g_per_serving = round(t.fiber / r.servings, 1),
       sodium_mg_per_serving = round(t.sod / r.servings, 1),
       updated_at = now()
  FROM (SELECT recipe_id,
               round(sum(amount_g * consumed_pct / 100 * calories_per_100g / 100), 1) AS cal,
               round(sum(amount_g * consumed_pct / 100 * protein_per_100g / 100), 1) AS prot,
               round(sum(amount_g * consumed_pct / 100 * fat_per_100g / 100), 1) AS fat,
               round(sum(amount_g * consumed_pct / 100 * carbs_per_100g / 100), 1) AS carbs,
               round(sum(amount_g * consumed_pct / 100 * fiber_per_100g / 100), 1) AS fiber,
               round(sum(amount_g * consumed_pct / 100 * sodium_mg_per_100g / 100), 1) AS sod
          FROM public.recipe_ingredients GROUP BY recipe_id) t
 WHERE t.recipe_id = r.id;


-- ============================================================================
-- PHẦN 2: NÂNG CẤP RPC search_recipes HỖ TRỢ PHÂN TRANG VÀ LỌC NÂNG CAO
-- ============================================================================

DROP FUNCTION IF EXISTS public.search_recipes(TEXT, VARCHAR, BOOLEAN, NUMERIC, INT[], INT, INT);

CREATE OR REPLACE FUNCTION public.search_recipes(
    p_query TEXT DEFAULT NULL,
    p_category VARCHAR DEFAULT NULL,
    p_is_vegetarian BOOLEAN DEFAULT NULL,
    p_min_calories NUMERIC DEFAULT NULL,
    p_max_calories NUMERIC DEFAULT NULL,
    p_max_total_time INT DEFAULT NULL,
    p_difficulty VARCHAR DEFAULT NULL,
    p_exclude_allergen_ids INT[] DEFAULT NULL,
    p_include_condiments BOOLEAN DEFAULT FALSE,
    p_sort VARCHAR DEFAULT 'title_asc',
    p_page INT DEFAULT 1,
    p_page_size INT DEFAULT 20,
    -- Giữ p_limit/p_offset cũ: app trên main gọi search_recipes(p_limit => 100), bỏ đi sẽ lỗi 'function not found'
    p_limit INT DEFAULT NULL,
    p_offset INT DEFAULT NULL
)
RETURNS TABLE (
    id UUID, title VARCHAR, slug VARCHAR, description TEXT, image_url TEXT, video_url TEXT, category VARCHAR, cuisine VARCHAR,
    servings INT, prep_time_minutes INT, cook_time_minutes INT, difficulty VARCHAR,
    calories_per_serving NUMERIC, protein_g_per_serving NUMERIC, fat_g_per_serving NUMERIC, carbs_g_per_serving NUMERIC,
    fiber_g_per_serving NUMERIC, sodium_mg_per_serving NUMERIC, is_vegetarian BOOLEAN,
    allergens INT[], condiment_allergens INT[], total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
    v_q TEXT := NULLIF(btrim(vn_unaccent(p_query)), '');
    v_limit INT := LEAST(GREATEST(COALESCE(p_limit, p_page_size, 20), 0), 100);
    v_offset INT := GREATEST(COALESCE(p_offset, (COALESCE(p_page, 1) - 1) * v_limit), 0);
BEGIN
    RETURN QUERY
    WITH filtered AS (
        SELECT r.id, r.title, r.slug, r.description, r.image_url, r.video_url, r.category, r.cuisine,
               r.servings, r.prep_time_minutes, r.cook_time_minutes, r.difficulty,
               r.calories_per_serving, r.protein_g_per_serving, r.fat_g_per_serving, r.carbs_g_per_serving,
               r.fiber_g_per_serving, r.sodium_mg_per_serving,
               (r.category = 'mon_chay') AS is_vegetarian,
               COALESCE(ARRAY_AGG(ra.allergen_id ORDER BY ra.allergen_id) FILTER (WHERE ra.allergen_id IS NOT NULL), '{}'::INT[]) AS allergens,
               COALESCE(ARRAY_AGG(ra.allergen_id ORDER BY ra.allergen_id) FILTER (WHERE ra.via_condiment), '{}'::INT[]) AS condiment_allergens
          FROM public.recipes r
          LEFT JOIN public.recipe_allergens ra ON r.id = ra.recipe_id
         WHERE r.is_verified
           -- Tìm kiếm theo tên món hoặc nguyên liệu (không dấu)
           AND (v_q IS NULL OR vn_unaccent(r.title) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\'
                OR EXISTS (
                    SELECT 1 FROM public.recipe_ingredients ri
                     WHERE ri.recipe_id = r.id AND vn_unaccent(ri.ingredient_name_raw) LIKE '%' || like_escape(v_q) || '%' ESCAPE '\'
                ))
           AND (p_category IS NULL OR r.category = p_category)
           -- Mặc định loại bỏ gia vị ăn kèm trừ khi tìm kiếm đích danh hoặc yêu cầu rõ
           AND (p_include_condiments OR v_q IS NOT NULL OR r.category <> 'gia_vi_an_kem')
           AND (p_is_vegetarian IS NULL OR (p_is_vegetarian = true AND r.category = 'mon_chay') OR (p_is_vegetarian = false AND r.category != 'mon_chay'))
           AND (p_min_calories IS NULL OR r.calories_per_serving >= p_min_calories)
           AND (p_max_calories IS NULL OR r.calories_per_serving <= p_max_calories)
           AND (p_max_total_time IS NULL OR (COALESCE(r.prep_time_minutes, 0) + COALESCE(r.cook_time_minutes, 0)) <= p_max_total_time)
           AND (p_difficulty IS NULL OR r.difficulty = p_difficulty)
           AND (p_exclude_allergen_ids IS NULL OR NOT EXISTS (
                   SELECT 1 FROM public.recipe_allergens sub_ra
                    WHERE sub_ra.recipe_id = r.id AND sub_ra.allergen_id = ANY(p_exclude_allergen_ids)))
         GROUP BY r.id
    )
    SELECT f.id, f.title, f.slug, f.description, f.image_url, f.video_url, f.category, f.cuisine,
           f.servings, f.prep_time_minutes, f.cook_time_minutes, f.difficulty,
           f.calories_per_serving, f.protein_g_per_serving, f.fat_g_per_serving, f.carbs_g_per_serving,
           f.fiber_g_per_serving, f.sodium_mg_per_serving, f.is_vegetarian,
           f.allergens, f.condiment_allergens,
           COUNT(*) OVER() AS total_count
      FROM filtered f
     ORDER BY
       CASE WHEN p_sort = 'calories_asc' THEN f.calories_per_serving END ASC,
       CASE WHEN p_sort = 'calories_desc' THEN f.calories_per_serving END DESC,
       CASE WHEN p_sort = 'time_asc' THEN (COALESCE(f.prep_time_minutes, 0) + COALESCE(f.cook_time_minutes, 0)) END ASC,
       f.title ASC
     LIMIT v_limit
    OFFSET v_offset;
END;
$$;


-- ============================================================================
-- PHẦN 3: BẢNG LƯU NGỮ CẢNH HỘI THOẠI AI CHATBOT (chat_sessions & chat_messages)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meal_type VARCHAR(20) NOT NULL DEFAULT 'lunch' CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    target_kcal NUMERIC,
    target_protein_g NUMERIC,
    target_fat_g NUMERIC,
    target_carbs_g NUMERIC,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    suggested_recipe_ids UUID[] DEFAULT '{}'::UUID[],
    rejected_recipe_ids UUID[] DEFAULT '{}'::UUID[],
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON public.chat_sessions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON public.chat_messages(session_id, created_at ASC);

ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own chat sessions" ON public.chat_sessions;
CREATE POLICY "Users can manage own chat sessions"
    ON public.chat_sessions FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own chat messages" ON public.chat_messages;
CREATE POLICY "Users can manage own chat messages"
    ON public.chat_messages FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ============================================================================
-- PHẦN 4: NGÂN SÁCH CALO BỮA + MÓN YÊU THÍCH + RECOMMENDATION ENGINE
-- ============================================================================

-- 4a. Calo cho bữa sắp ăn, theo phần còn lại hôm nay và có ngưỡng chặn 2 đầu.
--   chuẩn bữa  = mục tiêu ngày × tỉ lệ bữa (sáng 25%, trưa 35%, tối 30%, phụ 10%)
--   thô        = calo còn lại × tỉ lệ bữa / tổng tỉ lệ các bữa CHƯA ăn hôm nay (gồm bữa này)
--   còn < 150 kcal                  → goal_reached: không gợi ý món chính
--   thô < 0,5 × chuẩn (còn quá ít)  → low: target = max(thô, 150), gợi ý món nhẹ
--   thô > 1,5 × chuẩn (bỏ bữa trước)→ capped: target = 1,5 × chuẩn, không dồn cả ngày vào 1 bữa
--   còn lại                         → ok
CREATE OR REPLACE FUNCTION public.meal_calorie_budget(p_meal_type TEXT DEFAULT 'lunch')
RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_daily NUMERIC;
    v_consumed NUMERIC;
    v_remaining NUMERIC;
    v_share NUMERIC;
    v_open_share NUMERIC;
    v_base NUMERIC;
    v_raw NUMERIC;
    v_status TEXT := 'ok';
    v_target NUMERIC;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    IF p_meal_type NOT IN ('breakfast', 'lunch', 'dinner', 'snack') THEN
        RAISE EXCEPTION 'VALIDATION_ERROR';
    END IF;
    SELECT target_calories INTO v_daily FROM profiles WHERE id = v_uid;
    IF v_daily IS NULL THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;

    SELECT COALESCE(SUM(i.kcal), 0) INTO v_consumed
      FROM meal_log_items i JOIN meal_logs l ON l.id = i.meal_log_id
     WHERE l.user_id = v_uid AND l.log_date = vn_today();
    v_remaining := v_daily - v_consumed;

    v_share := CASE p_meal_type WHEN 'breakfast' THEN 0.25 WHEN 'lunch' THEN 0.35 WHEN 'dinner' THEN 0.30 ELSE 0.10 END;
    -- Bữa đã có món hôm nay thì không chia phần còn lại cho nó nữa (bữa đang hỏi luôn được tính)
    SELECT v_share + COALESCE(SUM(CASE m WHEN 'breakfast' THEN 0.25 WHEN 'lunch' THEN 0.35 WHEN 'dinner' THEN 0.30 ELSE 0.10 END), 0)
      INTO v_open_share
      FROM unnest(ARRAY['breakfast', 'lunch', 'dinner', 'snack']) AS m
     WHERE m <> p_meal_type
       AND NOT EXISTS (SELECT 1 FROM meal_logs l WHERE l.user_id = v_uid AND l.log_date = vn_today() AND l.meal_type = m);

    v_base := v_daily * v_share;
    v_raw := v_remaining * v_share / v_open_share;

    IF v_remaining < 150 THEN
        v_status := 'goal_reached';
        v_target := NULL;
    ELSIF v_raw < v_base * 0.5 THEN
        v_status := 'low';
        v_target := GREATEST(v_raw, 150);
    ELSIF v_raw > v_base * 1.5 THEN
        v_status := 'capped';
        v_target := v_base * 1.5;
    ELSE
        v_target := v_raw;
    END IF;

    RETURN jsonb_build_object(
        'meal_type', p_meal_type,
        'status', v_status,
        'target_kcal', ROUND(v_target),
        'base_kcal', ROUND(v_base),
        'remaining_kcal', ROUND(v_remaining),
        'daily_kcal', ROUND(v_daily)
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.meal_calorie_budget(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.meal_calorie_budget(TEXT) TO authenticated;

-- 4b. Món yêu thích. App đọc/ghi thẳng bảng, an toàn nhờ RLS:
--   - user_id mặc định = auth.uid() và policy bắt buộc khớp → không thêm/xóa/xem hộ người khác
--   - chỉ thêm được món đã duyệt; không có quyền UPDATE; anon không có quyền gì
--   - khóa chính (user_id, recipe_id) → bấm nhiều lần không nhân bản
CREATE TABLE IF NOT EXISTS public.user_favorite_recipes (
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, recipe_id)
);

ALTER TABLE public.user_favorite_recipes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.user_favorite_recipes FROM anon;
REVOKE UPDATE ON public.user_favorite_recipes FROM authenticated;

DROP POLICY IF EXISTS "Users read own favorites" ON public.user_favorite_recipes;
CREATE POLICY "Users read own favorites" ON public.user_favorite_recipes
    FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users add own favorites" ON public.user_favorite_recipes;
CREATE POLICY "Users add own favorites" ON public.user_favorite_recipes
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id
                AND EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.is_verified));
DROP POLICY IF EXISTS "Users remove own favorites" ON public.user_favorite_recipes;
CREATE POLICY "Users remove own favorites" ON public.user_favorite_recipes
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- 4c. Gợi ý món: lọc cứng (dị ứng, món từ chối, gia vị) + chấm điểm calo/protein/thời gian (+ món yêu thích).
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
BEGIN
    -- SECURITY DEFINER bỏ qua RLS: chặn gọi bằng uid của người khác (lộ mục tiêu calo + suy ra dị ứng)
    IF p_uid IS NULL OR p_uid IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;

    SELECT target_calories, target_protein_g INTO v_daily_cal, v_daily_prot FROM public.profiles WHERE id = p_uid;

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
               CASE WHEN (c.prep_time_minutes + c.cook_time_minutes) <= 30 THEN 1.0
                    WHEN (c.prep_time_minutes + c.cook_time_minutes) <= 45 THEN 0.8
                    ELSE 0.6 END AS time_score
          FROM candidates c
    )
    SELECT s.id, s.title, s.slug, s.category, s.image_url, s.servings,
           s.prep_time_minutes, s.cook_time_minutes,
           s.calories_per_serving, s.protein_g_per_serving, s.fat_g_per_serving, s.carbs_g_per_serving,
           -- Món yêu thích +0,1 (tối đa 1): ưu tiên nhẹ, không lấn át món hợp calo hơn
           LEAST(1, ROUND((0.45 * s.cal_score + 0.35 * s.prot_score + 0.20 * s.time_score
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
     LIMIT LEAST(GREATEST(p_limit, 1), 20);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.recommend_dishes_for_user(UUID, VARCHAR, NUMERIC, UUID[], INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.recommend_dishes_for_user(UUID, VARCHAR, NUMERIC, UUID[], INT) TO authenticated;


-- ==========================================
-- 5. Món người dùng upload mặc định CHƯA duyệt (chờ Jev/admin kiểm duyệt, xem docs/week9-10)
-- Seed/crawl luôn ghi is_verified = true tường minh nên không bị ảnh hưởng;
-- create_recipe_with_nutrition không truyền cột này -> món mới tạo qua RPC sẽ là false.
-- ==========================================
ALTER TABLE public.recipes ALTER COLUMN is_verified SET DEFAULT false;
