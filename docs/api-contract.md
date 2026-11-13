# API Contract – Elytra

Đặc tả mọi thứ app gọi được ở back-end (Supabase production). **Chỉ ghi những gì đã chạy**; tính năng chưa làm không có ở đây.
Nguồn sự thật: `supabase/migrations/` (DB, RPC, RLS) và `supabase/functions/` (Edge Functions). Test chứng minh hành vi: `supabase/scripts/test_*`.

## Đọc nhanh: app gọi được gì

| Loại | Tên | Cần đăng nhập | Dùng để | Mục |
| --- | --- | --- | --- | --- |
| Edge Function | `POST /calculate-bmr-tdee` | Không (trừ khi lưu hồ sơ) | Tính BMI/BMR/TDEE/calo mục tiêu | 1 |
| Edge Function | `POST /recommend-ai` | Có | Chat AI: gợi ý món, đổi món, ăn món, hỏi cách nấu, hỏi dinh dưỡng | 2 |
| Edge Function | `/meal-logs` (POST, GET, PATCH, DELETE) | Có | Nhật ký bữa ăn, Dashboard, lịch sử | 3 |
| RPC | `search_recipes` | Không | Tìm/lọc/sắp xếp/phân trang món | 4.1 |
| RPC | `search_dishes` | Không | Tìm món ăn sẵn (phở, xôi...) để ghi bữa | 4.2 |
| RPC | `search_ingredients`, `get_ingredient_details` | Không | Tìm nguyên liệu, xem chi tiết dinh dưỡng | 4.3 |
| RPC | `meal_calorie_budget` | Có | Calo cho bữa sắp ăn (theo phần còn lại hôm nay) | 4.4 |
| RPC | `submit_recipe`, `delete_my_recipe` | Có | Đóng góp / sửa / xóa công thức của mình | 6 |
| RPC | `list_community_recipes` | Không | Công thức cộng đồng đã duyệt + tên người đóng góp | 6.3 |
| RPC | `is_admin` | Không | App biết có hiện tab Admin không | 7 |
| RPC (chỉ admin) | `admin_list_pending_recipes`, `admin_review_recipe`, `admin_save_ingredient`, `admin_set_ingredient_active`, `admin_delete_ingredient` | Có + admin | Duyệt công thức, quản lý nguyên liệu | 7 |
| Edge Function (chỉ admin) | `POST /recipe-review-assist` | Có + admin | AI chấm sẵn món chờ duyệt | 7.2 |
| Bảng (đọc/ghi thẳng) | `profiles`, `user_allergens`, `user_favorite_recipes` | Có | Hồ sơ, dị ứng, món yêu thích | 5 |
| Bảng (chỉ đọc) | `recipes`, `recipe_ingredients`, `recipe_allergens`, `allergens`, `ingredients`, `prepared_dishes`… | Không | Dữ liệu món / nguyên liệu | 5 |
| Bảng (chỉ đọc) | `meal_logs`, `meal_log_items`, `chat_sessions`, `chat_messages` | Có | Lịch sử bữa ăn, lịch sử chat | 5 |
| Storage | bucket `recipe-images`, `recipe-videos` (public) | Không | Ảnh / video món | 5 |
| Storage | bucket `user-recipe-images` (public) | Có (để upload) | Ảnh món user đóng góp, mỗi user một thư mục | 6.2 |

Không còn: `/recommend` và `/chat` của bản nháp cũ (đã gộp vào `/recommend-ai`); chế độ "nguyên liệu trong tủ lạnh" (ngoài phạm vi đề cương).

---

## 0. Quy ước chung

### Địa chỉ gọi

```
Edge Function: https://<project-ref>.supabase.co/functions/v1/<tên-function>
RPC / bảng:    qua supabase-flutter: supabase.rpc(...), supabase.from(...)
```

### Header bắt buộc (Edge Function)

| Header | Giá trị |
| --- | --- |
| `Authorization` | `Bearer <access_token>` lấy từ Supabase Auth sau khi đăng nhập (`supabase.functions.invoke` tự gắn) |
| `Content-Type` | `application/json` |

### Đơn vị và kiểu dữ liệu

- Năng lượng: `kcal`. Khối lượng chất dinh dưỡng: gam, làm tròn 1 chữ số thập phân. Natri: mg.
- ID: `uuid` dạng chuỗi (riêng `allergens.id` là số nguyên). Tên trường: `snake_case`.
- "Hôm nay" tính theo giờ Việt Nam (UTC+7). Ngày dạng `YYYY-MM-DD`.

### Quy ước kết quả

- **Lỗi kỹ thuật hoặc dữ liệu sai** (thiếu token, nhập sai) → mã HTTP 4xx/5xx kèm khối `error`.
- **Kết quả nghiệp vụ bình thường** (đã đủ calo, không có món phù hợp, AI lỗi phải dùng câu mẫu) → vẫn trả `200`, phân biệt bằng `status` / `fallback` / `decision_mode`. App không coi đây là lỗi.

