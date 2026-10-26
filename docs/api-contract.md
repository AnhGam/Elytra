# API Contract – NutriAI (Draft)

---

## 0. Quy ước chung

### Địa chỉ gọi

```
https://<project-ref>.supabase.co/functions/v1/<tên-function>
```

### Header bắt buộc

| Header | Giá trị |
| --- | --- |
| `Authorization` | `Bearer <access_token>` lấy từ Supabase Auth sau khi đăng nhập |
| `Content-Type` | `application/json` |

### Đơn vị và kiểu dữ liệu

- Năng lượng: `kcal`, số nguyên.
- Khối lượng chất dinh dưỡng: gam, số thực làm tròn 1 chữ số thập phân.
- ID: `uuid` dạng chuỗi.
- Tên trường: `snake_case`.

### Quy ước kết quả

- **Lỗi kỹ thuật hoặc dữ liệu sai** (thiếu token, nhập sai) → trả mã HTTP 4xx/5xx kèm khối `error`.
- **Kết quả nghiệp vụ bình thường** (đã đủ calo, không có món phù hợp, Gemini lỗi phải dùng fallback) → vẫn trả `200`, phân biệt bằng trường `status` hoặc `mode`. App không coi đây là lỗi.

### Định dạng lỗi chung

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Tuổi phải nằm trong khoảng cho phép",
    "field": "age"
  }
}
```

| HTTP | `code` | Khi nào | App xử lý |
| --- | --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Thiếu trường hoặc giá trị ngoài khoảng | Hiện lỗi dưới ô tương ứng với `field` |
| 401 | `UNAUTHORIZED` | Token thiếu hoặc hết hạn | Chuyển về màn Đăng nhập |
| 404 | `PROFILE_NOT_FOUND` | Người dùng chưa hoàn tất onboarding | Chuyển sang Onboarding (Luồng 1) |
| 500 | `INTERNAL_ERROR` | Lỗi không lường trước | Hiện thông báo chung, cho thử lại |

### Kiểu dữ liệu dùng chung

**`Goal`**: `"lose_weight"` | `"maintain"` | `"gain_muscle"`

**`ActivityLevel`**

| Giá trị | Ý nghĩa | Hệ số |
| --- | --- | --- |
| `sedentary` | Ít vận động | 1.2 |
| `light` | 1–3 buổi/tuần | 1.375 |
| `moderate` | 3–5 buổi/tuần | 1.55 |
| `active` | 6–7 buổi/tuần | 1.725 |
| `very_active` | Lao động nặng, tập 2 lần/ngày | 1.9 |

**`MealType`**: `"breakfast"` | `"lunch"` | `"dinner"` | `"snack"`

**`RecipeCard`** – dùng chung cho `recommend` và `chat`, để thẻ món ở mọi màn hình giống nhau:

```json
{
  "recipe_id": "8f1c…",
  "name": "Ức gà áp chảo rau củ",
  "image_url": "https://…/uc-ga.jpg",
  "kcal": 420,
  "protein_g": 38.5,
  "carbs_g": 30.0,
  "fat_g": 14.2,
  "cook_minutes": 25,
  "score": 0.86,
  "reasons": ["Nhiều protein", "Vừa với calo còn lại của bữa trưa"],
  "pantry": null
}
```

- `reasons`: lý do do **engine** sinh ra, không phải do AI. Chatbot và giao diện dùng lại trực tiếp.
- `pantry`: chỉ có giá trị ở Chế độ 2 (xem mục 2), các trường hợp khác là `null`.

---

## 1. `POST /calc-nutrition` – Ước tính dinh dưỡng

**Dùng ở:** Onboarding (màn kết quả), Hồ sơ cá nhân (khi sửa thể trạng).
**Luồng:** Activity diagram Luồng 1.

Có 2 cách gọi:

- `save: false`: chỉ tính để hiện màn kết quả, chưa lưu.
- `save: true`: tính và lưu vào `user_profiles`, cùng `user_allergens` nếu có phần tùy chỉnh. Dùng khi bấm "Dùng ngay" hoặc khi lưu xong nhánh "Tùy chỉnh".

### Request

| Trường | Kiểu | Bắt buộc | Ràng buộc |
| --- | --- | --- | --- |
| `gender` | `"male"` \| `"female"` | Có | |
| `age` | số nguyên | Có | khoảng hợp lệ (đề xuất 18–80) |
| `height_cm` | số | Có | (đề xuất 120–220) |
| `weight_kg` | số | Có | (đề xuất 30–200) |
| `activity_level` | `ActivityLevel` | Có | |
| `goal` | `Goal` | Có | |
| `save` | boolean | Không | Mặc định `false` |
| `custom` | object | Không | Chỉ gửi khi đi nhánh "Tùy chỉnh" |
| `custom.macro_pct` | `{protein, carbs, fat}` | Không | Tổng = 100 |
| `custom.meal_split_pct` | `{breakfast, lunch, dinner, snack}` | Không | Tổng = 100 |
| `custom.allergen_ids` | `uuid[]` | Không | Phải tồn tại trong bảng `allergens` |
| `custom.diet_type` | chuỗi | Không | danh sách giá trị |

### Ví dụ request

```json
{
  "gender": "male",
  "age": 22,
  "height_cm": 170,
  "weight_kg": 65,
  "activity_level": "moderate",
  "goal": "lose_weight",
  "save": false
}
```

### Response `200`

```json
{
  "bmr": 1608,
  "tdee": 2492,
  "target_kcal": 2092,
  "floor_applied": false,
  "macros": {
    "protein_g": 156.9,
    "carbs_g": 209.2,
    "fat_g": 69.7,
    "pct": { "protein": 30, "carbs": 40, "fat": 30 }
  },
  "meal_split_kcal": { "breakfast": 523, "lunch": 732, "dinner": 628, "snack": 209 },
  "bmi": 22.5,
  "saved": false
}
```

- `floor_applied: true` nghĩa là calo mục tiêu đã được nâng lên mức sàn (1200 kcal với nữ, 1500 kcal với nam). App nên hiện một dòng giải thích.

### Lỗi riêng

| HTTP | `code` | Khi nào |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Trường thiếu hoặc ngoài khoảng (`field` cho biết trường nào) |
| 400 | `MACRO_SUM_INVALID` | Tổng `custom.macro_pct` khác 100 |
| 400 | `MEAL_SPLIT_INVALID` | Tổng `custom.meal_split_pct` khác 100 |
| 400 | `ALLERGEN_NOT_FOUND` | Có `allergen_id` không tồn tại |

---

## 2. `POST /recommend` – Gợi ý món ăn

**Dùng ở:** nút "Trưa nay ăn gì?" trên Dashboard (Chế độ 1), màn Bộ lọc nâng cao (Chế độ 2). Edge Function `chat` cũng gọi nội bộ.

### Request

| Trường | Kiểu | Bắt buộc | Ghi chú |
| --- | --- | --- | --- |
| `mode` | `"quick"` \| `"advanced"` | Có | `quick` = Chế độ 1, `advanced` = Chế độ 2 |
| `meal_type` | `MealType` | Không | Bữa nào trong ngày, bỏ trống thì server tự suy ra theo giờ hiện tại |
| `limit` | số nguyên | Không | Mặc định 3, tối đa 10 |
| `exclude_ids` | `uuid[]` | Không | Các món đã từ chối trong lượt này |
| `rejected_id` | `uuid` | Không | Món vừa bấm "Đổi món khác". Server ghi `recommendation_logs` = `rejected` và tự thêm món này vào danh sách loại trừ |
| `filters` | object | Bắt buộc khi `mode = advanced` | Phải có ít nhất 1 tiêu chí |
| `filters.pantry_ingredient_ids` | `uuid[]` | Không | Nguyên liệu đang có trong tủ lạnh |
| `filters.kcal_min` / `kcal_max` | số nguyên | Không | Dải calo mỗi khẩu phần |
| `filters.max_cook_minutes` | số nguyên | Không | |
| `filters.difficulty` | `"easy"` \| `"medium"` \| `"hard"` | Không | |
| `filters.category_ids` | `uuid[]` | Không | Nhóm món |

### Ví dụ request – Chế độ 1

```json
{ "mode": "quick", "limit": 3, "exclude_ids": [] }
```

### Ví dụ request – Chế độ 2

```json
{
  "mode": "advanced",
  "limit": 5,
  "filters": {
    "pantry_ingredient_ids": ["egg-uuid", "tomato-uuid"],
    "max_cook_minutes": 30
  }
}
```

### Response `200`

```json
{
  "status": "ok",
  "meal_type": "lunch",
  "budget": {
    "target":    { "kcal": 2092, "protein_g": 156.9, "carbs_g": 209.2, "fat_g": 69.7 },
    "consumed":  { "kcal": 520,  "protein_g": 30.0,  "carbs_g": 70.0,  "fat_g": 15.0 },
    "remaining": { "kcal": 1572, "protein_g": 126.9, "carbs_g": 139.2, "fat_g": 54.7 }
  },
  "relax_count": 0,
  "items": [ /* RecipeCard[] */ ]
}
```

Ở Chế độ 2, trường `pantry` của mỗi `RecipeCard` có dạng:

```json
"pantry": {
  "matched": 4,
  "total": 5,
  "missing": [{ "ingredient_id": "…", "name": "Hành lá" }],
  "label": "Thiếu 1 nguyên liệu"
}
```

### Giá trị `status`

| `status` | Ý nghĩa | `items` | App hiển thị |
| --- | --- | --- | --- |
| `ok` | Tìm được món bình thường | Có | Thẻ món |
| `relaxed` | Phải nới rộng dải calo mới tìm được (`relax_count` = 1 hoặc 2) | Có | Thẻ món + dòng nhắc "calo có thể lệch nhiều hơn bình thường" |
| `fallback_lowest_kcal` | Đã nới lỏng tối đa mà vẫn không có món, trả các món ít calo nhất | Có | Thẻ món + cảnh báo |
| `goal_reached` | Đã hết calo trong ngày | Rỗng | Thông báo đã đạt mục tiêu, không gợi ý món chính |
| `no_match` | Chế độ 2 không có món phù hợp | Rỗng | Gợi ý bỏ bớt tiêu chí |

- Số lần nới lỏng tối đa (đề xuất 2) và mức nới mỗi lần.
- Trọng số chấm điểm (calo, protein, sở thích, tủ lạnh). `S_pantry` = 0 ở Chế độ 1.
- Món chứa chất dị ứng của người dùng **luôn bị loại**, ở mọi chế độ, kể cả khi nới lỏng.

### Lỗi riêng

| HTTP | `code` | Khi nào |
| --- | --- | --- |
| 400 | `FILTER_REQUIRED` | `mode = advanced` nhưng không có tiêu chí nào |
| 404 | `PROFILE_NOT_FOUND` | Chưa có hồ sơ thể trạng |

---

## 3. `POST /chat` – Chatbot AI

**Nguyên tắc:** Mọi số liệu và mọi món ăn đều do engine và database cung cấp. Gemini chỉ viết lời dẫn. Khi Gemini lỗi, quá thời gian chờ, hoặc nhắc món không có trong danh sách ứng viên, API **vẫn trả 200** với `mode = "fallback"` và câu mẫu cố định.

### Request

| Trường | Kiểu | Bắt buộc | Ghi chú |
| --- | --- | --- | --- |
| `intent` | xem bảng dưới | Có | |
| `text` | chuỗi | Khi `intent = message` | Tối đa 500 ký tự |
| `recipe_id` | `uuid` | Khi `intent` là `accept`, `swap`, `how_to_cook`, `why_fit` | Món trên thẻ người dùng vừa bấm |
| `exclude_ids` | `uuid[]` | Không | Món đã từ chối trong phiên chat; app tự giữ và gửi lên |
| `history` | `{role, text}[]` | Không | Tối đa 6 lượt gần nhất, để Gemini hiểu ngữ cảnh |

| `intent` | Nguồn | Server làm gì |
| --- | --- | --- |
| `open` | Mở màn Chat | Nạp ngữ cảnh, gọi `recommend` (quick), chào kèm top 3 món |
| `message` | Người dùng gõ tự do | Kiểm tra phạm vi → nếu có nhắc nguyên liệu thì gọi `recommend` (advanced), nếu không thì xác định ý định |
| `accept` | Chip "Ăn món này" | Gọi RPC `log_meal` (cùng logic với `POST /meal-logs`, mục 4), ghi log `accepted` |
| `swap` | Chip "Đổi món khác" | Ghi log `rejected`, gọi `recommend` với món đó bị loại |
| `how_to_cook` | Chip "Nấu thế nào?" | Đọc `cooking_steps` từ database |
| `why_fit` | Chip "Vì sao hợp với tôi?" | Dùng `reasons` của engine và ngân sách còn lại |

### Ví dụ request – Đổi món

```json
{
  "intent": "swap",
  "recipe_id": "8f1c…",
  "exclude_ids": ["3a7d…"]
}
```

### Response `200`

```json
{
  "mode": "ai",
  "intent": "swap",
  "message": "Thử món Cá hồi nướng nhé, ít hơn khoảng 60 kcal mà vẫn đủ đạm cho bữa trưa.",
  "cards": [ /* RecipeCard[] – lấy từ engine */ ],
  "chips": ["accept", "swap", "how_to_cook", "why_fit"],
  "exclude_ids": ["3a7d…", "8f1c…"],
  "status": "ok",
  "logged": null,
  "out_of_scope": false
}
```

| Trường | Ý nghĩa |
| --- | --- |
| `mode` | `"ai"` = lời dẫn do Gemini viết; `"fallback"` = câu mẫu. App hiện banner "Kết nối AI đang gián đoạn" khi là `fallback` |
| `message` | Văn bản hiển thị trong bong bóng chat |
| `cards` | Thẻ món, luôn lấy từ engine, không bao giờ do AI tạo |
| `chips` | Các nút bấm nhanh cần hiển thị dưới tin nhắn |
| `exclude_ids` | Danh sách loại trừ đã cập nhật; app lưu lại và gửi lên ở lượt sau |
| `status` | Lấy nguyên từ `recommend` (`ok`, `relaxed`, `goal_reached`, …) khi lượt này có gọi engine; `null` nếu không |
| `logged` | Khi `intent = accept`: `{ "meal_log_item_id": "…", "kcal_added": 420 }` để app cập nhật Dashboard |
| `out_of_scope` | `true` khi câu hỏi ngoài phạm vi dinh dưỡng; khi đó `cards` rỗng |

### Ví dụ response – Fallback

```json
{
  "mode": "fallback",
  "intent": "open",
  "message": "Kết nối AI đang gián đoạn. Đây là 3 món phù hợp với lượng calo còn lại của bạn:",
  "cards": [ /* RecipeCard[] */ ],
  "chips": ["accept", "swap", "how_to_cook", "why_fit"],
  "exclude_ids": [],
  "status": "ok",
  "logged": null,
  "out_of_scope": false
}
```

### Lỗi riêng

| HTTP | `code` | Khi nào |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Thiếu `text` hoặc `recipe_id` theo `intent`, `text` quá dài |
| 404 | `RECIPE_NOT_FOUND` | `recipe_id` không tồn tại hoặc chưa được duyệt |
| 404 | `PROFILE_NOT_FOUND` | Chưa có hồ sơ thể trạng |
| 429 | `RATE_LIMITED` | Gửi quá nhiều tin trong thời gian ngắn |

> Gemini lỗi **không** phải là lỗi API. Không có mã lỗi nào cho trường hợp này, vì nó luôn được xử lý bằng `mode = "fallback"`.

---

## 4. `/meal-logs` – Nhật ký bữa ăn

**Dùng ở:** Dashboard (đã nạp / còn lại), màn Ghi bữa ăn, Chi tiết món (nút "Ăn món này"), màn Lịch sử + biểu đồ.

- Mọi nơi ghi bữa ăn đều đi qua endpoint này (hoặc RPC `log_meal` mà nó gọi). App **không** insert thẳng vào bảng: RLS chỉ cho đọc và xóa.
- Dinh dưỡng được **chụp lại lúc ghi** (snapshot). Sau này sửa món/nguyên liệu thì lịch sử cũ không đổi.
- "Hôm nay" tính theo giờ Việt Nam (UTC+7). `date` có dạng `YYYY-MM-DD`.

**`Budget`** – cùng dạng với `budget` của `recommend`. `remaining` có thể **âm** khi đã ăn vượt mục tiêu.

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

- `source = "recipe"` → có `servings`, `amount_g = null`. `source = "ingredient"` → có `amount_g`, `servings = null`.
- `recipe_id` / `ingredient_id` có thể thành `null` nếu món gốc bị xóa; `name` và số liệu vẫn giữ.

### 4.1 `POST /meal-logs` – Ghi 1 món

| Trường | Kiểu | Bắt buộc | Ràng buộc |
| --- | --- | --- | --- |
| `meal_type` | `MealType` | Có | |
| `recipe_id` | `uuid` | Một trong hai | Món đã duyệt |
| `servings` | số | Không | Chỉ đi với `recipe_id`. 0.25–10, mặc định 1 |
| `ingredient_id` | `uuid` | Một trong hai | Nguyên liệu đang hoạt động |
| `amount_g` | số | Khi có `ingredient_id` | 1–2000 (gam phần ăn được) |
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

- Cùng key + cùng nội dung → trả món đã ghi, `replayed: true`.
- Cùng key + khác nội dung → `422 IDEMPOTENCY_CONFLICT` (lỗi lập trình phía app).
- Không gửi key → mỗi request là một lần ghi mới (retry có thể ghi trùng).

### 4.2 `GET /meal-logs?date=YYYY-MM-DD` – Tổng hợp 1 ngày

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

### 4.3 `GET /meal-logs/history?from=YYYY-MM-DD&to=YYYY-MM-DD` – Lịch sử theo ngày

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

- `days[].target_kcal`: mục tiêu của **chính ngày đó** (lưu lúc ghi món đầu tiên của bữa). Đổi hồ sơ sau đó không làm đổi các ngày cũ. Ngày chưa ghi gì dùng mục tiêu hiện tại.
- `target_kcal` ở ngoài: mục tiêu hiện tại.
- `budget` của `GET /meal-logs?date=` luôn dùng mục tiêu **hiện tại** (kể cả khi xem ngày cũ).

### 4.4 `PATCH /meal-logs/items/:id` – Sửa khẩu phần / khối lượng

Gửi `servings` nếu món là `recipe`, `amount_g` nếu là `ingredient` (cùng khoảng như 4.1). Dinh dưỡng được nhân theo tỉ lệ trên **snapshot cũ**, không đọc lại món gốc.

```json
{ "servings": 2 }
```

Response `200`: `{ "item": { /* MealLogItem */ "meal_type": "lunch", "date": "2026-10-26" }, "budget": { /* Budget */ } }`.

Đặt giá trị tuyệt đối nên retry an toàn. Không đổi được bữa/ngày: muốn chuyển bữa thì xóa rồi ghi lại.

### 4.5 `DELETE /meal-logs/items/:id` – Xóa 1 món

Response `204`, không có body. Idempotent: món không tồn tại hoặc đã xóa vẫn trả `204`. Gọi lại `GET /meal-logs?date=` để cập nhật Dashboard.

### Lỗi riêng

| HTTP | `code` | `field` | Khi nào |
| --- | --- | --- | --- |
| 400 | `VALIDATION_ERROR` | trường sai | Sai `meal_type`; gửi cả hai hoặc không gửi `recipe_id`/`ingredient_id` (`field = recipe_id`); `servings`/`amount_g`/`date` ngoài khoảng; `from`/`to` sai hoặc quá 31 ngày (`field = from`) |
| 404 | `RECIPE_NOT_FOUND` | `recipe_id` | Không tồn tại hoặc chưa duyệt |
| 404 | `INGREDIENT_NOT_FOUND` | `ingredient_id` | Không tồn tại hoặc đã vô hiệu hóa |
| 404 | `PROFILE_NOT_FOUND` | | Chưa có mục tiêu calo |
| 404 | `ITEM_NOT_FOUND` | `id` | PATCH món không tồn tại hoặc của người khác |
| 422 | `IDEMPOTENCY_CONFLICT` | `client_request_id` | Xem 4.1 |

### Gọi từ Flutter

```dart
await supabase.functions.invoke('meal-logs', body: {...});                       // POST
await supabase.functions.invoke('meal-logs', method: HttpMethod.get, queryParameters: {'date': '2026-10-26'});
await supabase.functions.invoke('meal-logs/history', method: HttpMethod.get, queryParameters: {'from': '…', 'to': '…'});
await supabase.functions.invoke('meal-logs/items/$id', method: HttpMethod.patch, body: {'servings': 2});
await supabase.functions.invoke('meal-logs/items/$id', method: HttpMethod.delete);
```

---

## 5. Cần xác định

1. Khoảng hợp lệ của tuổi, chiều cao, cân nặng.
2. Thời gian chờ Gemini trước khi chuyển fallback.
3. `exclude_ids` do app giữ hay lưu ở server theo phiên chat.
4. ~~Ghi bữa ăn từ ngoài màn Chatbot~~ → Đã chốt: mục 4 `/meal-logs`.
5. Danh sách giá trị của `diet_type` và `difficulty`.
