# Báo cáo Kỹ thuật: Thiết kế và Triển khai Module Tính toán Dinh dưỡng (BMR, TDEE, Macro)

- **Đơn vị thực hiện:** Nhóm sinh viên thực hiện Đồ án 1
- **Phụ trách kỹ thuật:** Nguyễn Minh Anh
- **Giai đoạn:** Sprint 3 (Tuần 3 & 4)
- **Công nghệ triển khai:**
  - Supabase Edge Functions (Deno Runtime, TypeScript, Serverless)
  - PostgreSQL Stored Function (PL/pgSQL)
  - Supabase Auth & Row Level Security (RLS)

---

## 1. Mục tiêu và Phạm vi Kỹ thuật

Theo định hướng kiến trúc của đồ án, toàn bộ logic tính toán chỉ số nhân trắc học, năng lượng tiêu hao và phân bổ đa lượng (Macronutrients) thuộc về **Rule-based Engine**. Module này hoạt động độc lập và xác định bởi các công thức khoa học, không phụ thuộc vào trí tuệ nhân tạo (AI/LLM) nhằm bảo đảm tính nhất quán, tốc độ xử lý và độ chính xác toán học.

Module cung cấp:
1. **Lớp xử lý phía Cơ sở dữ liệu (Database Layer):** Hàm lưu trữ nội bộ `calculate_nutrition_targets` thực thi trực tiếp trên PostgreSQL, hỗ trợ truy vấn nhanh qua cơ chế RPC của Supabase.
2. **Lớp dịch vụ không máy chủ (Edge Function Layer):** Endpoint `calculate-bmr-tdee` hoạt động trên mạng biên (Edge Network) của Supabase, phục vụ việc tiếp nhận yêu cầu từ ứng dụng mobile/web với độ trễ thấp và tùy chọn lưu trữ tự động vào bảng hồ sơ (`profiles`).

---

## 2. Cơ sở Khoa học và Công thức Tính toán

### 2.1. Chỉ số khối cơ thể (BMI - Body Mass Index)
Được tính theo công thức:
$$\text{BMI} = \frac{\text{Cân nặng (kg)}}{(\text{Chiều cao (m)})^2}$$

Phân loại thể trạng áp dụng tiêu chuẩn **WHO WPRO** (tiêu chuẩn dành riêng cho người trưởng thành khu vực Châu Á - Thái Bình Dương):
- $\text{BMI} < 18.5$: Thiếu cân.
- $18.5 \le \text{BMI} < 23.0$: Bình thường (Thể trạng chuẩn).
- $23.0 \le \text{BMI} < 25.0$: Tiền béo phì (Thừa cân).
- $\text{BMI} \ge 25.0$: Béo phì.

### 2.2. Tỷ lệ chuyển hóa cơ bản (BMR - Basal Metabolic Rate)
Sử dụng công thức **Mifflin-St Jeor**, hiện là công thức ước tính BMR có độ tương thích lâm sàng cao nhất cho đối tượng người bình thường không đo nhiệt lượng trực tiếp:
- **Đối với Nam:**
  $$\text{BMR} = (10 \times \text{weight\_kg}) + (6.25 \times \text{height\_cm}) - (5 \times \text{age}) + 5$$
- **Đối với Nữ:**
  $$\text{BMR} = (10 \times \text{weight\_kg}) + (6.25 \times \text{height\_cm}) - (5 \times \text{age}) - 161$$

### 2.3. Tổng năng lượng tiêu hao hằng ngày (TDEE - Total Daily Energy Expenditure)
Được tính bằng BMR nhân với hệ số hoạt động thể lực (Physical Activity Level - PAL):
$$\text{TDEE} = \text{BMR} \times \text{PAL}$$

Quy định hệ số PAL:
- **Ít vận động (Sedentary - làm việc văn phòng, ít vận động):** $1.200$
- **Vận động nhẹ (Light - luyện tập nhẹ 1–3 ngày/tuần):** $1.375$
- **Vận động vừa (Moderate - luyện tập 3–5 ngày/tuần):** $1.550$
- **Vận động nhiều (Active - luyện tập 6–7 ngày/tuần):** $1.725$
- **Vận động rất nhiều (Very Active - lao động nặng hoặc vận động viên):** $1.900$

### 2.4. Năng lượng mục tiêu (Target Calories) và Sàn an toàn chuyển hóa
Tùy theo mục tiêu của người dùng, mức calo hằng ngày được điều chỉnh:
- **Giữ cân (`maintain`):** $\text{Target} = \text{TDEE}$
- **Giảm cân (`lose_weight`):** Thiết lập mức thâm hụt năng lượng an toàn là $-500\text{ kcal/ngày}$ (tương đương giảm khoảng $0.45\text{ kg}$ mỡ mỗi tuần).
  - *Cơ chế kiểm soát an toàn (Metabolic Safety Floor):* Tránh nguy cơ suy nhược hoặc tụt chuyển hóa, năng lượng mục tiêu sau khi trừ không được phép thấp hơn **1200 kcal/ngày đối với nữ** và **1500 kcal/ngày đối với nam**.
