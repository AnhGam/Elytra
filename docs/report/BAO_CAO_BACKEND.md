# Báo cáo Back-end, AI, Cơ sở dữ liệu và Hệ thống gợi ý — Elytra

Báo cáo tổng hợp thiết kế, cài đặt, bảo mật, kiểm thử và triển khai phần back-end, cơ sở dữ liệu, động cơ tính toán dinh dưỡng, hệ thống gợi ý và AI chatbot của ứng dụng di động Elytra (Đồ án 1, Trường Đại học Công nghệ Thông tin — ĐHQG TP.HCM). Người thực hiện phần back-end theo đề cương: Nguyễn Minh Anh (MSSV: 24520107), cán bộ hướng dẫn: ThS. Võ Tuấn Kiệt. Dữ liệu trong báo cáo được tổng hợp theo trạng thái hệ thống tính đến ngày 23/11/2026.

## 1. Kiến trúc tổng thể

Hệ thống back-end của Elytra được xây dựng trên nền tảng Supabase (project `iwmnkygicqfesvbilmrw`, khu vực `ap-southeast-1`), kết hợp giữa PostgreSQL (lưu trữ dữ liệu, PL/pgSQL RPC, Row Level Security), Supabase Auth, Supabase Storage và bốn Supabase Edge Functions viết bằng TypeScript trên runtime Deno. Lớp trí tuệ nhân tạo giao tiếp với Google Gemini API thông qua các Edge Function, không lưu API key ở ứng dụng di động.

```text
+-------------------------------------------------------------------------+
|                        Ứng dụng di động (Flutter)                       |
+-----+--------------------+-------------------------+--------------------+
      |                    |                         |
      v                    v                         v
+------------+   +-------------------+   +--------------------------------+
| Supabase   |   | PostgREST         |   | Supabase Edge Functions (Deno) |
| Auth       |   | - Bảng dữ liệu    |   | - calculate-bmr-tdee           |
| (JWT/Email)|   | - RPC (PL/pgSQL)  |   | - meal-logs                    |
|            |   | - Chính sách RLS  |   | - recommend-ai                 |
+------------+   +---------+---------+   | - recipe-review-assist         |
                           |             +----+----------------------+----+
                           |                  |                      |
                           v                  v                      v
                 +-------------------+  +-------------+    +--------------+
                 | PostgreSQL DB     |  | Gemini      |    | Gemini Chat  |
                 | & Storage Buckets |  | Decision 1  |    | (diễn đạt    |
                 | (ảnh, video món)  |  | (xếp hạng,  |    | tự nhiên)    |
                 |                   |  | phân loại,  |    +--------------+
                 |                   |  | kiểm duyệt) |
                 +-------------------+  +-------------+
```

Nguyên tắc thiết kế xuyên suốt của hệ thống là tách biệt hoàn toàn giữa tính toán định lượng và sinh ngôn ngữ tự nhiên: mọi con số dinh dưỡng (chỉ số BMI, BMR, TDEE, calo và macro mục tiêu, thành phần dinh dưỡng của công thức, ngân sách calo theo bữa, điểm xếp hạng gợi ý và kiểm tra dị ứng) đều do rule-based engine viết bằng PL/pgSQL và cơ sở dữ liệu thực hiện. Mô hình AI chỉ đảm nhận vai trò xếp hạng lại danh sách ứng viên hợp lệ đã được SQL lọc cứng trước (Gemini Decision 1) và diễn đạt kết quả hoặc hướng dẫn nấu ăn thành hội thoại tự nhiên (Gemini chat), đồng thời hệ thống luôn có cơ chế dự phòng để hoạt động bình thường khi API AI gián đoạn.

## 2. Cơ sở dữ liệu

### 2.1 Mô hình dữ liệu

Cơ sở dữ liệu PostgreSQL của Elytra gồm nhóm bảng hồ sơ người dùng, danh mục thực phẩm và công thức, nhật ký bữa ăn, lịch sử hội thoại AI, và nhóm bảng quản trị/giới hạn hệ thống. Bảng dưới đây liệt kê các bảng chính và phân quyền truy cập trực tiếp từ ứng dụng (qua RLS và `GRANT`):

| Tên bảng | Vai trò | Ai đọc / ghi |
| --- | --- | --- |
| `profiles` | Hồ sơ thể trạng, mục tiêu calo/macro, chế độ ăn (`dietary_preference`) | User đọc, tạo và sửa dòng của mình (tạo sẵn qua trigger khi đăng ký) |
| `user_allergens` | Danh sách chất gây dị ứng mà người dùng cần tránh | User đọc, thêm và xóa dòng của mình |
| `allergens` | Danh mục 8 nhóm chất gây dị ứng chuẩn (`seafood`, `egg`, `dairy`, `peanut`, `tree_nut`, `soy`, `gluten`, `sesame`) | Công khai chỉ đọc; chỉ `service_role` hoặc migration ghi |
| `ingredient_categories` | 15 nhóm phân loại thực phẩm theo Bảng TPTP VN 2017 | Công khai chỉ đọc |
| `ingredients` | Kho nguyên liệu chuẩn (620 mục gốc + quy đổi, vi chất, `edible_portion_pct`, `density_g_per_ml`) | Công khai đọc mục `is_active = true`; admin đọc tất cả; ghi qua RPC admin |
| `ingredient_allergens` | Liên kết nguyên liệu với chất gây dị ứng (141 liên kết ban đầu) | Công khai chỉ đọc |
| `prepared_dishes` | 73 món ăn sẵn tách từ chương XV Bảng TPTP VN 2017 (số liệu/100 g) | Công khai đọc mục `is_active = true` |
| `prepared_dish_allergens` | Liên kết món ăn sẵn với chất gây dị ứng (10 liên kết) | Công khai chỉ đọc |
| `recipes` | Công thức món ăn, dinh dưỡng tổng và mỗi khẩu phần, trạng thái duyệt (`pending`/`approved`/`rejected`) | Công khai đọc món đã duyệt; tác giả đọc món của mình; admin đọc tất cả; ghi qua RPC `submit_recipe` / `admin_review_recipe` |
| `recipe_ingredients` | Thành phần nguyên liệu, khối lượng (`amount_g`), tỷ lệ ăn được (`consumed_pct`) và snapshot dinh dưỡng/100 g | Đọc theo quyền xem của `recipes`; ghi qua RPC |
| `recipe_allergens` | Dị ứng kế thừa của công thức và cờ phân biệt dị ứng từ gia vị (`via_condiment`) | Đọc theo quyền xem của `recipes`; ghi qua RPC/migration |
| `meal_logs` | Đầu mục bữa ăn theo ngày/bữa và snapshot mục tiêu ngày (`target_kcal`, macro) | User chỉ đọc dòng của mình; ghi/xóa qua Edge Function `/meal-logs` (RPC `log_meal`) |
| `meal_log_items` | Chi tiết từng món đã ghi (`recipe`, `ingredient`, `dish`), snapshot dinh dưỡng và `client_request_id` | User chỉ đọc dòng của mình; ghi/sửa/xóa qua `/meal-logs` |
| `user_favorite_recipes` | Danh sách công thức yêu thích của người dùng (món đã duyệt) | User đọc, thêm và xóa dòng của mình |
| `chat_sessions` | Phiên hội thoại gợi ý món ăn theo `meal_type` và ngân sách calo | User đọc và xóa phiên của mình; `recommend-ai` (`service_role`) tạo/cập nhật |
| `chat_messages` | Tin nhắn hội thoại, món gợi ý/từ chối và `metadata` xác suất mô hình | User chỉ đọc tin nhắn thuộc phiên của mình; `recommend-ai` (`service_role`) ghi |
| `admins` | Danh sách `user_id` quản trị viên | App không đọc/ghi trực tiếp (kiểm tra qua RPC `is_admin()`); chỉ thêm qua Dashboard/migration |
| `admin_audit_log` | Nhật ký thao tác duyệt món và quản lý nguyên liệu của admin | Chỉ admin được đọc (`is_admin()`); ghi qua hàm nội bộ `log_admin_action` |
| `ai_usage` | Nhật ký lượt gọi `/recommend-ai` để giới hạn 30 lượt/giờ/user | App không đọc/ghi trực tiếp; chỉ RPC `consume_ai_quota()` thao tác |
| `recipe_submissions` | Nhật ký lượt gửi công thức mới (giới hạn 5 món/ngày/user theo giờ VN) | App không đọc/ghi trực tiếp; chỉ RPC `submit_recipe` thao tác |
| `app_config` | Cấu hình hệ thống nội bộ (ví dụ `storage_public_base` để kiểm URL ảnh) | App không đọc/ghi trực tiếp; chỉ hàm nội bộ `storage_public_base()` đọc |

### 2.2 Nguồn dữ liệu dinh dưỡng và chuẩn hóa

Nguồn dữ liệu dinh dưỡng chính của hệ thống là **Bảng thành phần thực phẩm Việt Nam 2017** (Bộ Y tế — Viện Dinh dưỡng), từ đó trích xuất và chuẩn hóa 620 thực phẩm vào bảng `ingredients` (kèm tỷ lệ phần ăn được `edible_portion_pct`, khối lượng riêng `density_g_per_ml`, đa lượng, khoáng chất, vitamin) và 141 liên kết `ingredient_allergens` thuộc 8 nhóm dị ứng. Đối với các thành phần phổ biến trong món Việt nhưng không có trong bảng gốc, hệ thống bổ sung nhóm mã quy đổi `X...`: `X01004` Cơm tẻ (tính từ gạo tẻ máy chia cho hệ số nở 2,6, đạt 133,1 kcal/100 g) và `X03001` Nước cốt dừa lấy từ **USDA FoodData Central (SR Legacy 12117)** (230 kcal, 2,3 g đạm, 23,8 g béo, 5,5 g bột, 2,2 g xơ và 15 mg natri trên 100 g).

Trong quá trình rà soát và kiểm thử thực tế trên 45 công thức mẫu (604–605 dòng `recipe_ingredients` thu thập từ nguồn tiếng Việt), nhóm đã phát hiện và xử lý năm nhóm lỗi dữ liệu lớn:

1. **Ánh xạ sai và bỏ sót nguyên liệu khi parse:** Từ điển ban đầu dùng mã FCT đoán tay khiến 116/285 mục trỏ sai (ví dụ `gà` trỏ nhầm sang Thịt cừu, `lạc` sang Quả đại, `mè` sang Bột đậu xanh, `nước dừa` sang Rượu cô nhắc, `dầu ăn` sang Dầu lạc và vừng gây báo dị ứng giả) và 69/605 dòng bị `ingredient_id = NULL` (58 tên nguyên liệu, làm món thiếu calo và mất tag dị ứng; ví dụ Cá biển kho cà chua chỉ tính 120 kcal/khẩu phần thay vì khoảng 310 kcal). Hệ thống đã viết lại từ điển đối chiếu theo tên FCT chuẩn, so khớp theo ranh giới từ, sửa từ khóa dị ứng (bỏ từ đơn `tương`, bổ sung nhãn `sesame` cho Vừng) và thêm cột `recipe_allergens.via_condiment` để tách dị ứng đến từ gia vị (`condiment_allergens`).
2. **Phần ăn được (`consumed_pct`):** Bảng FCT đo dinh dưỡng trên 100 g phần ăn được, trong khi công thức nấu ăn thường cân cả xương/vỏ. Hệ thống bổ sung `recipe_ingredients.consumed_pct` và hiệu chỉnh 190 dòng (ví dụ Đuôi heo hầm giảm từ 1.365 xuống 969 kcal/khẩu phần theo báo cáo kiểm tra ngày 26/10/2026; trong bảng rà soát 23/11/2026 là 970 kcal/khẩu phần).
3. **Parser đọc sai khối lượng:** Bộ tách định lượng cũ không xử lý dấu phẩy thập phân, phân số, khoảng giá trị và ký tự mã hóa HTML (`gà: 1,5 kg` bị đọc thành 30 g; `Cá chim biển (1 con vừa ăn)` thành 2 g; `nghệ bột: ⅓ muỗng cafe` thành 30 g; `đường: 3-4 muỗng canh` thành 90 g; `Dầu mè: 1 muỗng cà phê` thành 30 g; `&#8230;` thành 8.230 g). Sau khi viết lại bộ parser và duyệt tay toàn bộ, 199/604 dòng được cập nhật đúng khối lượng (1.500 g gà, 500 g cá chim, 1,7 g bột nghệ, 52,5 g đường, 4,6 g dầu mè, 2 g rau ăn kèm), đưa khoảng calo của 45 món từ 22–1.244 kcal lên 92–1.244 kcal/khẩu phần (Lẩu gà lá giang: 81 → 483 kcal; Cá chim kho thơm: 85 → 237 kcal; Hủ tiếu gà trộn: 269 → 542 kcal). Ngoài ra, 5 món bún/lẩu/hủ tiếu không ghi lượng bánh ăn kèm được cộng thêm khẩu phần tinh bột chuẩn 200 g tươi/khẩu phần (Bún riêu cua đồng hải sản: 287 → 511 kcal; Lẩu riêu tôm: 437 → 661 kcal; Lẩu gà lá giang: 483 → 706 kcal; Lẩu Thái: 520 → 743 kcal; Hủ tiếu gà trộn: 542 → 824 kcal).
4. **Tách món ăn sẵn khỏi kho nguyên liệu:** 73 món thuộc chương XV "Thức ăn truyền thống" trong Bảng TPTP VN 2017 (như Phở bò chín, Bún chả, Xôi…) trước đây bị nạp chung vào `ingredients`. Nhóm đã tách 73 mục này sang bảng `prepared_dishes` cùng 10 liên kết `prepared_dish_allergens` và gắn ràng buộc `CHECK (category_id <> 15)` trên `ingredients` (ví dụ 500 g Phở bò chín cung cấp 365 kcal).
5. **Điều chỉnh khẩu phần, dầu chiên và đồ chấm (Sprint 6):** Sửa số khẩu phần Súp nui gà thành 6 phần (giảm từ khoảng 1.050 xuống 701 kcal/khẩu phần) và Chè đậu trắng thành 10 phần (trước đó 1.244 kcal/tô); bổ sung lượng dầu ngấm thực tế cho món chiên (Gà rang muối 60 g, Sườn chiên sả ớt 40 g, Cá bống chay chiên sả điều chỉnh từ 30 g xuống 20 g); và chuyển 2 món gia vị (Muối tôm khô Campuchia, Tỏi ngâm giấm) sang danh mục `gia_vi_an_kem` để ẩn khỏi gợi ý món chính.

### 2.3 Tính dinh dưỡng cho công thức

Mỗi dòng nguyên liệu trong `recipe_ingredients` lưu khối lượng thô hoặc đã sơ chế (`amount_g`), phần trăm thực sự ăn vào (`consumed_pct`) và bản chụp giá trị dinh dưỡng trên 100 g tại thời điểm nạp/tạo món. Tổng dinh dưỡng toàn món bằng tổng đóng góp của từng nguyên liệu, làm tròn 1 chữ số thập phân, sau đó chia cho số khẩu phần (`servings`) để tính các chỉ số trên một khẩu phần (`*_per_serving`). Với công thức do cộng đồng đóng góp qua RPC `submit_recipe`, người dùng không tự nhập số dinh dưỡng mà chỉ chọn nguyên liệu và nhập khối lượng phần ăn được (`g` hoặc `ml`, trong đó `ml` được nhân với `density_g_per_ml`), đồng thời hệ thống tự động kế thừa nhãn dị ứng từ bảng `ingredient_allergens`.

Biểu thức SQL tính lại dinh dưỡng công thức được trích nguyên văn từ `supabase/migrations/20261106090000_recommendation_and_chat_schema.sql`:

```sql
UPDATE public.recipes r
   SET total_calories = t.cal, total_protein_g = t.prot, total_fat_g = t.fat, total_carbs_g = t.carbs,
       total_fiber_g = t.fiber, total_sodium_mg = t.sod,
       calories_per_serving = round(t.cal / r.servings, 1),
       protein_g_per_serving = round(t.prot / r.servings, 1),
       fat_g_per_serving = round(t.fat / r.servings, 1),
       carbs_g_per_serving = round(t.carbs / r.servings, 1),
       fiber_g_per_serving = round(t.fiber / r.servings, 1),
       sodium_mg_per_serving = round(t.sod / r.servings, 1),
       updated_at = now()
  FROM (SELECT recipe_id,
               round(sum(amount_g * consumed_pct / 100 * calories_per_100g / 100), 1) AS cal,
               round(sum(amount_g * consumed_pct / 100 * protein_per_100g / 100), 1) AS prot,
               round(sum(amount_g * consumed_pct / 100 * fat_per_100g / 100), 1) AS fat,
               round(sum(amount_g * consumed_pct / 100 * carbs_per_100g / 100), 1) AS carbs,
               round(sum(amount_g * consumed_pct / 100 * fiber_per_100g / 100), 1) AS fiber,
               round(sum(amount_g * consumed_pct / 100 * sodium_mg_per_100g / 100), 1) AS sod
          FROM public.recipe_ingredients GROUP BY recipe_id) t
 WHERE t.recipe_id = r.id;
```

### 2.4 Phân quyền dữ liệu (Row Level Security)

Tất cả các bảng nghiệp vụ trong schema `public` và các bucket trong Supabase Storage đều bật Row Level Security (RLS) theo nguyên tắc đặc quyền tối thiểu:

- **Dữ liệu cá nhân** (`profiles`, `user_allergens`, `user_favorite_recipes`, `meal_logs`, `meal_log_items`, `chat_sessions`, `chat_messages`): cách ly theo `auth.uid()`. Riêng nhật ký bữa ăn và tin nhắn chat bị khóa quyền `INSERT`/`UPDATE` trực tiếp từ client; mọi thao tác ghi phải đi qua Edge Function hoặc RPC chuyên trách nhằm chống giả mạo calo và bảo toàn dữ liệu huấn luyện.
- **Dữ liệu công khai và cộng đồng** (`recipes`, `recipe_ingredients`, `recipe_allergens`, `ingredients`, `prepared_dishes`): người dùng thường chỉ xem được công thức đã duyệt (`is_verified = true`, tức `status = 'approved'`) hoặc công thức do chính mình tạo, và chỉ xem nguyên liệu/món ăn sẵn đang hoạt động (`is_active = true`).
- **Bảng nội bộ** (`admins`, `app_config`, `ai_usage`, `recipe_submissions`): bật RLS không có policy mở và thu hồi toàn bộ quyền (`REVOKE ALL`) đối với `anon` và `authenticated`; chỉ có `admin_audit_log` cho phép tài khoản vượt qua `is_admin()` đọc nhật ký.
- **Các hàm `SECURITY DEFINER`:** toàn bộ hàm nâng quyền đều cố định `SET search_path = public` (hoặc `public, extensions`) và tự xác thực danh tính qua `auth.uid()` ngay trong thân hàm (ví dụ `recommend_dishes_for_user` từ chối khi `p_uid IS DISTINCT FROM auth.uid()`; các hàm quản trị kiểm tra `is_admin()` ở DB). Các hàm nội bộ (`day_target_kcal`, `storage_public_base`, `log_admin_action`, trigger đồng bộ) bị `REVOKE EXECUTE` khỏi `PUBLIC`, `anon` và `authenticated`.

Kết quả kiểm thử E2E ma trận RLS trên môi trường production (`supabase/scripts/test_rls_matrix_e2e.mjs`) với 2 người dùng tạm A, B và tài khoản ẩn danh đạt **72/72 kiểm tra**: người dùng B và ẩn danh không thể đọc, chèn, sửa hoặc xóa dữ liệu trên 10 bảng cá nhân, 5 bảng nội bộ, các RPC (`recommend_dishes_for_user`, `update_meal_log_item`, `delete_meal_log_item`, `submit_recipe`, `delete_my_recipe`, `get_daily_nutrition`), các Edge Function (`meal-logs`, `recommend-ai`) và thư mục Storage `user-recipe-images` của người dùng A.

## 3. Ước tính nhu cầu dinh dưỡng (BMR/TDEE/macro)

Hệ thống hợp nhất toàn bộ công thức ước tính vào một nguồn duy nhất tại hàm SQL `public.calculate_nutrition_targets`. Edge Function `POST /calculate-bmr-tdee` gọi trực tiếp hàm này (kiểm tra đầu vào khớp ứng dụng: tuổi 18–80, chiều cao 120–220 cm, cân nặng 30–200 kg; riêng ràng buộc CHECK trên bảng `profiles` cho phép tuổi 10–100, chiều cao 50–250 cm, cân nặng 20–300 kg) và có tùy chọn `save_to_profile: true` để lưu kết quả cho người dùng đang đăng nhập.

Các bước tính toán trong `calculate_nutrition_targets` gồm:

1. **BMI và phân loại (chuẩn WHO WPRO cho người châu Á):** `BMI = ROUND(weight_kg / (height_cm / 100)^2, 1)`. Phân loại: `< 18,5` (Thiếu cân), `18,5–22,9` (Bình thường), `23,0–24,9` (Tiền béo phì (Thừa cân)), `>= 25,0` (Béo phì).
2. **BMR (Mifflin-St Jeor):**
   - Nữ (`female`): `BMR = ROUND(10 × weight_kg + 6,25 × height_cm - 5 × age - 161, 1)`
   - Nam (`male`) và `other`: `BMR = ROUND(10 × weight_kg + 6,25 × height_cm - 5 × age + 5, 1)`
3. **TDEE theo hệ số vận động thể chất (PAL):** `TDEE = ROUND(BMR × factor, 1)`, với `factor` lấy theo bảng sau (giá trị ngoài danh sách mặc định `1,375`):

