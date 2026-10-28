# Báo cáo Kỹ thuật: Thiết kế Lược đồ Cơ sở Dữ liệu Món ăn & Động cơ Dinh dưỡng Tự động

- **Đơn vị thực hiện:** Nhóm sinh viên thực hiện Đồ án 1
- **Phụ trách kỹ thuật:** Nguyễn Minh Anh
- **Giai đoạn:** Sprint 4 (Tuần 5 & 6)
- **Nền tảng triển khai:** Supabase PostgreSQL (Project ID: `iwmnkygicqfesvbilmrw`, Khu vực: Singapore - `ap-southeast-1`)

---

## 1. Mục tiêu Kỹ thuật

1. **Thiết kế Lược đồ Dữ liệu Món ăn Quan hệ (Relational Recipe Schema):** Xây dựng các thực thể bảng lưu trữ thông tin công thức nấu ăn, chi tiết thành phần nguyên liệu và danh mục chất gây dị ứng kế thừa.
2. **Động cơ Tính toán Dinh dưỡng Tự động (Automated Nutrition Aggregation Engine):** Tự động tổng hợp và tính toán chính xác chỉ số Calo, Protein, Chất béo (Fat), Tinh bột (Carbohydrate), Chất xơ (Fiber) và Natri (Sodium) trên toàn bộ món ăn và trên từng khẩu phần ăn tiêu chuẩn (`per serving`).
3. **Kế thừa và Nhận diện Tác nhân Dị ứng (Allergen Inheritance):** Tự động phát hiện các chất gây dị ứng tiềm ẩn trong món ăn dựa trên liên kết khóa ngoại với bảng `ingredient_allergens` và các luật ẩm thực đặc thù (nước mắm, mắm tôm, xì dầu, trứng...).
4. **Bảo mật & Tối ưu hóa Truy vấn (Security & Performance):** Áp dụng Row Level Security (RLS) cho phép đọc công khai (`anon`), phân quyền quản trị và đánh chỉ mục B-tree trên các trường tra cứu tần suất cao (`slug`, `category`, `cuisine`, `is_vegetarian`).

---

## 2. Thiết kế Lược đồ Cơ sở Dữ liệu (Database Schema)

Lược đồ cơ sở dữ liệu được mở rộng và tích hợp chặt chẽ với cơ sở dữ liệu dinh dưỡng Viện Dinh Dưỡng đã thiết lập tại Sprint 3:

```
+------------------------------------+
|            public.recipes          |
+------------------------------------+
| id (PK, UUID)                      |
| title (VARCHAR), slug (UNIQUE)     |
| description, instructions (JSONB)  |
| image_url, servings, times         |
| calories_per_serving, macros...    |
+------------------------------------+
         | 1                      | 1
         |                        |
         | N                      | N
+--------------------+   +-----------------------+
| recipe_ingredients |   |   recipe_allergens    |
+--------------------+   +-----------------------+
| id (PK, UUID)      |   | recipe_id   (PK, FK)  |---+
| recipe_id (FK) ----+   | allergen_id (PK, FK)  |---+
| ingredient_id (FK) |   +-----------------------+   |
| amount, unit, g    |                               |
| calories, macros...|                               |
+--------------------+                               |
         | N                                         |
         v 1                                         v 1
+--------------------+                   +--------------------+
| public.ingredients |                   |  public.allergens  |
| (620 VDD 2017)     |                   |  (8 Nhóm dị ứng)   |
+--------------------+                   +--------------------+
```