### Định dạng lỗi chung

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Tuổi phải nằm trong khoảng cho phép", "field": "age" } }
```

| HTTP | `code` | Khi nào | App xử lý |
| --- | --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Thiếu trường hoặc giá trị ngoài khoảng | Hiện lỗi dưới ô tương ứng với `field` |
| 401 | `UNAUTHORIZED` | Token thiếu hoặc hết hạn | Chuyển về màn Đăng nhập |
| 404 | `PROFILE_NOT_FOUND` | Người dùng chưa hoàn tất onboarding | Chuyển sang Onboarding |
| 500 | `INTERNAL_ERROR` | Lỗi không lường trước | Hiện thông báo chung, cho thử lại |

### Kiểu dữ liệu dùng chung

**`Goal`**: `"lose_weight"` | `"maintain"` | `"gain_weight"` (khớp CHECK của `profiles.goal`)

**`ActivityLevel`**

| Giá trị | Ý nghĩa | Hệ số |
| --- | --- | --- |
| `sedentary` | Ít vận động | 1.2 |
| `light` | 1–3 buổi/tuần | 1.375 |
| `moderate` | 3–5 buổi/tuần | 1.55 |
| `active` | 6–7 buổi/tuần | 1.725 |
| `very_active` | Lao động nặng, tập 2 lần/ngày | 1.9 |

**`MealType`**: `"breakfast"` | `"lunch"` | `"dinner"` | `"snack"`

**Danh mục món (`recipes.category`)**: `mon_an_sang`, `mon_canh`, `mon_chay`, `mon_kho`, `mon_man`, `mon_nuong`, `mon_xao`, `gia_vi_an_kem` (đồ chấm/gia vị: bị ẩn khỏi danh sách và gợi ý). **Độ khó**: `easy`, `medium`.

**Chất gây dị ứng (`allergens`)**: `1 seafood`, `2 egg`, `3 dairy`, `4 peanut`, `5 tree_nut`, `6 soy`, `7 gluten`, `8 sesame` (`id code`; tên tiếng Việt ở cột `name_vi`).

---

## 1. `POST /calculate-bmr-tdee` – Ước tính dinh dưỡng

**Dùng ở:** Onboarding (màn kết quả), Hồ sơ cá nhân (khi sửa thể trạng).
**Luồng:** Activity diagram Luồng 1.

Số liệu lấy từ RPC `calculate_nutrition_targets` (nguồn công thức duy nhất; `NutritionCalculator` trong app cho kết quả giống hệt). Hiện app tự tính và ghi thẳng vào `profiles`, chưa gọi endpoint này.

- Không cần đăng nhập nếu chỉ tính.
- `save_to_profile: true`: tính và lưu vào `profiles` của người đang đăng nhập (bắt buộc có `Authorization`).

### Request

| Trường | Kiểu | Bắt buộc | Ràng buộc |
| --- | --- | --- | --- |
| `gender` | `"male"` \| `"female"` \| `"other"` | Có | `other` dùng công thức nam |
| `age` | số nguyên | Có | 18–80 (khớp app) |
| `height_cm` | số | Có | 120–220 (khớp app) |
| `weight_kg` | số | Có | 30–200 (khớp app) |
| `activity_level` | `ActivityLevel` | Có | |
| `goal` | `Goal` | Có | |
| `save_to_profile` | boolean | Không | Mặc định `false` |

> Chưa làm: nhánh "Tùy chỉnh" (macro %, chia bữa %, dị ứng, chế độ ăn).

### Ví dụ request

```json
{
  "gender": "male",
  "age": 22,
  "height_cm": 170,
  "weight_kg": 65,
  "activity_level": "moderate",
  "goal": "lose_weight"
}
```

### Response `200`

```json
{
  "success": true,
  "saved": false,
  "data": {
    "bmi": 22.5,
    "bmi_classification": "Bình thường",
    "bmr": 1607.5,
    "tdee": 2491.6,
    "target_calories": 1991.6,
    "calorie_difference": -500.0,
    "macros": { "protein_g": 130.0, "fat_g": 55.3, "carbs_g": 243.4, "fiber_g": 27.9, "water_ml": 2275 },
    "macro_percentages": { "protein_pct": 26.1, "fat_pct": 25.0, "carbs_pct": 48.9 },
    "advice": "Mục tiêu giảm cân khoa học với mức thâm hụt 500 kcal/ngày. …"
  }
}
```

- Calo mục tiêu (mọi mục tiêu, kể cả duy trì/tăng cân) không thấp hơn mức sàn 1200 kcal (nữ) / 1500 kcal (nam). Khi bị nâng lên sàn, `calorie_difference` khác −500 / 0 / +400.

### Lỗi riêng

| HTTP | `code` | Khi nào |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Body không phải JSON object; trường thiếu, sai kiểu, sai giá trị hoặc ngoài khoảng (`field` cho biết trường nào) |
| 401 | `UNAUTHORIZED` | `save_to_profile: true` mà chưa đăng nhập |
| 500 | `INTERNAL_ERROR` | Lỗi tính hoặc không lưu được hồ sơ |

---

## 2. `POST /recommend-ai` – Trợ lý dinh dưỡng AI (màn Chat)

**Nguyên tắc:** mọi món và mọi số liệu đều từ DB. AI không bịa món, không tự tính số.

- **An toàn:** SQL lọc cứng món chứa chất dị ứng của người dùng, món đã từ chối, đồ chấm/gia vị.
- **Chọn món:** mô hình quyết định Gemini Decision 1 (kiểu Jev: trả xác suất, không viết chữ) xếp lại 10 ứng viên của SQL.
- **Lời nói:** Gemini chat chỉ diễn đạt lại dữ liệu đã có.
- AI lỗi / quá giờ / hết hạn mức → vẫn `200`: thứ tự điểm SQL (`decision_mode: "sql"`) và/hoặc câu mẫu (`fallback: true`).

Thiết kế chi tiết: `docs/week9-10/01_DECISION_MODEL_RECOMMEND_AND_MODERATION.md`.

### 2.1 Request

| Trường | Kiểu | Bắt buộc | Ràng buộc / ý nghĩa |
| --- | --- | --- | --- |
| `session_id` | `uuid` | Không | Phiên chat. Bỏ trống (hoặc gửi phiên không phải của mình) → server tạo phiên mới và trả `session_id`. App giữ lại và gửi ở các lượt sau |
| `intent` | `"recommend"` \| `"how_to_cook"` \| `"nutrition"` | Không | Gửi khi người dùng **bấm chip**. Bỏ trống mà có `message` → server tự phân loại câu (2.3) |
| `recipe_id` | `uuid` | Nên gửi khi `intent` là `how_to_cook`/`nutrition` | Món người dùng hỏi. Không gửi → server lấy món đứng đầu lượt gợi ý gần nhất trong phiên; phiên chưa có gợi ý → 400 |
| `message` | chuỗi | Không | Câu người dùng gõ, tối đa 500 ký tự |
| `meal_type` | `MealType` | Không | Mặc định `"lunch"` |
| `target_calories` | số | Không | 100–2000. Bỏ trống → server tính theo phần calo còn lại hôm nay (2.4) |
| `rejected_recipe_ids` | `uuid[]` | Không | Tối đa 50. Món đã từ chối **trong phiên này**; app tự giữ danh sách và gửi lại mỗi lượt |
| `accepted_recipe_id` | `uuid` | Không | Chip "Ăn món này": ghi món vào nhật ký (cùng logic `POST /meal-logs`). Có trường này thì bỏ qua `intent` |
| `servings` | số | Không | Đi với `accepted_recipe_id`. 0.25–10, mặc định 1 |
| `client_request_id` | `uuid` | Không (nên gửi) | Đi với `accepted_recipe_id`. Chống ghi trùng khi retry, quy tắc như 3.1 |

Server xử lý theo thứ tự: `accepted_recipe_id` → `intent` → phân loại `message` → mặc định `recommend`.

Trường có giá trị `null` được coi như không gửi (vd `'session_id': null` ở lượt đầu). `session_id` trong response có thể vắng nếu server không tạo được phiên (hiếm); khi đó lượt sau cứ gửi không có `session_id`.

### 2.2 Chip và request tương ứng

| Chip / hành động | Request |
| --- | --- |
| Mở màn Chat / "Gợi ý món" | `{ "meal_type": "lunch" }` |
| Gõ tự do | `{ "session_id": "…", "meal_type": "lunch", "message": "Muốn ăn món nước, ít dầu mỡ", "rejected_recipe_ids": [...] }` |
| "Đổi món khác" | Thêm id món đó vào `rejected_recipe_ids` rồi gửi lại: `{ "session_id": "…", "meal_type": "lunch", "rejected_recipe_ids": ["…"] }` |
| "Ăn món này" | `{ "session_id": "…", "meal_type": "lunch", "accepted_recipe_id": "…", "client_request_id": "<uuid sinh 1 lần>" }` |
| "Nấu thế nào?" | `{ "session_id": "…", "intent": "how_to_cook", "recipe_id": "…" }` |
| "Dinh dưỡng" | `{ "session_id": "…", "intent": "nutrition", "recipe_id": "…" }` |

`message` trả về là **Markdown** (in đậm, gạch đầu dòng): app cần hiển thị dạng Markdown.

### 2.3 Phân loại câu gõ tự do

Khi không có `intent` mà có `message`, Gemini Decision 1 phân loại câu thành `recommend` / `how_to_cook` / `nutrition` / `out_of_scope`.

- Hỏi cách nấu / dinh dưỡng mà không gửi `recipe_id` → server lấy **món đứng đầu lượt gợi ý gần nhất** trong phiên. Phiên chưa có gợi ý nào → coi như `recommend`.
- `out_of_scope` (câu không liên quan ăn uống, mô hình chắc ≥ 0,7) → từ chối lịch sự, không có món.
- Mô hình lỗi → coi như `recommend`.

### 2.4 Calo cho bữa (`status` khi gợi ý)

Bỏ trống `target_calories` thì server gọi `meal_calorie_budget` (4.4):

- **Chuẩn bữa** = mục tiêu ngày × tỉ lệ bữa (sáng 25%, trưa 35%, tối 30%, phụ 10%).
- **Calo bữa** = calo còn lại hôm nay × tỉ lệ bữa / tổng tỉ lệ các bữa **chưa ghi** hôm nay. Sau đó kẹp lại theo bảng:

| `status` | Khi nào | Calo bữa | App hiển thị |
| --- | --- | --- | --- |
| `ok` | Bình thường | Như công thức | Thẻ món |
| `low` | Còn ít: < 0,5 × chuẩn | max(công thức, 150) | Thẻ món (đã có câu nhắc "món nhẹ" trong `message`) |
| `capped` | Các bữa trước ghi nhưng ăn ít: > 1,5 × chuẩn | 1,5 × chuẩn | Thẻ món (đã có câu nhắc trong `message`) |
| `goal_reached` | Còn < 150 kcal | Không gợi ý | `suggested_recipes` rỗng, lời nhắc đã đạt mục tiêu |

Bữa chưa ghi được coi là còn sẽ ăn, nên quên ghi bữa sáng không làm bữa trưa bị dồn calo.

### 2.5 Response `200`

Mọi response đều có `session_id`, `intent`, `status`, `message`. Phần còn lại tùy `intent`:

**Gợi ý món** (`intent: "recommend"`):

```json
{
  "session_id": "a1b2…",
  "intent": "recommend",
  "status": "ok",
  "budget": { "meal_type": "lunch", "status": "ok", "target_kcal": 700, "base_kcal": 700, "remaining_kcal": 2000, "daily_kcal": 2000 },
  "message": "Elytra đã chọn cho bữa trưa món **Bún riêu cua đồng hải sản**…",
  "suggested_recipes": [
    {
      "id": "8f1c…", "title": "Bún riêu cua đồng hải sản", "slug": "…", "category": "mon_an_sang",
      "image_url": "https://…", "servings": 4, "prep_time_minutes": 20, "cook_time_minutes": 25,
      "calories_per_serving": 510.6, "protein_g_per_serving": 51.2, "fat_g_per_serving": 5.7, "carbs_g_per_serving": 63.3,
      "score": 0.83, "match_reason": "Giàu protein (51.2g), phù hợp phục hồi cơ bắp",
      "is_favorite": false, "decision_probability": 0.47
    }
  ],
  "rejected_recipe_ids": [],
  "fallback": false,
  "decision_mode": "model"
}
```

| Trường | Ý nghĩa |
| --- | --- |
| `suggested_recipes` | Tối đa 10 món, **món đầu là món được chọn**. Rỗng khi `goal_reached` hoặc không còn món hợp lệ |
| `match_reason` | Lý do do engine SQL viết (không phải AI), dùng làm dòng phụ trên thẻ món |
| `is_favorite` | Món nằm trong yêu thích của người dùng (được cộng 0,1 điểm) |
| `decision_probability` | Xác suất mô hình chọn món này; `null` khi `decision_mode = "sql"` |
| `decision_mode` | `"model"` = Gemini Decision 1 xếp hạng; `"sql"` = giữ thứ tự điểm SQL (mô hình lỗi, không có key, hoặc chỉ có 0–1 ứng viên nên không cần chọn); `null` khi `goal_reached` |
| `fallback` | `true` = Gemini chat lỗi, `message` là câu mẫu. App có thể hiện ghi chú nhỏ "AI đang gián đoạn" |
| `budget` | Kết quả `meal_calorie_budget`; `null` khi app tự gửi `target_calories` |

**Hỏi cách nấu / dinh dưỡng** (`intent: "how_to_cook"` / `"nutrition"`): `status: "answered"`, số liệu để hiển thị nằm ở `recipe` (lấy từ DB).

```json
{
  "session_id": "a1b2…", "intent": "how_to_cook", "status": "answered", "fallback": false,
  "message": "Hướng dẫn nấu **Bún riêu cua đồng hải sản** (4 khẩu phần, ~45 phút)…",
  "recipe": {
    "id": "8f1c…", "title": "Bún riêu cua đồng hải sản", "servings": 4, "prep_time_minutes": 20, "cook_time_minutes": 25,
    "video_url": null,
    "instructions": [{ "step_number": 1, "title": "Sơ chế", "description": "…" }],
    "ingredients": ["Cua đồng: 500 g", "…"],
    "calories_per_serving": 510.6, "protein_g_per_serving": 51.2, "fat_g_per_serving": 5.7, "carbs_g_per_serving": 63.3,
    "fiber_g_per_serving": 3.1, "sodium_mg_per_serving": 1020.0,
    "allergens": ["Hải sản (Tôm, Cua, Mực, Cá)"]
  }
}
```

`fallback: true` ở đây nghĩa là `message` là dữ liệu nguyên văn từ DB (nguyên liệu + các bước / bảng số liệu), chưa được AI diễn đạt lại.

**Ngoài phạm vi**: `{ "session_id": "…", "intent": "out_of_scope", "status": "out_of_scope", "message": "Mình là trợ lý dinh dưỡng…", "suggested_recipes": [], "fallback": false }`

**Ăn món này** (`accepted_recipe_id`):

```json
{ "session_id": "…", "intent": "accept", "status": "logged", "message": "Đã ghi **Bún riêu cua đồng** (442 kcal) vào bữa trưa.",
  "logged": { /* MealLogItem, mục 3 */ }, "budget": { /* Budget, mục 3 */ } }