| Mức vận động (`activity_level`) | Mô tả | Hệ số (`factor`) |
| --- | --- | --- |
| `sedentary` | Ít vận động | 1,200 |
| `light` | 1–3 buổi/tuần | 1,375 |
| `moderate` | 3–5 buổi/tuần | 1,550 |
| `active` | 6–7 buổi/tuần | 1,725 |
| `very_active` | Lao động nặng, tập 2 lần/ngày | 1,900 |

4. **Calo mục tiêu và sàn an toàn chuyển hóa:** Điều chỉnh theo mục tiêu (`lose_weight`: `TDEE - 500`; `maintain`: `TDEE`; `gain_weight`: `TDEE + 400`). Từ bản vá `20261028090000_fix_review_findings.sql`, sàn an toàn được áp dụng cho mọi mục tiêu nhằm bảo vệ ngưỡng tối thiểu của bảng `profiles`: tối thiểu `1.200 kcal` đối với nữ và `1.500 kcal` đối với nam hoặc `other`.
5. **Phân bổ đa lượng (macro), chất xơ và nước:**
   - **Chất đạm (Protein):** `protein_g = ROUND(weight_kg × p_factor, 1)`, trong đó `p_factor` bằng `2,0 g/kg` (`lose_weight`), `1,8 g/kg` (`gain_weight`) hoặc `1,6 g/kg` (`maintain`), tương ứng `protein_kcal = protein_g × 4`.
   - **Chất béo (Fat):** chiếm 25% tổng calo mục tiêu (`fat_kcal = target_calories × 0,25`, `fat_g = ROUND(fat_kcal / 9, 1)`).
   - **Tinh bột (Carbs):** lấy phần calo còn lại (`carbs_kcal = GREATEST(target_calories - protein_kcal - fat_kcal, 0)`, `carbs_g = ROUND(carbs_kcal / 4, 1)`).
   - **Chất xơ và nước:** `fiber_g = GREATEST(ROUND(target_calories / 1000 × 14, 1), 25)` g/ngày; `water_ml = ROUND(weight_kg × 35, 0)` ml/ngày.

Kiểm thử tự động bằng `supabase/scripts/test_nutrition_targets.mjs` trên PGlite vượt qua toàn bộ **90 ca ma trận** (3 giới tính × 5 mức vận động × 3 mục tiêu × 2 thể trạng), ca mẫu chuẩn (`male`, 22 tuổi, 170 cm, 65 kg, `moderate`, `lose_weight` → BMI 22,5, BMR 1.607,5 kcal, TDEE 2.491,6 kcal, mục tiêu 1.991,6 kcal, 130 g đạm, 55,3 g béo, 243,4 g bột, 27,9 g xơ, 2.275 ml nước), các điểm biên BMI và ngưỡng sàn 1.200/1.500 kcal. Ngoài ra, vòng đối soát PR #4 đã xác nhận hàm SQL khớp hoàn toàn với `NutritionCalculator` (Dart) trên **1.920** tổ hợp đầu vào.

## 4. Nhật ký bữa ăn và dashboard

Toàn bộ thao tác ghi nhận và theo dõi dinh dưỡng hàng ngày đi qua Edge Function `/meal-logs` (cùng luồng "Ăn món này" trong `/recommend-ai` gọi chung RPC `log_meal`). Edge Function đóng vai trò xác thực JWT, định tuyến phương thức HTTP (`POST /meal-logs`, `GET /meal-logs`, `GET /meal-logs/history`, `PATCH /meal-logs/items/:id`, `DELETE /meal-logs/items/:id`) và ánh xạ mã lỗi PostgreSQL sang định dạng HTTP 4xx/5xx thống nhất; mọi logic tính toán và kiểm tra biên nằm trong các RPC `SECURITY DEFINER`.

Các cơ chế cốt lõi bảo đảm tính toàn vẹn số liệu gồm:

- **Snapshot dinh dưỡng lúc ghi và sửa khẩu phần:** Bảng `meal_log_items` hỗ trợ ba nguồn thực phẩm là công thức đã duyệt (`recipe`, theo `servings` từ 0,25 đến 10), nguyên liệu thô (`ingredient`, theo `amount_g` từ 1 đến 2.000 g) và món ăn sẵn trong `prepared_dishes` (`dish`, theo `amount_g` từ 1 đến 2.000 g). Khi ghi bữa, `log_meal` sao chép tên món và tính ngay lượng `kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g` lưu vào `meal_log_items` với kiểu `NUMERIC(14,6)`, đảm bảo việc cập nhật hoặc xóa món gốc sau này (`ON DELETE SET NULL`) không làm thay đổi lịch sử cũ. Khi sửa khẩu phần/khối lượng qua `update_meal_log_item`, hệ thống nhân trực tiếp theo tỷ lệ mới/cũ trên snapshot `NUMERIC(14,6)` để tránh sai số tích lũy khi chỉnh nhiều lần.
- **Snapshot mục tiêu ngày:** Bảng `meal_logs` lưu kèm mục tiêu của ngày tại thời điểm ghi (`target_kcal`, `target_protein_g`, `target_carbs_g`, `target_fat_g`). Hàm nội bộ `day_target_kcal()` thống nhất quy tắc giữa Dashboard (`get_daily_nutrition`) và biểu đồ lịch sử (`get_nutrition_history`): các ngày đã qua luôn đối chiếu theo mục tiêu snapshot lúc ghi bữa đầu tiên, còn ngày hôm nay dùng mục tiêu hiện tại trong `profiles`.
- **Chống ghi trùng (`client_request_id`):** Ràng buộc `UNIQUE (user_id, client_request_id)` trên `meal_log_items` kết hợp dấu vân tay MD5 `request_hash` (tính từ `meal_type`, ID món, `servings`/`amount_g` và `p_date` gốc) giúp xử lý an toàn trường hợp ứng dụng gửi lại khi mạng chập chờn. Gửi lại đúng khóa và đúng nội dung gốc trả HTTP `200` với `replayed: true` cùng trạng thái hiện tại của món và `budget` cập nhật (giúp ứng dụng cập nhật Dashboard mà không cần gọi thêm `GET`); gửi trùng khóa nhưng khác nội dung trả `422 IDEMPOTENCY_CONFLICT`.
- **"Hôm nay" theo giờ Việt Nam và cửa sổ 30 ngày:** Hàm `vn_today()` xác định ngày hiện tại theo múi giờ `Asia/Ho_Chi_Minh` (`(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date`). Các thao tác ghi, sửa hoặc xóa đều bị chặn nếu ngày vượt quá tương lai hoặc lùi quá 30 ngày so với `vn_today()`. Khi xóa món cuối cùng trong một bữa qua `delete_meal_log_item`, hệ thống tự động dọn dòng `meal_logs` rỗng tương ứng.
- **Dashboard và lịch sử 31 ngày:** `GET /meal-logs?date=` luôn trả đủ 4 bữa (`breakfast`, `lunch`, `dinner`, `snack`) kèm khối `budget` (`target`, `consumed`, `remaining`, trong đó `remaining` có thể âm khi nạp vượt mục tiêu). `GET /meal-logs/history?from=&to=` truy vấn tối đa 31 ngày mỗi lần (`p_to - p_from <= 30`), dùng `generate_series` để trả về liên tục mọi ngày trong khoảng (ngày không ghi nhận bữa ăn có giá trị bằng `0`).





## 5. Hệ thống gợi ý món ăn

Hệ thống gợi ý món ăn kết hợp lọc ràng buộc và chấm điểm bằng SQL (RPC `recommend_dishes_for_user`, `meal_calorie_budget`) với mô hình quyết định Gemini Decision 1 (`recommend-ai`). Toàn bộ dinh dưỡng và tập ứng viên đều xuất phát từ cơ sở dữ liệu; AI không tự tính số liệu và không tạo món ngoài danh mục. Hàm `recommend_dishes_for_user` chạy ở chế độ `SECURITY DEFINER` và kiểm tra `p_uid = auth.uid()` để chặn truy vấn thay người dùng khác.

### 5.1 Lọc theo ràng buộc

Ở tầng SQL (`supabase/migrations/20261123092000_diet_and_fat_score.sql`), mọi ứng viên phải vượt qua 5 điều kiện lọc cứng trước khi chấm điểm:

- **Trạng thái duyệt**: chỉ lấy món có `is_verified = true` (đồng bộ với `status = 'approved'`).
- **Loại bỏ đồ chấm và gia vị ăn kèm**: loại các món thuộc danh mục `gia_vi_an_kem` (ví dụ: Muối tôm khô, Tỏi ngâm giấm) để tránh gợi ý nhầm thành món chính.
- **Chế độ ăn chay**: đọc `profiles.dietary_preference`; nếu là `vegetarian`, chỉ giữ món thuộc danh mục `mon_chay` (mặc định `none` giữ toàn bộ danh mục hợp lệ).
- **Món đã từ chối trong phiên**: loại trừ các ID nằm trong `p_exclude_recipe_ids` (tối đa 50 UUID do ứng dụng lưu trong phiên khi người dùng chọn "Đổi món khác").
- **Dị ứng thực phẩm**: loại trừ mọi món có bản ghi trong `recipe_allergens` trùng với `user_allergens` của người dùng, bao gồm cả dị ứng bắt nguồn từ gia vị (`via_condiment = true` như nước mắm, xì dầu). Nhờ lọc cứng ngay trong SQL, các món chứa chất gây dị ứng không bao giờ được đưa tới mô hình AI.

### 5.2 Ngân sách calo cho bữa

Nếu ứng dụng không truyền `target_calories` (khoảng hợp lệ 100–2000 kcal), hệ thống gọi RPC `meal_calorie_budget(p_meal_type)` để tính ngân sách cho bữa sắp ăn dựa trên mục tiêu ngày trong `profiles` và tổng calo đã ghi trong ngày theo giờ Việt Nam (UTC+7):

- **Tỉ lệ chuẩn theo bữa**: sáng (`breakfast`) 25%, trưa (`lunch`) 35%, tối (`dinner`) 30%, phụ (`snack`) 10%.
- **Chuẩn bữa**: `base_kcal = mục tiêu ngày × tỉ lệ bữa`.
- **Tổng tỉ lệ các bữa chưa ghi (`open_share`)**: bằng tỉ lệ bữa đang hỏi cộng tổng tỉ lệ các bữa khác chưa có dữ liệu trong `meal_logs` ngày hôm nay. Cách tính này coi bữa chưa ghi là bữa còn sẽ ăn, nên việc quên ghi bữa sáng không làm bữa trưa bị dồn calo.
- **Giá trị thô**: `raw = calo còn lại hôm nay × tỉ lệ bữa / open_share`.

Ngân sách bữa được kẹp trong khoảng `[0,5 ; 1,5] × base_kcal` với 4 trạng thái:

| Trạng thái (`status`) | Điều kiện kích hoạt | Mức `target_kcal` áp dụng | Hành vi hệ thống |
| --- | --- | --- | --- |
| `ok` | `remaining >= 150` và `0,5 × base <= raw <= 1,5 × base` | `round(raw)` | Gợi ý món bình thường |
| `low` | `remaining >= 150` và `raw < 0,5 × base` | `round(max(raw, 150))` | Gợi ý món nhẹ, kèm câu nhắc |
| `capped` | `remaining >= 150` và `raw > 1,5 × base` | `round(1,5 × base)` | Không dồn calo bữa bỏ lỡ, kèm câu nhắc |
| `goal_reached` | `remaining < 150` kcal | `null` | Không gợi ý món chính (`suggested_recipes` rỗng) |

### 5.3 Chấm điểm theo nội dung

Sau khi lọc cứng, SQL tính mục tiêu đạm và chất béo của bữa tỉ lệ theo `target_cal` so với mục tiêu ngày (`target_prot = round(daily_prot × target_cal / daily_cal)`, mặc định 25 g; `target_fat = round(daily_fat × target_cal / daily_cal)`, mặc định 20 g). Mỗi món được chấm các điểm thành phần trong `[0 ; 1]`:

- **Điểm calo**: `cal_score = max(0, 1 − |calo_món − target_cal| / max(target_cal, 100))`
- **Điểm đạm**: `prot_score = max(0, 1 − |đạm_món − target_prot| / max(target_prot, 10))`
- **Điểm chất béo**: nếu `béo_món <= target_fat` thì `fat_score = 1,0`; nếu vượt ngưỡng thì `fat_score = max(0, 1 − (béo_món − target_fat) / max(target_fat, 10))` (chỉ phạt khi vượt, món ít béo không bị trừ điểm).
- **Điểm thời gian** (`tổng thời gian = prep_time_minutes + cook_time_minutes`, mặc định `15 + 20` phút nếu thiếu): `<= 30` phút đạt `1,0`; `<= 45` phút đạt `0,8`; `> 45` phút đạt `0,6`.

Điểm tổng hợp cuối cùng (cập nhật ở Sprint 8, thay cho bộ trọng số 0,45 / 0,35 / 0,20 ở Sprint 6 khi chưa tính chất béo):

`score = min(1, round(0,40 × cal_score + 0,30 × prot_score + 0,15 × fat_score + 0,15 × time_score + bonus_yêu_thích, 2))`

Trong đó `bonus_yêu_thích = 0,10` nếu món có trong `user_favorite_recipes` của người dùng, ngược lại bằng `0`. Kết quả sắp xếp theo `score` giảm dần (hòa thì ưu tiên `|calo_món − target_cal|` nhỏ hơn), lấy tối đa 10 ứng viên cho `recommend-ai`. Lý do `match_reason` được sinh trực tiếp trong SQL theo thứ tự ưu tiên:

- `|calo_món − target_cal| <= 50` và `đạm_món >= target_prot`: *"Rất chuẩn calo (~X kcal) và dồi dào đạm (Yg protein)"*.
- `đạm_món >= 1,2 × target_prot`: *"Giàu protein (Yg), phù hợp phục hồi cơ bắp"*.
- `tổng thời gian <= 30` phút: *"Nhanh gọn (~T phút), calo vừa vặn"*.
- Trường hợp còn lại: *"Cân đối dinh dưỡng (X kcal, Yg đạm)"*.

### 5.4 Mô hình quyết định xếp hạng lại

Khi SQL trả từ 2 ứng viên trở lên (tối đa 10 ứng viên, đánh khóa `r0..r9`), Edge Function `recommend-ai` gọi **Gemini Decision 1** (`models/gemini-decision-1`, ra mắt 11/11/2026 qua `POST /v1beta/decisions`) bằng hàm `decideDish` (`supabase/functions/_shared/decision.ts`). Khác với LLM sinh chữ, mô hình quyết định kiểu Jev nhận trạng thái và câu hỏi có kiểu (`choice`, `noul`, `score`) rồi trả về phân phối xác suất cho từng lựa chọn.

- **Lý do chọn mô hình**:
  - **Gemini Decision 1**: được chọn vì có gói miễn phí trên Google AI Studio (dùng chung `GEMINI_API_KEY`), hỗ trợ `choice` 2–255 lựa chọn và tối đa 1.000 câu hỏi/request.
  - **Jev (TypeSafe) qua OpenRouter**: không dùng do thu phí ($0,042/1M token) và gói credit miễn phí $5 đã tạm dừng từ 27/9/2026.
  - **Quyet-1.0-Small** (328M, Apache-2.0, macro-F1 đạt 53,6 so với 69,2 của Jev trên tiếng Việt theo preprint UIT arXiv 2610.31422): giữ làm phương án dự phòng nếu Google siết gói miễn phí (cần tự host trên VM, tối đa 10 lựa chọn).
  - Các mô hình khác (Laya, Von) không đáp ứng do độ chính xác thấp hoặc chỉ hỗ trợ tiếng Anh; tự đọc logprobs không khả thi trên hạ tầng miễn phí.
- **Dữ liệu gửi đi và cấu hình**: để tuân thủ quyền riêng tư trên gói miễn phí, request **không gửi cân nặng hay tuổi**, chỉ gửi `goal`, `meal_type`, `meal_calorie_target`, `calories_left_today`, `eaten_last_3_days` (tối đa 30 món ăn trong 3 ngày gần nhất), `rejected_dishes` và `user_message`. Câu hỏi tiêu chí viết bằng tiếng Anh vì mô hình giảm độ chính xác với tiêu chí tiếng Việt; thời gian chờ tối đa (`timeout`) đặt **3 giây** (`3000 ms`).

Xác suất trả về được gán vào `decision_probability` để sắp xếp lại danh sách (món đứng đầu là món được chọn, `decision_mode = "model"`) và lưu vào `chat_messages.metadata.decision_probabilities` để hiệu chỉnh sau này.

### 5.5 Cơ chế dự phòng (fallback)

Lỗi từ Gemini không bao giờ làm hỏng luồng gợi ý; hệ thống sử dụng fallback 2 tầng và luôn trả HTTP `200`:

- **Tầng 1 (Mô hình quyết định)**: nếu thiếu `GEMINI_API_KEY`, chỉ có 0–1 ứng viên, API lỗi hoặc quá timeout 3 s, `decideDish` trả `null` và hệ thống giữ nguyên thứ tự điểm SQL (`decision_mode: "sql"`, `decision_probability: null`). Khi phân loại câu gõ tự do (`classifyIntent`) bị lỗi, hệ thống mặc định chuyển về `recommend`.
- **Tầng 2 (Gemini chat)**: nếu Gemini chat (`gemini-flash-lite-latest`, timeout 6,5 s) lỗi, hết hạn mức hoặc trả rỗng, hệ thống dùng câu mẫu định sẵn (`fallbackRecommend`, `fallbackHowToCook`, `fallbackNutrition`) từ dữ liệu DB, gắn cờ `fallback: true` và ghi lỗi vào `chat_messages.metadata.chat_error`.
- **Giới hạn tần suất**: người dùng được gọi tối đa **30 lượt hỏi AI trong 1 giờ** (cửa sổ trượt, hàm `consume_ai_quota` khóa theo `user_id` trên bảng `ai_usage`). Vượt ngưỡng sẽ trả HTTP `429 RATE_LIMITED` kèm `retry_after_seconds` và header `Retry-After`. Thao tác "Ăn món này" không bị tính vào hạn mức; nếu truy vấn kiểm tra hạn mức gặp lỗi DB, hệ thống cho qua và ghi log để không gián đoạn trải nghiệm.

## 6. AI chatbot

Toàn bộ hội thoại và gợi ý món được hợp nhất vào một Edge Function duy nhất là `POST /recommend-ai` (`supabase/functions/recommend-ai/`), thay thế hai endpoint bản nháp cũ `/recommend` và `/chat`. Endpoint xác thực JWT người dùng, kiểm tra đầu vào (`message` tối đa 500 ký tự, `rejected_recipe_ids` tối đa 50 UUID, `target_calories` trong khoảng 100–2000 kcal), quản lý phiên tại `chat_sessions` và ghi từng tin nhắn tuần tự vào `chat_messages` để giữ đúng thứ tự `created_at`.

**Các ý định (`intent`) và định tuyến**

Server xử lý theo thứ tự ưu tiên: `accepted_recipe_id` → `intent` từ chip → phân loại câu tự do → mặc định `recommend`:

| Ý định (`intent`) | Nguồn kích hoạt | Nguồn dữ liệu & xử lý | Trạng thái trả về (`status`) |
| --- | --- | --- | --- |
| `accept` | Gửi `accepted_recipe_id` | Gọi RPC `log_meal` (hỗ trợ `servings` 0,25–10, `client_request_id`) | `logged` (kèm `logged`, `budget`) |
| `recommend` | Chip "Gợi ý" / "Đổi món" hoặc mặc định | `meal_calorie_budget` + `recommend_dishes_for_user` + `decideDish`, Gemini chat giải thích 3 món đầu | `ok` / `low` / `capped` / `goal_reached` |
| `how_to_cook` | Chip "Nấu thế nào?" hoặc câu tự do | Đọc nguyên liệu, `instructions`, thời gian, `video_url` từ DB; Gemini chat diễn đạt lại | `answered` |
| `nutrition` | Chip "Dinh dưỡng" hoặc câu tự do | Đọc calo, macro, xơ, natri và `allergens` từ DB; Gemini chat diễn đạt lại | `answered` |
| `out_of_scope` | Câu tự do ngoài ăn uống (`p >= 0,7`) | Trả câu mẫu `OUT_OF_SCOPE_MESSAGE`, không gợi ý món | `out_of_scope` |

Khi hỏi `how_to_cook` hoặc `nutrition` mà không truyền `recipe_id`, server tự lấy món đứng đầu lượt gợi ý gần nhất trong phiên. Nếu phiên chưa có gợi ý nào, câu gõ tự do được chuyển sang `recommend`, còn bấm chip gửi `intent` tường minh mà thiếu `recipe_id` sẽ trả `400 VALIDATION_ERROR`.

**Phân loại câu tự do, lớp ngôn ngữ và phân quyền chat**