### 2.1. Bảng `public.recipes` (Công thức món ăn)
Lưu trữ thông tin tổng thể của món ăn, bao gồm các chỉ số dinh dưỡng đã tổng hợp sẵn để phục vụ hiển thị nhanh (pre-computed values):
- `id` (UUID, Primary Key, Mặc định `gen_random_uuid()`): Định danh duy nhất.
- `title` (VARCHAR(255), Not Null): Tên món ăn tiếng Việt.
- `slug` (VARCHAR(255), Unique, Not Null): Chuỗi định danh URL thân thiện cho SEO.
- `description` (TEXT): Tóm tắt hương vị và đặc trưng món ăn.
- `instructions` (JSONB, Not Null): Danh sách các bước nấu dạng mảng đối tượng `[{"step": 1, "content": "..."}]`.
- `image_url` (TEXT): Đường dẫn ảnh minh họa độ phân giải cao thu thập từ nguồn ẩm thực.
- `video_url` (TEXT): Đường dẫn video clip hướng dẫn nấu ăn chuẩn từng bước (YouTube HD).
- `servings` (INT, Default 4): Số khẩu phần ăn tiêu chuẩn.
- `prep_time_minutes` (INT): Thời gian sơ chế (phút).
- `cook_time_minutes` (INT): Thời gian nấu nướng (phút).
- `difficulty` (VARCHAR(20), Default 'medium'): Độ khó ('easy', 'medium', 'hard').
- `cuisine` (VARCHAR(50), Default 'vietnamese'): Nền ẩm thực.
- `category` (VARCHAR(50)): Phân loại món ('kho', 'xao', 'canh', 'chay', 'bun_mi', 'chua').
- `is_vegetarian` (BOOLEAN, Default false): Cờ đánh dấu món chay.
- `calories_per_serving` (NUMERIC(8,2)): Lượng calo trên 1 khẩu phần (kcal).
- `protein_g_per_serving` (NUMERIC(8,2)): Lượng protein trên 1 khẩu phần (g).
- `fat_g_per_serving` (NUMERIC(8,2)): Lượng chất béo trên 1 khẩu phần (g).
- `carbs_g_per_serving` (NUMERIC(8,2)): Lượng carbohydrate trên 1 khẩu phần (g).
- `fiber_g_per_serving` (NUMERIC(8,2)): Lượng chất xơ trên 1 khẩu phần (g).
- `sodium_mg_per_serving` (NUMERIC(8,2)): Lượng natri trên 1 khẩu phần (mg).
- `created_at`, `updated_at` (TIMESTAMPTZ): Thời điểm khởi tạo và cập nhật.

### 2.2. Bảng `public.recipe_ingredients` (Chi tiết thành phần nguyên liệu)
Lưu trữ định lượng từng nguyên liệu cấu thành món ăn và liên kết trực tiếp với bảng nguyên liệu chuẩn:
- `id` (UUID, Primary Key, Mặc định `gen_random_uuid()`).
- `recipe_id` (UUID, Foreign Key -> `public.recipes.id` ON DELETE CASCADE).
- `ingredient_id` (UUID, Nullable, Foreign Key -> `public.ingredients.id` ON DELETE SET NULL): Khóa ngoại trỏ đến 620 nguyên liệu Viện Dinh Dưỡng.
- `order_index` (INT, Default 0): Thứ tự xuất hiện trong danh sách nguyên liệu.
- `raw_text` (TEXT, Not Null): Chuỗi nguyên liệu nguyên bản thu thập từ nguồn.
- `ingredient_name_raw` (VARCHAR(255), Not Null): Tên nguyên liệu đã làm sạch.
- `amount` (NUMERIC(10,2)): Số lượng theo đơn vị tự nhiên.
- `unit` (VARCHAR(50)): Đơn vị đo tự nhiên ('gram', 'muỗng canh', 'quả', 'củ'...).
- `amount_g` (NUMERIC(10,2), Not Null): Khối lượng quy đổi tương đương sang gam.
- `calories_per_100g`, `protein_per_100g`, `fat_per_100g`, `carbs_per_100g`, `fiber_per_100g`, `sodium_mg_per_100g` (NUMERIC(8,2)): Chỉ số dinh dưỡng cơ sở trên 100g của nguyên liệu đó.

### 2.3. Bảng `public.recipe_allergens` (Bảng liên kết chất gây dị ứng)
Quản lý các dị ứng tố mà món ăn có thể gây ra cho người dùng:
- `recipe_id` (UUID, Foreign Key -> `public.recipes.id` ON DELETE CASCADE).
- `allergen_id` (INT, Foreign Key -> `public.allergens.id` ON DELETE CASCADE).
- **Primary Key kép:** `(recipe_id, allergen_id)`.

