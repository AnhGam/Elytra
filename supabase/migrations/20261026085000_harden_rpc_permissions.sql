-- Vá quyền gọi RPC. Anon key nằm trong app nên hàm nào anon gọi được = ai cũng gọi được.
-- Lặp theo tên trong pg_proc để không phụ thuộc signature (DB remote từng được sửa tay qua exec_seed_sql).
DO $$
DECLARE f regprocedure;
BEGIN
    -- 1. exec_seed_sql chạy SQL tùy ý bằng anon key -> xóa. Migration từ nay đi qua `supabase db push`.
    FOR f IN SELECT oid::regprocedure FROM pg_proc
              WHERE pronamespace = 'public'::regnamespace AND proname = 'exec_seed_sql'
    LOOP
        EXECUTE format('DROP FUNCTION %s', f);
    END LOOP;

    -- 2. Hai hàm ghi vào dữ liệu gốc, bỏ qua RLS: recipe tạo ra có is_verified = true, ingredient có is_active = true.
    --    Tạm chỉ service_role (admin/script) gọi được; Sprint 7 làm luồng cộng đồng pending -> duyệt sẽ mở lại có kiểm soát.
    FOR f IN SELECT oid::regprocedure FROM pg_proc
              WHERE pronamespace = 'public'::regnamespace
                AND proname IN ('create_recipe_with_nutrition', 'create_custom_ingredient')
    LOOP
        EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated', f);
        EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', f);
    END LOOP;

    -- 3. Hàm SECURITY DEFINER phải cố định search_path, tránh bị chèn object cùng tên từ schema khác.
    --    Giữ extensions: unaccent và các extension khác nằm ở schema này trên Supabase.
    FOR f IN SELECT oid::regprocedure FROM pg_proc
              WHERE pronamespace = 'public'::regnamespace AND prosecdef
                -- bỏ qua hàm đã tự đặt search_path (vd rls_auto_enable của Supabase dùng pg_catalog)
                AND NOT EXISTS (SELECT 1 FROM unnest(proconfig) c WHERE c LIKE 'search_path=%')
    LOOP
        EXECUTE format('ALTER FUNCTION %s SET search_path = public, extensions', f);
    END LOOP;
END $$;