- **Phân loại câu gõ tự do**: khi không gửi `intent` mà có `message`, hàm `classifyIntent` gọi Gemini Decision 1 phân loại vào 4 nhãn (`recommend`, `how_to_cook`, `nutrition`, `out_of_scope`). Hệ thống chỉ trả `out_of_scope` khi xác suất đạt `>= 0,7` để tránh từ chối nhầm; dưới ngưỡng này hoặc khi mô hình lỗi sẽ chuyển về `recommend`.
- **Kiểm soát lớp ngôn ngữ (`chat.ts`)**: sử dụng model `gemini-flash-lite-latest` (`temperature: 0,6`, `maxOutputTokens: 800`, `thinkingConfig: { thinkingLevel: "minimal" }`, timeout **6,5 giây**). System prompt bắt buộc Gemini **chỉ diễn đạt lại** dữ liệu đã có từ DB, tuyệt đối không bịa món, không đổi thứ tự và không tự tính lại số liệu dinh dưỡng.
- **Theo dõi lỗi chat**: khi Gemini chat lỗi hoặc quá giờ (`fallback: true`), lý do được ghi vào `chat_messages.metadata.chat_error` (ví dụ: `"timeout"`, `"no key"`, `"HTTP 503: ... high demand ..."` ghi nhận khi đo thử ngày 12/11/2026, `"HTTP 429: ..."`).
- **Bảo mật lịch sử chat**: từ Sprint 8 (`20261123091000_chat_service_writes.sql`), ứng dụng chỉ có quyền đọc (`SELECT`) trên `chat_sessions`, `chat_messages` và xóa (`DELETE`) cả phiên của mình; chỉ Edge Function (dùng `service_role` sau khi đã xác thực JWT) mới được ghi tin nhắn để bảo vệ dữ liệu `decision_probabilities` và `rejected_recipe_ids` dùng cho hiệu chỉnh mô hình.

**Số đo thời gian phản hồi trên production (23/11/2026, từ `docs/week13-14/README.md`)**:

| API | Số lần đo | Lần đầu (ms) | p50 (ms) | p95 (ms) | Max (ms) | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- |
| `search_recipes` (20 món/trang) | 20 | 1.216 | 396 | 716 | 757 | |
| `search_recipes` (từ khóa `"ga"`) | 20 | 415 | 397 | 726 | 739 | |
| `GET /meal-logs` (Dashboard) | 20 | 4.009 | 320 | 641 | 2.630 | |
| `POST /meal-logs` (ghi 1 món) | 10 | 322 | 319 | 339 | 339 | |
| `meal_calorie_budget` | 20 | 397 | 392 | 409 | 413 | |
| `recommend-ai` (gợi ý món, có AI) | 5 | 8.629 | 3.439 | 8.388 | 8.388 | fallback 0/6; `decision_mode = model` |
| `recommend-ai` (hỏi cách nấu) | 5 | 7.680 | 3.216 | 7.805 | 7.805 | fallback 3/6 |

Ghi chú: cột "Số lần đo" không tính lần đầu (khởi động); cột "Ghi chú" đếm cả lần đầu. Các API không dùng AI đạt p50 khoảng 0,3–0,4 giây; `recommend-ai` đạt p50 khoảng 3,2–3,4 giây và p95 khoảng 7,8–8,4 giây do chờ gọi Gemini (lượt đo "hỏi cách nấu" ghi nhận 3/6 lần chuyển sang câu mẫu do Gemini chat lỗi hoặc quá giờ).

## 7. Cộng đồng đóng góp công thức và quản trị

Chức năng cộng đồng và quản trị được xây dựng tại `20261113090000_community_and_admin.sql`, `20261113100000_sprint7_security_fixes.sql` và Edge Function `recipe-review-assist`. Bảng `recipes` bổ sung các cột `created_by`, `status` (`pending` / `approved` / `rejected`, mặc định `pending`), `reject_reason`, `reviewed_by`, `reviewed_at`, `submitted_at`, `ai_review`, cùng trigger `trg_recipes_sync_verified` đồng bộ hai chiều với `is_verified`.

**Luồng đóng góp, chỉnh sửa và khóa món đã duyệt**

- **Gửi hoặc sửa công thức (`submit_recipe`)**: người dùng chọn 2–40 nguyên liệu đang hoạt động (`amount` trong `(0 ; 5000]`, đơn vị `g` hoặc `ml` quy đổi theo `density_g_per_ml`, khối lượng tính theo phần ăn được `consumed_pct = 100`), 1–30 bước nấu, 1–20 khẩu phần, tiêu đề 3–120 ký tự, mô tả tối đa 2000 ký tự, thời gian chuẩn bị/nấu 0–600 phút.
- **Tự tính dinh dưỡng và dị ứng**: hệ thống tự tính toàn bộ dinh dưỡng từ nguyên liệu, không cho người dùng tự nhập số liệu; dị ứng kế thừa sang `recipe_allergens` (đánh dấu `via_condiment = true` nếu chỉ đến từ gia vị nhóm FCT `13%`).
- **Giới hạn 5 món mới/ngày**: đếm theo giờ Việt Nam trên bảng nhật ký `recipe_submissions`, kết hợp khóa `pg_advisory_xact_lock` chống gửi song song; xóa món không hoàn lượt, sửa món cũ không tính thêm lượt.
- **Ảnh minh họa (`user-recipe-images`)**: chỉ nhận JPG/PNG/WebP tối đa 5 MB trong thư mục `<user_id>/` (tên file chỉ gồm chữ không dấu, số, `_`, `-`, dài 1–100 ký tự). `submit_recipe` kiểm tra URL phải khớp gốc `storage_public_base` trong `app_config`, đúng thư mục người gửi và tệp phải tồn tại trong `storage.objects`.
- **Trạng thái và khóa món**: món mới ở `pending` (chỉ tác giả và admin xem được qua RLS). Nếu bị từ chối (`rejected` kèm `reject_reason` 5–500 ký tự), người dùng có thể sửa rồi gửi lại về `pending` (giữ `reject_reason` cũ tới khi được duyệt) hoặc xóa qua `delete_my_recipe`. Khi đã `approved`, món bị khóa vĩnh viễn (`RECIPE_LOCKED`) để không làm thay đổi nhật ký bữa ăn và danh sách yêu thích của người dùng khác; món được hiển thị qua `search_recipes`, `recommend_dishes_for_user` và `list_community_recipes` (hiện `profiles.full_name` hoặc `"Người dùng Elytra"`, không bao giờ lộ email).
- **Kết quả trả về ngay khi gửi**: `submit_recipe` trả về `id`, `status: "pending"`, `slug`, `servings`, dinh dưỡng mỗi khẩu phần (`calories/protein_g/fat_g/carbs_g_per_serving`) và mảng `allergens` để ứng dụng hiển thị ngay số liệu do hệ thống tính.
- **Tích hợp từ chối ở app cũ**: ngoài `submit_recipe` và `delete_my_recipe`, các hàm cũ `create_recipe_with_nutrition` và `create_custom_ingredient` đã được xóa bỏ hoàn toàn ở Sprint 8 (`20261123093000_drop_legacy_rpcs.sql`).

**Quản trị và kiểm quyền trong DB**

Danh sách quản trị viên lưu ở bảng `admins` (bật RLS, thu hồi mọi quyền từ `anon` và `authenticated`, chỉ thêm qua Supabase Dashboard hoặc migration). Ứng dụng gọi `is_admin()` để ẩn/hiện tab Admin, nhưng toàn bộ quyền thực thi được kiểm tra trực tiếp trong DB tại mọi RPC `SECURITY DEFINER` (trả `FORBIDDEN` với user thường, HTTP 401 với `anon`) và trong `recipe-review-assist`. Mọi thao tác quản trị đều ghi vào `admin_audit_log` qua `log_admin_action`.

| RPC quản trị | Chức năng và ràng buộc chính |
| --- | --- |
| `admin_list_pending_recipes` | Liệt kê hàng chờ `pending` (gửi trước hiện trước) kèm tên tác giả, `reject_reason` cũ và `ai_review` |
| `admin_review_recipe` | Duyệt hoặc từ chối (từ chối bắt buộc `p_reason` 5–500 ký tự); admin không sửa nội dung món; bắt buộc truyền `p_submitted_at` của bản đang xem để chống race condition (`RECIPE_CHANGED`) |
| `admin_save_ingredient` | Thêm mới (tự cấp mã `A00001`…) hoặc sửa; kiểm tra calo 0–900, tổng macro + xơ <= 100 g, natri 0–40000 mg, `edible_portion_pct` 1–100%, tỷ trọng 0,1–3 g/ml, cấm `category_id = 15`; sửa không làm đổi số liệu công thức cũ |
| `admin_set_ingredient_active` | Bật hoặc tắt nguyên liệu; nguyên liệu tắt không chọn được khi tạo công thức hoặc ghi bữa |
| `admin_delete_ingredient` | Xóa hẳn nếu chưa được tham chiếu (`deleted`), tự chuyển sang `is_active = false` (`deactivated`) nếu đã xuất hiện trong `recipe_ingredients` hoặc `meal_log_items` |

**AI chấm sẵn hỗ trợ kiểm duyệt (`POST /recipe-review-assist`)**

Chỉ admin được gọi trên món đang `pending`. Edge Function dùng Gemini Decision 1 đánh giá 4 nhóm câu hỏi (tiêu chí tiếng Anh) và lưu kết quả vào `recipes.ai_review` khi `status = 'pending'` và `submitted_at` không đổi; nếu AI lỗi hoặc thiếu key vẫn trả HTTP `200` với `ai_review: null` để admin duyệt tay:

| Khóa câu hỏi | Loại | Mục đích | Ngưỡng sinh cảnh báo (`warnings`) |
| --- | --- | --- | --- |
| `is_dish` | `noul` | Kiểm tra có phải công thức món ăn thật | `< 0,5`: cảnh báo có thể không phải món thật |
| `category` | `choice` | Gợi ý phân loại vào 8 danh mục | Khác danh mục gửi với xác suất `>= 0,6` |
| `kcal` | `score` | Chấm độ hợp lý calo/khẩu phần (5 mức 0–4) | Mức `0` (quá thấp) hoặc `4` (quá cao) với xác suất `>= 0,5` |
| `allergen_<code>` | `noul` | Kiểm tra 8 chất gây dị ứng | Xác suất `>= 0,7` nhưng nguyên liệu chưa gắn dị ứng |

AI chấm sẵn hiện **chỉ dùng để tham khảo** (không tự duyệt, không gỡ tag dị ứng của hệ thống), quản trị viên duyệt tay 100%. Ngưỡng tự duyệt đề xuất (0,9) chưa kích hoạt vì chưa hoàn tất đo kiểm trên bộ 100 món gán nhãn tay:

*(Chờ kết quả: chạy eval_moderation.mjs với bộ 100 món)*

## 8. Bảo mật

Hệ thống áp dụng nguyên tắc phòng vệ theo chiều sâu tại tầng cơ sở dữ liệu: bật Row Level Security (RLS) trên toàn bộ bảng, thu hồi quyền ghi trực tiếp vào các bảng nghiệp vụ nhạy cảm, buộc luồng ghi đi qua RPC hoặc Edge Function để kiểm tra biên tin cậy, và cố định `search_path` cho mọi hàm `SECURITY DEFINER`. Bảng dưới đây tổng hợp các lỗ hổng đã phát hiện và vá qua các vòng rà soát từ Sprint 5 đến Sprint 8:

| Lỗ hổng | Hậu quả | Cách vá | File liên quan |
| --- | --- | --- | --- |
| Tồn tại hàm `exec_seed_sql(query)` gọi được bằng anon key | Anon key lấy từ APK có thể thực thi SQL tùy ý, đọc hoặc xóa toàn bộ dữ liệu kể cả sức khỏe người dùng | Xóa hoàn toàn hàm; chuyển quy trình áp migration sang `supabase db push` | `20261026085000_harden_rpc_permissions.sql` |
| 2 RPC cũ (`create_recipe_with_nutrition`, `create_custom_ingredient`) mở cho anon/authenticated | Người dùng đăng công thức với `is_verified = true` bỏ qua kiểm duyệt, hoặc tự thêm nguyên liệu vào bảng gốc FCT | Sprint 5 thu hồi quyền chỉ còn `service_role`; Sprint 8 xóa hẳn 2 hàm (thay bằng `submit_recipe` và `admin_save_ingredient`) | `20261026085000_harden_rpc_permissions.sql`, `20261123093000_drop_legacy_rpcs.sql` |
| Policy Storage `Allow anon upload/update` | Ai dùng anon key cũng tải lên hoặc ghi đè ảnh/video món ăn | Xóa policy cho anon; chỉ tải tài nguyên hệ thống qua Dashboard hoặc `supabase storage cp` | `20261026100000_recipe_media_and_storage.sql` |
| Lộ món chưa duyệt qua REST và `search_recipes` | Policy `USING (true)` và `search_recipes` không lọc `is_verified` làm lộ món chờ duyệt khi mở tính năng cộng đồng | Giới hạn policy SELECT và `search_recipes` chỉ trả món đã duyệt (`is_verified`), riêng tác giả và admin xem được món chờ duyệt | `20261026120000_fix_audit_findings.sql`, `20261113090000_community_and_admin.sql` |
| Thiếu ràng buộc trên `profiles`, lỗi cửa sổ 30 ngày và mã lỗi HTTP ở `meal-logs` | User tự ghi tuổi/calo âm vào hồ sơ; `PATCH`/`DELETE` sửa được món cũ hơn 30 ngày và để lại bữa rỗng; lỗi `42501`/body `null` trả HTTP 500 | Thêm CHECK cho `profiles`; chặn sửa/xóa quá 30 ngày và dọn bữa rỗng qua RPC `delete_meal_log_item`; bỏ policy DELETE trên `meal_log_items`; map đúng mã 401/400 | `20261026120000_fix_audit_findings.sql`, `20261028090000_fix_review_findings.sql`, `supabase/functions/meal-logs/index.ts` |
| `ILIKE` không escape ký tự đại diện `%`, `_` | Tìm kiếm ký tự `%` trả về toàn bộ 45 món | Bổ sung hàm `like_escape` (cố định `search_path`) và `vn_unaccent` cho tìm kiếm | `20261028090000_fix_review_findings.sql`, `20261028120000_pin_like_escape_search_path.sql` |
| Gọi RPC `recommend_dishes_for_user` bằng `p_uid` của người khác | Hàm `SECURITY DEFINER` bỏ qua RLS, truyền `uid` người khác làm lộ mục tiêu calo và suy ra dị ứng | Kiểm tra `p_uid IS NULL OR p_uid IS DISTINCT FROM auth.uid()`, vi phạm ném `UNAUTHORIZED` | `20261112120000_sprint6_review_fixes.sql` |
| `chat_messages` thiếu kiểm tra chủ sở hữu phiên | Policy chỉ kiểm `user_id`, cho phép chèn tin nhắn rác vào `session_id` của người khác | Thêm `WITH CHECK` đối chiếu `session_id` thuộc `auth.uid()` (sau đó Sprint 8 khóa hẳn quyền ghi từ app) | `20261112120000_sprint6_review_fixes.sql` |
| URL ảnh công thức lách kiểm tra bằng query string / host lạ / file chưa upload | Kiểm chuỗi con bị lách qua dạng `https://evil.com/x.jpg?/storage/...`, dùng ảnh thư mục người khác hoặc file ảo | Lưu gốc URL project trong `app_config` (chặn app đọc/ghi); neo đầu chuỗi URL, kiểm regex tên file và đối chiếu tồn tại trong `storage.objects` | `20261113100000_sprint7_security_fixes.sql` |
| Đổi nội dung công thức lúc admin đang duyệt | Tác giả sửa và gửi lại ngay lúc admin bấm duyệt khiến admin duyệt nhầm bản chưa xem | `admin_review_recipe` bắt buộc nhận `p_submitted_at` của bản đang xem; sai lệch trả `RECIPE_CHANGED`; AI chấm sẵn chỉ ghi khi `submitted_at` khớp | `20261113100000_sprint7_security_fixes.sql`, `supabase/functions/recipe-review-assist/index.ts` |
| Lách giới hạn 5 món cộng đồng mỗi ngày | Xóa món để tạo lại hoặc gửi nhiều request song song vượt quá giới hạn | Đếm lượt gửi trong `recipe_submissions` (xóa món không hoàn lượt) kết hợp khóa `pg_advisory_xact_lock` theo user | `20261113100000_sprint7_security_fixes.sql` |
| Liệt kê công khai bucket `user-recipe-images` | Bất kỳ ai cũng liệt kê được `user_id` và ảnh của các món đang `pending` / `rejected` | Xóa policy SELECT công khai trên `storage.objects`; chỉ chủ thư mục liệt kê/xóa được ảnh của mình (ảnh vẫn xem qua URL public) | `20261113100000_sprint7_security_fixes.sql` |
| App tự ghi, sửa, xóa lịch sử chat | Người dùng sửa hoặc giả dữ liệu nhận/từ chối món dùng để hiệu chỉnh mô hình | Thu hồi quyền INSERT/UPDATE/DELETE trên `chat_sessions` (chỉ giữ SELECT, DELETE cả phiên) và `chat_messages` (chỉ giữ SELECT); `/recommend-ai` ghi bằng `service_role` sau khi xác thực user | `20261123091000_chat_service_writes.sql`, `supabase/functions/recommend-ai/index.ts` |
| Gọi AI liên tục làm cạn hạn mức Gemini miễn phí | Một tài khoản spam `/recommend-ai` làm gián đoạn dịch vụ của toàn hệ thống | Bổ sung bảng `ai_usage` và hàm `consume_ai_quota()` khóa 30 lượt/giờ/user bằng `pg_advisory_xact_lock`, vượt trả `429 RATE_LIMITED` (trừ thao tác "Ăn món này") | `20261123090000_ai_rate_limit.sql`, `supabase/functions/recommend-ai/index.ts` |

Ngoài ra, quyền quản trị được kiểm tra trực tiếp trong cơ sở dữ liệu thông qua `is_admin()` (bảng `admins` không cấp quyền ghi cho app; Edge Function `recipe-review-assist` kiểm `is_admin()` theo token người gọi trước khi dùng `service_role`) và mọi thao tác quản trị đều được lưu vào `admin_audit_log`. Cấu hình Auth hiện còn một số điểm ghi nhận ở mức trung bình từ vòng rà soát Sprint 5: bật tự động xác nhận email khi đăng ký (`mailer_autoconfirm = true`) và chưa bật tính năng cảnh báo mật khẩu bị rò rỉ (Leaked password protection).

## 9. Kiểm thử

Hoạt động kiểm thử back-end gồm ba lớp: kiểm thử đơn vị (unit test dùng hàm giả `fetch`), kiểm thử dựng lại toàn bộ cơ sở dữ liệu từ đầu bằng PGlite (WASM PostgreSQL chạy không cần mạng) và kiểm thử tích hợp đầu cuối (E2E) trên Supabase production với dữ liệu tạm tự xóa sau khi chạy. Bảng dưới đây liệt kê các bộ kiểm thử hiện có:

| Tên file | Loại | Kiểm gì | Kết quả |
| --- | --- | --- | --- |
| `supabase/scripts/test_recommend_ai_unit.mjs` | Unit (mock `fetch`) | Chọn món (`decideDish`, `rankByDecision`), phân loại câu (`classifyIntent`), lọc timeout 6,5 s / HTTP 429 / câu trả lời rỗng sang mẫu | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_recipe_review_unit.mjs` | Unit (mock `fetch`) | Tạo payload kiểm duyệt gửi AI (3 tiêu chí + 8 dị ứng), sinh 4 loại cảnh báo tiếng Việt, AI lỗi trả `null` | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_recommendation_flow.js` | Unit | Công thức chấm điểm nội dung (calo, đạm, chất béo, thời gian), câu trả lời dự phòng và cấu trúc migration | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_ingredient_parser.js` | Unit | Từ điển ánh xạ FCT, từ khóa dị ứng (tránh khớp chuỗi con), dị ứng qua gia vị, `consumed_pct`, tách định lượng và đơn vị | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_dish_name.js` | Unit | `normalizeDishName` tách tên món (đúng 42/45 tên hiện có, 3 ngoại lệ duyệt tay) và đọc `sourceNutrition` từ JSON-LD | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_migrations_replay.mjs` | Dựng lại DB (PGlite) | Chạy lại tuần tự toàn bộ 35 migration; kiểm tra vá lỗi `AUDIT_REPORT`, `consumed_pct`, tách `prepared_dishes`, `meal_calorie_budget` 4 trạng thái, `recommend_dishes_for_user` (chay, điểm béo, chặn `uid` khác), cộng đồng/admin và giới hạn 30 lượt AI | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_meal_logs_sql.mjs` | Dựng lại DB (PGlite) | Vá quyền RPC (`exec_seed_sql`, `search_path`), `log_meal`, chống ghi trùng `client_request_id`, snapshot khi sửa khẩu phần và lịch sử 31 ngày | Đạt (CI `backend-tests.yml`) |
| `supabase/scripts/test_nutrition_targets.mjs` | Dựng lại DB (PGlite) | `calculate_nutrition_targets` qua ma trận 90 ca (3 giới tính × 5 mức vận động × 3 mục tiêu × 2 thể trạng), sàn 1200/1500 kcal, 5 ranh giới BMI, tổng tỉ lệ macro | Đạt (CI `backend-tests.yml`; đối chiếu SQL ≡ Dart trước đó qua 810 và 1.920 ca) |
| `supabase/scripts/run_security_audit.js` | Kiểm tra tĩnh (CI) | Xác nhận mọi bảng đều bật RLS, không có policy ghi công khai tùy tiện, không lộ `service_role` hoặc credential | Đạt (CI `security-audit.yml`, `api-release.yml`) |
| `supabase/scripts/test_meal_logs_e2e.mjs` | E2E production | Toàn bộ endpoint `/meal-logs` (`POST`, `GET`, `/history`, `PATCH`, `DELETE`), idempotency 200/422, mã lỗi hợp đồng, RLS giữa 2 user | Đạt (chạy tay trên production) |
| `supabase/scripts/test_recommend_ai_e2e.mjs` | E2E production | `/recommend-ai` gợi ý, đổi món, ăn món, hỏi cách nấu/dinh dưỡng, câu tự do, yêu thích + RLS, `goal_reached`, chặn 429 (30 lượt/giờ), khóa ghi bảng chat | Đạt (chạy tay trên production) |
| `supabase/scripts/test_community_admin_e2e.mjs` | E2E production | Cô lập bảng `admins`/`app_config`, `FORBIDDEN` ở RPC admin, RLS món `pending`, Storage `user-recipe-images`, `recipe-review-assist`, `RECIPE_CHANGED`, không lộ email tác giả | Đạt (chạy tay trên production) |
| `supabase/scripts/test_rls_matrix_e2e.mjs` | E2E production | Ma trận 72 kiểm tra cô lập giữa người dùng B, `anon` và dữ liệu của người dùng A trên toàn bộ bảng, RPC, Edge Function và Storage | Đạt 72/72 (chạy tay 23/11/2026) |
| `supabase/scripts/measure_latency.mjs` | Đo hiệu năng (production) | Đo thời gian phản hồi p50, p95, max cho tìm kiếm, `meal-logs`, `meal_calorie_budget` và `recommend-ai` | Đã đo 23/11/2026 (API không AI p50 0,32–0,40 s; `recommend-ai` p50 3,2–3,4 s) |
| `supabase/scripts/eval_moderation.mjs` | Đánh giá AI | Đo độ chính xác `recipe-review-assist` trên bộ 100 món Việt gắn nhãn tay (`moderation_eval_set.json`) | *(Chờ kết quả: chạy eval_moderation.mjs với bộ 100 món)* |