---

## 3. Động cơ Tính toán Dinh dưỡng (Nutrition Engine)

### 3.1. Thuật toán Tổng hợp Dinh dưỡng Món ăn
Để cung cấp các chỉ số dinh dưỡng đáng tin cậy cho từng khẩu phần ăn, hệ thống áp dụng công thức tính toán lũy tích trên từng nguyên liệu liên kết:

Đối với mỗi chất dinh dưỡng $X$ (Calo, Protein, Lipid, Glucid, Fiber, Natri), hàm lượng trong món ăn được tính như sau:

$$X_{\text{total}} = \sum_{i=1}^{n} \left( \frac{\text{amount\_g}_i}{100} \times X_{\text{per\_100g}, i} \right)$$

Hàm lượng dinh dưỡng trên mỗi khẩu phần ăn (`per serving`):

$$X_{\text{per\_serving}} = \frac{X_{\text{total}}}{\text{servings}}$$

Trong đó:
- $n$: Tổng số nguyên liệu có liên kết trong công thức món ăn.
- $\text{amount\_g}_i$: Khối lượng gam của nguyên liệu thứ $i$ đã được quy đổi.
- $X_{\text{per\_100g}, i}$: Hàm lượng chất dinh dưỡng $X$ trên 100 gam thực phẩm lấy từ Bảng thành phần thực phẩm Việt Nam (FCT 2017).
- $\text{servings}$: Số khẩu phần quy định của món ăn (mặc định 4 phần).

### 3.2. Cơ chế Kế thừa và Cảnh báo Dị ứng (Allergen Inheritance)
Hệ thống sử dụng ma trận suy luận hai tầng:
1. **Tầng 1 (Kế thừa từ khóa ngoại cơ sở dữ liệu):**
   Nếu một nguyên liệu $I$ trong món ăn có liên kết với bảng `ingredient_allergens` thông qua mã `ingredient_id`, món ăn đó tự động kế thừa toàn bộ các `allergen_id` liên kết.
2. **Tầng 2 (Luật suy luận ẩm thực bổ sung):**
   Đối với các gia vị chế biến sâu hoặc đặc thù không phân rã thành nguyên liệu thô đơn lẻ:
   - Các món có chứa *nước mắm*, *mắm tôm*, *mắm tép*, *mắm cá* -> Tự động gắn nhãn Dị ứng Hải sản (`allergen_id = 1`).
   - Các món có chứa *xì dầu*, *nước tương*, *đậu hũ*, *chao* -> Gắn nhãn Dị ứng Đậu nành (`allergen_id = 6`).
   - Các món có dùng *mì trứng*, *nui*, *bột mì* -> Gắn nhãn Dị ứng Gluten (`allergen_id = 7`).
   - Các món dùng *trứng gà*, *trứng cút* -> Gắn nhãn Dị ứng Trứng (`allergen_id = 2`).

---

## 4. Triển khai Nạp Dữ liệu & Đảm bảo Tính Toàn vẹn (Seeding Strategy)

### 4.1. Khắc phục Thách thức Kỹ thuật
Khi chuyển dịch dữ liệu lớn qua giao thức MCP SQL Execution, hai vấn đề kỹ thuật lớn đã được giải quyết triệt để:
1. **Không phụ thuộc vào UUID cứng (Dynamic Foreign Key Resolution):** Thay vì tạo UUID giả định dễ gãy vỡ, toàn bộ câu lệnh nạp nguyên liệu và dị ứng sử dụng truy vấn phụ động:
   ```sql
   (SELECT id FROM public.recipes WHERE slug = '<recipe_slug>')
   ```
   giúp đảm bảo tính toàn vẹn khóa ngoại (Referential Integrity) tuyệt đối.
2. **Kỹ thuật phân chia Payload (Chunking Strategy):** Để tránh tràn bộ đệm giao tiếp và quá thời gian chờ (timeout), dữ liệu 604 nguyên liệu được chia thành các phân đoạn từ 100 - 125 bản ghi (~25KB mỗi đợt gửi), thực thi tuần tự không lỗi.