```

App dùng `budget` để cập nhật Dashboard, không cần gọi lại `GET /meal-logs`.

### 2.6 Lỗi riêng

| HTTP | `code` | `field` | Khi nào |
| --- | --- | --- | --- |
| 400 | `VALIDATION_ERROR` | trường sai | Sai `meal_type` / `intent`; uuid sai; `rejected_recipe_ids` không phải mảng uuid hoặc > 50; `message` > 500 ký tự; `target_calories` ngoài 100–2000; chip `how_to_cook`/`nutrition` thiếu `recipe_id` mà phiên chưa có gợi ý; `servings` ngoài khoảng (lỗi này không có `field`) |
| 401 | `UNAUTHORIZED` | | Thiếu/hết hạn token, hoặc gửi anon key |
| 404 | `PROFILE_NOT_FOUND` | | Chưa có mục tiêu calo (khi server phải tự tính calo bữa) |
| 404 | `RECIPE_NOT_FOUND` | `recipe_id` | Món không tồn tại hoặc chưa duyệt |
| 422 | `IDEMPOTENCY_CONFLICT` | `client_request_id` | Như 3.1 |

AI (Gemini) lỗi **không** phải lỗi API: luôn xử lý bằng `fallback` / `decision_mode`.

### 2.7 Gọi từ Flutter

```dart
final res = await supabase.functions.invoke('recommend-ai', body: {
  'session_id': sessionId,            // null ở lượt đầu (null = không gửi)
  'meal_type': 'lunch',
  'message': text,
  'rejected_recipe_ids': rejectedIds, // app tự giữ trong phiên
});
final data = res.data as Map<String, dynamic>;
sessionId = data['session_id'];
```

---

## 3. `/meal-logs` – Nhật ký bữa ăn

**Dùng ở:** Dashboard (đã nạp / còn lại), màn Ghi bữa ăn, Chi tiết món (nút "Ăn món này"); màn Chat dùng `/recommend-ai` (cùng logic ghi), màn Lịch sử + biểu đồ.

- Mọi nơi ghi bữa ăn đều đi qua endpoint này (hoặc RPC `log_meal` mà nó gọi). App **không** ghi/sửa/xóa thẳng vào bảng: RLS chỉ cho đọc.
- Dinh dưỡng được **chụp lại lúc ghi** (snapshot). Sau này sửa món/nguyên liệu thì lịch sử cũ không đổi.
- "Hôm nay" tính theo giờ Việt Nam (UTC+7). `date` có dạng `YYYY-MM-DD`.

**`Budget`** – cũng là `budget` trả về khi "Ăn món này" ở `/recommend-ai`. `remaining` có thể **âm** khi đã ăn vượt mục tiêu.

```json
{
  "target":    { "kcal": 2092, "protein_g": 156.9, "carbs_g": 209.2, "fat_g": 69.7 },
  "consumed":  { "kcal": 874,  "protein_g": 55.3,  "carbs_g": 90.6,  "fat_g": 28.9 },
  "remaining": { "kcal": 1218, "protein_g": 101.6, "carbs_g": 118.6, "fat_g": 40.8 }
}
```

**`MealLogItem`**

```json
{
  "id": "c2b4…",
  "source": "recipe",
  "recipe_id": "8f1c…",
  "ingredient_id": null,
  "dish_id": null,
  "name": "Phở bò",
  "image_url": "https://…/pho-bo.jpg",
  "servings": 1.5,
  "amount_g": null,
  "kcal": 675,
  "protein_g": 37.5,
  "carbs_g": 90.0,
  "fat_g": 15.0,
  "created_at": "2026-10-26T05:12:00Z"
}
```

- `source = "recipe"` → có `servings`, `amount_g = null`. `source = "ingredient"` hoặc `"dish"` (món ăn sẵn) → có `amount_g`, `servings = null`.
- `recipe_id` / `ingredient_id` / `dish_id` có thể thành `null` nếu món gốc bị xóa; `name` và số liệu vẫn giữ.

### 3.1 `POST /meal-logs` – Ghi 1 món

| Trường | Kiểu | Bắt buộc | Ràng buộc |
| --- | --- | --- | --- |
| `meal_type` | `MealType` | Có | |
| `recipe_id` | `uuid` | Một trong ba | Món đã duyệt |
| `servings` | số | Không | Chỉ đi với `recipe_id`. 0.25–10, mặc định 1 |
| `ingredient_id` | `uuid` | Một trong ba | Nguyên liệu đang hoạt động |
| `dish_id` | `uuid` | Một trong ba | Món ăn sẵn (phở, bún chả, xôi... từ Bảng TPTP 2017), tìm bằng RPC `search_dishes` |
| `amount_g` | số | Khi có `ingredient_id` hoặc `dish_id` | 1–2000 (gam phần ăn được) |
| `date` | `YYYY-MM-DD` | Không | Mặc định hôm nay. Không ở tương lai, lùi tối đa 30 ngày |
| `client_request_id` | `uuid` | Không (nên gửi) | Chống ghi trùng khi mạng chập chờn, xem dưới |

```json
{ "meal_type": "lunch", "recipe_id": "8f1c…", "servings": 1.5, "client_request_id": "5e0a…" }
```

**Response `201`** (ghi mới) hoặc **`200`** (retry trùng, không ghi thêm):

```json
{ "item": { /* MealLogItem */ "meal_type": "lunch", "date": "2026-10-26" }, "replayed": false, "budget": { /* Budget */ } }
```

App dùng luôn `budget` để cập nhật Dashboard, không cần gọi lại `GET`.

**`client_request_id`:** app sinh UUID **một lần** khi người dùng bấm "Thêm", lưu lại và gửi **y nguyên** khi retry. Không sinh lại mỗi lần gửi.

- Cùng key + cùng nội dung **request gốc** → trả món đã ghi ở **trạng thái hiện tại** (kể cả đã bị PATCH, hoặc gửi lại sau 0h khi không gửi `date`), `replayed: true`, `budget` là của ngày món được ghi.
- Cùng key + khác nội dung (so với request gốc, không phải trạng thái hiện tại) → `422 IDEMPOTENCY_CONFLICT` (lỗi lập trình phía app).
- Không gửi key → mỗi request là một lần ghi mới (retry có thể ghi trùng).

### 3.2 `GET /meal-logs?date=YYYY-MM-DD` – Tổng hợp 1 ngày

Bỏ `date` = hôm nay.

```json
{
  "date": "2026-10-26",
  "budget": { /* Budget */ },
  "meals": {
    "breakfast": { "kcal": 199, "items": [ /* MealLogItem[] */ ] },
    "lunch":     { "kcal": 675, "items": [ … ] },
    "dinner":    { "kcal": 0,   "items": [] },
    "snack":     { "kcal": 0,   "items": [] }
  }
}
```

Luôn có đủ 4 bữa; bữa chưa ăn có `items` rỗng.

### 3.3 `GET /meal-logs/history?from=YYYY-MM-DD&to=YYYY-MM-DD` – Lịch sử theo ngày

Cho biểu đồ. Tối đa 31 ngày mỗi lần. Trả **đủ mọi ngày** trong khoảng, ngày không ghi có giá trị 0. Xem chi tiết từng ngày bằng `GET /meal-logs?date=`.

```json
{
  "from": "2026-10-20",
  "to": "2026-10-26",
  "target_kcal": 2092,
  "days": [
    { "date": "2026-10-20", "kcal": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0, "item_count": 0, "target_kcal": 2092 },
    { "date": "2026-10-26", "kcal": 874, "protein_g": 55.3, "carbs_g": 90.6, "fat_g": 28.9, "item_count": 2, "target_kcal": 2200 }
  ]
}
```

- `days[].target_kcal`: mục tiêu của ngày đó (lưu lúc ghi). Đổi hồ sơ không làm đổi các ngày đã qua.
- `target_kcal` ở ngoài: mục tiêu hiện tại.
- Quy tắc chung cho `budget.target` của `GET /meal-logs?date=` và `days[].target_kcal`: **ngày đã qua** dùng mục tiêu lúc ghi bữa đầu tiên trong ngày (cả kcal và macro), **hôm nay** dùng hồ sơ hiện tại.

### 3.4 `PATCH /meal-logs/items/:id` – Sửa khẩu phần / khối lượng

Gửi `servings` nếu món là `recipe`, `amount_g` nếu là `ingredient` (cùng khoảng như 3.1), chỉ với món trong 30 ngày gần nhất. Dinh dưỡng được nhân theo tỉ lệ trên **snapshot cũ**, không đọc lại món gốc.

```json
{ "servings": 2 }
```

Response `200`: `{ "item": { /* MealLogItem */ "meal_type": "lunch", "date": "2026-10-26" }, "budget": { /* Budget */ } }`.

Đặt giá trị tuyệt đối nên retry an toàn. Không đổi được bữa/ngày: muốn chuyển bữa thì xóa rồi ghi lại.

### 3.5 `DELETE /meal-logs/items/:id` – Xóa 1 món

Response `204`, không có body. Chỉ xóa được món trong 30 ngày gần nhất. Idempotent: món không tồn tại hoặc đã xóa vẫn trả `204`. Xóa món cuối cùng của một bữa thì bữa đó cũng được dọn. Gọi lại `GET /meal-logs?date=` để cập nhật Dashboard.

### Lỗi riêng

| HTTP | `code` | `field` | Khi nào |
| --- | --- | --- | --- |
| 400 | `VALIDATION_ERROR` | trường sai | Body không phải JSON object; sai `meal_type`; không gửi đúng 1 trong `recipe_id`/`ingredient_id`/`dish_id` (`field = recipe_id`); `servings`/`amount_g`/`date` ngoài khoảng; `from`/`to` sai hoặc quá 31 ngày (`field = from`) |
| 404 | `RECIPE_NOT_FOUND` | `recipe_id` | Không tồn tại hoặc chưa duyệt |
| 404 | `INGREDIENT_NOT_FOUND` | `ingredient_id` | Không tồn tại hoặc đã vô hiệu hóa |
| 404 | `DISH_NOT_FOUND` | `dish_id` | Món ăn sẵn không tồn tại hoặc đã vô hiệu hóa |
| 404 | `PROFILE_NOT_FOUND` | | Chưa có mục tiêu calo |
| 400 | `VALIDATION_ERROR` | `date` | PATCH hoặc DELETE món cũ hơn 30 ngày |
| 401 | `UNAUTHORIZED` | | Token không phải của user đã đăng nhập (vd gửi anon key) |
| 404 | `ITEM_NOT_FOUND` | `id` | PATCH món không tồn tại hoặc của người khác |
| 422 | `IDEMPOTENCY_CONFLICT` | `client_request_id` | Xem 3.1 |

### Gọi từ Flutter

```dart
await supabase.functions.invoke('meal-logs', body: {...});                       // POST
await supabase.rpc('search_dishes', params: {'p_query': 'pho'});              // tìm món ăn sẵn để ghi bữa
await supabase.functions.invoke('meal-logs', method: HttpMethod.get, queryParameters: {'date': '2026-10-26'});
await supabase.functions.invoke('meal-logs/history', method: HttpMethod.get, queryParameters: {'from': '…', 'to': '…'});
await supabase.functions.invoke('meal-logs/items/$id', method: HttpMethod.patch, body: {'servings': 2});
await supabase.functions.invoke('meal-logs/items/$id', method: HttpMethod.delete);
```


---

## 4. RPC (gọi bằng `supabase.rpc`)

### 4.1 `search_recipes` – Tìm, lọc, sắp xếp, phân trang món

Chỉ trả món đã duyệt. Mặc định ẩn đồ chấm/gia vị (`gia_vi_an_kem`), trừ khi có từ khóa hoặc `p_include_condiments = true`.

| Tham số | Kiểu | Mặc định | Ý nghĩa |
| --- | --- | --- | --- |
| `p_query` | `text` | `null` | Từ khóa theo tên món hoặc tên nguyên liệu, không phân biệt dấu |
| `p_category` | `text` | `null` | Danh mục món (mục 0) |
| `p_is_vegetarian` | `boolean` | `null` | `true` = chỉ `mon_chay`, `false` = bỏ `mon_chay` |
| `p_min_calories` / `p_max_calories` | `numeric` | `null` | Dải kcal mỗi khẩu phần |
| `p_max_total_time` | `integer` | `null` | Chuẩn bị + nấu tối đa (phút) |
| `p_difficulty` | `text` | `null` | `easy` / `medium` |
| `p_exclude_allergen_ids` | `int[]` | `null` | Loại món chứa các chất dị ứng này (kể cả dị ứng đến từ gia vị) |
| `p_include_condiments` | `boolean` | `false` | Hiện cả đồ chấm/gia vị |
| `p_sort` | `text` | `'title_asc'` | `title_asc`, `calories_asc`, `calories_desc`, `time_asc` |
| `p_page` / `p_page_size` | `integer` | `1` / `20` | Phân trang, trang bắt đầu từ 1, tối đa 100 dòng/trang |
| `p_limit` / `p_offset` | `integer` | `null` | Kiểu cũ (app hiện dùng `p_limit: 100`). Có giá trị thì thay cho `p_page_size` / `p_page` |

Mỗi dòng: `id, title, slug, description, image_url, video_url, category, cuisine, servings, prep_time_minutes, cook_time_minutes, difficulty, calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving, is_vegetarian, allergens, condiment_allergens, total_count`.

- `allergens`: mọi id chất dị ứng của món, vd `[1, 6, 8]`. `condiment_allergens`: phần **chỉ** đến từ gia vị (nước mắm, xì dầu…), vd `[1]` → món vẫn bị lọc khi người dùng dị ứng, nhưng không gọi là "món hải sản".
- `total_count`: tổng số món khớp bộ lọc (giống nhau ở mọi dòng) → `totalPages = (total_count / p_page_size).ceil()`.

```dart
await supabase.rpc('search_recipes', params: {'p_query': 'bun', 'p_max_calories': 600, 'p_page': 1, 'p_page_size': 20});
```

### 4.2 `search_dishes` – Món ăn sẵn để ghi bữa

`p_query`, `p_limit` (20), `p_offset` (0). Món ăn sẵn từ Bảng thành phần thực phẩm VN 2017 (phở, xôi, bún chả…), số liệu **trên 100 g**: `id, code, name_vi, name_en, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg, allergens` (`allergens` = `[{id, code, name_vi}]`). Ghi bữa bằng `POST /meal-logs` với `dish_id` + `amount_g`.

### 4.3 `search_ingredients`, `get_ingredient_details` – Nguyên liệu

- `search_ingredients(p_query, p_category_id, p_is_featured, p_limit = 20, p_offset = 0)` → `id, code, name_vi, name_en, category_id, category_name, calories/protein/fat/carbs/fiber_per_100g, sodium_mg, edible_portion_pct, density_g_per_ml, is_featured, allergens`.
- `get_ingredient_details(p_ingredient_id)` → JSON: `macros_per_100g`, `minerals_per_100g`, `vitamins_per_100g`, `allergens`, `category_name`, `edible_portion_pct`, `density_g_per_ml`…

### 4.4 `meal_calorie_budget(p_meal_type)` – Calo cho bữa sắp ăn

Cần đăng nhập. Trả `{ meal_type, status, target_kcal, base_kcal, remaining_kcal, daily_kcal }`, quy tắc như 2.4 (`target_kcal = null` khi `goal_reached`). Lỗi: `PROFILE_NOT_FOUND`, `VALIDATION_ERROR` (sai `meal_type`). `/recommend-ai` đã gọi sẵn; app chỉ cần nếu muốn hiện "bữa này nên ăn ~X kcal" mà không gọi AI.

RPC khác (`log_meal`, `get_daily_nutrition`, `get_nutrition_history`, `update_meal_log_item`, `delete_meal_log_item`, `recommend_dishes_for_user`) là phần bên trong của các Edge Function: app gọi qua Edge Function, không gọi thẳng.

---

## 5. Bảng và Storage (gọi bằng `supabase.from`)

Mọi bảng đều bật RLS. Bảng nào không ghi quyền ghi ở đây thì app **không** ghi được.

| Bảng | App được | Ghi chú |
| --- | --- | --- |
| `profiles` | Xem / tạo / sửa **dòng của mình** | Dòng được trigger tạo sẵn khi đăng ký. "Đã onboarding" = `target_calories != null` |
| `user_allergens` | Xem / thêm / xóa **của mình** | `{ user_id, allergen_id }`. Dùng cho bộ lọc gợi ý món |
| `user_favorite_recipes` | Xem / thêm / xóa **của mình** | Xem 5.1 |
| `recipes`, `recipe_ingredients`, `recipe_allergens` | Chỉ xem: món đã duyệt (ai cũng xem); món **của mình** ở mọi trạng thái; admin xem tất cả | `recipes.instructions` = `[{step_number, title, description}]`. Cột cộng đồng: `created_by`, `status`, `reject_reason`, `submitted_at`, `reviewed_at`, `ai_review`. Ghi qua RPC mục 6–7 |
| `allergens`, `ingredients`, `ingredient_categories`, `ingredient_allergens`, `prepared_dishes`, `prepared_dish_allergens` | Chỉ xem | `ingredients`: chỉ nguyên liệu đang hoạt động; admin xem cả nguyên liệu đã tắt |
| `admin_audit_log` | Admin xem | Nhật ký mọi thao tác admin (ai, làm gì, lúc nào). User thường đọc ra rỗng |
| `admins` | Không | Danh sách admin, chỉ thêm qua Supabase Dashboard. App hỏi quyền bằng RPC `is_admin` |
| `meal_logs`, `meal_log_items` | Chỉ xem **của mình** | Ghi/sửa/xóa qua `/meal-logs` |
| `chat_sessions`, `chat_messages` | Xem **của mình** | Ghi qua `/recommend-ai` (5.2) |
| Storage `recipe-images`, `recipe-videos` | Xem (public) | Không upload được từ app |
| Storage `user-recipe-images` | Xem (public); upload / sửa / xóa trong thư mục `<user_id>/` **của mình** | Xem 6.2 |

### 5.1 Món yêu thích (`user_favorite_recipes`)

- Chỉ xem/thêm/xóa của chính mình: `user_id` tự lấy từ token (không cần gửi), gửi `user_id` của người khác bị từ chối. Không có quyền sửa; anon key không làm gì được.
- Chỉ thêm được món đã duyệt. Thêm trùng → lỗi `409` (khóa chính `user_id, recipe_id`): app coi như đã thích.
- Món yêu thích được +0,1 điểm khi gợi ý và có `is_favorite: true` trong `suggested_recipes`.

```dart
await supabase.from('user_favorite_recipes').insert({'recipe_id': id});                       // thích
await supabase.from('user_favorite_recipes').delete().eq('recipe_id', id);                    // bỏ thích
final favs = await supabase.from('user_favorite_recipes').select('recipe_id, created_at, recipes(*)'); // danh sách
```

### 5.2 Lịch sử chat (`chat_sessions`, `chat_messages`)

- `chat_sessions`: `id, user_id, meal_type, target_kcal, target_protein_g, target_fat_g, target_carbs_g, created_at, updated_at` (3 cột `target_*_g` hiện luôn `null`).
- `chat_messages`: `id, session_id, user_id, role, content, suggested_recipe_ids, rejected_recipe_ids, metadata, created_at`. `role` là `'user'` hoặc `'assistant'` (schema cho phép `'system'` nhưng server không ghi). Sắp theo `created_at` để dựng lại hội thoại.
- `metadata` (lượt user luôn có `intent`):

| Lượt | `metadata` của lượt assistant |
| --- | --- |
| Gợi ý món | `{ intent, fallback, chat_error, meal_type, budget_status, decision_mode, decision_probabilities: { recipe_id: xác suất } }` |
| `goal_reached` | `{ intent, meal_type, budget_status }` |
| Cách nấu / dinh dưỡng | `{ intent, recipe_id, fallback, chat_error }` |
| Ngoài phạm vi | `{ intent }` |
| Ăn món này | `{ logged_item_id, replayed }` (lượt user: `{ intent: "accept", accepted_recipe_id, meal_type }`) |

`chat_error` (chỉ để theo dõi, app không cần đọc): lý do Gemini chat không trả lời khi `fallback = true`, vd `"timeout"`, `"HTTP 503: … high demand …"` (Google quá tải), `"HTTP 429: …"` (hết hạn mức), `"no key"`.
- RLS kỹ thuật cho phép app ghi thẳng 2 bảng này (Edge Function ghi bằng token của người dùng), nhưng **app không ghi**: dữ liệu nhận/từ chối món dùng để hiệu chỉnh mô hình về sau.

```dart
final history = await supabase.from('chat_messages').select().eq('session_id', sessionId).order('created_at');
```

---

## 6. Cộng đồng đóng góp công thức

Luồng: user chọn nguyên liệu + nhập khối lượng → hệ thống tự tính dinh dưỡng và dị ứng → món ở trạng thái `pending` (chưa ai thấy ngoài tác giả và admin) → admin duyệt (`approved`, hiện ra tìm kiếm, gợi ý, danh sách cộng đồng) hoặc từ chối kèm lý do (`rejected`) → user sửa và gửi lại (về `pending`).

**Lỗi của RPC** (gọi bằng `supabase.rpc`): `PostgrestException.message` là mã lỗi (vd `VALIDATION_ERROR`, `FORBIDDEN`), `hint` là trường sai (vd `title`, `ingredients`). Gọi khi chưa đăng nhập: HTTP 401, `message` = `permission denied…`.

| `message` | Khi nào |
| --- | --- |
| `UNAUTHORIZED` | Chưa đăng nhập |
| `PROFILE_NOT_FOUND` | Chưa có hồ sơ |
| `VALIDATION_ERROR` | Dữ liệu sai, `hint` cho biết trường |
| `INGREDIENT_NOT_FOUND` | Nguyên liệu không tồn tại hoặc đã bị tắt |
| `RECIPE_NOT_FOUND` | Món không tồn tại hoặc không phải của mình |
| `RECIPE_LOCKED` | Món đã duyệt: không sửa / xóa được (muốn đổi thì tạo món mới) |
| `RECIPE_CHANGED` | (admin) Món đã được user gửi lại sau khi admin mở xem |
| `RATE_LIMITED` | Quá 5 lượt gửi món mới trong ngày (giờ Việt Nam). Xóa món không trả lại lượt; sửa / gửi lại món cũ không tính lượt |

### 6.1 `submit_recipe` – Gửi / sửa công thức

| Tham số | Kiểu | Bắt buộc | Ràng buộc |
| --- | --- | --- | --- |
| `p_title` | text | Có | 3–120 ký tự |
| `p_category` | text | Có | Danh mục món (mục 0) |
| `p_servings` | int | Có | 1–20 |
| `p_ingredients` | JSON | Có | 2–40 dòng `{ "ingredient_id": uuid, "amount": số, "unit": "g" \| "ml" }` (`unit` mặc định `g`; 0 < `amount` ≤ 5000). **Khối lượng phần ăn được, đã sơ chế** (không tính xương, vỏ). `ml` đổi ra gam theo tỷ trọng của nguyên liệu. Nguyên liệu tìm bằng `search_ingredients` |
| `p_instructions` | JSON | Có | 1–30 bước `{ "title"?: chuỗi ≤ 120, "description": chuỗi 1–1000 }`; thứ tự trong mảng = thứ tự bước |
| `p_description` | text | Không | ≤ 2000 ký tự |
| `p_prep_time_minutes`, `p_cook_time_minutes` | int | Không | 0–600, mặc định 15 / 30 |
| `p_difficulty` | text | Không | `easy` (mặc định) / `medium` / `hard` |
| `p_image_url` | text | Không | URL lấy từ `getPublicUrl` của ảnh **đã upload** vào thư mục của mình ở bucket `user-recipe-images` (6.2). URL khác project, thư mục người khác, có `?`/`#`/`..`, hoặc file chưa upload → `VALIDATION_ERROR`, `hint = image_url` |
| `p_recipe_id` | uuid | Không | Bỏ trống = tạo mới. Có = sửa + gửi duyệt lại món **của mình** đang `pending`/`rejected` (thay toàn bộ nội dung, nguyên liệu) |