Ngoài các kịch bản back-end trên, bộ kiểm thử phía ứng dụng (`flutter test`, 24/24 ca đạt ở Sprint 5) cũng đối chiếu khớp công thức `NutritionCalculator` trên Dart với SQL; toàn bộ các bài kiểm thử E2E trên Supabase production đều dùng tài khoản tạm và tự động thu hồi dữ liệu sau khi hoàn tất.

## 10. Triển khai và CI/CD

Quy trình triển khai back-end lên Supabase production (chi tiết tại `docs/DEPLOYMENT.md`) gồm các bước tuần tự:

1. **Chuẩn bị và thiết lập biến bí mật**: Cài đặt Supabase CLI (`npx supabase`), đăng nhập bằng tài khoản có quyền Owner hoặc Admin đối với `project-ref` mục tiêu. Đặt secret `GEMINI_API_KEY` (khóa Google AI Studio) cho Edge Functions; nếu chưa có khóa, các hàm AI vẫn hoạt động bằng tầng dự phòng SQL và câu mẫu. Các biến `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` do Supabase tự cấp.
2. **Áp dụng migration cơ sở dữ liệu**: Liên kết project bằng `supabase link --project-ref <ref>`, đối chiếu danh sách qua `supabase migration list --linked`, kiểm tra thử với `supabase db push --linked --dry-run` rồi chạy `supabase db push --linked` để đẩy toàn bộ migration mới.
3. **Triển khai Edge Functions**: Deploy đầy đủ 4 hàm `calculate-bmr-tdee`, `meal-logs`, `recommend-ai` và `recipe-review-assist`. Khi chỉnh sửa mã dùng chung trong `supabase/functions/_shared/`, phải deploy lại cả `recommend-ai` và `recipe-review-assist`.
4. **Cấu hình và kiểm tra sau triển khai**: Thêm tài khoản quản trị vào bảng `admins` qua SQL Editor; kiểm tra giá trị `storage_public_base` trong `app_config` khớp URL project; xác nhận đủ 3 bucket (`recipe-images`, `recipe-videos`, `user-recipe-images`); chạy lại 3 bộ E2E (`test_rls_matrix_e2e.mjs`, `test_recommend_ai_e2e.mjs`, `test_community_admin_e2e.mjs`) và kiểm tra không còn dữ liệu thử nghiệm tồn đọng.

**Sao lưu cơ sở dữ liệu**: Do Supabase gói miễn phí không hỗ trợ sao lưu tự động hằng ngày, đội ngũ thực hiện sao lưu thủ công qua `supabase db dump` trước khi kết thúc dự án: *(Chờ kết quả: Sprint 9 sao lưu DB)*.

**Hệ thống CI/CD (GitHub Actions)**: Mã nguồn được tự động kiểm tra qua 4 workflow trong `.github/workflows/`:

| Workflow | Thời điểm chạy | Nhiệm vụ chính |
| --- | --- | --- |
| `backend-tests.yml` | PR vào `main` hoặc push lên `main`, `feat/*`, `fix/*` có sửa `supabase/**` | Chạy ngoại tuyến 8 bộ unit test và PGlite replay toàn bộ migration trên Node 24 (không cần secret hay mạng ngoài) |
| `api-release.yml` | Push lên `main`, tạo tag `v*` hoặc chạy tay | Chỉ chạy khi `backend-tests.yml` đạt; chạy `run_security_audit.js`, sinh `openapi.json`, `openapi.yaml` qua `generate_api_spec.js`, nén kèm `docs/api-contract.md` thành `elytra-api-bundle.zip` lên GitHub Releases |
| `security-audit.yml` | Push (`main`, `feat/*`, `fix/*`, `sprint-*`) và PR vào `main` | Quét bí mật bằng Gitleaks và chặn track file `.env*`/`app/env.json`/`service_role`; chạy `run_security_audit.js`; chạy `flutter analyze` |
| `keep-supabase-alive.yml` | Định kỳ lúc 01:17 UTC mỗi 2 ngày (`*/2`) hoặc chạy tay | Ping `/auth/v1/settings` và `/rest/v1/recipes?select=id&limit=1` (có DNS dự phòng `1.1.1.1`/`8.8.8.8`) dùng secret `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` để tránh Supabase free tier tự tạm dừng sau 7 ngày |

## 11. Hạn chế và hướng phát triển

**Hạn chế hiện tại:**

- **Giới hạn của hạ tầng miễn phí:** Supabase gói miễn phí không có sao lưu tự động và sẽ tự tạm dừng sau 7 ngày không có truy vấn (phải duy trì bằng cron ping). Ở phía AI, mô hình xếp hạng/phân loại `gemini-decision-1` (ra mắt ngày 11/11/2026) và Gemini chat chạy qua gói miễn phí Google AI Studio với hạn mức chưa được công bố rõ và API `v1beta` có thể thay đổi; phép đo thực tế ngày 23/11/2026 ghi nhận nhánh `how_to_cook` có 3/6 lần rơi về fallback do Gemini phản hồi lỗi hoặc quá thời gian 6,5 giây. Vì gói miễn phí có thể sử dụng dữ liệu gửi lên để cải thiện sản phẩm, hệ thống phải lọc bỏ các trường nhạy cảm như cân nặng và tuổi khỏi payload gửi Gemini.
- **Chưa đo định lượng AI kiểm duyệt:** Bộ kiểm thử 100 món Việt gắn nhãn tay (`moderation_eval_set.json`) và script `eval_moderation.mjs` đã sẵn sàng, nhưng chưa chạy đánh giá thực tế với khóa API để làm căn cứ bật tự duyệt ở ngưỡng 0,9; hiện tại quản trị viên vẫn duyệt thủ công 100% món cộng đồng: *(Chờ kết quả: chạy eval_moderation.mjs với bộ 100 món)*.
- **Dữ liệu calo bất thường của một số món chưa xử lý xong:** Kết quả kiểm tra tự động ngày 23/11/2026 (`docs/report/calorie_audit_2026-11-23.md`) trên 45 công thức đã duyệt cho thấy mới có 15/45 món không dính cờ cảnh báo nào; 30 món còn lại chưa được chỉnh sửa dữ liệu trong DB với phân bố cờ như sau: `NO_INGREDIENT_ID` (nguyên liệu ngoài gia vị chưa ánh xạ, tính 0 kcal): 18 món; `ZERO_ROW` (nguyên liệu ngoài gia vị tính 0 g hoặc 0 kcal): 18 món; `SODIUM_HIGH` (natri > 2.300 mg/khẩu phần): 16 món; `ONE_INGREDIENT` (một nguyên liệu chiếm > 70% tổng calo): 9 món; `KCAL_LOW` (< 150 kcal/khẩu phần): 3 món; `FAT_HEAVY` (năng lượng từ chất béo > 60%): 3 món; `BIG_AMOUNT` (có nguyên liệu > 600 g/khẩu phần): 3 món; `KCAL_HIGH`, `MACRO_MISMATCH` và `TOTAL_MISMATCH`: đều 0 món.
- **Quy mô tập món ăn còn nhỏ và phạm vi chế độ ăn hẹp:** Dữ liệu mẫu hiện có 45 công thức (bên cạnh 620 nguyên liệu FCT 2017 và 73 món ăn sẵn `prepared_dishes`), độ phủ món Việt phổ biến còn hạn chế và bộ lọc chế độ ăn mới hỗ trợ `none` (bình thường) và `vegetarian` (ăn chay). Ngoài ra, cấu hình Auth vẫn bật `mailer_autoconfirm = true` và chưa bật Leaked password protection.

**Hướng phát triển (theo đề cương mục 8 và định hướng AI):**

- Tích hợp nhận diện món ăn qua hình ảnh và quét mã vạch thực phẩm đóng gói (Open Food Facts) để rút ngắn thao tác ghi nhận bữa ăn.
- Xây dựng tính năng lập kế hoạch bữa ăn theo tuần kèm danh sách mua sắm tự động, đồng bộ dữ liệu vận động từ thiết bị đeo thông minh (smartwatch, fitness tracker) và theo dõi lịch sử cân nặng, BMI, tỉ lệ mỡ cơ thể theo thời gian.
- Mở rộng cơ sở dữ liệu món ăn và nguyên liệu từ nguồn quốc tế (USDA FoodData Central), hỗ trợ thêm các chế độ ăn đặc biệt (keto, low-carb, thuần chay).
- Bổ sung yếu tố gamification (huy hiệu, chuỗi ngày, bảng xếp hạng), mở rộng lên iOS và Web App, đồng thời nghiên cứu áp dụng collaborative filtering khi đủ dữ liệu tương tác người dùng và chuẩn bị phương án tự host mô hình quyết định (`Quyet-1.0-Small` 328M) được hiệu chỉnh từ dữ liệu chấp nhận/từ chối món đã thu thập trong `chat_messages`.

## Phụ lục A. Danh sách API

Bảng tổng hợp các điểm cuối và tài nguyên mà ứng dụng Flutter được phép truy cập trực tiếp (theo mục "Đọc nhanh" trong `docs/api-contract.md`):

