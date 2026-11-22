# Triển khai back-end Elytra (Supabase)

## Cần có

- [ ] Supabase CLI (`npx supabase`) và đã đăng nhập (`supabase login`).
- [ ] Project ref của Supabase project mục tiêu.
- [ ] Quyền Owner hoặc Admin trên Supabase project đó.

## Secrets (Edge Functions)

| Secret | Bắt buộc | Ghi chú |
| --- | --- | --- |
| `GEMINI_API_KEY` | Có (cho tính năng AI) | Lấy ở Google AI Studio; thiếu thì app vẫn chạy với thứ tự SQL + câu mẫu |
| `SUPABASE_URL` | Không cần đặt | Supabase tự cấp cho Edge Function |
| `SUPABASE_ANON_KEY` | Không cần đặt | Supabase tự cấp cho Edge Function |
| `SUPABASE_SERVICE_ROLE_KEY` | Không cần đặt | Supabase tự cấp cho Edge Function |

- [ ] Đặt khóa Gemini: `supabase secrets set GEMINI_API_KEY=...`
- [ ] Kiểm tra lại danh sách secret: `supabase secrets list`

## Áp migration

- [ ] Liên kết project: `supabase link --project-ref <ref>`
- [ ] Kiểm tra trạng thái migration (cột local và remote phải khớp): `supabase migration list --linked`
- [ ] Chạy thử trước khi đẩy: `supabase db push --linked --dry-run`
- [ ] Đẩy migration lên database: `supabase db push --linked`

## Deploy Edge Functions

Lưu ý: `recommend-ai` và `recipe-review-assist` dùng chung `supabase/functions/_shared/`, sửa `_shared/` thì phải deploy lại cả hai hàm.

- [ ] `supabase functions deploy calculate-bmr-tdee --project-ref <ref>`
- [ ] `supabase functions deploy meal-logs --project-ref <ref>`
- [ ] `supabase functions deploy recommend-ai --project-ref <ref>`
- [ ] `supabase functions deploy recipe-review-assist --project-ref <ref>`

## Cấu hình sau khi deploy

- [ ] Thêm tài khoản admin (chạy trong Supabase Dashboard → SQL Editor):

```sql
insert into admins (user_id, note) values ('<uuid>', '<ghi chú>');
```

- [ ] Kiểm tra gốc URL dùng để kiểm ảnh: chạy `select * from app_config;` — giá trị `storage_public_base` phải là `https://<ref>.supabase.co`. Nếu đổi project thì cập nhật:

```sql
update app_config set value = 'https://<ref>.supabase.co' where key = 'storage_public_base';
```

- [ ] Xác nhận các bucket Storage `recipe-images`, `recipe-videos`, `user-recipe-images` đã có sẵn (tạo qua migration).

## Kiểm tra sau deploy

- [ ] Chạy 3 bộ test E2E trên Supabase thật (tự tạo và xóa user tạm):

```powershell
$env:SUPABASE_URL="https://<ref>.supabase.co"; $env:ANON_KEY="..."; $env:SERVICE_ROLE_KEY="..."
node supabase/scripts/test_rls_matrix_e2e.mjs
node supabase/scripts/test_recommend_ai_e2e.mjs
node supabase/scripts/test_community_admin_e2e.mjs
```

- [ ] Kiểm tra Storage và bảng `recipes` không còn dữ liệu test (`created_by is not null` phải rỗng nếu chưa có món cộng đồng thật).

## CI/CD

- [ ] `backend-tests.yml`: chạy test back-end (unit + dựng lại DB bằng PGlite) ở mọi PR vào `main`.
- [ ] `api-release.yml`: phát hành tài liệu API lên GitHub Releases tag `api-latest` khi push `main`, chỉ chạy khi `backend-tests.yml` qua.
- [ ] `security-audit.yml`: quét secret, kiểm tra bảo mật RLS/schema và `flutter analyze`.
- [ ] `keep-supabase-alive.yml`: ping 2 ngày/lần để dự án gói miễn phí không bị tạm dừng; cần đặt 2 secret `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` trên GitHub.

## Giới hạn gói miễn phí cần biết

- [ ] Không có sao lưu tự động trên gói miễn phí (mục Sao lưu sẽ bổ sung ở Sprint 9).
- [ ] Dự án bị tạm dừng nếu 7 ngày không có truy vấn.
- [ ] Hạn mức Gemini miễn phí chưa công bố rõ, app tự chuyển sang câu mẫu khi hết hoặc lỗi.
