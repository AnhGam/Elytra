# Báo cáo Kỹ thuật: Khởi tạo Cơ sở dữ liệu và Nhập Dữ liệu Thực phẩm trên Supabase

- **Đơn vị thực hiện:** Nhóm sinh viên thực hiện Đồ án 1
- **Phụ trách kỹ thuật:** Nguyễn Minh Anh
- **Giai đoạn:** Sprint 3 (Tuần 3 & 4)
- **Nền tảng triển khai:** Supabase PostgreSQL (Project ID: `iwmnkygicqfesvbilmrw`, Khu vực: Singapore - `ap-southeast-1`)

---

## 1. Mục tiêu thực hiện

1. Xây dựng lược đồ cơ sở dữ liệu quan hệ (Relational Schema) phục vụ việc lưu trữ thông tin thực phẩm, hồ sơ người dùng và các thuộc tính dị ứng.
2. Thiết lập cơ chế bảo mật cấp hàng (Row Level Security - RLS) và các chỉ mục (Indexes) nhằm tối ưu hiệu năng truy vấn.
3. Khai thác, làm sạch và chuẩn hóa toàn bộ 620 nguyên liệu thực phẩm từ ấn bản chính thức "Bảng thành phần thực phẩm Việt Nam 2017" do Bộ Y tế / Viện Dinh dưỡng phát hành.
4. Nạp dữ liệu vào cơ sở dữ liệu Supabase thông qua công cụ quản trị tự động hóa, đảm bảo tính toàn vẹn và không xảy ra xung đột dữ liệu.

---

## 2. Thiết kế Lược đồ Cơ sở dữ liệu (Database Schema)

Lược đồ cơ sở dữ liệu được triển khai gồm 5 bảng chính, tuân thủ các quy tắc chuẩn hóa dữ liệu:

```
+--------------------------+       +------------------------+
|  ingredient_categories   |       |       allergens        |
+--------------------------+       +------------------------+
| id (PK)                  |<--+   | id (PK)                |<--+
| code, roman, name_vi...  |   |   | code, name_vi, desc... |   |
+--------------------------+   |   +------------------------+   |
                               |                                |
+--------------------------+   |   +------------------------+   |
|       ingredients        |   |   |  ingredient_allergens  |   |
+--------------------------+   |   +------------------------+   |
| id (PK, UUID)            |   |   | ingredient_id (PK, FK) |---+
| code (UNIQUE)            |   |   | allergen_id   (PK, FK) |---+
| category_id (FK) --------+---+   +------------------------+
| 40+ nutrition columns    |
+--------------------------+
            ^
            | (User reference)
+--------------------------+       +------------------------+
|         profiles         |       |     user_allergens     |
+--------------------------+       +------------------------+
| id (PK, FK -> auth.users)|<------+ user_id (PK, FK)       |
| physical & macro metrics |       | allergen_id (PK, FK)   |
+--------------------------+       +------------------------+
```

### 2.1. Bảng `ingredient_categories` (Danh mục nhóm thực phẩm)
Phân loại thực phẩm theo 15 nhóm chuẩn của Bộ Y tế:
- `id` (INT, Primary Key)
- `code` (VARCHAR(50), Unique)
- `roman` (VARCHAR(10)): Ký hiệu số La Mã (I đến XV)
- `name_vi` (VARCHAR(100)): Tên tiếng Việt
- `name_en` (VARCHAR(100)): Tên tiếng Anh
- `display_order` (INT)

### 2.2. Bảng `allergens` (Danh mục chất gây dị ứng)
Quản lý 8 nhóm tác nhân dị ứng phổ biến theo khuyến nghị y khoa:
- `id` (INT, Primary Key)
- `code` (VARCHAR(50), Unique): seafood, egg, dairy, peanut, tree_nut, soy, gluten, sesame
- `name_vi` (VARCHAR(100)): Tên mô tả tiếng Việt
- `description` (TEXT)