| Tên | Loại | Cần đăng nhập | Dùng để làm gì |
| --- | --- | --- | --- |
| `POST /calculate-bmr-tdee` | Edge Function | Không bắt buộc | Tính BMR, TDEE, BMI và macro theo chỉ số cơ thể, mục tiêu |
| `POST /recommend-ai` | Edge Function | Có | Gợi ý món, chọn/đổi món, hỏi cách nấu hoặc dinh dưỡng, ghi bữa khi chấp nhận |
| `/meal-logs` (`POST`, `GET`, `PATCH`, `DELETE`) | Edge Function | Có | Ghi bữa ăn, xem nhật ký hôm nay/31 ngày, sửa khẩu phần, xóa món |
| `POST /recipe-review-assist` | Edge Function | Có (admin) | Chấm sẵn gợi ý kiểm duyệt món cộng đồng bằng AI (lưu vào bảng `recipes`) |
| `search_recipes` | RPC | Có hoặc không | Tìm món, lọc theo chế độ ăn, dị ứng, calo tối đa và phân trang |
| `search_dishes` | RPC | Có hoặc không | Tìm 73 món ăn sẵn (`prepared_dishes`) để ghi nhanh bữa ăn |
| `search_ingredients` | RPC | Có hoặc không | Tìm nguyên liệu trong 620 thực phẩm (Viện Dinh dưỡng 2017) |
| `get_ingredient_details` | RPC | Có hoặc không | Chi tiết dinh dưỡng và chất gây dị ứng của 1 nguyên liệu |
| `meal_calorie_budget` | RPC | Có | Tính ngân sách calo còn lại cho 1 bữa trong ngày (theo giờ VN) |
| `submit_recipe` | RPC | Có | Gửi món mới hoặc sửa món `pending`/`rejected` (tối đa 5 món/ngày) |
| `delete_my_recipe` | RPC | Có | Tác giả xóa món của mình khi chưa được duyệt (`pending`/`rejected`) |
| `list_community_recipes` | RPC | Có (admin) | Xem danh sách món cộng đồng đóng góp (có lọc theo trạng thái) |
| `is_admin` | RPC | Có | Kiểm tra tài khoản hiện tại có phải quản trị viên hay không |
| `admin_list_pending_recipes`, `admin_review_recipe`, `admin_save_ingredient`, `admin_set_ingredient_active`, `admin_delete_ingredient` | RPC | Có (admin) | Quản lý hàng đợi chờ duyệt, duyệt/từ chối công thức và quản lý nguyên liệu gốc |
| `profiles`, `user_allergens`, `user_favorite_recipes` | Bảng (đọc/ghi thẳng) | Có | Đọc và cập nhật hồ sơ, dị ứng và món yêu thích của chính người dùng |
| `recipes`, `recipe_ingredients`, `recipe_allergens`, `allergens`, `ingredients`, `prepared_dishes` | Bảng (chỉ đọc) | Có hoặc không | Dữ liệu món ăn, nguyên liệu và món ăn sẵn |
| `meal_logs`, `meal_log_items`, `chat_sessions`, `chat_messages` | Bảng (chỉ đọc; `chat_sessions` được `DELETE`) | Có | Đọc nhật ký bữa ăn và lịch sử chat của chính người dùng (hoặc xóa phiên chat) |
| `recipe-images`, `recipe-videos`, `user-recipe-images` | Storage | Công khai / Có | Ảnh, video món ăn và ảnh món cộng đồng (`user-recipe-images` ghi theo thư mục user) |

Các RPC nội bộ (`calculate_nutrition_targets`, `log_meal`, `update_meal_log_item`, `delete_meal_log_item`, `recommend_dishes_for_user`, `consume_ai_quota`...) được gọi gián tiếp qua Edge Function hoặc hàm khác, ứng dụng không gọi trực tiếp.

## Phụ lục B. Danh sách migration

Toàn bộ lược đồ, dữ liệu hạt giống, hàm RPC và các bản vá bảo mật của hệ thống được quản lý qua 35 tệp migration trong `supabase/migrations/` (từ ngày 05/10/2026 đến ngày 23/11/2026) theo đúng thứ tự áp dụng:

| STT | Tên tệp migration | Mô tả ngắn |
| --- | --- | --- |
| 1 | `20261005061323_create_ingredients_schema.sql` | Tạo lược đồ bảng `ingredient_categories`, `allergens`, `ingredients`, `ingredient_allergens` và RLS |
| 2 | `20261005062000_seed_categories_and_allergens.sql` | Nạp danh mục nhóm thực phẩm và 8 nhóm chất gây dị ứng |
| 3 | `20261005062100_seed_ingredients.sql` | Nạp 620 thực phẩm chuẩn hóa từ Bảng thành phần thực phẩm Việt Nam 2017 |
| 4 | `20261005062200_seed_ingredient_allergens.sql` | Nạp ánh xạ chất gây dị ứng cho các nguyên liệu |
| 5 | `20261005063616_create_profiles_and_user_allergens.sql` | Tạo bảng `profiles`, `user_allergens`, RLS và trigger tạo hồ sơ khi đăng ký |
| 6 | `20261005063644_create_nutrition_calculation_functions.sql` | Tạo hàm `calculate_nutrition_targets` tính BMI, BMR, TDEE, calo mục tiêu và macro |
| 7 | `20261005073403_create_recipes_schema.sql` | Tạo bảng `recipes`, `recipe_ingredients`, `recipe_allergens` và RLS |
| 8 | `20261005073500_seed_recipes.sql` | Nạp 45 công thức món ăn Việt Nam mẫu, nguyên liệu và dị ứng kế thừa |
| 9 | `20261005073600_create_recipe_search_function.sql` | Tạo RPC `search_recipes` tìm kiếm, lọc dị ứng, giới hạn calo và phân trang |
| 10 | `20261005073700_create_recipe_creation_engine.sql` | Tạo hàm `create_recipe_with_nutrition` tự tính dinh dưỡng và kế thừa dị ứng (đã xóa ở Sprint 8) |
| 11 | `20261005073800_create_ingredient_management_functions.sql` | Tạo các RPC tìm kiếm, chi tiết nguyên liệu và `create_custom_ingredient` |
| 12 | `20261026085000_harden_rpc_permissions.sql` | Xóa `exec_seed_sql`, thu hồi quyền anon/authenticated trên 2 RPC cũ và cố định `search_path` |
| 13 | `20261026090000_create_meal_logs.sql` | Tạo bảng `meal_logs`, `meal_log_items` và các RPC ghi nhận, sửa khẩu phần, thống kê ngày và lịch sử |
| 14 | `20261026093000_fix_security_advisor_warnings.sql` | Cố định `search_path` cho các hàm phụ trợ và thu hồi quyền thực thi `handle_new_user` |
| 15 | `20261026100000_recipe_media_and_storage.sql` | Thêm cột `video_url`, tạo bucket `recipe-images`, `recipe-videos` và bỏ quyền anon upload |
| 16 | `20261026110000_remap_recipe_ingredients.sql` | Ánh xạ lại nguyên liệu của 45 món vào FCT, thêm "Cơm tẻ" (`X01004`), tính lại dinh dưỡng và dị ứng |
| 17 | `20261026120000_fix_audit_findings.sql` | Vá các lỗi `AUDIT_REPORT`: ẩn món chưa duyệt, lọc `is_active`, snapshot macro, chặn sửa > 30 ngày, CHECK `profiles` |
| 18 | `20261026125000_recipe_allergens_via_condiment.sql` | Thêm cột `via_condiment` phân biệt dị ứng qua gia vị và trả `condiment_allergens` trong `search_recipes` |
| 19 | `20261026130000_remap_recipe_allergens_via_condiment.sql` | Tính lại `recipe_allergens` kèm cờ `via_condiment` |
| 20 | `20261026140000_fix_soy_keyword_and_sesame_tag.sql` | Sửa từ khóa soy khớp nhầm và bổ sung tag `sesame` cho nguyên liệu Vừng (`03020`) |
| 21 | `20261026150000_recipe_ingredients_consumed_pct.sql` | Thêm cột `consumed_pct` để tính dinh dưỡng theo phần thực sự ăn được (trừ xương, vỏ) |
| 22 | `20261028090000_fix_review_findings.sql` | Áp sàn calo 1200/1500, thêm `delete_meal_log_item`, `like_escape`, `vn_unaccent` và `request_hash` |
| 23 | `20261028100000_normalize_recipe_titles.sql` | Chuẩn hóa 45 tên món vào `recipes.title`, lưu tiêu đề bài viết gốc vào `source_title` |
| 24 | `20261028110000_split_prepared_dishes.sql` | Tách 73 món ăn sẵn (FCT chương XV) sang `prepared_dishes` và thêm RPC `search_dishes` |
| 25 | `20261028120000_pin_like_escape_search_path.sql` | Cố định `search_path = public` cho hàm `like_escape` |
| 26 | `20261028130000_reparse_ingredient_amounts.sql` | Đọc lại khối lượng nguyên liệu từ câu gốc, thêm "Nước cốt dừa" (`X03001`, nguồn USDA SR Legacy 12117) và ghi đè có lý do |
| 27 | `20261028140000_staple_standard_portion.sql` | Áp khẩu phần chuẩn 200 g/khẩu phần cho bún/hủ tiếu không ghi lượng ở 5 món |
| 28 | `20261106090000_recommendation_and_chat_schema.sql` | Chuẩn hóa dữ liệu Sprint 6, nâng cấp `search_recipes`, tạo bảng chat, yêu thích, `meal_calorie_budget` và `recommend_dishes_for_user` |
| 29 | `20261112120000_sprint6_review_fixes.sql` | Ràng buộc `chat_messages` theo phiên, chặn `p_uid` giả mạo trong `recommend_dishes_for_user`, sửa `meal_calorie_budget(NULL)` |
| 30 | `20261113090000_community_and_admin.sql` | Tạo bảng `admins`, `admin_audit_log`, bucket `user-recipe-images`, luồng đóng góp/duyệt món và RPC quản lý nguyên liệu |
| 31 | `20261113100000_sprint7_security_fixes.sql` | Tạo `app_config`, `recipe_submissions`; kiểm tra chặt URL ảnh, chống TOCTOU khi duyệt, khóa 5 món/ngày và bỏ liệt kê bucket công khai |
| 32 | `20261123090000_ai_rate_limit.sql` | Tạo bảng `ai_usage` và hàm `consume_ai_quota()` giới hạn 30 lượt gọi AI/giờ/user |
| 33 | `20261123091000_chat_service_writes.sql` | Thu hồi quyền ghi bảng `chat_sessions` và `chat_messages` từ app (chỉ giữ SELECT và DELETE phiên) |
| 34 | `20261123092000_diet_and_fat_score.sql` | Ràng buộc `dietary_preference` (`none`/`vegetarian`) và thêm điểm chất béo (trọng số 0,15) vào `recommend_dishes_for_user` |
| 35 | `20261123093000_drop_legacy_rpcs.sql` | Xóa 2 hàm cũ `create_recipe_with_nutrition` và `create_custom_ingredient` |
