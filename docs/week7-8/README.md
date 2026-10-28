# Sprint 5 (Tuần 7 & 8): Ghi nhận bữa ăn, dinh dưỡng trong ngày, lịch sử

Đặc tả API: [api-contract.md – mục 4 `/meal-logs`](../api-contract.md).

## Đã làm

| Thành phần | File |
| --- | --- |
| Vá quyền RPC: xóa `exec_seed_sql`, khóa `create_recipe_with_nutrition` / `create_custom_ingredient` chỉ cho `service_role`, cố định `search_path` cho mọi hàm SECURITY DEFINER | `supabase/migrations/20261026085000_harden_rpc_permissions.sql` |
| Bảng `meal_logs`, `meal_log_items` + RLS + RPC `log_meal`, `update_meal_log_item`, `get_daily_nutrition`, `get_nutrition_history` | `supabase/migrations/20261026090000_create_meal_logs.sql` |
| Edge Function `meal-logs` (POST ghi món, GET tổng hợp ngày, GET lịch sử, PATCH sửa khẩu phần, DELETE món) | `supabase/functions/meal-logs/index.ts` |
| Đưa bucket Storage, cột `video_url`, link ảnh/video 45 món vào migration; xóa policy cho anon upload | `supabase/migrations/20261026100000_recipe_media_and_storage.sql` |
| Dọn cảnh báo Supabase security advisor (search_path, thu quyền gọi `handle_new_user`) | `supabase/migrations/20261026093000_fix_security_advisor_warnings.sql` |
| Kiểm thử E2E trên Supabase thật: mọi endpoint, format lỗi, RLS giữa 2 user, chặn insert/update thẳng. Tự tạo và xóa 2 user tạm | `supabase/scripts/test_meal_logs_e2e.mjs` |
| Kiểm thử dựng lại DB từ toàn bộ migrations + kiểm từng lỗi trong AUDIT_REPORT | `supabase/scripts/test_migrations_replay.mjs` |
| Kiểm thử từ điển map nguyên liệu và từ khóa dị ứng | `supabase/scripts/test_ingredient_parser.js` |
| Kiểm thử bóc tên món khỏi tiêu đề bài viết | `supabase/scripts/test_dish_name.js` |
| Kiểm thử SQL: vá quyền, tính kcal, chống ghi trùng, validation, tách dữ liệu 2 user, sửa khẩu phần, lịch sử + mục tiêu theo ngày | `supabase/scripts/test_meal_logs_sql.mjs` |

## Quyết định thiết kế

- **Logic ở RPC, Edge Function chỉ định tuyến + đổi lỗi sang format contract.** Edge Function `chat` (intent `accept`) gọi lại đúng RPC `log_meal`.
- **Snapshot dinh dưỡng lúc ghi**: sửa món/nguyên liệu sau này không làm đổi lịch sử. Sửa khẩu phần nhân theo tỉ lệ trên snapshot.
- **Snapshot mục tiêu kcal theo ngày** (`meal_logs.target_kcal`): biểu đồ lịch sử so với mục tiêu của chính ngày đó.
- **App không insert/update thẳng vào bảng**: RLS chỉ cho SELECT/DELETE, ghi bắt buộc qua RPC nên kcal không bị giả.
- **Chống ghi trùng bằng `client_request_id`**: unique `(user_id, client_request_id)` quyết định request nào thắng.
- **"Hôm nay" theo giờ Việt Nam** (`vn_today()`).

## Bảo mật: đã vá

Anon key nằm trong APK nên ai cũng lấy được. Trước đây anon key gọi được:

| Hàm | Hậu quả | Xử lý |
| --- | --- | --- |
| `exec_seed_sql(query)` | Chạy SQL tùy ý: đọc/xóa toàn bộ dữ liệu, kể cả sức khỏe của mọi user | Xóa |
| `create_recipe_with_nutrition` | Đăng món với `is_verified = true`, bỏ qua duyệt | Chỉ `service_role` |
| `create_custom_ingredient` | Thêm nguyên liệu vào bảng gốc FCT | Chỉ `service_role` |
| Policy Storage `Allow anon upload/update` | Upload hoặc ghi đè ảnh/video món ăn | Xóa; upload chỉ qua Dashboard / `supabase storage cp` |

Đã xóa 9 script dùng một lần (`apply_*.js`, `list_db_functions.js`, `setup_*_bucket.js`, `update_recipe_videos.js`, `upload_to_supabase_storage.js`, `upload_demo_video.js`): chúng dựa vào `exec_seed_sql` hoặc quyền upload của anon. Những gì chúng tạo ra (cột `video_url`, 2 bucket, link ảnh/video) nay nằm trong `20261026100000_recipe_media_and_storage.sql`. Từ nay áp migration bằng `supabase db push`.

## Triển khai

Đã deploy ngày 26/10/2026. 7 migration cũ từng chạy qua `exec_seed_sql` đã được `supabase migration repair --status applied` để lịch sử remote khớp với local.

```powershell
supabase login
supabase link --project-ref iwmnkygicqfesvbilmrw
supabase migration list        # kiểm tra lịch sử migration trên remote khớp với file local
supabase db push
supabase functions deploy meal-logs
```

## Kiểm thử

```powershell
mkdir $env:TEMP\pgtest; cd $env:TEMP\pgtest; npm i @electric-sql/pglite@0.2
node <repo>\supabase\scripts\test_meal_logs_sql.mjs

# E2E trên Supabase thật (lấy key: supabase projects api-keys)
$env:SUPABASE_URL="https://iwmnkygicqfesvbilmrw.supabase.co"; $env:ANON_KEY="..."; $env:SERVICE_ROLE_KEY="..."
node supabase\scripts\test_meal_logs_e2e.mjs
```

Cảnh báo advisor còn lại là cố ý: các RPC của `meal-logs` cho `authenticated` gọi (tự lọc theo `auth.uid()`), `search_*` / `get_ingredient_details` chỉ đọc dữ liệu công khai, `rls_auto_enable` do Supabase quản lý.