Trả về: `{ id, status: "pending", slug, servings, calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, allergens: [id…] }` để app hiện ngay số liệu hệ thống tính.

- Gửi lại sau khi bị từ chối: `reject_reason` cũ được **giữ** để user thấy lần trước sai ở đâu; bị xóa khi được duyệt.
- Dị ứng kế thừa từ nguyên liệu (giống món của hệ thống).

```dart
final r = await supabase.rpc('submit_recipe', params: {
  'p_title': 'Trứng chiên cà chua', 'p_category': 'mon_man', 'p_servings': 2,
  'p_ingredients': [{'ingredient_id': eggId, 'amount': 150}, {'ingredient_id': tomatoId, 'amount': 200}],
  'p_instructions': [{'title': 'Sơ chế', 'description': 'Đánh trứng, thái cà chua'}, {'description': 'Xào cà chua rồi đổ trứng'}],
  'p_image_url': imageUrl, // tùy chọn
});
```

**Món của tôi:** đọc thẳng bảng, RLS chỉ trả món của mình:

```dart
final mine = await supabase.from('recipes')
    .select('id, title, status, reject_reason, submitted_at, calories_per_serving')
    .eq('created_by', supabase.auth.currentUser!.id).order('submitted_at', ascending: false);
```

**`delete_my_recipe(p_recipe_id)`**: xóa món của mình đang `pending`/`rejected`. Món đã duyệt → `RECIPE_LOCKED`.

