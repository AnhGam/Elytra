# Báo cáo Kỹ thuật: Hệ thống API Món ăn, Quản lý Nguyên liệu & Hạ tầng Lưu trữ Supabase Storage

- **Đơn vị thực hiện:** Nhóm sinh viên thực hiện Đồ án 1
- **Phụ trách kỹ thuật:** Nguyễn Minh Anh (Backend & Database)
- **Giai đoạn:** Sprint 4 (Tuần 5 & 6)
- **Nền tảng triển khai:** Supabase (Project ID: `iwmnkygicqfesvbilmrw`, Khu vực: `ap-southeast-1`)

---

## 1. Mục tiêu Kỹ thuật

Trong phạm vi Sprint 4 (Tuần 5 & 6) theo đề cương đồ án, các hạng mục phát triển phía máy chủ và cơ sở dữ liệu tập trung vào 4 trụ cột kỹ thuật:

1. **Hạ tầng Lưu trữ Đa phương tiện (Supabase Storage):** Triển khai các bucket lưu trữ hình ảnh và video hướng dẫn nấu ăn, cấu hình chính sách bảo mật Row Level Security (RLS) cho truy cập công khai (Public CDN) và tải lên an toàn.
2. **API Tìm kiếm & Lọc Món ăn Nâng cao (`public.search_recipes`):** Cung cấp giao thức tìm kiếm toàn văn tiếng Việt, lọc theo nhóm món, lọc món chay, giới hạn calo và loại trừ nghiêm ngặt các chất gây dị ứng theo hồ sơ người dùng.
3. **Động cơ Tạo Món ăn Tự động Tính Dinh dưỡng (`public.create_recipe_with_nutrition`):** Cho phép người dùng/cộng đồng đóng góp công thức món ăn mới chỉ bằng việc chọn nguyên liệu và định lượng; hệ thống tự động tổng hợp năng lượng, đa lượng (macro), chia theo khẩu phần và tự động kế thừa nhãn dị ứng.
4. **API Quản lý & Tra cứu Nguyên liệu (`public.search_ingredients`, `public.get_ingredient_details`):** Cung cấp API phục vụ chức năng tìm kiếm tự động điền (autocomplete), lọc theo 15 nhóm thực phẩm Viện Dinh Dưỡng 2017 và tra cứu chi tiết vi chất dinh dưỡng (vitamin, khoáng chất).

---

## 2. Hạ tầng Lưu trữ Đa phương tiện (Supabase Storage Architecture)

### 2.1. Đánh giá Hạn mức Tài nguyên (Quota Analysis)
Supabase Free Tier cung cấp giới hạn tài nguyên:
- **Dung lượng lưu trữ (Storage):** Tối đa 1.0 GB.
- **Băng thông tải về (Egress Bandwidth):** Tối đa 2.0 GB / tháng.

Nếu lưu trữ toàn bộ 45 video hướng dẫn nấu ăn chuẩn Full HD (1080p) ở định dạng MP4 trực tiếp trên máy chủ lưu trữ (dung lượng ước tính ~3.5 GB đến 5.0 GB), hệ thống sẽ vượt ngưỡng tài nguyên ngay lập tức và làm gián đoạn dịch vụ khi ứng dụng mobile thực hiện phát video kiểm thử.

### 2.2. Chiến lược Lưu trữ Lai (Hybrid Storage Strategy)
Để đảm bảo trải nghiệm người dùng tối ưu, tính sẵn sàng cao và tuân thủ giới hạn tài nguyên đồ án, hệ thống áp dụng mô hình phân tách lưu trữ:

```
+---------------------------------------------------------------------------------+
|                               HYBRID MEDIA STORAGE                              |
+---------------------------------------------------------------------------------+
| 1. HÌNH ẢNH MÓN ĂN (Static Assets)                                              |
|    - Lưu trữ tập trung tại Supabase Storage bucket: "recipe-images" (Public)     |
|    - Toàn bộ 45 ảnh món ăn HD được tải lên và phục vụ qua Supabase Global CDN.   |
|    - Cột `image_url` trong `public.recipes` lưu trực tiếp URL CDN vĩnh viễn.    |
+---------------------------------------------------------------------------------+
| 2. VIDEO HƯỚNG DẪN NẤU ĂN (Video Cooking Guides)                                |
|    - Bucket "recipe-videos" (Public): Được tạo và cấu hình sẵn sàng trên         |
|      Supabase Storage để phục vụ video demo và tính năng người dùng đăng tải clip.|
|    - 45 Video mẫu chuẩn: Được phát trực tuyến thông qua giao thức CDN YouTube   |
|      với công nghệ truyền phát thích ứng (Adaptive Bitrate Streaming 480p-1080p),|
|      không tiêu tốn băng thông và dung lượng lưu trữ của máy chủ Supabase.      |
+---------------------------------------------------------------------------------+
```

### 2.3. Cấu hình Bucket & Chính sách RLS trên Supabase Storage

Các bucket lưu trữ được khởi tạo và phân quyền thông qua migration và script quản trị:

| Tên Bucket | Trạng thái Công khai | Giới hạn Kích thước File | Định dạng Cho phép |
| :--- | :--- | :--- | :--- |
| `recipe-images` | `public = true` | 5 MB | `image/jpeg`, `image/png`, `image/webp` |
| `recipe-videos` | `public = true` | 50 MB | `video/mp4`, `video/webm`, `video/quicktime` |

**Chính sách Bảo mật RLS (`storage.objects`):**
- **Quyền đọc (SELECT):** Cho phép tất cả người dùng (kể cả khách vãng lai `anon`) đọc dữ liệu công khai qua URL:
  ```
  https://iwmnkygicqfesvbilmrw.supabase.co/storage/v1/object/public/<bucket-name>/<filename>
  ```
- **Quyền tải lên (INSERT):** Cho phép người dùng đã xác thực hoặc service role tải lên và ghi đè (`x-upsert: true`).

---

## 3. Đặc tả API Tìm kiếm & Lọc Món ăn Nâng cao (`public.search_recipes`)

### 3.1. Thiết kế Tham số & Kiểu Trả về
Hàm RPC `public.search_recipes` được thiết kế để xử lý toàn bộ logic tìm kiếm và lọc phức tạp trong một lần truy vấn duy nhất phía cơ sở dữ liệu:

```sql
CREATE OR REPLACE FUNCTION public.search_recipes(
    p_query TEXT DEFAULT NULL,                  -- Từ khóa tìm kiếm (tiêu đề, mô tả)
    p_category VARCHAR DEFAULT NULL,            -- Nhóm món ('kho', 'xao', 'canh', 'mon_chay'...)
    p_is_vegetarian BOOLEAN DEFAULT NULL,       -- Lọc món chay (true/false)
    p_max_calories NUMERIC DEFAULT NULL,        -- Ngưỡng calo tối đa trên 1 khẩu phần (kcal)
    p_exclude_allergen_ids INT[] DEFAULT NULL,  -- Danh sách ID dị ứng cần loại trừ
    p_limit INT DEFAULT 20,                     -- Giới hạn số lượng bản ghi trả về
    p_offset INT DEFAULT 0                      -- Độ lệch phân trang
)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    slug VARCHAR,
    description TEXT,
    image_url TEXT,
    video_url TEXT,
    category VARCHAR,
    cuisine VARCHAR,
    servings INT,
    prep_time_minutes INT,
    cook_time_minutes INT,
    difficulty VARCHAR,
    calories_per_serving NUMERIC,
    protein_g_per_serving NUMERIC,
    fat_g_per_serving NUMERIC,
    carbs_g_per_serving NUMERIC,
    fiber_g_per_serving NUMERIC,
    sodium_mg_per_serving NUMERIC,
    is_vegetarian BOOLEAN,
    allergens INT[]
);
```

### 3.2. Cơ chế Loại trừ Dị ứng Tuyệt đối (Safety Allergen Hard-Filter)
Để bảo vệ an toàn cho người dùng có tiền sử dị ứng thực phẩm, thuật ngữ loại trừ được thực thi tại tầng SQL thông qua biểu thức `NOT EXISTS`:

```sql
AND (
    p_exclude_allergen_ids IS NULL 
    OR NOT EXISTS (
        SELECT 1 
        FROM public.recipe_allergens ra_ex
        WHERE ra_ex.recipe_id = r.id 
          AND ra_ex.allergen_id = ANY(p_exclude_allergen_ids)
    )
)
```
Cơ chế này đảm bảo món ăn chứa bất kỳ thành phần nào thuộc nhóm dị ứng của người dùng sẽ bị loại bỏ hoàn toàn khỏi kết quả tìm kiếm ngay từ cơ sở dữ liệu, không phụ thuộc vào bộ lọc phía client.

---

## 4. Đặc tả Động cơ Tạo Món ăn Tự động (`public.create_recipe_with_nutrition`)

### 4.1. Luồng Nghiệp vụ Tính toán
Theo yêu cầu đề cương đồ án: *“Người dùng không tự nhập giá trị dinh dưỡng mà chỉ chọn nguyên liệu và nhập khối lượng theo g/ml. Hệ thống tự tính dinh dưỡng bằng cách tổng hợp từ từng nguyên liệu rồi chia cho số khẩu phần.”*

Hàm `public.create_recipe_with_nutrition` thực thi tuần tự các bước:
1. **Khởi tạo định danh & Slug:** Tự động tạo slug SEO từ tên món ăn và hậu tố ngẫu nhiên để tránh xung đột khóa chính.
2. **Tổng hợp Dinh dưỡng Lũy tích:** Lặp qua mảng JSON nguyên liệu đầu vào (`p_ingredients`), truy vấn chỉ số dinh dưỡng chuẩn trên 100g từ bảng `public.ingredients` và tính toán theo công thức:
   $$\text{Macro}_{\text{total}} = \sum \left( \frac{\text{amount\_g}}{100} \times \text{Macro}_{\text{per\_100g}} \right)$$
3. **Phân bổ theo Khẩu phần (`per serving`):**
   $$\text{Macro}_{\text{serving}} = \frac{\text{Macro}_{\text{total}}}{\text{servings}}$$
4. **Kế thừa Tác nhân Dị ứng Tự động:** Tự động truy vấn bảng `public.ingredient_allergens` của các nguyên liệu cấu thành và chèn các liên kết dị ứng vào `public.recipe_allergens`.

### 4.2. Định dạng Gọi Hàm từ Client (SDK / REST)

```json
POST /rest/v1/rpc/create_recipe_with_nutrition
Content-Type: application/json

{
  "p_title": "Ức gà áp chảo sốt bơ tỏi",
  "p_description": "Món ăn giàu đạm hỗ trợ tăng cơ giảm mỡ",
  "p_servings": 2,
  "p_prep_time_minutes": 10,
  "p_cook_time_minutes": 15,
  "p_category": "mon_man",
  "p_difficulty": "easy",
  "p_instructions": [
    { "step": 1, "content": "Rửa sạch ức gà, khứa nhẹ bề mặt và ướp tiêu muối" },
    { "step": 2, "content": "Làm nóng chảo, cho bơ và tỏi băm vào phi thơm rồi áp chảo gà vàng đều hai mặt" }
  ],
  "p_ingredients": [
    {
      "ingredient_id": "8a32b6e5-430c-40ad-a035-7cebf60ba087",
      "ingredient_name_raw": "Thịt gà nạc (ức gà)",
      "raw_text": "300g ức gà tươi",
      "amount": 300,
      "unit": "g",
      "amount_g": 300
    },
    {
      "ingredient_id": "60e671ef-2d22-48db-baed-7184da56ee4b",
      "ingredient_name_raw": "Bơ thực vật",
      "raw_text": "15g bơ",
      "amount": 15,
      "unit": "g",
      "amount_g": 15
    }
  ]
}
```

---

## 5. Đặc tả API Quản lý & Tra cứu Nguyên liệu

### 5.1. Hàm Tìm kiếm Tự động Điền (`public.search_ingredients`)
Phục vụ màn hình chọn nguyên liệu khi tạo công thức nấu ăn hoặc tra cứu dinh dưỡng thực phẩm:

- **Hỗ trợ tìm kiếm linh hoạt:** Tìm theo tên tiếng Việt có dấu (`name_vi`), tên không dấu (`name_unaccented`), tên khoa học/tiếng Anh (`name_en`) hoặc mã số Viện Dinh Dưỡng 2017 (`code`).
- **Phân loại theo danh mục:** Lọc theo 15 nhóm thực phẩm (Ngũ cốc, Khoai củ, Hạt, Rau củ, Thịt, Thủy sản, Trứng, Sữa...).
- **Đính kèm cảnh báo dị ứng:** Mỗi nguyên liệu trả về kèm mảng JSON chứa các chất dị ứng tương ứng (ví dụ: Sữa bò -> Dị ứng Sữa & Chế phẩm sữa; Tôm -> Dị ứng Hải sản).

### 5.2. Hàm Truy xuất Chi tiết Nguyên liệu (`public.get_ingredient_details`)
Trả về đầy đủ hồ sơ phân tích dinh dưỡng sâu bao gồm:
- **Đa lượng:** Calo, Protein, Chất béo, Tinh bột, Chất xơ, Độ ẩm (Nước), Độ tro.
- **Khoáng chất:** Canxi, Phốt pho, Sắt, Kẽm, Natri, Kali, Magiê, Mangan, Đồng, Selen.
- **Vitamin:** Vitamin C, B1, B2, B3, B5, B6, B9 (Folate), B12, Vitamin A, Vitamin D, Vitamin E, Vitamin K, Beta-carotene.

---

## 6. Kết quả Kiểm định Toàn diện (Test Results)

Hệ thống đã trải qua quy trình kiểm thử đơn vị và tích hợp thông qua bộ kịch bản tự động trên môi trường thật Supabase:

| Hạng mục Kiểm thử | Kịch bản / Đầu vào | Kết quả Thực tế | Trạng thái |
| :--- | :--- | :--- | :--- |
| **Storage CDN Ảnh** | Kiểm tra HTTP HEAD trên 45 ảnh trong `recipe-images` | 45/45 trả về HTTP 200, Content-Type `image/jpeg` | **ĐẠT** |
| **Storage CDN Video** | Tải lên file MP4 demo vào `recipe-videos` | Upload thành công, HEAD trả về HTTP 200, Content-Type `video/mp4` | **ĐẠT** |
| **Tìm kiếm món ăn** | `p_query = 'cá'`, `p_limit = 3` | Trả về 3 món cá (Cá biển kho cà chua, cá bống chay, cá chim kho thơm) kèm đầy đủ calo và video link | **ĐẠT** |
| **Lọc loại trừ dị ứng** | `p_exclude_allergen_ids = [1]` (Loại trừ hải sản) | Toàn bộ món canh chua cá, bún riêu cua, cá kho bị loại bỏ; chỉ trả về các món thịt lợn, thịt bò, rau xào | **ĐẠT** |
| **Tạo món ăn tự động** | Món trứng chiên với 100g trứng gà (106 kcal/100g), 2 khẩu phần | Kết quả chính xác: 53.0 kcal/khẩu phần, 2.2g protein, 0.2g fat | **ĐẠT** |
| **Tra cứu nguyên liệu** | `p_query = 'bò'` | Trả về chính xác các loại thịt bò, sữa bò tươi, kèm phân loại và chỉ số calo/protein | **ĐẠT** |
| **Chi tiết nguyên liệu** | `p_ingredient_id` của Sữa bò tươi | Trả về đầy đủ 13 loại khoáng chất và vitamin chuẩn Bảng TPTP VN 2017 | **ĐẠT** |

---

## 7. Tổng kết

Hệ thống Backend, Cơ sở Dữ liệu và Lưu trữ cho Sprint 4 (Tuần 5 & 6) đã hoàn thành 100% các tiêu chí kỹ thuật đề ra theo Đề cương Đồ án 1, sẵn sàng kết nối trực tiếp với giao diện người dùng Mobile Flutter trong các Sprint tiếp theo.