### 2.3. Bảng `ingredients` (Nguyên liệu thực phẩm)
Chứa thông tin dinh dưỡng chi tiết trên 100g phần ăn được:
- `id` (UUID, Primary Key, `gen_random_uuid()`)
- `code` (VARCHAR(50), Unique): Mã số thực phẩm theo Bảng TPTP VN (ví dụ: `01001`)
- `name_vi` (VARCHAR(150), Not Null): Tên tiếng Việt
- `name_en` (VARCHAR(150)): Tên tiếng Anh
- `name_unaccented` (VARCHAR(150)): Tên không dấu phục vụ tìm kiếm
- `category_id` (INT, Foreign Key -> `ingredient_categories.id`)
- `is_featured` (BOOLEAN): Đánh dấu nhóm nguyên liệu cốt lõi cho Recipe Engine
- `is_active` (BOOLEAN): Trạng thái khả dụng
- `edible_portion_pct` (NUMERIC(5,1)): Tỷ lệ phần ăn được (0.0% - 100.0%)
- `density_g_per_ml` (NUMERIC(4,2)): Khối lượng riêng (g/ml) phục vụ quy đổi đơn vị đo lường
- **Chỉ số đa lượng (Macronutrients):** `calories_per_100g`, `protein_per_100g`, `fat_per_100g`, `carbs_per_100g`, `fiber_per_100g`, `water_g`, `ash_g`
- **Chỉ số khoáng vi lượng:** `calcium_mg`, `phosphorus_mg`, `iron_mg`, `zinc_mg`, `sodium_mg`, `potassium_mg`, `magnesium_mg`, `manganese_mg`, `copper_mcg`, `selenium_mcg`
- **Chỉ số Vitamin:** `vit_c_mg`, `thiamine_b1_mg`, `riboflavin_b2_mg`, `niacin_b3_mg`, `pantothenic_b5_mg`, `vit_b6_mg`, `folate_b9_mcg`, `vit_b12_mcg`, `retinol_mcg`, `vit_a_rae_mcg`, `vit_d_mcg`, `vit_e_mg`, `vit_k_mcg`, `beta_carotene_mcg`

### 2.4. Bảng `ingredient_allergens` (Liên kết nguyên liệu - dị ứng)
Phục vụ chức năng lọc bỏ món ăn (Hard-filter) đối với người dùng có tiền sử dị ứng:
- `ingredient_id` (UUID, Foreign Key -> `ingredients.id` ON DELETE CASCADE)
- `allergen_id` (INT, Foreign Key -> `allergens.id` ON DELETE CASCADE)
- Khóa chính tổng hợp: `(ingredient_id, allergen_id)`

### 2.5. Bảo mật và Tối ưu hóa truy vấn
- **Chỉ mục:** Đã đánh chỉ mục trên các cột thường xuyên tìm kiếm và lọc:
  - `idx_ingredients_category` trên `ingredients(category_id)`
  - `idx_ingredients_active` trên `ingredients(id) WHERE is_active = TRUE`
  - `idx_ingredients_name_vi` trên `ingredients(name_vi)`
  - `idx_ingredients_unaccented` trên `ingredients(name_unaccented)`
  - `idx_ingredient_allergens_allergen` trên `ingredient_allergens(allergen_id)`
- **Row Level Security (RLS):** Kích hoạt trên toàn bộ các bảng. Áp dụng chính sách `Allow public read` cho phép truy cập đọc đối với người dùng ẩn danh (`anon`) và người dùng đã xác thực (`authenticated`), đảm bảo chỉ phía quản trị hoặc quy trình nội bộ mới được phép sửa đổi dữ liệu.

---

## 3. Quy trình Trích xuất và Chuẩn hóa Dữ liệu (ETL)

### 3.1. Nguồn dữ liệu
Dữ liệu được khai thác từ tài liệu gốc dạng tài liệu văn bản (`.docx`) của Bảng thành phần thực phẩm Việt Nam 2017 gồm hơn 200 bảng số liệu.

### 3.2. Chuẩn hóa giá trị định lượng
- Các ô chứa ký tự đặc biệt thể hiện thiếu dữ liệu (`-`, rỗng, khoảng trắng) được chuyển đổi thành `NULL` trong cơ sở dữ liệu thay vì gán mặc định bằng 0, nhằm bảo đảm độ chính xác trong phân tích dinh dưỡng.
- Các ký tự vết (`Trace` hoặc `vết`) được chuẩn hóa thành 0.
- Tỷ lệ phần ăn được (`edible_portion_pct`) được giới hạn trong khoảng từ 0% đến 100%.