- **Tăng cân (`gain_weight`):** Thiết lập mức thặng dư năng lượng vừa phải là $+400\text{ kcal/ngày}$ nhằm tối ưu hóa việc tăng cơ nạc và hạn chế tích mỡ thừa.

### 2.5. Phân bổ Dinh dưỡng Đa lượng (Macronutrient Distribution)
- **Chất đạm (Protein):** Xác định theo khối lượng cơ thể (g/kg thể trọng) dựa trên mục tiêu:
  - Giảm cân: $2.0\text{ g/kg}$ (nhằm hạn chế mất cơ trong giai đoạn thâm hụt calo và duy trì cảm giác no lâu).
  - Tăng cân: $1.8\text{ g/kg}$ (hỗ trợ xây dựng mô cơ kết hợp tập luyện kháng lực).
  - Duy trì: $1.6\text{ g/kg}$.
  - Năng lượng cung cấp: $1\text{g Protein} = 4\text{ kcal}$.
- **Chất béo (Fat):** Cố định ở mức $25\%$ tổng năng lượng mục tiêu (nằm trong dải khuyến nghị chuẩn $20\% - 35\%$).
  $$\text{Fat (g)} = \frac{\text{Target Calories} \times 0.25}{9}$$
- **Chất bột đường (Carbohydrates):** Bù đắp lượng năng lượng còn lại để đạt đủ calo mục tiêu:
  $$\text{Carbs (kcal)} = \text{Target Calories} - (\text{Protein}_{\text{kcal}} + \text{Fat}_{\text{kcal}})$$
  $$\text{Carbs (g)} = \frac{\text{Carbs (kcal)}}{4}$$
- **Chất xơ (Dietary Fiber):** Tính theo tỷ lệ chuẩn $14\text{g} / 1000\text{ kcal}$ tiêu thụ, với mức sàn tối thiểu là $25\text{g/ngày}$.
- **Lượng nước khuyến nghị:** Tính toán dựa trên hệ số $35\text{ ml} \times \text{Cân nặng (kg)}$.

---

## 3. Kiến trúc Triển khai Kỹ thuật

Module được tích hợp đồng thời ở hai tầng:

```
                  +-----------------------------------+
                  |        Client Mobile / Web        |
                  +-----------------------------------+
                        |                       |
       (Direct RPC Call)|                       |(HTTP POST Request)
                        v                       v
            +-----------------------+   +-------------------------------+
            |  PostgreSQL Stored Fn |   |     Supabase Edge Function    |
            |  calculate_nutrition  |   |      calculate-bmr-tdee       |
            +-----------------------+   +-------------------------------+
                        |                               |
                        |      +-----------------+      |
                        +----->| public.profiles |<-----+ (If authenticated
                               +-----------------+         and requested)
```

### 3.1. Tầng Database (PostgreSQL Stored Function)
- Tệp di chuyển: `20261005000006_create_nutrition_calculation_functions.sql`
- Hàm: `public.calculate_nutrition_targets(p_gender, p_age, p_height_cm, p_weight_kg, p_activity_level, p_goal)`
- Thuộc tính: `IMMUTABLE` (hàm thuần túy, cùng đầu vào cho ra cùng kết quả, tối ưu hóa bộ nhớ đệm truy vấn).
- Trả về: Đối tượng `JSONB` bao gồm tất cả các chỉ số tính toán.

### 3.2. Tầng Edge Function (Supabase Edge Network)
- Tệp nguồn: `supabase/functions/calculate-bmr-tdee/index.ts`
- Môi trường: Deno Runtime trên Supabase Edge Functions.
- Trạng thái triển khai: `ACTIVE` (Version 1).
- Tính năng xử lý:
  - Xử lý CORS cho phép gọi từ mọi client ứng dụng mobile/web.
  - Kiểm tra tính hợp lệ dữ liệu đầu vào (phạm vi tuổi $10 - 100$, chiều cao $50 - 250\text{ cm}$, cân nặng $20 - 300\text{ kg}$).
  - Cung cấp nhận định và khuyến nghị dinh dưỡng vắn tắt bằng tiếng Việt phù hợp theo từng mục tiêu.
  - Tích hợp ghi nhận trực tiếp vào bảng `public.profiles` nếu người dùng truyền kèm token xác thực (`Authorization: Bearer <JWT>`) và cờ `save_to_profile = true`.

---

## 4. Đặc tả Giao diện Lập trình (API Specification)

### 4.1. Thông tin Endpoint
- **URL:** `https://iwmnkygicqfesvbilmrw.supabase.co/functions/v1/calculate-bmr-tdee`
- **Method:** `POST`
- **Headers:**
  - `Content-Type: application/json`
  - `apikey: <SUPABASE_ANON_KEY>`
  - `Authorization: Bearer <TOKEN>` *(Tùy chọn khi muốn lưu vào profile cá nhân)*

