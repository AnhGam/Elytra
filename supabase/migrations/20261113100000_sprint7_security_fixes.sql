-- Sửa các điểm review bảo mật Sprint 7. Migration 20261113090000 đã áp lên production nên sửa bằng migration mới.

-- 1. Gốc URL công khai của project: dùng để kiểm URL ảnh user gửi (chặn ảnh từ host lạ).
--    Đổi project thì UPDATE app_config. App không đọc/ghi được bảng này.
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.app_config FROM anon, authenticated;
INSERT INTO public.app_config (key, value) VALUES ('storage_public_base', 'https://iwmnkygicqfesvbilmrw.supabase.co')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.storage_public_base()
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT value FROM app_config WHERE key = 'storage_public_base' $$;
REVOKE EXECUTE ON FUNCTION public.storage_public_base() FROM PUBLIC, anon, authenticated;

-- 2. Nhật ký lượt gửi công thức (để đếm giới hạn 5 món/ngày; xóa món không trả lại lượt)
CREATE TABLE IF NOT EXISTS public.recipe_submissions (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_recipe_submissions_user ON public.recipe_submissions(user_id, created_at);
ALTER TABLE public.recipe_submissions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.recipe_submissions FROM anon, authenticated;

-- 3. submit_recipe: kiểm URL ảnh chặt (neo cả chuỗi + file phải tồn tại), giới hạn 5 món/ngày theo lượt gửi + khóa
CREATE OR REPLACE FUNCTION public.submit_recipe(
    p_title TEXT,
    p_category TEXT,
    p_servings INT,
    p_ingredients JSONB,
    p_instructions JSONB,
    p_description TEXT DEFAULT NULL,
    p_prep_time_minutes INT DEFAULT 15,
    p_cook_time_minutes INT DEFAULT 30,
    p_difficulty TEXT DEFAULT 'easy',
    p_image_url TEXT DEFAULT NULL,
    p_recipe_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_title TEXT := btrim(COALESCE(p_title, ''));
    v_recipe recipes%ROWTYPE;
    v_id UUID;
    v_el JSONB;
    v_ing ingredients%ROWTYPE;
    v_amount NUMERIC;
    v_unit TEXT;
    v_grams NUMERIC;
    v_idx INT := 0;
    v_steps JSONB := '[]'::jsonb;
    v_step_desc TEXT;
    v_slug TEXT;
    v_image_path TEXT;
    v_image_prefix TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_uid) THEN
        RAISE EXCEPTION 'PROFILE_NOT_FOUND';
    END IF;

    -- Kiểm tra dữ liệu (biên tin cậy: mọi giá trị từ app)
    IF char_length(v_title) NOT BETWEEN 3 AND 120 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'title';
    END IF;
    IF p_category IS NULL OR p_category NOT IN ('mon_an_sang', 'mon_canh', 'mon_chay', 'mon_kho', 'mon_man', 'mon_nuong', 'mon_xao', 'gia_vi_an_kem') THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'category';
    END IF;
    IF p_servings IS NULL OR p_servings NOT BETWEEN 1 AND 20 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'servings';
    END IF;
    IF COALESCE(p_prep_time_minutes, -1) NOT BETWEEN 0 AND 600 OR COALESCE(p_cook_time_minutes, -1) NOT BETWEEN 0 AND 600 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'prep_time_minutes';
    END IF;
    IF p_difficulty IS NULL OR p_difficulty NOT IN ('easy', 'medium', 'hard') THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'difficulty';
    END IF;
    IF char_length(COALESCE(p_description, '')) > 2000 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'description';
    END IF;
    IF jsonb_typeof(p_ingredients) IS DISTINCT FROM 'array' OR jsonb_array_length(p_ingredients) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'ingredients';
    END IF;
    IF jsonb_typeof(p_instructions) IS DISTINCT FROM 'array' OR jsonb_array_length(p_instructions) NOT BETWEEN 1 AND 30 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'instructions';
    END IF;
    -- Ảnh: URL công khai ĐÚNG project này, đúng thư mục của chính user, tên file đơn giản, file đã upload thật.
    -- Neo cả chuỗi: chặn host lạ, '?', '#', '%', '..' (trước đây chỉ kiểm chuỗi con nên lách được bằng query string)
    IF p_image_url IS NOT NULL THEN
        v_image_prefix := storage_public_base() || '/storage/v1/object/public/user-recipe-images/';
        v_image_path := CASE WHEN left(p_image_url, length(v_image_prefix)) = v_image_prefix THEN substr(p_image_url, length(v_image_prefix) + 1) END;
        IF v_image_path IS NULL OR v_image_path !~ ('^' || v_uid::text || '/[A-Za-z0-9_-]{1,100}[.](jpg|jpeg|png|webp)$')
           OR NOT EXISTS (SELECT 1 FROM storage.objects o WHERE o.bucket_id = 'user-recipe-images' AND o.name = v_image_path) THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'image_url';
        END IF;
    END IF;

    FOR v_el IN SELECT * FROM jsonb_array_elements(p_instructions) LOOP
        v_step_desc := btrim(COALESCE(v_el->>'description', ''));
        IF jsonb_typeof(v_el) IS DISTINCT FROM 'object' OR char_length(v_step_desc) NOT BETWEEN 1 AND 1000 OR char_length(COALESCE(v_el->>'title', '')) > 120 THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'instructions';
        END IF;
        v_idx := v_idx + 1;
        v_steps := v_steps || jsonb_build_object('step_number', v_idx, 'title', btrim(COALESCE(v_el->>'title', '')), 'description', v_step_desc);
    END LOOP;

    IF p_recipe_id IS NULL THEN
        -- Tối đa 5 món mới mỗi ngày (giờ Việt Nam). Đếm theo nhật ký lượt gửi (xóa món không trả lại lượt);
        -- khóa theo user để gửi song song không vượt giới hạn
        PERFORM pg_advisory_xact_lock(hashtext('submit_recipe:' || v_uid::text));
        IF (SELECT count(*) FROM recipe_submissions WHERE user_id = v_uid AND (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = vn_today()) >= 5 THEN
            RAISE EXCEPTION 'RATE_LIMITED' USING HINT = 'Tối đa 5 công thức mỗi ngày';
        END IF;
        INSERT INTO recipe_submissions (user_id) VALUES (v_uid);
        v_slug := trim(both '-' from regexp_replace(lower(vn_unaccent(v_title)), '[^a-z0-9]+', '-', 'g')) || '-' || substr(md5(random()::text), 1, 6);
        INSERT INTO recipes (title, slug, description, category, servings, prep_time_minutes, cook_time_minutes, difficulty,
                             image_url, instructions, created_by, status, submitted_at)
        VALUES (v_title, v_slug, NULLIF(btrim(p_description), ''), p_category, p_servings, p_prep_time_minutes, p_cook_time_minutes,
                p_difficulty, p_image_url, v_steps, v_uid, 'pending', now())
        RETURNING id INTO v_id;
    ELSE
        SELECT * INTO v_recipe FROM recipes WHERE id = p_recipe_id FOR UPDATE;
        IF NOT FOUND OR v_recipe.created_by IS DISTINCT FROM v_uid THEN
            RAISE EXCEPTION 'RECIPE_NOT_FOUND' USING HINT = 'recipe_id';
        END IF;
        -- Món đã duyệt không sửa được: nhật ký ăn uống và lịch sử của người khác không bị đổi theo
        IF v_recipe.status = 'approved' THEN
            RAISE EXCEPTION 'RECIPE_LOCKED' USING HINT = 'recipe_id';
        END IF;
        v_id := p_recipe_id;
        -- Gửi lại: về pending, giữ reject_reason cũ để user thấy lần trước sai ở đâu
        UPDATE recipes SET title = v_title, description = NULLIF(btrim(p_description), ''), category = p_category,
               servings = p_servings, prep_time_minutes = p_prep_time_minutes, cook_time_minutes = p_cook_time_minutes,
               difficulty = p_difficulty, image_url = p_image_url, instructions = v_steps,
               status = 'pending', reviewed_by = NULL, reviewed_at = NULL, ai_review = NULL, submitted_at = now(), updated_at = now()
         WHERE id = v_id;
        DELETE FROM recipe_ingredients WHERE recipe_id = v_id;
        DELETE FROM recipe_allergens WHERE recipe_id = v_id;
    END IF;

    v_idx := 0;
    FOR v_el IN SELECT * FROM jsonb_array_elements(p_ingredients) LOOP
        v_idx := v_idx + 1;
        -- IS DISTINCT FROM / COALESCE: trường thiếu (NULL) phải bị chặn, không được lọt qua phép so sánh NULL
        IF jsonb_typeof(v_el) IS DISTINCT FROM 'object'
           OR COALESCE(v_el->>'ingredient_id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
           OR jsonb_typeof(v_el->'amount') IS DISTINCT FROM 'number' THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'ingredients';
        END IF;
        SELECT * INTO v_ing FROM ingredients WHERE id = (v_el->>'ingredient_id')::uuid AND is_active;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'ingredients';
        END IF;
        v_amount := (v_el->>'amount')::numeric;
        v_unit := COALESCE(v_el->>'unit', 'g');
        IF v_unit NOT IN ('g', 'ml') OR NOT (v_amount > 0 AND v_amount <= 5000) THEN
            RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'ingredients';
        END IF;
        v_grams := CASE v_unit WHEN 'ml' THEN v_amount * COALESCE(v_ing.density_g_per_ml, 1) ELSE v_amount END;
        INSERT INTO recipe_ingredients (recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw, amount, unit, amount_g, consumed_pct,
                                        calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg_per_100g)
        VALUES (v_id, v_ing.id, v_idx, v_ing.name_vi || ': ' || v_amount || ' ' || v_unit, v_ing.name_vi, v_amount, v_unit, round(v_grams, 2), 100,
                v_ing.calories_per_100g, v_ing.protein_per_100g, v_ing.fat_per_100g, v_ing.carbs_per_100g,
                COALESCE(v_ing.fiber_per_100g, 0), COALESCE(v_ing.sodium_mg, 0));
    END LOOP;

    -- Dinh dưỡng: tổng nguyên liệu (cùng công thức với dữ liệu gốc) chia số khẩu phần
    UPDATE recipes r
       SET total_calories = t.cal, total_protein_g = t.prot, total_fat_g = t.fat, total_carbs_g = t.carbs,
           total_fiber_g = t.fiber, total_sodium_mg = t.sod,
           calories_per_serving = round(t.cal / r.servings, 1), protein_g_per_serving = round(t.prot / r.servings, 1),
           fat_g_per_serving = round(t.fat / r.servings, 1), carbs_g_per_serving = round(t.carbs / r.servings, 1),
           fiber_g_per_serving = round(t.fiber / r.servings, 1), sodium_mg_per_serving = round(t.sod / r.servings, 1)
      FROM (SELECT round(sum(amount_g * consumed_pct / 100 * calories_per_100g / 100), 1) AS cal,
                   round(sum(amount_g * consumed_pct / 100 * protein_per_100g / 100), 1) AS prot,
                   round(sum(amount_g * consumed_pct / 100 * fat_per_100g / 100), 1) AS fat,
                   round(sum(amount_g * consumed_pct / 100 * carbs_per_100g / 100), 1) AS carbs,
                   round(sum(amount_g * consumed_pct / 100 * fiber_per_100g / 100), 1) AS fiber,
                   round(sum(amount_g * consumed_pct / 100 * sodium_mg_per_100g / 100), 1) AS sod
              FROM recipe_ingredients WHERE recipe_id = v_id) t
     WHERE r.id = v_id;

    -- Dị ứng kế thừa từ nguyên liệu; chỉ đến từ gia vị chế biến sẵn (nhóm FCT 13) thì via_condiment = true
    INSERT INTO recipe_allergens (recipe_id, allergen_id, via_condiment)
    SELECT v_id, ia.allergen_id, bool_and(i.code LIKE '13%')
      FROM recipe_ingredients x
      JOIN ingredients i ON i.id = x.ingredient_id
      JOIN ingredient_allergens ia ON ia.ingredient_id = x.ingredient_id
     WHERE x.recipe_id = v_id
     GROUP BY ia.allergen_id;

    RETURN (SELECT jsonb_build_object('id', id, 'status', status, 'slug', slug, 'servings', servings,
                   'calories_per_serving', calories_per_serving, 'protein_g_per_serving', protein_g_per_serving,
                   'fat_g_per_serving', fat_g_per_serving, 'carbs_g_per_serving', carbs_g_per_serving,
                   'allergens', COALESCE((SELECT array_agg(allergen_id ORDER BY allergen_id) FROM recipe_allergens WHERE recipe_id = v_id), '{}'::int[]))
              FROM recipes WHERE id = v_id);
END;
$$;


-- 4. admin_review_recipe: bắt buộc gửi submitted_at của bản admin đã xem (chống đổi nội dung lúc đang duyệt)
DROP FUNCTION IF EXISTS public.admin_review_recipe(UUID, BOOLEAN, TEXT);
CREATE OR REPLACE FUNCTION public.admin_review_recipe(p_recipe_id UUID, p_approve BOOLEAN, p_submitted_at TIMESTAMPTZ, p_reason TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_recipe recipes%ROWTYPE;
    v_reason TEXT := NULLIF(btrim(COALESCE(p_reason, '')), '');
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'FORBIDDEN';
    END IF;
    IF p_approve IS NULL THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'approve';
    END IF;
    SELECT * INTO v_recipe FROM recipes WHERE id = p_recipe_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'RECIPE_NOT_FOUND' USING HINT = 'recipe_id';
    END IF;
    IF v_recipe.status <> 'pending' THEN
        RAISE EXCEPTION 'RECIPE_NOT_PENDING' USING HINT = 'recipe_id';
    END IF;
    -- Admin phải duyệt đúng bản đã xem: user gửi lại trong lúc admin đang xem → submitted_at đổi → từ chối thao tác
    IF p_submitted_at IS NULL OR v_recipe.submitted_at IS DISTINCT FROM p_submitted_at THEN
        RAISE EXCEPTION 'RECIPE_CHANGED' USING HINT = 'submitted_at';
    END IF;
    IF NOT p_approve AND char_length(COALESCE(v_reason, '')) NOT BETWEEN 5 AND 500 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'reason';
    END IF;

    UPDATE recipes
       SET status = CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
           reject_reason = CASE WHEN p_approve THEN NULL ELSE v_reason END,
           reviewed_by = auth.uid(), reviewed_at = now(), updated_at = now()
     WHERE id = p_recipe_id;
    PERFORM log_admin_action(CASE WHEN p_approve THEN 'recipe.approve' ELSE 'recipe.reject' END, 'recipe', p_recipe_id::text,
                             jsonb_build_object('title', v_recipe.title, 'author', v_recipe.created_by, 'reason', v_reason));
    RETURN jsonb_build_object('id', p_recipe_id, 'status', CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_review_recipe(UUID, BOOLEAN, TIMESTAMPTZ, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_review_recipe(UUID, BOOLEAN, TIMESTAMPTZ, TEXT) TO authenticated;

-- 5. Storage: bỏ quyền liệt kê bucket cho mọi người (lộ user_id + ảnh món pending/rejected).
--    Bucket public nên ảnh vẫn xem được qua URL công khai; chủ thư mục vẫn liệt kê/xóa được ảnh của mình.
DROP POLICY IF EXISTS "Public read user recipe images" ON storage.objects;
DROP POLICY IF EXISTS "Users read own recipe images" ON storage.objects;
CREATE POLICY "Users read own recipe images" ON storage.objects FOR SELECT TO authenticated
    USING (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

-- 6. Hiệu năng: (SELECT ...) để Postgres tính is_admin()/auth.uid() 1 lần mỗi truy vấn thay vì mỗi dòng
DROP POLICY IF EXISTS "Authors read own recipes" ON public.recipes;
CREATE POLICY "Authors read own recipes" ON public.recipes FOR SELECT TO authenticated USING (created_by = (SELECT auth.uid()));
DROP POLICY IF EXISTS "Admins read all recipes" ON public.recipes;
CREATE POLICY "Admins read all recipes" ON public.recipes FOR SELECT TO authenticated USING ((SELECT public.is_admin()));
DROP POLICY IF EXISTS "Authors and admins read recipe ingredients" ON public.recipe_ingredients;
CREATE POLICY "Authors and admins read recipe ingredients" ON public.recipe_ingredients FOR SELECT TO authenticated
    USING ((SELECT public.is_admin()) OR EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.created_by = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Authors and admins read recipe allergens" ON public.recipe_allergens;
CREATE POLICY "Authors and admins read recipe allergens" ON public.recipe_allergens FOR SELECT TO authenticated
    USING ((SELECT public.is_admin()) OR EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.created_by = (SELECT auth.uid())));
DROP POLICY IF EXISTS "Admins read all ingredients" ON public.ingredients;
CREATE POLICY "Admins read all ingredients" ON public.ingredients FOR SELECT TO authenticated USING ((SELECT public.is_admin()));
DROP POLICY IF EXISTS "Admins read audit log" ON public.admin_audit_log;
CREATE POLICY "Admins read audit log" ON public.admin_audit_log FOR SELECT TO authenticated USING ((SELECT public.is_admin()));
DROP POLICY IF EXISTS "Users upload own recipe images" ON storage.objects;
CREATE POLICY "Users upload own recipe images" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
DROP POLICY IF EXISTS "Users update own recipe images" ON storage.objects;
CREATE POLICY "Users update own recipe images" ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text)
    WITH CHECK (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
DROP POLICY IF EXISTS "Users delete own recipe images" ON storage.objects;
CREATE POLICY "Users delete own recipe images" ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);