### 3.3. Quy đổi đơn vị và khối lượng riêng
Các nguyên liệu lỏng và bán lỏng được phân loại và gán khối lượng riêng thực nghiệm (`density_g_per_ml`) để hỗ trợ việc tính toán dinh dưỡng theo thể tích (ml) trong công thức nấu ăn:
- Nhóm dầu, mỡ: $0.92\text{ g/ml}$
- Nước mắm: $1.18\text{ g/ml}$
- Nước tương, xì dầu: $1.15\text{ g/ml}$
- Mật ong: $1.42\text{ g/ml}$
- Sữa tươi: $1.03\text{ g/ml}$
- Sữa đặc có đường: $1.30\text{ g/ml}$
- Các nguyên liệu thông thường khác: $1.00\text{ g/ml}$

### 3.4. Chuẩn hóa nhãn dị ứng và loại trừ nhầm lẫn từ vựng
Thuật toán gán nhãn dị ứng tự động sử dụng biểu thức chính quy có giới hạn từ (Word boundary), kết hợp các điều kiện phủ định nhằm tránh gán nhầm dị ứng:
- Không nhận nhầm "Gạo nếp cái" thành hải sản (loại trừ từ "cái").
- Không nhận nhầm "Quả trứng gà" (quả lêkima) hoặc "Đậu trứng cuốc" thành dị ứng trứng gia cầm.
- Không nhận nhầm "Cá mè" thành dị ứng mè/vừng.
- Không nhận nhầm "Ruốc thịt lợn" thành dị ứng thủy hải sản.
- Không nhận nhầm "Quả bơ" hoặc "Sữa đậu nành" thành dị ứng sữa động vật.

---

## 4. Phương thức Nhập Dữ liệu lên Supabase

1. **Khởi tạo DDL:** Áp dụng tệp di chuyển cấu trúc `20261005000001_create_ingredients_schema.sql` thông qua công cụ Supabase MCP (`apply_migration`).
2. **Khởi tạo danh mục và dị ứng:** Thực thi `20261005000002_seed_categories_and_allergens.sql` nạp 15 nhóm thực phẩm và 8 nhóm dị ứng.
3. **Nạp dữ liệu 620 nguyên liệu:** Sử dụng kịch bản thực thi theo lô (batch execution) thông qua giao tiếp bảo mật với cơ sở dữ liệu. Mọi câu lệnh chèn đều áp dụng cơ chế `ON CONFLICT (code) DO UPDATE` để đảm bảo tính bất biến (Idempotent), tránh tạo bản ghi trùng lặp khi chạy lại kịch bản.
4. **Nạp dữ liệu liên kết dị ứng:** Thực thi `20261005000004_seed_ingredient_allergens.sql` nạp 141 mối liên kết dị ứng chính xác.

---

## 5. Kết quả Kiểm định Thực tế

Truy vấn đối soát trực tiếp trên cơ sở dữ liệu Supabase:

```sql
SELECT 
  (SELECT count(*) FROM ingredient_categories) AS categories_count,
  (SELECT count(*) FROM allergens) AS allergens_count,
  (SELECT count(*) FROM ingredients) AS ingredients_count,
  (SELECT count(*) FROM ingredient_allergens) AS ingredient_allergens_count;
```

**Kết quả đối soát:**

| Đối tượng | Số lượng bản ghi | Đánh giá |
| :--- | :---: | :--- |
| `ingredient_categories` | 15 | Đầy đủ 15 nhóm theo danh mục chuẩn Bộ Y tế |
| `allergens` | 8 | Đầy đủ 8 nhóm dị ứng phổ biến |
| `ingredients` | 620 | Đầy đủ 100% nguyên liệu theo ấn bản 2017 |
| `ingredient_allergens` | 141 | Đã làm sạch, không tồn tại bản ghi sai lệch |

### Kiểm tra mẫu dữ liệu truy vấn liên kết:
- `01001` (Gạo nếp cái): Danh mục "Ngũ cốc", Dị ứng `[]` (Chính xác, không bị gán nhầm).
- `01012` (Bánh mỳ): Danh mục "Ngũ cốc", Dị ứng `["Gluten"]`.
- `03007` (Đậu tương): Danh mục "Hạt, quả giàu đạm", Dị ứng `["Đậu nành"]`.
- `08001` (Cá bống): Danh mục "Thủy sản", Dị ứng `["Hải sản"]`.
- `10001` (Sữa bò tươi): Danh mục "Sữa", Dị ứng `["Sữa & Chế phẩm từ sữa"]`.

Hệ thống cơ sở dữ liệu nền tảng đã sẵn sàng phục vụ cho việc tích hợp tính toán thể trạng người dùng và xây dựng tập dữ liệu công thức món ăn (Recipe Dataset).
