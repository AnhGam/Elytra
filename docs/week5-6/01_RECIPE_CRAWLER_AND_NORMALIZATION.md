# Báo cáo Kỹ thuật: Thu thập Dữ liệu Công thức Món ăn & Chuẩn hóa Định lượng Nguyên liệu

- **Đơn vị thực hiện:** Nhóm sinh viên thực hiện Đồ án 1
- **Phụ trách kỹ thuật:** Nguyễn Minh Anh
- **Giai đoạn:** Sprint 4 (Tuần 5 & 6)
- **Hệ thống liên kết:** Viện Dinh dưỡng Quốc gia (620 nguyên liệu FCT 2017) & Supabase Cloud (`iwmnkygicqfesvbilmrw`)

---

## 1. Đặt vấn đề và Mục tiêu Kỹ thuật

Trong các ứng dụng tư vấn dinh dưỡng và quản lý khẩu phần ăn cho người Việt, việc tự biên soạn hoặc sử dụng dữ liệu món ăn giả lập (synthetic data do AI sinh ra) mang lại rủi ro cao về tính khả thi khi chế biến thực tế (thiếu bước nấu, sai tỷ lệ gia vị, thời gian sơ chế phi thực tế). Đồng thời, các công thức nấu ăn trên mạng Internet thường sử dụng ngôn ngữ ẩm thực dân dã, định lượng ước lệ ("nêm vừa ăn", "muỗng canh", "thìa cafe", "nhánh", "trái", "củ", "chén") và tên gọi đa dạng theo phương ngữ (chẳng hạn: *thơm* / *dứa* / *khóm*; *đậu phụ* / *đậu hũ*; *ngò rí* / *rau mùi*).