### 6.2 Ảnh món (Storage `user-recipe-images`)

- Đường dẫn: `<user_id>/<tên file>.<jpg|jpeg|png|webp>`, tên file chỉ gồm chữ không dấu, số, `_`, `-` (≤ 100 ký tự), vd `<user_id>/1731400000.jpg`. Thư mục người khác bị từ chối.
- Chỉ JPG / PNG / WebP, tối đa 5 MB. Ai cũng xem được qua URL công khai; chỉ chủ thư mục liệt kê / xóa được ảnh của mình.
- Upload trước, rồi gửi URL công khai vào `p_image_url`.

```dart
final path = '${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
await supabase.storage.from('user-recipe-images').uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
final imageUrl = supabase.storage.from('user-recipe-images').getPublicUrl(path);
```

### 6.3 `list_community_recipes(p_page = 1, p_page_size = 20)` – Công thức cộng đồng

Không cần đăng nhập. Chỉ món user đóng góp đã duyệt, mới duyệt trước. Mỗi dòng: `id, title, slug, image_url, category, servings, prep_time_minutes, cook_time_minutes, difficulty, calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, author_name, submitted_at, total_count`.

- `author_name` = `profiles.full_name`; chưa đặt tên → `"Người dùng Elytra"`. **Không bao giờ trả email.**
- Chi tiết món: đọc như món thường (bảng `recipes` / `search_recipes`); món cộng đồng đã duyệt cũng xuất hiện trong tìm kiếm và gợi ý.

