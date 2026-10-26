# Tài liệu Kỹ thuật Sprint 4 (Tuần 5 & 6): Động cơ Món ăn, Quản lý Nguyên liệu & Hạ tầng Lưu trữ

Thư mục này chứa toàn bộ báo cáo kỹ thuật, tài liệu thiết kế hệ thống và hướng dẫn kiểm định cho Sprint 4 của Đồ án 1.

---

## Danh mục Tài liệu Kỹ thuật

1. **[01_RECIPE_CRAWLER_AND_NORMALIZATION.md](file:///d:/Antigravity/DA1/docs/week5-6/01_RECIPE_CRAWLER_AND_NORMALIZATION.md)**
   - Cơ chế thu thập dữ liệu công thức món ăn thực tế từ `bepxua.vn` qua WP REST API.
   - Thuật toán bóc tách cú pháp nguyên liệu (Regex parsing pipeline).
   - Bảng hệ số quy đổi đơn vị ước lệ dân gian Việt Nam sang hệ mét (gam).
   - Từ điển đồng nghĩa ánh xạ nguyên liệu vào Bảng thành phần thực phẩm Viện Dinh Dưỡng 2017 (FCT 620).

2. **[02_RECIPES_DATABASE_SCHEMA_AND_NUTRITION_ENGINE.md](file:///d:/Antigravity/DA1/docs/week5-6/02_RECIPES_DATABASE_SCHEMA_AND_NUTRITION_ENGINE.md)**
   - Lược đồ cơ sở dữ liệu quan hệ (`public.recipes`, `public.recipe_ingredients`, `public.recipe_allergens`).
   - Thiết lập Row Level Security (RLS) và chỉ mục B-tree.
   - Thuật toán động cơ tính toán dinh dưỡng tự động trên toàn món và trên từng khẩu phần (`per serving`).
   - Cơ chế kế thừa và cảnh báo dị ứng 2 tầng.
   - Báo cáo số liệu nạp thực tế vào Supabase và ví dụ truy vấn kiểm tra.

3. **[03_RECIPE_AND_INGREDIENT_APIS_AND_STORAGE.md](file:///d:/Antigravity/DA1/docs/week5-6/03_RECIPE_AND_INGREDIENT_APIS_AND_STORAGE.md)**
   - Hạ tầng lưu trữ đa phương tiện Supabase Storage (Buckets: `recipe-images` và `recipe-videos`).
   - Phân tích hạn mức tài nguyên (Quota Analysis) và chiến lược lưu trữ lai (Hybrid Media Strategy).
   - API Tìm kiếm & Lọc món ăn nâng cao có loại trừ dị ứng an toàn (`public.search_recipes`).
   - Động cơ tạo công thức món ăn tự động tính toán dinh dưỡng (`public.create_recipe_with_nutrition`).
   - API Quản lý & Tra cứu chi tiết nguyên liệu, vi chất dinh dưỡng (`public.search_ingredients`, `public.get_ingredient_details`).
   - Kết quả kiểm định đơn vị và tích hợp toàn diện trên môi trường thực tế.

---

## Bảng Thống kê Dữ liệu Đã nạp trên Supabase

| Thực thể / Dịch vụ | Số lượng / Trạng thái | Nguồn gốc / Mô tả |
| :--- | :--- | :--- |
| `public.recipes` | **45** món ăn | Đa dạng thể loại ẩm thực Việt Nam (kho, xào, canh, lẩu, chay, bún/mì) |
| `public.recipe_ingredients` | **604** bản ghi | Định lượng bóc tách chi tiết, quy đổi sang gam và tính dinh dưỡng cơ sở |
| `public.recipe_allergens` | **57** liên kết | Kế thừa tự động từ 8 nhóm dị ứng chuẩn y khoa |
| Nguyên liệu FCT liên kết | **77** loại | Ánh xạ trực tiếp với bảng `public.ingredients` (Viện Dinh Dưỡng 2017) |
| Video hướng dẫn nấu ăn | **45/45** (100%) | Video HD quay cận cảnh chuẩn xác từng bước thực hiện tương ứng công thức |
| Supabase Storage CDN Ảnh | **45/45** (100%) | Bucket `recipe-images` (Public), phân phối qua Global CDN |
| Supabase Storage CDN Video | **Hoạt động 100%** | Bucket `recipe-videos` (Public), kiểm định hoàn tất với video demo MP4 |

---

## Vị trí Mã nguồn Liên quan trong Repository `Elytra`

- **Tệp dữ liệu:**
  - Dữ liệu master công thức món ăn: [`data/vietnamese_recipes_master.json`](file:///d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json)
  - Thư mục ảnh chất lượng cao: [`data/recipe_images/`](file:///d:/Antigravity/DA1/Elytra/data/recipe_images/)
  - Thư mục video hướng dẫn: [`data/recipe_videos/`](file:///d:/Antigravity/DA1/Elytra/data/recipe_videos/)
- **Migrations Cơ sở dữ liệu:**
  - Lược đồ công thức món ăn: [`20261005000007_create_recipes_schema.sql`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000007_create_recipes_schema.sql)
  - Nạp dữ liệu 45 món ăn mẫu: [`20261005000008_seed_recipes.sql`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000008_seed_recipes.sql)
  - API Tìm kiếm & Lọc món ăn: [`20261005000009_create_recipe_search_function.sql`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000009_create_recipe_search_function.sql)
  - Động cơ tạo món ăn tự động: [`20261005000010_create_recipe_creation_engine.sql`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000010_create_recipe_creation_engine.sql)
  - API Quản lý & Tra cứu nguyên liệu: [`20261005000011_create_ingredient_management_functions.sql`](file:///d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000011_create_ingredient_management_functions.sql)
- **Kịch bản Tự động hóa & Kiểm thử:**
  - Upload ảnh lên Supabase Storage: [`scripts/upload_to_supabase_storage.js`](file:///d:/Antigravity/DA1/Elytra/scripts/upload_to_supabase_storage.js)
  - Cấu hình bucket video: [`scripts/setup_video_bucket.js`](file:///d:/Antigravity/DA1/Elytra/scripts/setup_video_bucket.js)
  - Upload video kiểm thử: [`scripts/upload_demo_video.js`](file:///d:/Antigravity/DA1/Elytra/scripts/upload_demo_video.js)
  - Kiểm thử RPC Tra cứu nguyên liệu: [`scripts/test_ingredient_management.js`](file:///d:/Antigravity/DA1/Elytra/scripts/test_ingredient_management.js)