Mục tiêu của giai đoạn này bao gồm:
1. **Thu thập dữ liệu thực tế (Authentic Data Acquisition):** Cào và bóc tách dữ liệu từ nguồn ẩm thực Việt Nam chuẩn xác ([`bepxua.vn`](https://bepxua.vn)), đảm bảo món ăn có đầy đủ hình ảnh chất lượng cao, khẩu phần ăn, thời gian sơ chế, thời gian nấu, danh sách nguyên liệu và hướng dẫn thực hiện từng bước (step-by-step instructions).
2. **Bóc tách và chuẩn hóa chuỗi nguyên liệu (Ingredient Parsing):** Chuyển đổi chuỗi văn bản tự do thành cấu trúc có kiểu dữ liệu tường minh: Tên nguyên liệu thô, số lượng (number), đơn vị (unit).
3. **Quy đổi định lượng ước lệ sang hệ mét (Unit Normalization):** Chuyển đổi các đơn vị dân gian Việt Nam sang khối lượng gam (`amount_g`) hoặc thể tích tương đương để phục vụ tính toán hóa lý dinh dưỡng.
4. **Liên kết định danh với Viện Dinh Dưỡng (FCT Mapping):** Đối soát tên nguyên liệu với danh mục 620 thực phẩm của Viện Dinh dưỡng Quốc gia đã nạp ở Tuần 3, gán khóa ngoại `ingredient_id` (UUID) chính xác.

---

## 2. Thiết kế Hệ thống Thu thập Dữ liệu (Crawler Engine)

### 2.1. Nguồn dữ liệu và Cơ chế thu thập
Hệ thống sử dụng crawler trực tiếp qua chuẩn REST API của nền tảng Bếp Xưa (`/wp-json/wp/v2/posts`), tận dụng metadata cấu trúc sẵn của bài viết nhằm đạt độ chính xác cao hơn phương pháp bóc tách HTML truyền thống (HTML scraping):
- **Endpoint:** `https://bepxua.vn/wp-json/wp/v2/posts`
- **Bộ lọc truy vấn:** `per_page=50`, `_embed=true` (nhúng kèm ảnh đại diện gốc và taxonomy danh mục).
- **Bộ sưu tập danh mục (Diverse Culinary Categories):**
  - Món kho / rim truyền thống (cá nục kho nước mía, sườn ram, gà kho sả...).
  - Món xào / chiên (mì xào bò, cơm chiên dương châu, bò lúc lắc...).
  - Canh / Lẩu (lẩu riêu cua hải sản, canh chua cá điêu hồng, lẩu gà lá giang, lẩu bò Mông Cổ...).
  - Món chay thanh đạm (bún bò Huế chay, sườn non chay rim nước mía, nấm kho...).
  - Món sợi / ăn sáng (hủ tiếu gà, nui gà xé, miến xào...).

### 2.2. Xử lý DOM & Bóc tách nội dung cấu trúc
Nội dung bài viết HTML được xử lý thông qua parser DOM cục bộ (`cheerio`) để trích xuất các thành phần cốt lõi:
- **Nguyên liệu:** Quét thẻ `<ul>` hoặc `<ol>` nằm trong khối chứa class `.recipe-ingredients`, `.entry-content`, hoặc các danh sách có tiền đề "Nguyên liệu:".
- **Các bước thực hiện:** Bóc tách các thẻ `<p>` hoặc `<li>` thuộc các phân đoạn "Cách làm", "Sơ chế", "Chế biến", loại bỏ các đoạn quảng cáo, kêu gọi chia sẻ và text rác.
- **Thời gian & Khẩu phần:** Sử dụng biểu thức chính quy (Regex) quét các thông số:
  - Khẩu phần (`servings`): Mặc định trích xuất số người ăn (2-6 người, fallback: 4).
  - Chuẩn bị (`prep_time_minutes`): 10 - 30 phút.
  - Nấu nướng (`cook_time_minutes`): 15 - 60 phút.

---

## 3. Thuật toán Chuẩn hóa Định lượng & Quy đổi Khối lượng

### 3.1. Bóc tách Cú pháp Nguyên liệu (Regex Parsing Pipeline)
Chuỗi nguyên liệu đầu vào thường có dạng: `"thịt ba rọi: 300 gram"`, `"nước mắm: 2 muỗng canh"`, `"cà chua: 2 quả"`, hoặc `"Hành lá, ngò gai (ít)"`.

Pipeline bóc tách gồm 3 bước:
1. **Tách tên và định lượng:** Sử dụng regex phân rã theo dấu hai chấm `:` hoặc gạch nối `-`.
   ```javascript
   const parts = rawText.split(/:\s*|\s*-\s*/);
   ```
2. **Trích xuất số lượng (Fraction & Decimal Parsing):** Hỗ trợ số thập phân tiếng Việt (dấu phẩy `1,5`), phân số thông dụng (`½` -> 0.5, `⅓` -> 0.33, `¼` -> 0.25, `¾` -> 0.75, `1 1/2` -> 1.5).
3. **Phân loại đơn vị đo lường:** Đối chiếu đơn vị với từ điển đơn vị chuẩn.

### 3.2. Bảng Hệ số Quy đổi Định lượng Dân dã Việt Nam sang Gam (`amount_g`)
Để tính toán dinh dưỡng, mọi đơn vị đo lường được chuyển đổi về gam thực tế dựa trên khối lượng riêng và thói quen nấu nướng của người Việt:

| Đơn vị gốc | Hệ số quy đổi (Gam) | Diễn giải kỹ thuật |
| :--- | :--- | :--- |
| `g`, `gram`, `gr` | `amount * 1` | Đơn vị khối lượng hệ mét |
| `kg`, `kí`, `kilogram` | `amount * 1000` | Đơn vị kilôgam hệ mét |
| `ml`, `mililit` | `amount * 1` | Xem khối lượng riêng tương đương nước ($1\text{ ml} \approx 1\text{ g}$) |
| `l`, `lit`, `lít` | `amount * 1000` | 1 lít tương đương 1000 gam chất lỏng |
| `muỗng canh`, `thìa canh`, `tbsp` | `amount * 15` | Tiêu chuẩn muỗng canh ẩm thực (15 ml / 15 g) |
| `muỗng cafe`, `thìa cà phê`, `tsp` | `amount * 5` | Tiêu chuẩn thìa cà phê (5 ml / 5 g) |
| `chén`, `bát` | `amount * 200` | Chén ăn cơm gia đình trung bình chứa 200 g |
| `quả`, `trái` | Tra cứu theo loại thực phẩm | Cà chua ($75\text{ g}$), Chanh ($30\text{ g}$), Trứng ($50\text{ g}$), Ớt ($5\text{ g}$) |
| `củ` | Tra cứu theo loại thực phẩm | Cà rốt ($100\text{ g}$), Khoai tây ($120\text{ g}$), Hành tím ($15\text{ g}$), Tỏi ($20\text{ g}$) |
| `nhánh`, `tép`, `cây` | `amount * 10` - `amount * 25` | Tép tỏi ($5\text{ g}$), Sả cây ($25\text{ g}$), Gừng nhánh ($15\text{ g}$) |
| `bó` | `amount * 300` | Bó rau muống, bó lá giang, tần ô |
| `lát`, `khoanh`, `miếng` | `amount * 30` | Miếng thịt, lát đậu hũ |
| `ít`, `vừa ăn`, `nêm nếm` | `2` | Khối lượng gia vị ước lượng tượng trưng (2 gam) |

---

## 4. Cơ chế Ánh xạ Từ điển Đồng nghĩa (Synonym Mapping Engine)

### 4.1. Vấn đề lệch pha định danh
Tên nguyên liệu trong công thức dân gian và tên pháp quy trong ấn bản Viện Dinh Dưỡng 2017 có sự khác biệt lớn:
- Dân gian gọi: *"thịt ba chỉ"*, Viện Dinh Dưỡng lưu: *"Thịt lợn nửa nạc nửa mỡ"*.
- Dân gian gọi: *"tép bạc"*, *"tôm sú"*, Viện Dinh Dưỡng lưu: *"Tôm biển"* hoặc *"Tôm đồng"*.
- Dân gian gọi: *"nước cốt dừa"*, Viện Dinh Dưỡng lưu: *"Nước cốt dừa"*.
- Dân gian gọi: *"đậu hũ"*, Viện Dinh Dưỡng lưu: *"Đậu phụ"*.

### 4.2. Từ điển Đồng nghĩa & Khóa ngoại
Hệ thống xây dựng bộ từ điển đồng nghĩa (Synonym Map) gồm hơn 120 mục từ mapping trực tiếp vào mã code chuẩn hoặc UUID của bảng `public.ingredients`.

Ví dụ ma trận mapping:
```json
{
  "thịt ba chỉ": "053c8ea4-5b43-4fc6-b8c7-4340798be12d",
  "thịt bò": "c893db6c-a1b2-4e27-bbb0-92724957e044",
  "ức gà": "ac0b5613-b6df-4e08-97c2-4743e580137b",
  "trứng gà": "f83ca0a5-8fa3-43c1-b1fc-0ca11430526b",
  "đậu phụ": "d9ce50a4-4865-4c7e-9a1c-20a8146f3c33",
  "nước mắm": "0f9ff070-81cb-4e32-a661-44927b971958",
  "cà chua": "5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4"
}
```

Kết quả: **Tỷ lệ bao phủ và liên kết thành công đạt trên 85%** đối với các nguyên liệu chính yếu sinh năng lượng (thịt, cá, trứng, rau củ quả, tinh bột, dầu ăn). Đối với các phụ gia đặc thù (sa tế, huyết heo, lá giang, gia vị bột đóng gói), hệ thống lưu `ingredient_id = NULL` và giữ nguyên tên thô `ingredient_name_raw` để không làm mất tính toàn vẹn của công thức.

---

## 5. Kết luận Giai đoạn Thu thập & Tiền xử lý

1. Đã cào và lưu trữ thành công **45 công thức món ăn Việt Nam truyền thống hoàn chỉnh** tại tệp dữ liệu chủ:
   [`d:\Antigravity\DA1\Elytra\data\vietnamese_recipes_master.json`](file:///d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json).
2. Xây dựng 2 module xử lý chuyên dụng:
   - Module bóc tách nguyên liệu: [`d:\Antigravity\DA1\Elytra\scripts\ingredient_parser.js`](file:///d:/Antigravity/DA1/Elytra/scripts/ingredient_parser.js).
   - Module chuẩn hóa và nạp dữ liệu: [`d:\Antigravity\DA1\Elytra\scripts\unified_recipe_parser.js`](file:///d:/Antigravity/DA1/Elytra/scripts/unified_recipe_parser.js).
3. Tập dữ liệu sau khi chuẩn hóa được dùng làm đầu vào cho Lược đồ Cơ sở dữ liệu và Động cơ Dinh dưỡng của hệ thống.