---

## 7. Admin

Tài khoản admin dùng cùng app; app gọi `supabase.rpc('is_admin')` (trả `true`/`false`) để quyết định hiện tab Admin. **Quyền kiểm trong DB, không dựa vào việc app ẩn/hiện tab:**

- Mọi thao tác admin là RPC tự kiểm `is_admin()`; user thường gọi → `FORBIDDEN`, anon → HTTP 401.
- Không có cách nào từ app để tự thành admin (bảng `admins` không có quyền ghi; chỉ thêm qua Supabase Dashboard: `insert into admins (user_id, note) values ('<uuid>', '<ghi chú>')`).
- Mọi thao tác admin ghi vào `admin_audit_log`.
- Admin **không sửa nội dung món** của user: chỉ duyệt hoặc từ chối kèm lý do.

### 7.1 Duyệt công thức

- `admin_list_pending_recipes(p_page = 1, p_page_size = 20)` → hàng chờ, gửi trước hiện trước: `id, title, category, servings, image_url, calories/protein/fat/carbs_per_serving, author_id, author_name, submitted_at, reject_reason (lý do lần trước nếu là gửi lại), ai_review, total_count`. Xem chi tiết nguyên liệu/bước: đọc thẳng `recipes` / `recipe_ingredients` (admin đọc được mọi món).
- `admin_review_recipe(p_recipe_id, p_approve, p_submitted_at, p_reason)`: `p_approve = true` → duyệt; `false` → từ chối, **bắt buộc** `p_reason` 5–500 ký tự. `p_submitted_at` = giá trị `submitted_at` của bản admin **đang xem** (lấy từ hàng chờ): nếu user đã gửi lại bản khác trong lúc đó → `RECIPE_CHANGED`, app tải lại hàng chờ để admin xem bản mới. Món không còn `pending` → `RECIPE_NOT_PENDING`. Trả `{ id, status }`.

