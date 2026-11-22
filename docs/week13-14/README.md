# Sprint 8 (Tuần 13 & 14): Kiểm thử + vá

Làm sớm ngày 23/11/2026. Đặc tả API cho FE: [api-contract.md](../api-contract.md) mục 2.6 (429), mục 5 (quyền bảng chat, `dietary_preference`), mục 8.

## Đã làm

| Thành phần | File |
| --- | --- |
| Giới hạn 30 lượt hỏi AI/giờ/user (`consume_ai_quota`, bảng `ai_usage`), vượt → 429; "Ăn món này" không bị đếm | `supabase/migrations/20261123090000_ai_rate_limit.sql`, `supabase/functions/recommend-ai/index.ts` |
| Bảng chat: app chỉ đọc + xóa cả phiên của mình; Edge Function ghi bằng service_role sau khi xác thực | `supabase/migrations/20261123091000_chat_service_writes.sql`, `supabase/functions/recommend-ai/index.ts` |
| Sở thích ăn chay (`dietary_preference`: `none` / `vegetarian`) + điểm chất béo trong gợi ý (40% calo, 30% đạm, 15% béo, 15% thời gian) | `supabase/migrations/20261123092000_diet_and_fat_score.sql` |
| Xóa 2 hàm cũ `create_recipe_with_nutrition`, `create_custom_ingredient` | `supabase/migrations/20261123093000_drop_legacy_rpcs.sql` |
| Test BMR/TDEE/macro: 90 ca ma trận | `supabase/scripts/test_nutrition_targets.mjs` |
| Test E2E ma trận RLS: 72 kiểm tra, user B không đọc/ghi được dữ liệu của A trên mọi bảng, RPC, Storage | `supabase/scripts/test_rls_matrix_e2e.mjs` |
| Đo thời gian phản hồi | `supabase/scripts/measure_latency.mjs` |
| Rà calo toàn bộ món (chỉ danh sách) + bộ 100 món test offline cho AI kiểm duyệt | `supabase/scripts/audit_recipe_calories.mjs`, `docs/report/calorie_audit_2026-11-23.md`, `supabase/data/moderation_eval_set.json`, `supabase/scripts/eval_moderation.mjs` |

## Kết quả đo thời gian phản hồi (production, 23/11/2026)

Đo lúc: 2026-11-22T17:26:31.807Z, từ máy chạy script, Supabase project iwmnkygicqfesvbilmrw.supabase.co

| API | số lần đo | lần đầu (ms) | p50 (ms) | p95 (ms) | max (ms) | ghi chú |
| --- | --- | --- | --- | --- | --- | --- |
| search_recipes (20 món/trang) | 20 | 1216 | 396 | 716 | 757 |  |
| search_recipes (từ khóa "ga") | 20 | 415 | 397 | 726 | 739 |  |
| GET /meal-logs (Dashboard) | 20 | 4009 | 320 | 641 | 2630 |  |
| POST /meal-logs (ghi 1 món) | 10 | 322 | 319 | 339 | 339 |  |
| meal_calorie_budget | 20 | 397 | 392 | 409 | 413 |  |
| recommend-ai (gợi ý món, có AI) | 5 | 8629 | 3439 | 8388 | 8388 | fallback 0/6; decision_mode=model |
| recommend-ai (hỏi cách nấu) | 5 | 7680 | 3216 | 7805 | 7805 | fallback 3/6 |

- Các API không dùng AI có p50 khoảng 0,3–0,4 s.
- `recommend-ai` có p50 khoảng 3,2–3,4 s, p95 khoảng 7,8–8,4 s, chậm vì gọi Gemini; lần "hỏi cách nấu" có 3/6 lần dùng câu mẫu do Gemini chat lỗi/quá giờ.
- Ghi chú: cột "số lần đo" không tính lần đầu (khởi động); cột ghi chú đếm cả lần đầu.

## Quyết định thiết kế

- Giới hạn AI đếm trong DB, hàm `consume_ai_quota` không nhận tham số (app không tự đổi được con số 30), khóa theo user chống gửi song song.
- Lỗi DB khi kiểm hạn mức → cho qua (không chặn user), ghi log.
- Chat ghi bằng `service_role`: dữ liệu nhận/từ chối món dùng hiệu chỉnh mô hình không bị app sửa; user vẫn xóa được cả phiên (quyền riêng tư).
- Ăn chay chỉ lọc theo danh mục `mon_chay`; các chế độ khác (keto, low-carb) để hướng phát triển (đề cương mục 8).
- Chất béo chỉ trừ điểm khi món vượt mức béo của bữa (ít béo không bị phạt).

## Triển khai

Đã áp 4 migration (`20261123090000`–`20261123093000`) và deploy Edge Function `recommend-ai` lên production ngày 23/11/2026; chi tiết thứ tự triển khai xem [DEPLOYMENT.md](../DEPLOYMENT.md).

## Kiểm thử

CI (`backend-tests.yml`, không cần key):

```powershell
node supabase/scripts/test_nutrition_targets.mjs
node supabase/scripts/test_migrations_replay.mjs
node supabase/scripts/test_recommendation_flow.js
node supabase/scripts/test_recommend_ai_unit.mjs
```

Chạy tay trên production (cần service_role key; tự tạo và xóa dữ liệu tạm):

```powershell
$env:SUPABASE_URL="https://<ref>.supabase.co"; $env:ANON_KEY="..."; $env:SERVICE_ROLE_KEY="..."
node supabase/scripts/test_rls_matrix_e2e.mjs
node supabase/scripts/test_recommend_ai_e2e.mjs
node supabase/scripts/test_community_admin_e2e.mjs
node supabase/scripts/measure_latency.mjs
```

## Chưa làm

- Chạy `eval_moderation.mjs` (cần `GEMINI_API_KEY`, người dùng chạy) để quyết định có bật tự duyệt ở ngưỡng 0,9.
- Danh sách calo bất thường chờ người dùng xem ([calorie_audit_2026-11-23.md](../report/calorie_audit_2026-11-23.md)), chưa sửa dữ liệu.
- Sao lưu DB (Sprint 9).