### 4.2. Request Payload
```json
{
  "gender": "male",
  "age": 22,
  "height_cm": 172.0,
  "weight_kg": 68.0,
  "activity_level": "moderate",
  "goal": "lose_weight",
  "save_to_profile": false
}
```

**Bảng tham số đầu vào:**

| Tham số | Kiểu dữ liệu | Bắt buộc | Giá trị hợp lệ |
| :--- | :---: | :---: | :--- |
| `gender` | String | Có | `"male"`, `"female"` |
| `age` | Number | Có | Số nguyên từ 10 đến 100 |
| `height_cm` | Number | Có | Giá trị số từ 50.0 đến 250.0 |
| `weight_kg` | Number | Có | Giá trị số từ 20.0 đến 300.0 |
| `activity_level` | String | Có | `"sedentary"`, `"light"`, `"moderate"`, `"active"`, `"very_active"` |
| `goal` | String | Có | `"lose_weight"`, `"maintain"`, `"gain_weight"` |
| `save_to_profile` | Boolean | Không | `true` hoặc `false` (mặc định: `false`) |

### 4.3. Response Payload (Thành công - HTTP 200)
```json
{
  "success": true,
  "data": {
    "bmi": 23.0,
    "bmi_classification": "Tiền béo phì (Thừa cân)",
    "bmr": 1650.0,
    "tdee": 2557.5,
    "target_calories": 2057.5,
    "calorie_difference": -500.0,
    "macros": {
      "protein_g": 136.0,
      "fat_g": 57.2,
      "carbs_g": 249.8,
      "fiber_g": 28.8,
      "water_ml": 2380
    },
    "macro_percentages": {
      "protein_pct": 26.4,
      "fat_pct": 25.0,
      "carbs_pct": 48.6
    },
    "advice": "Mục tiêu giảm cân khoa học với mức thâm hụt 500 kcal/ngày. Ưu tiên đạm cao (136g) để duy trì khối cơ nạc và tạo cảm giác no lâu. Hạn chế đường đơn và dầu mỡ bão hòa."
  }
}
```

### 4.4. Response Payload (Lỗi dữ liệu - HTTP 400)
```json
{
  "error": "Missing required parameters: gender, age, height_cm, weight_kg, activity_level, goal."
}
```

---

## 5. Kết quả Kiểm thử và Đánh giá (Verification)

Bộ kiểm thử tự động được thiết lập tại tệp `tests/test_nutrition_engine.js` nhằm kiểm tra độ chính xác của các thuật toán với 3 trường hợp đại diện:

### Bảng Ma trận Kiểm thử

| Thông số | Ca kiểm thử 1 (Nam - Giảm cân) | Ca kiểm thử 2 (Nữ - Duy trì) | Ca kiểm thử 3 (Nam - Tăng cơ) |
| :--- | :---: | :---: | :---: |
| **Giới tính** | Nam | Nữ | Nam |
| **Tuổi** | 22 | 20 | 25 |
| **Chiều cao / Cân nặng** | $172\text{ cm}$ / $68\text{ kg}$ | $158\text{ cm}$ / $50\text{ kg}$ | $178\text{ cm}$ / $75\text{ kg}$ |
| **Mức vận động** | Vừa phải (`moderate`) | Nhẹ (`light`) | Nhiều (`active`) |
| **Mục tiêu** | Giảm cân (`lose_weight`) | Duy trì (`maintain`) | Tăng cân (`gain_weight`) |
| **Kết quả BMR** | **1650.0 kcal** (Khớp lý thuyết) | **1226.5 kcal** (Khớp lý thuyết) | **1742.5 kcal** (Khớp lý thuyết) |
| **Kết quả TDEE** | **2557.5 kcal** ($\text{BMR} \times 1.55$) | **1686.4 kcal** ($\text{BMR} \times 1.375$) | **3005.8 kcal** ($\text{BMR} \times 1.725$) |
| **Calo mục tiêu** | **2057.5 kcal** ($-500\text{ kcal}$) | **1686.4 kcal** ($0\text{ kcal}$) | **3405.8 kcal** ($+400\text{ kcal}$) |
| **Định lượng Protein** | **136.0 g** ($2.0\text{ g/kg}$) | **80.0 g** ($1.6\text{ g/kg}$) | **135.0 g** ($1.8\text{ g/kg}$) |
| **Định lượng Nước** | **2380 ml** | **1750 ml** | **2625 ml** |
| **Trạng thái kiểm tra** | **ĐẠT (PASS)** | **ĐẠT (PASS)** | **ĐẠT (PASS)** |

### Kiểm tra thực tế trên hạ tầng Edge Function:
- Thực thi gọi trực tiếp endpoint đám mây bằng giao thức HTTPS.
- Thời gian phản hồi trung bình: $\sim 150\text{ms} - 250\text{ms}$.
- Trạng thái HTTP trả về: `200 OK`.
- Dữ liệu hoàn toàn khớp với kết quả từ Database Stored Function.

Toàn bộ mã nguồn, cấu hình di chuyển và bộ kiểm thử đã được lưu trữ và quản lý phiên bản trong kho mã nguồn Git của dự án `Elytra`.