### 7.2 `POST /recipe-review-assist` – AI chấm sẵn (Edge Function, chỉ admin)

Body `{ "recipe_id": uuid }`, món phải đang `pending`. Gemini Decision 1 trả lời: có phải món ăn thật không, danh mục phù hợp, calo/khẩu phần có hợp lý không, có chứa từng chất dị ứng không. Kết quả lưu vào `recipes.ai_review` (hàng chờ trả kèm) và trả về:

```json
{ "recipe_id": "…", "ai_review": {
  "model": "models/gemini-decision-1", "reviewed_at": "…",
  "is_dish": 0.97,
  "category": { "suggested": "mon_xao", "probability": 0.82, "matches_submitted": false },
  "kcal_plausibility": { "level": 2, "probabilities": { "0": 0.01, "1": 0.1, "2": 0.8, "3": 0.08, "4": 0.01 } },
  "allergens": { "seafood": 0.91, "egg": 0.98, "…": 0.01 },
  "warnings": ["Danh mục có thể là \"mon_xao\" thay vì \"mon_man\"", "Có thể chứa Hải sản nhưng nguyên liệu chưa gắn dị ứng này"] } }
```

- `kcal_plausibility.level`: 0 quá thấp, 1 thấp, 2 bình thường, 3 cao, 4 quá cao (cho 1 khẩu phần).
- `warnings`: câu tiếng Việt để hiện cho admin. **Chỉ để tham khảo**: không tự duyệt, admin vẫn duyệt 100%. Tiêu đề và các bước do user viết nên có thể cố tình "lừa" AI (prompt injection): không tin tuyệt đối vào điểm AI.
- Điểm chỉ được lưu nếu món chưa bị gửi lại trong lúc AI đang chấm.
- AI lỗi / hết hạn mức → `200` với `ai_review: null` và `message`; admin duyệt tay như bình thường.
- Lỗi: `401` chưa đăng nhập, `403 FORBIDDEN` không phải admin, `400 VALIDATION_ERROR` sai `recipe_id`, `404 RECIPE_NOT_FOUND`, `409 RECIPE_NOT_PENDING`.

