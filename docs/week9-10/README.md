# Sprint 6 (Tuần 9 & 10): Hệ thống gợi ý món + Chat AI

Đặc tả API cho FE: [api-contract.md](../api-contract.md) mục 2 (`/recommend-ai`), 4.1 (`search_recipes`), 4.4 (`meal_calorie_budget`), 5.1 (món yêu thích), 5.2 (lịch sử chat).
Thiết kế mô hình quyết định: [01_DECISION_MODEL_RECOMMEND_AND_MODERATION.md](01_DECISION_MODEL_RECOMMEND_AND_MODERATION.md).

## Đã làm (back-end; UI Chat và nút yêu thích do FE làm)

| Thành phần | File |
| --- | --- |
| Sửa dữ liệu: Súp nui gà 6 phần, Chè đậu trắng 10 phần + nước cốt dừa, dầu ngấm món chiên, 2 món gia vị → `gia_vi_an_kem` | `supabase/migrations/20261106090000_recommendation_and_chat_schema.sql` (Phần 1), `supabase/data/recipe_ingredient_overrides.json` |
| `search_recipes`: phân trang `p_page`/`p_page_size` + `total_count`, lọc calo/thời gian/độ khó, ẩn gia vị; giữ `p_limit`/`p_offset` cho app cũ | Phần 2 |
| `chat_sessions`, `chat_messages` + RLS | Phần 3 |
| `meal_calorie_budget`: calo bữa theo phần còn lại, chặn 2 đầu (`ok`/`low`/`capped`/`goal_reached`) | Phần 4a |
| `user_favorite_recipes` + RLS (app gọi thẳng) | Phần 4b |
| `recommend_dishes_for_user`: lọc cứng dị ứng/món từ chối/gia vị, chấm điểm calo-protein-thời gian + món yêu thích; chặn gọi bằng uid người khác | Phần 4c |
| Món tạo mới mặc định chưa duyệt (`is_verified` = false) | Phần 5 |
| Edge Function `recommend-ai`: gợi ý món (SQL → Gemini Decision 1 chọn → Gemini viết lời), đổi món, "Ăn món này" → `log_meal`, hỏi cách nấu, hỏi dinh dưỡng, phân loại câu gõ tự do, từ chối câu ngoài phạm vi; lưu xác suất + món nhận/từ chối | `supabase/functions/recommend-ai/` (`index.ts` định tuyến, `decision.ts` mô hình quyết định, `chat.ts` Gemini chat + câu mẫu) |
| CI: test back-end ở mọi PR vào `main`; workflow phát hành tài liệu API (OpenAPI) lên GitHub Releases, chỉ chạy khi test qua | `.github/workflows/backend-tests.yml`, `.github/workflows/api-release.yml`, `supabase/scripts/generate_api_spec.js` |

## Quyết định thiết kế

- **Tách chọn món và lời nói.** Mô hình quyết định (kiểu Jev) trả xác suất, không viết chữ; Gemini chat chỉ diễn đạt lại dữ liệu DB. Dị ứng lọc ở SQL nên mô hình không bao giờ thấy món nguy hiểm.
- **Gemini Decision 1 (gói miễn phí)** thay cho Jev/OpenRouter (trả phí). Lý do và phương án dự phòng: xem file thiết kế.
- **Fallback 2 tầng:** mô hình quyết định lỗi → thứ tự điểm SQL (`decision_mode: "sql"`), phân loại câu lỗi → coi như gợi ý món; Gemini chat lỗi → câu mẫu / dữ liệu nguyên văn (`fallback: true`). Luôn trả 200.
- **Ngưỡng calo bữa:** chặn trong [0,5 ; 1,5] × chuẩn bữa; còn < 150 kcal thì không gợi ý món chính. Bữa chưa ghi coi như còn ăn, để quên ghi không làm dồn calo.
- **Lịch sử chat ghi lần lượt từng dòng** để `created_at` khác nhau, dựng lại hội thoại đúng thứ tự.

## Triển khai

Đã deploy ngày 12/11/2026 (`supabase db push`, `supabase functions deploy recommend-ai`). Secret cần có: `GEMINI_API_KEY` (key Google AI Studio, gói miễn phí); thiếu key thì vẫn chạy bằng thứ tự SQL + câu mẫu.

## Kiểm thử

Chạy tự động ở CI (`backend-tests.yml`), không cần key:

```powershell
npm i --no-save --no-package-lock @electric-sql/pglite@0.2   # ở thư mục gốc repo, 1 lần
node supabase/scripts/test_recommend_ai_unit.mjs     # chọn món, phân loại câu, Gemini lỗi 429/timeout/rỗng → câu mẫu (fetch giả)
node supabase/scripts/test_recommendation_flow.js    # công thức chấm điểm, câu fallback
node supabase/scripts/test_migrations_replay.mjs     # dựng lại DB: ngân sách calo 4 trạng thái, yêu thích, phân trang, chặn uid người khác...
node supabase/scripts/test_meal_logs_sql.mjs
```

Chạy tay trên Supabase thật (cần service_role key; tự tạo và xóa 2 user tạm):

```powershell
$env:SUPABASE_URL="https://<ref>.supabase.co"; $env:ANON_KEY="..."; $env:SERVICE_ROLE_KEY="..."
node supabase/scripts/test_recommend_ai_e2e.mjs   # gợi ý, đổi món, ăn món, cách nấu, dinh dưỡng, câu tự do, yêu thích + RLS, goal_reached
```

## Chưa làm

- UI Chat AI + nút yêu thích (FE).
- Kiểm duyệt món người dùng upload (chỉ có thiết kế; app chưa có tính năng upload).
