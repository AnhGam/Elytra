-- Sprint 8: xóa 2 hàm cũ đã có hàm mới thay thế, app không gọi (bớt code chết, bớt chỗ phải bảo vệ).
--   create_recipe_with_nutrition → submit_recipe (user gửi món, chờ duyệt)
--   create_custom_ingredient     → admin_save_ingredient (admin, có kiểm quyền + nhật ký)
DROP FUNCTION IF EXISTS public.create_recipe_with_nutrition;
DROP FUNCTION IF EXISTS public.create_custom_ingredient;