### 7.3 Quản lý nguyên liệu

| RPC | Làm gì |
| --- | --- |
| `admin_save_ingredient(p_name_vi, p_category_id, p_calories_per_100g, p_protein_per_100g, p_fat_per_100g, p_carbs_per_100g, p_fiber_per_100g = 0, p_sodium_mg, p_edible_portion_pct = 100, p_density_g_per_ml = 1, p_name_en, p_is_featured = false, p_allergen_ids = {}, p_id)` | `p_id` trống = thêm mới (mã tự cấp `A00001`…); có = sửa. Trả `{ id, code }` |
| `admin_set_ingredient_active(p_id, p_active)` | Bật / tắt. Nguyên liệu tắt không chọn được khi tạo công thức hay ghi bữa |
| `admin_delete_ingredient(p_id)` | Chưa ai dùng → xóa (`action: "deleted"`); đã có công thức hoặc nhật ký dùng → **chỉ tắt** (`action: "deactivated"`) |

Ràng buộc `admin_save_ingredient` (`VALIDATION_ERROR`, `hint` = trường): tên 2–150 ký tự; kcal 0–900; đạm/béo/bột/xơ 0–100 g và tổng ≤ 100 g; natri 0–40000 mg; phần ăn được 1–100 %; tỷ trọng 0,1–3 g/ml; `p_category_id` phải tồn tại và khác 15 (nhóm 15 là món ăn sẵn); `p_allergen_ids` phải là id có thật. Sửa nguyên liệu **không** làm đổi số liệu các công thức đã tạo (công thức lưu số liệu lúc tạo).

---

## 8. Quyết định đã chốt

1. **Khoảng hợp lệ của thể trạng:** tuổi 18–80; chiều cao 120–220 cm; cân nặng 30–200 kg.
2. **AI không bao giờ làm hỏng luồng:** Gemini Decision 1 timeout 3 s → thứ tự SQL; Gemini chat timeout 6,5 s → câu mẫu. Không có mã lỗi nào cho AI lỗi.
3. **Danh sách món từ chối:** app giữ trong phiên và gửi `rejected_recipe_ids` mỗi lượt; server lưu thêm vào `chat_messages.rejected_recipe_ids`.
4. **Phân trang:** `p_page` (từ 1) + `p_page_size`, kèm `total_count` (đếm bằng window function, 1 lần quét).
5. **Mô hình quyết định:** Gemini Decision 1 (gói miễn phí AI Studio). Không dùng Jev qua OpenRouter (trả phí).
6. **Đồ chấm/gia vị** (`gia_vi_an_kem`: Muối tôm khô, Tỏi ngâm giấm) không bao giờ được gợi ý như món chính.
7. **Món mới tạo** mặc định **chưa duyệt**, không hiện ra cho app tới khi được duyệt. `is_verified` luôn bằng `status = 'approved'` (tự đồng bộ).
8. **Cộng đồng:** món bị từ chối sửa rồi gửi lại được; món đã duyệt không sửa/xóa được; tối đa 5 món mới/ngày; ảnh ≤ 5 MB JPG/PNG/WebP; 2–40 nguyên liệu; tên tác giả hiện `full_name` hoặc "Người dùng Elytra", không lộ email.
9. **Admin:** giao diện trong app Flutter; quyền kiểm trong DB; admin không sửa nội dung món; AI chấm sẵn nhưng admin duyệt 100% tới khi đo xong bộ ~100 món gắn nhãn.
