-- Dọn cảnh báo của Supabase security advisor.
ALTER FUNCTION public.vn_today() SET search_path = public;
ALTER FUNCTION public.meal_item_json(public.meal_log_items) SET search_path = public;
ALTER FUNCTION public.calculate_nutrition_targets(VARCHAR, INT, NUMERIC, NUMERIC, VARCHAR, VARCHAR) SET search_path = public;

-- Hàm trigger, chỉ được gọi khi tạo auth.users; không cần lộ ra /rest/v1/rpc (trigger không cần quyền EXECUTE).
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
