-- Sprint 7 (Tuần 11-12): Cộng đồng đóng góp công thức + Admin.
-- Quyền admin kiểm NGHIÊM NGẶT trong DB: mọi thao tác admin là RPC SECURITY DEFINER tự kiểm is_admin(),
-- app không ghi thẳng bảng admin, mọi thao tác admin ghi nhật ký, user không tự cấp quyền được.

-- ============================================================================
-- PHẦN 1: ADMIN + NHẬT KÝ
-- ============================================================================

-- Chỉ thêm admin qua Supabase Dashboard / migration (service_role). Không có policy nào → app không đọc/ghi được.
CREATE TABLE IF NOT EXISTS public.admins (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admins FROM anon, authenticated;

-- Dùng trong RLS của recipes nên anon cũng phải gọi được (luôn trả false khi chưa đăng nhập)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT EXISTS (SELECT 1 FROM admins WHERE user_id = auth.uid()) $$;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated;

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id BIGSERIAL PRIMARY KEY,
    admin_id UUID NOT NULL,
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admin_audit_log FROM anon, authenticated;
GRANT SELECT ON public.admin_audit_log TO authenticated;
DROP POLICY IF EXISTS "Admins read audit log" ON public.admin_audit_log;
CREATE POLICY "Admins read audit log" ON public.admin_audit_log FOR SELECT TO authenticated USING (public.is_admin());

-- Ghi nhật ký: chỉ gọi từ RPC admin (không cấp quyền cho app)
CREATE OR REPLACE FUNCTION public.log_admin_action(p_action TEXT, p_target_type TEXT, p_target_id TEXT, p_details JSONB DEFAULT '{}'::jsonb)
RETURNS VOID
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$ INSERT INTO admin_audit_log (admin_id, action, target_type, target_id, details) VALUES (auth.uid(), p_action, p_target_type, p_target_id, p_details) $$;
REVOKE EXECUTE ON FUNCTION public.log_admin_action(TEXT, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;

-- ============================================================================
-- PHẦN 2: TRẠNG THÁI CÔNG THỨC
-- ============================================================================

ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS status VARCHAR(10);
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS reject_reason TEXT;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ;
ALTER TABLE public.recipes ADD COLUMN IF NOT EXISTS ai_review JSONB; -- Gemini Decision 1 chấm sẵn cho admin (Edge Function recipe-review-assist)

UPDATE public.recipes SET status = CASE WHEN is_verified THEN 'approved' ELSE 'pending' END WHERE status IS NULL;
ALTER TABLE public.recipes ALTER COLUMN status SET DEFAULT 'pending';
ALTER TABLE public.recipes ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.recipes DROP CONSTRAINT IF EXISTS recipes_status_check;
ALTER TABLE public.recipes ADD CONSTRAINT recipes_status_check CHECK (status IN ('pending', 'approved', 'rejected'));
CREATE INDEX IF NOT EXISTS idx_recipes_created_by ON public.recipes(created_by);
CREATE INDEX IF NOT EXISTS idx_recipes_pending ON public.recipes(submitted_at) WHERE status = 'pending';

-- is_verified luôn = (status = 'approved'), đồng bộ 2 chiều: mọi truy vấn/policy cũ dùng is_verified vẫn đúng,
-- và script/Dashboard cũ đặt thẳng is_verified cũng đổi theo status
CREATE OR REPLACE FUNCTION public.sync_recipe_verified()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.is_verified THEN NEW.status := 'approved'; END IF;
    ELSIF NEW.status IS NOT DISTINCT FROM OLD.status AND NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
        NEW.status := CASE WHEN NEW.is_verified THEN 'approved' ELSE 'pending' END;
    END IF;
    NEW.is_verified := (NEW.status = 'approved');
    RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.sync_recipe_verified() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_recipes_sync_verified ON public.recipes;
CREATE TRIGGER trg_recipes_sync_verified BEFORE INSERT OR UPDATE OF status, is_verified ON public.recipes
    FOR EACH ROW EXECUTE FUNCTION public.sync_recipe_verified();

-- Đọc: ai cũng xem món đã duyệt (policy cũ); tác giả xem món của mình mọi trạng thái; admin xem tất cả.
-- Ghi: không có policy INSERT/UPDATE/DELETE cho app → chỉ qua RPC bên dưới.
DROP POLICY IF EXISTS "Authors read own recipes" ON public.recipes;
CREATE POLICY "Authors read own recipes" ON public.recipes FOR SELECT TO authenticated USING (created_by = auth.uid());
DROP POLICY IF EXISTS "Admins read all recipes" ON public.recipes;
CREATE POLICY "Admins read all recipes" ON public.recipes FOR SELECT TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "Authors and admins read recipe ingredients" ON public.recipe_ingredients;
CREATE POLICY "Authors and admins read recipe ingredients" ON public.recipe_ingredients FOR SELECT TO authenticated
    USING (public.is_admin() OR EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.created_by = auth.uid()));
DROP POLICY IF EXISTS "Authors and admins read recipe allergens" ON public.recipe_allergens;
CREATE POLICY "Authors and admins read recipe allergens" ON public.recipe_allergens FOR SELECT TO authenticated
    USING (public.is_admin() OR EXISTS (SELECT 1 FROM public.recipes r WHERE r.id = recipe_id AND r.created_by = auth.uid()));

-- Admin xem cả nguyên liệu đã vô hiệu hóa
DROP POLICY IF EXISTS "Admins read all ingredients" ON public.ingredients;
CREATE POLICY "Admins read all ingredients" ON public.ingredients FOR SELECT TO authenticated USING (public.is_admin());

-- ============================================================================
-- PHẦN 3: ẢNH MÓN CỦA USER (Storage)
-- ============================================================================

-- Mỗi user chỉ ghi vào thư mục <user_id>/ của mình; chỉ ảnh JPG/PNG/WebP ≤ 5 MB; ai cũng xem được (bucket public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('user-recipe-images', 'user-recipe-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = EXCLUDED.file_size_limit, allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Public read user recipe images" ON storage.objects;
CREATE POLICY "Public read user recipe images" ON storage.objects FOR SELECT USING (bucket_id = 'user-recipe-images');
DROP POLICY IF EXISTS "Users upload own recipe images" ON storage.objects;
CREATE POLICY "Users upload own recipe images" ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = auth.uid()::text);
DROP POLICY IF EXISTS "Users update own recipe images" ON storage.objects;
CREATE POLICY "Users update own recipe images" ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = auth.uid()::text)
    WITH CHECK (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = auth.uid()::text);
DROP POLICY IF EXISTS "Users delete own recipe images" ON storage.objects;
CREATE POLICY "Users delete own recipe images" ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'user-recipe-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================================
-- PHẦN 4: USER GỬI / SỬA / XÓA CÔNG THỨC
-- ============================================================================

-- Tạo mới (p_recipe_id NULL) hoặc sửa + gửi duyệt lại món của mình đang pending/rejected.
-- Dinh dưỡng + dị ứng do hệ thống tính từ nguyên liệu; user không nhập số dinh dưỡng.
-- p_ingredients: [{ "ingredient_id": uuid, "amount": số, "unit": "g" | "ml" }] (khối lượng phần ăn được, đã sơ chế)
-- p_instructions: [{ "title"?: chuỗi, "description": chuỗi }] (thứ tự trong mảng = thứ tự bước)
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
    -- Ảnh chỉ được nằm trong thư mục của chính user trên bucket user-recipe-images
    IF p_image_url IS NOT NULL AND (p_image_url !~ '^https://' OR position('/storage/v1/object/public/user-recipe-images/' || v_uid::text || '/' IN p_image_url) = 0) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'image_url';
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
        -- Tối đa 5 món mới mỗi ngày (giờ Việt Nam)
        IF (SELECT count(*) FROM recipes WHERE created_by = v_uid AND (created_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date = vn_today()) >= 5 THEN
            RAISE EXCEPTION 'RATE_LIMITED' USING HINT = 'Tối đa 5 công thức mỗi ngày';
        END IF;
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
REVOKE EXECUTE ON FUNCTION public.submit_recipe(TEXT, TEXT, INT, JSONB, JSONB, TEXT, INT, INT, TEXT, TEXT, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_recipe(TEXT, TEXT, INT, JSONB, JSONB, TEXT, INT, INT, TEXT, TEXT, UUID) TO authenticated;

-- Xóa món của mình khi chưa duyệt (pending/rejected). Món đã duyệt không xóa được từ app.
CREATE OR REPLACE FUNCTION public.delete_my_recipe(p_recipe_id UUID)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_recipe recipes%ROWTYPE;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'UNAUTHORIZED';
    END IF;
    SELECT * INTO v_recipe FROM recipes WHERE id = p_recipe_id FOR UPDATE;
    IF NOT FOUND OR v_recipe.created_by IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'RECIPE_NOT_FOUND' USING HINT = 'recipe_id';
    END IF;
    IF v_recipe.status = 'approved' THEN
        RAISE EXCEPTION 'RECIPE_LOCKED' USING HINT = 'recipe_id';
    END IF;
    DELETE FROM recipes WHERE id = p_recipe_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.delete_my_recipe(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_recipe(UUID) TO authenticated;

-- Món cộng đồng đã duyệt + tên người đóng góp. Không bao giờ trả email; chưa đặt tên → "Người dùng Elytra".
CREATE OR REPLACE FUNCTION public.list_community_recipes(p_page INT DEFAULT 1, p_page_size INT DEFAULT 20)
RETURNS TABLE (
    id UUID, title VARCHAR, slug VARCHAR, image_url TEXT, category VARCHAR, servings INT,
    prep_time_minutes INT, cook_time_minutes INT, difficulty VARCHAR,
    calories_per_serving NUMERIC, protein_g_per_serving NUMERIC, fat_g_per_serving NUMERIC, carbs_g_per_serving NUMERIC,
    author_name TEXT, submitted_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
    v_limit INT := LEAST(GREATEST(COALESCE(p_page_size, 20), 1), 100);
BEGIN
    RETURN QUERY
    SELECT r.id, r.title, r.slug, r.image_url, r.category, r.servings, r.prep_time_minutes, r.cook_time_minutes, r.difficulty,
           r.calories_per_serving, r.protein_g_per_serving, r.fat_g_per_serving, r.carbs_g_per_serving,
           COALESCE(NULLIF(btrim(p.full_name), ''), 'Người dùng Elytra')::TEXT, r.submitted_at,
           COUNT(*) OVER()
      FROM recipes r
      LEFT JOIN profiles p ON p.id = r.created_by
     WHERE r.status = 'approved' AND r.created_by IS NOT NULL
     ORDER BY r.reviewed_at DESC NULLS LAST, r.id
     LIMIT v_limit OFFSET GREATEST((COALESCE(p_page, 1) - 1) * v_limit, 0);
END;
$$;
GRANT EXECUTE ON FUNCTION public.list_community_recipes(INT, INT) TO anon, authenticated;

-- ============================================================================
-- PHẦN 5: ADMIN – DUYỆT CÔNG THỨC
-- ============================================================================

-- Hàng chờ duyệt (cũ nhất trước) kèm tên người gửi và điểm AI chấm sẵn
CREATE OR REPLACE FUNCTION public.admin_list_pending_recipes(p_page INT DEFAULT 1, p_page_size INT DEFAULT 20)
RETURNS TABLE (
    id UUID, title VARCHAR, category VARCHAR, servings INT, image_url TEXT,
    calories_per_serving NUMERIC, protein_g_per_serving NUMERIC, fat_g_per_serving NUMERIC, carbs_g_per_serving NUMERIC,
    author_id UUID, author_name TEXT, submitted_at TIMESTAMPTZ, reject_reason TEXT, ai_review JSONB, total_count BIGINT
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
    v_limit INT := LEAST(GREATEST(COALESCE(p_page_size, 20), 1), 100);
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'FORBIDDEN';
    END IF;
    RETURN QUERY
    SELECT r.id, r.title, r.category, r.servings, r.image_url,
           r.calories_per_serving, r.protein_g_per_serving, r.fat_g_per_serving, r.carbs_g_per_serving,
           r.created_by, COALESCE(NULLIF(btrim(p.full_name), ''), 'Người dùng Elytra')::TEXT, r.submitted_at, r.reject_reason, r.ai_review,
           COUNT(*) OVER()
      FROM recipes r
      LEFT JOIN profiles p ON p.id = r.created_by
     WHERE r.status = 'pending'
     ORDER BY r.submitted_at ASC NULLS LAST, r.id
     LIMIT v_limit OFFSET GREATEST((COALESCE(p_page, 1) - 1) * v_limit, 0);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_list_pending_recipes(INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_list_pending_recipes(INT, INT) TO authenticated;

-- Duyệt / từ chối. Admin KHÔNG sửa nội dung món (chỉ duyệt hoặc từ chối kèm lý do).
CREATE OR REPLACE FUNCTION public.admin_review_recipe(p_recipe_id UUID, p_approve BOOLEAN, p_reason TEXT DEFAULT NULL)
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
REVOKE EXECUTE ON FUNCTION public.admin_review_recipe(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_review_recipe(UUID, BOOLEAN, TEXT) TO authenticated;

-- ============================================================================
-- PHẦN 6: ADMIN – QUẢN LÝ NGUYÊN LIỆU
-- ============================================================================

-- Thêm (p_id NULL) hoặc sửa nguyên liệu. Sửa không làm đổi các công thức cũ: recipe_ingredients giữ số liệu lúc tạo.
CREATE OR REPLACE FUNCTION public.admin_save_ingredient(
    p_name_vi TEXT,
    p_category_id INT,
    p_calories_per_100g NUMERIC,
    p_protein_per_100g NUMERIC,
    p_fat_per_100g NUMERIC,
    p_carbs_per_100g NUMERIC,
    p_fiber_per_100g NUMERIC DEFAULT 0,
    p_sodium_mg NUMERIC DEFAULT NULL,
    p_edible_portion_pct NUMERIC DEFAULT 100,
    p_density_g_per_ml NUMERIC DEFAULT 1,
    p_name_en TEXT DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT false,
    p_allergen_ids INT[] DEFAULT '{}'::INT[],
    p_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_name TEXT := btrim(COALESCE(p_name_vi, ''));
    v_id UUID;
    v_code TEXT;
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'FORBIDDEN';
    END IF;
    IF char_length(v_name) NOT BETWEEN 2 AND 150 OR char_length(COALESCE(p_name_en, '')) > 150 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'name_vi';
    END IF;
    -- Nhóm 15 = món ăn sẵn (bảng prepared_dishes), không phải nguyên liệu
    IF p_category_id IS NULL OR p_category_id = 15 OR NOT EXISTS (SELECT 1 FROM ingredient_categories WHERE id = p_category_id) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'category_id';
    END IF;
    IF p_calories_per_100g IS NULL OR p_calories_per_100g NOT BETWEEN 0 AND 900
       OR p_protein_per_100g IS NULL OR p_protein_per_100g NOT BETWEEN 0 AND 100
       OR p_fat_per_100g IS NULL OR p_fat_per_100g NOT BETWEEN 0 AND 100
       OR p_carbs_per_100g IS NULL OR p_carbs_per_100g NOT BETWEEN 0 AND 100
       OR COALESCE(p_fiber_per_100g, 0) NOT BETWEEN 0 AND 100
       OR p_protein_per_100g + p_fat_per_100g + p_carbs_per_100g + COALESCE(p_fiber_per_100g, 0) > 100 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'macros';
    END IF;
    IF COALESCE(p_sodium_mg, 0) NOT BETWEEN 0 AND 40000 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'sodium_mg';
    END IF;
    IF COALESCE(p_edible_portion_pct, -1) NOT BETWEEN 1 AND 100 OR COALESCE(p_density_g_per_ml, 0) NOT BETWEEN 0.1 AND 3 THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'edible_portion_pct';
    END IF;
    IF EXISTS (SELECT 1 FROM unnest(COALESCE(p_allergen_ids, '{}'::INT[])) a WHERE a NOT IN (SELECT id FROM allergens)) THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'allergen_ids';
    END IF;

    IF p_id IS NULL THEN
        -- Mã A00001…: nguyên liệu do admin thêm (FCT dùng mã số, X… là mã quy đổi)
        v_code := 'A' || lpad((COALESCE((SELECT max(substr(code, 2)::int) FROM ingredients WHERE code ~ '^A[0-9]+$'), 0) + 1)::text, 5, '0');
        INSERT INTO ingredients (code, name_vi, name_en, name_unaccented, category_id, is_featured, is_active, edible_portion_pct, density_g_per_ml,
                                 calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg)
        VALUES (v_code, v_name, NULLIF(btrim(p_name_en), ''), vn_unaccent(v_name), p_category_id, COALESCE(p_is_featured, false), true,
                p_edible_portion_pct, p_density_g_per_ml, p_calories_per_100g, p_protein_per_100g, p_fat_per_100g, p_carbs_per_100g,
                COALESCE(p_fiber_per_100g, 0), p_sodium_mg)
        RETURNING id INTO v_id;
    ELSE
        UPDATE ingredients
           SET name_vi = v_name, name_en = NULLIF(btrim(p_name_en), ''), name_unaccented = vn_unaccent(v_name), category_id = p_category_id,
               is_featured = COALESCE(p_is_featured, false), edible_portion_pct = p_edible_portion_pct, density_g_per_ml = p_density_g_per_ml,
               calories_per_100g = p_calories_per_100g, protein_per_100g = p_protein_per_100g, fat_per_100g = p_fat_per_100g,
               carbs_per_100g = p_carbs_per_100g, fiber_per_100g = COALESCE(p_fiber_per_100g, 0), sodium_mg = p_sodium_mg, updated_at = now()
         WHERE id = p_id
        RETURNING id, code INTO v_id, v_code;
        IF v_id IS NULL THEN
            RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'id';
        END IF;
        DELETE FROM ingredient_allergens WHERE ingredient_id = v_id;
    END IF;
    INSERT INTO ingredient_allergens (ingredient_id, allergen_id)
    SELECT v_id, a FROM unnest(COALESCE(p_allergen_ids, '{}'::INT[])) a ON CONFLICT DO NOTHING;

    PERFORM log_admin_action(CASE WHEN p_id IS NULL THEN 'ingredient.create' ELSE 'ingredient.update' END, 'ingredient', v_id::text,
                             jsonb_build_object('code', v_code, 'name_vi', v_name, 'calories_per_100g', p_calories_per_100g));
    RETURN jsonb_build_object('id', v_id, 'code', v_code);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_save_ingredient(TEXT, INT, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT, BOOLEAN, INT[], UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_ingredient(TEXT, INT, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, TEXT, BOOLEAN, INT[], UUID) TO authenticated;

-- Bật / tắt nguyên liệu. Tắt thì không chọn được khi tạo công thức hay ghi bữa; công thức cũ giữ nguyên số liệu.
CREATE OR REPLACE FUNCTION public.admin_set_ingredient_active(p_id UUID, p_active BOOLEAN)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'FORBIDDEN';
    END IF;
    IF p_active IS NULL THEN
        RAISE EXCEPTION 'VALIDATION_ERROR' USING HINT = 'active';
    END IF;
    UPDATE ingredients SET is_active = p_active, updated_at = now() WHERE id = p_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'id';
    END IF;
    PERFORM log_admin_action(CASE WHEN p_active THEN 'ingredient.activate' ELSE 'ingredient.deactivate' END, 'ingredient', p_id::text);
    RETURN jsonb_build_object('id', p_id, 'is_active', p_active);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_set_ingredient_active(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_ingredient_active(UUID, BOOLEAN) TO authenticated;

-- Xóa nguyên liệu: đã có công thức hoặc nhật ký dùng → không xóa mà vô hiệu hóa (theo đề cương)
CREATE OR REPLACE FUNCTION public.admin_delete_ingredient(p_id UUID)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NOT is_admin() THEN
        RAISE EXCEPTION 'FORBIDDEN';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM ingredients WHERE id = p_id) THEN
        RAISE EXCEPTION 'INGREDIENT_NOT_FOUND' USING HINT = 'id';
    END IF;
    IF EXISTS (SELECT 1 FROM recipe_ingredients WHERE ingredient_id = p_id)
       OR EXISTS (SELECT 1 FROM meal_log_items WHERE ingredient_id = p_id) THEN
        UPDATE ingredients SET is_active = false, updated_at = now() WHERE id = p_id;
        PERFORM log_admin_action('ingredient.deactivate', 'ingredient', p_id::text, '{"reason": "referenced"}'::jsonb);
        RETURN jsonb_build_object('id', p_id, 'action', 'deactivated');
    END IF;
    DELETE FROM ingredients WHERE id = p_id;
    PERFORM log_admin_action('ingredient.delete', 'ingredient', p_id::text);
    RETURN jsonb_build_object('id', p_id, 'action', 'deleted');
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_delete_ingredient(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_ingredient(UUID) TO authenticated;
