# Sprint 7 (Tuần 11 & 12): Cộng đồng đóng góp công thức + Admin

Đặc tả API cho FE: [api-contract.md](../api-contract.md) mục 6 (cộng đồng), 7 (admin), 5 (quyền trên từng bảng / Storage).

## Đã làm (back-end; giao diện cộng đồng và tab Admin do FE làm)

| Thành phần | File |
| --- | --- |
| Bảng `admins` + `is_admin()`, nhật ký `admin_audit_log` | `supabase/migrations/20261113090000_community_and_admin.sql` (Phần 1) |
| Trạng thái công thức `pending` / `approved` / `rejected` + `created_by`, `reject_reason`, `reviewed_by/at`, `submitted_at`, `ai_review`; `is_verified` tự đồng bộ 2 chiều với `status`; RLS: tác giả xem món của mình, admin xem tất cả | Phần 2 |
| Bucket `user-recipe-images`: mỗi user một thư mục, chỉ ảnh JPG/PNG/WebP ≤ 5 MB | Phần 3 |
| `submit_recipe` (tạo / sửa + gửi lại, tự tính dinh dưỡng + dị ứng, 5 món/ngày), `delete_my_recipe`, `list_community_recipes` (tên tác giả, không lộ email) | Phần 4 |
| `admin_list_pending_recipes`, `admin_review_recipe` (từ chối bắt buộc lý do) | Phần 5 |
| `admin_save_ingredient`, `admin_set_ingredient_active`, `admin_delete_ingredient` (đã có công thức dùng → chỉ tắt) | Phần 6 |
| Edge Function `recipe-review-assist`: Gemini Decision 1 chấm sẵn món chờ duyệt (có phải món thật, danh mục, calo hợp lý, dị ứng) → `recipes.ai_review` + cảnh báo tiếng Việt | `supabase/functions/recipe-review-assist/` |
| Sửa sau review bảo mật: URL ảnh phải đúng project + thư mục của mình + file đã upload (trước lách được bằng query string); admin duyệt phải gửi `submitted_at` bản đã xem (chống đổi nội dung lúc đang duyệt, `RECIPE_CHANGED`); giới hạn 5 món/ngày đếm theo lượt gửi (xóa không trả lượt) + khóa chống gửi song song; bỏ quyền liệt kê bucket ảnh cho mọi người; AI chỉ ghi điểm cho đúng bản đã chấm | `supabase/migrations/20261113100000_sprint7_security_fixes.sql` |
| Mô hình quyết định dùng chung cho `recommend-ai` và `recipe-review-assist` | `supabase/functions/_shared/decision.ts` |

## Quyết định thiết kế

- **Quyền admin kiểm trong DB, nghiêm ngặt.** Mọi thao tác admin là RPC `SECURITY DEFINER` tự kiểm `is_admin()` (không tin app ẩn/hiện tab); bảng `admins` không có quyền ghi từ app; mọi thao tác ghi nhật ký; Edge Function `recipe-review-assist` kiểm `is_admin()` bằng token người gọi **trước** khi dùng service_role để ghi.
- **`is_admin()` cho cả anon gọi** (luôn trả `false`): hàm nằm trong policy RLS của `recipes`, thiếu quyền thì app chưa đăng nhập đọc `recipes` bị lỗi.
- **App không ghi thẳng `recipes`**: không có policy INSERT/UPDATE/DELETE, mọi thay đổi qua RPC có kiểm tra dữ liệu (biên tin cậy).
- **Món đã duyệt bị khóa** (không sửa/xóa từ app) để nhật ký ăn uống, món yêu thích của người khác không đổi theo.
- **Admin không sửa nội dung món**, chỉ duyệt hoặc từ chối kèm lý do; user tự sửa rồi gửi lại (lý do cũ được giữ tới khi duyệt).
- **AI chấm sẵn chỉ để tham khảo**: admin duyệt 100% tới khi đo xong bộ ~100 món gắn nhãn (Sprint 8). Chỉ chấm khi admin bấm (tiết kiệm hạn mức miễn phí).
- **Khối lượng nguyên liệu user nhập là phần ăn được** (`consumed_pct = 100`); `ml` đổi ra gam theo tỷ trọng nguyên liệu.

## Triển khai

Đã deploy 12/11/2026 (2 migration `20261113090000`, `20261113100000`; `supabase db push`, `supabase functions deploy recipe-review-assist recommend-ai`). Thêm admin: Supabase Dashboard → SQL Editor:

```sql
insert into admins (user_id, note) values ('<uuid trong Authentication > Users>', 'ghi chú');
-- Đổi project Supabase thì cập nhật gốc URL dùng để kiểm ảnh:
update app_config set value = 'https://<project-ref>.supabase.co' where key = 'storage_public_base';
```

## Kiểm thử

CI (`backend-tests.yml`, không cần key):

```powershell
node supabase/scripts/test_recipe_review_unit.mjs     # câu hỏi gửi AI, cảnh báo, AI lỗi → null
node supabase/scripts/test_migrations_replay.mjs      # dựng lại DB: FORBIDDEN cho user thường ở mọi RPC admin, validate submit, 5 món/ngày,
                                                      # từ chối → gửi lại → duyệt, khóa món đã duyệt, nguyên liệu tắt thay vì xóa, nhật ký
```

Chạy tay trên Supabase thật (cần service_role key; tự tạo và xóa user, nguyên liệu, món, ảnh tạm):

```powershell
node supabase/scripts/test_community_admin_e2e.mjs    # không tự cấp admin, user/anon bị chặn mọi thao tác admin, RLS món pending,
                                                      # không PATCH thẳng recipes, Storage đúng thư mục + chỉ ảnh, AI chấm chỉ admin, không lộ email
```

## Chưa làm

- Giao diện cộng đồng (xem món công khai, form đăng món, "Món của tôi") và tab Admin (FE).