---

## 5. Kết quả Kiểm định Thực tế trên Supabase

Truy vấn kiểm tra tổng số lượng bản ghi trên cơ sở dữ liệu Supabase:

```sql
SELECT 
  (SELECT count(*) FROM public.recipes) as total_recipes,
  (SELECT count(*) FROM public.recipe_ingredients) as total_recipe_ingredients,
  (SELECT count(*) FROM public.recipe_allergens) as total_recipe_allergens,
  (SELECT count(DISTINCT ingredient_id) FROM public.recipe_ingredients WHERE ingredient_id IS NOT NULL) as unique_linked_ingredients;
```

**Kết quả trả về:**
```json
[
  {
    "total_recipes": 45,
    "total_recipe_ingredients": 604,
    "total_recipe_allergens": 57,
    "unique_linked_ingredients": 77
  }
]
```

### 5.1. Kiểm thử Thực tế trên Món ăn Phức hợp
Kiểm tra món ăn *"Bún riêu cua đồng hải sản"* (`slug = 'cach-nau-bun-rieu-cua-dong-hai-san-ngon-dam-da'`):
- **Khẩu phần:** 4 người ăn.
- **Thời gian:** Chuẩn bị 15 phút, nấu 30 phút.
- **Dinh dưỡng tính toán tự động:**
  - Năng lượng: $450.80\text{ kcal / khẩu phần}$
  - Protein: $86.70\text{ g / khẩu phần}$
  - Lipid (Fat): $4.90\text{ g / khẩu phần}$
  - Glucid (Carbs): $15.10\text{ g / khẩu phần}$
  - Natri: $5585.50\text{ mg / khẩu phần}$
- **Tác nhân dị ứng kế thừa tự động:**
  - `Hải sản (Tôm, Cua, Mực, Cá)`
  - `Đậu nành & Chế phẩm đậu nành`
- **Số lượng nguyên liệu bóc tách:** 16 nguyên liệu chi tiết (cua đồng, mực tươi, tôm đồng, cà chua, hành tím, đậu hũ, bún tươi, ngò gai, gia vị...).

---

## 6. Hướng dẫn Tích hợp Phía Ứng dụng (Client Integration)

### 6.1. Lưu trữ Hình ảnh & Video Hướng dẫn
- **Hình ảnh Món ăn:** 100% ảnh món ăn được lưu trữ vĩnh viễn trên **Supabase Storage** (Bucket `recipe-images`, chế độ Public). Đường dẫn CDN trực tiếp có dạng:
  ```
  https://iwmnkygicqfesvbilmrw.supabase.co/storage/v1/object/public/recipe-images/<slug>.jpg
  ```
- **Video Hướng dẫn Nấu ăn:** Cột `video_url` chứa liên kết YouTube HD chính thức, quay cận cảnh từng bước thực hiện tương ứng với công thức nấu.

### 6.2. API Tìm kiếm & Lọc Món ăn Nâng cao (`public.search_recipes`)
Phía client (Flutter / React Native) có thể gọi trực tiếp hàm RPC `search_recipes` để tìm kiếm theo từ khóa, lọc theo nhóm món, lọc món chay, giới hạn calo và **loại trừ các món chứa chất gây dị ứng** của người dùng trong một lượt gọi mạng duy nhất:

```typescript
// Gọi RPC tìm kiếm và lọc món ăn từ Supabase Client SDK
const { data: recipes, error } = await supabase.rpc('search_recipes', {
  p_query: 'gà',                         // Tìm theo từ khóa (tùy chọn)
  p_category: 'mon_man',                  // Lọc theo nhóm (tùy chọn)
  p_is_vegetarian: false,                 // Lọc món chay (tùy chọn)
  p_max_calories: 500.0,                  // Giới hạn calo tối đa trên 1 khẩu phần (tùy chọn)
  p_exclude_allergen_ids: [1, 6],         // Loại trừ dị ứng (VD: 1 = Hải sản, 6 = Đậu nành)
  p_limit: 20,                            // Số bản ghi trả về
  p_offset: 0                             // Phân trang
});
```

