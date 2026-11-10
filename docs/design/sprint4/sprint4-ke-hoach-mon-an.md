# Sprint 4: Kế hoạch thiết kế màn Tìm kiếm món & Chi tiết món (tái sử dụng prototype Figma Make)

Cập nhật: 27/10/2026 · Thay cho kế hoạch dùng Stitch (đã bỏ vì Stitch cho kết quả kém hơn Make).
Nguồn: Figma Make "Nutrition Tracking App" (`RecipesScreen`, `RecipeDetailScreen`, `RecipeCard` trong `src/App.tsx`) · Figma Elytra (trang 824:2) · DB `create_recipes_schema`.

## 0. Ý tưởng

Lấy **bố cục và thành phần** của 2 màn trong prototype làm gốc, **sửa những chỗ sai** so với hệ thống Elytra, **bổ sung** phần còn thiếu, rồi dựng thành khung thật trong file Figma Elytra (layer gốc, auto layout, màu theo ElytraPalette). Bản Figma này là chuẩn để code Flutter.

```
Make (App.tsx: RecipesScreen, RecipeDetailScreen)
   │ 1. Đối chiếu: giữ / sửa / thêm
   ▼
Figma Elytra, trang "Sprint 4 – Món ăn"  (dựng lại bằng layer gốc, đúng palette, khung Android 390)
   │ 2. Vẽ thêm các trạng thái
   ▼
Review → handoff Flutter
```

Make đã dùng gần đúng bảng màu Elytra (biến CSS `--color-*` trùng token), nên phần lớn chỉ cần sửa font, vài mã màu cứng và màu macro.

## 1. Giữ nguyên từ prototype

**Màn Tìm kiếm (`RecipesScreen`)**
- Header trắng dính đầu trang, viền dưới `outline`.
- Thanh tìm kiếm bo 12, icon kính lúp bên trái, nền `background`.
- Hàng chip nhóm món cuộn ngang (chip đang chọn nền tối `text-primary`, chữ trắng).
- Dòng "N món" + nút sắp xếp; bottom sheet "Sắp xếp theo" với 7 tiêu chí (Calo thấp → cao, Protein / 100 kcal…).
- `RecipeCard`: ảnh 144 cao + lớp phủ gradient + chip nhóm món góc trái + tên món trên ảnh; phần dưới có dòng dinh dưỡng, thời gian, khẩu phần.
- Trạng thái "Không tìm thấy món nào".

**Màn Chi tiết (`RecipeDetailScreen`)**
- Ảnh hero 224 cao, gradient trên/dưới, nút quay lại nổi góc trái, tên món + chip nhóm món đè lên ảnh.
- Lưới 4 ô Calo / Protein / Carbs / Fat.
- Dòng thời gian chuẩn bị · thời gian nấu · khẩu phần.
- Thẻ "Nguyên liệu": danh sách dòng, tên trái, lượng phải (chữ xanh đậm).
- "Hướng dẫn": các bước đánh số trong ô vuông bo xanh.

## 2. Sửa (chỗ Make làm sai)

| # | Chỗ sai trong Make | Sửa thành |
|---|---|---|
| 1 | Font Outfit / Inter / JetBrains Mono | **Be Vietnam Pro** cho cả tiêu đề, nội dung và số |
| 2 | Khung iPhone 393×852, Dynamic Island, góc bo 48 | Khung **Android 390 × 826,5**, thanh trạng thái Android như các màn cũ |
| 3 | Màu cứng #10B981, #059669 (tab, nút, thanh điều hướng) | `primary` #16A34A / `primary-dark` #15803D |
| 4 | #1E293B (tiêu đề), #F1F5F9, #F8FAFC, #FFF1F2 | `text-primary`, `background`, `surface-variant`, `error-container` (theo quy tắc ver9) |
| 5 | Màu macro sai: Carbs xanh lá, Fat hồng (`NutriBadge`, lưới 4 ô) | Protein `protein` #0284C7 · Carbs `carbs` #D97706 · Fat `fat` #6366F1 (đúng ResultScreen). Calo dùng `text-primary` hoặc `primary` để không trùng màu Carbs |
| 6 | Icon lucide nét 1,75 (Flame, Dumbbell, Wheat, Droplet, ChefHat) | Bộ `app/assets/icons` (ic_flame, ic_protein, ic_kcal, ic_portion, ic_macro…) + Material Symbols cho icon còn thiếu (search, tune, schedule) |
| 7 | Thanh điều hướng 5 tab, có "Kế hoạch" | 4 tab: Trang chủ · Nhật ký · Món ăn · Cá nhân (Kế hoạch ngoài phạm vi). Dạng Material 3 NavigationBar |
| 8 | "bởi {authorName}", tags, tab "Yêu thích", nút tim, nút "Đóng góp" | **Bỏ**: DB chưa có (để Sprint sau) |
| 9 | Dòng dinh dưỡng thẻ món quá nhỏ (chữ 12, icon 10) | Kcal nổi bật (14/700), P/C/F dạng chấm màu + số |
| 10 | Vùng chạm nhỏ: nút quay lại 36, chip cao ~24 | ≥ 48×48 (vùng chạm), chip cao 32 |
| 11 | Số liệu dạng "38.5g" | Định dạng VN: "38,5 g", "1.968 kcal" |

## 3. Bổ sung (Make chưa có)

**Màn Tìm kiếm**
- Nút lọc (icon tune + badge số bộ lọc) bên phải thanh tìm kiếm.
- Hàng chip lọc nhanh: **"Từ tủ lạnh"**, **"Bỏ món dị ứng"** (bật sẵn), "< 500 kcal", "≤ 30 phút" (Lưu ý.txt yêu cầu giữ lọc tủ lạnh và dị ứng).
- Bottom sheet **Bộ lọc**: khoảng calo, thời gian, độ khó, nhóm món, nguyên liệu trong tủ lạnh, công tắc dị ứng; "Xóa lọc" / "Xem N món".
- Trạng thái: chưa nhập (tìm gần đây + món phổ biến), đang tải (skeleton), mất mạng.
- Nút AI tròn góc phải dưới (Lưu ý.txt).

**Màn Chi tiết**
- Dòng phụ dưới tên: `cuisine` · độ khó (`difficulty`).
- Banner **cảnh báo dị ứng** (`error-container`) khi món chứa chất người dùng đã khai báo.
- Dòng "≈ 61 % calo bữa trưa của bạn" dưới lưới 4 ô (chia bữa 25/35/30/10).
- Bộ chọn **khẩu phần −/+** trên thẻ Nguyên liệu (nhân `amount`), gam ở chữ mờ (`amount_g`).
- Mục **Thông tin dinh dưỡng** (yêu cầu Sprint): bảng mỗi khẩu phần gồm kcal, protein, carbs, fat, **chất xơ**, **natri** + thanh % mục tiêu ngày; có thể tái dùng donut từ ResultScreen.
- Thứ tự nội dung: Nguyên liệu → Cách nấu → Dinh dưỡng. Dài thì chuyển thành 3 tab dính.
- Nút ghim đáy "Thêm vào bữa …" (chờ chốt cách ghi `meal_logs`).

## 4. Các bước (≈ 3–3,5 ngày)

| Bước | Việc | Thời lượng | Kết quả |
|---|---|---|---|
| B1 | Chốt bảng giữ/sửa/thêm (mục 1–3) với nhóm | 0,5 ngày | Danh sách đã duyệt |
| B2 | Dựng **RecipeCard** thành component trong Figma (biến thể: thường / có cảnh báo dị ứng / skeleton) | 0,5 ngày | Component dùng chung, map với `RecipeCard` của api-contract |
| B3 | Dựng màn Tìm kiếm theo bố cục Make + sửa + thêm; vẽ 6 trạng thái (chưa nhập, có kết quả, bộ lọc, sắp xếp, không có kết quả, đang tải) | 1 ngày | Khung `RecipeSearchScreen – …` |
| B4 | Dựng màn Chi tiết; trạng thái mặc định, có dị ứng, đổi khẩu phần, đang tải | 1 ngày | Khung `RecipeDetailScreen – …` |
| B5 | Quét màu (0 màu ngoài palette), kiểm tra vùng chạm và nội dung dài (tên 2 dòng, 20 nguyên liệu, 12 bước), nhờ Minh Anh review | 0,5 ngày | Sẵn sàng code |

**Cách đưa sang Figma (B2–B4):** dựng lại bằng layer gốc trong file Elytra, lấy kích thước/khoảng cách từ class Tailwind trong `App.tsx`. Không dán thẳng bản Make vì sẽ kéo theo font, màu cứng và khung iPhone, sửa lại còn lâu hơn. Claude có thể dựng phần này trực tiếp vào file Elytra qua Figma.

**Khi code Flutter:** `App.tsx` là tài liệu tham khảo cấu trúc tốt: `RecipeCard` → `RecipeCard` widget, `NutriBadge` → `MacroRow`, bottom sheet sắp xếp → `showModalBottomSheet`, logic sắp xếp (`proteinScore`, `carbScore`…) chuyển sang truy vấn Supabase.

## 4b. Tiến độ (27/10/2026)

Đã dựng trong Figma Elytra, trang **"Sprint 4 – Món ăn"** (833:2):

- **Components – Sprint 4** (835:2): `RecipeCard` (Mặc định / Dị ứng / Đang tải), `Chip` (Lọc Bật/Tắt, Nhóm món Bật/Tắt), `NavigationBar / Món ăn` (4 tab), `FAB / Trợ lý AI`.
- **RecipeSearchScreen**, 7 khung 390 × 826,5: Có kết quả (836:2) · Chưa nhập/đang focus (839:557) · Bộ lọc (837:184) · Sắp xếp (837:304) · Không có kết quả (839:673) · Đang tải (839:892) · Mất mạng (839:1099).
- Kiểm tra: 0 màu ngoài ElytraPalette, 100 % chữ Be Vietnam Pro, icon Material Symbols Outlined (cùng bộ với `assets/icons`).
- Ảnh món đang dùng tạm ảnh `welcome_food_bowl` cho mọi thẻ; khi có `image_url` thật thì thay.
- Lưu ý khi code: chip, nút sắp xếp cao 32 và nút xóa từ khóa 24 → bọc vùng chạm 48 (`materialTapTargetSize`/`IconButton`).

- Bộ lọc: mục "Calo mỗi khẩu phần" đã đổi sang **2 ô nhập Tối thiểu / Tối đa** (phương án A, đã chốt). Bảng lọc cao ~739 px → khi code cho nội dung cuộn, giữ footer cố định.

**Màn Chi tiết món (B4):** Figma MCP chạm giới hạn lượt gọi của gói Starter, nên màn này được đóng gói thành plugin chạy 1 lần: `Claude outputs/figma-plugin-chi-tiet-mon/` (manifest.json + code.js). Plugin dựng 4 khung ở hàng y = 1100: Mặc định (toàn trang) · Có cảnh báo dị ứng · Đổi khẩu phần (đã cuộn, app bar thu gọn) · Đang tải; và xoá khung Bộ lọc phương án B.
Nội dung màn: hero 240 + nút quay lại, chip nhóm món, "Việt Nam · Dễ"; lưới 4 ô Calo/P/C/F; "≈ 35% calo bữa trưa"; Nguyên liệu (stepper khẩu phần, lượng + quy đổi gam); Cách nấu (bước đánh dấu xong); Thông tin dinh dưỡng (tỉ lệ năng lượng, 6 chất với % mục tiêu ngày, cảnh báo natri); nút ghim "Thêm vào bữa trưa".

## 4c. Review lần 1 (27/10/2026, từ file Elytra.fig xuất sau khi chạy plugin)

Đã có đủ 4 khung Chi tiết món, khung Bộ lọc phương án B đã xoá, không có chỉnh sửa nào khác ngoài plugin.

Lỗi cần sửa (script `figma-plugin-chi-tiet-mon/fix-review-1.js`):
- Dòng Meta (Chuẩn bị · Nấu · 2 khẩu phần) tràn lề phải 12 px ở 3 khung → "2 phần", gap 12.
- Chú thích nguồn cuối mục Dinh dưỡng không xuống dòng, tràn 74 px → rộng 342, tự xuống dòng.
- Chữ thông tin dùng text-subtle #94A3B8 (2,4:1) → text-muted #64748B: gợi ý cách nấu, chú thích nguồn, số gam quy đổi, ghi chú lọc dị ứng.

Đã chốt (27/10) và gộp vào `fix-review-2.js` (thay cho fix-review-1):
- Nút −/+ khẩu phần **chỉ nhân lượng nguyên liệu để nấu**. Thêm nhãn "Nấu cho"; nút ghim → "Thêm 1 phần vào bữa trưa"; dinh dưỡng luôn tính 1 phần.
- Màn có cảnh báo dị ứng: giữ nguyên hành vi, không thêm bước xác nhận.
- Palette thêm token **fat-outline #C7D2FE** (29 token); ô Fat dùng viền này.

Tương phản (chốt 27/10, gộp vào `fix-review-3.js` – thay cho fix-review-1/2, áp dụng cho cả trang Elytra):
- on-error-container **#BE123C** (5,2:1) cho chữ đỏ trên nền cảnh báo.
- on-fat-container **#4F46E5** (5,6:1) cho số Fat trên fat-container.
- Nút chính có chữ trắng: nền **primary-dark #15803D** (5,0:1). primary #16A34A giữ cho icon, thanh, công tắc, FAB.
- text-muted **#64748B → #5B6B80** (≥ 4,5:1 trên mọi nền đang dùng). text-subtle #94A3B8 chỉ dùng cho icon/đường kẻ, không dùng cho chữ.
- Palette: 31 token (thêm fat-outline, on-fat-container, on-error-container).

Review sau fix-review-3 (27/10): màn Chi tiết, nút chính, chữ đỏ, số Fat, text-muted trên màn đều đã đúng; không còn chữ tràn lề. Còn sót: khung ElytraPalette chưa cập nhật, 4 dòng chữ nhiều màu ("Chưa có tài khoản? Tạo tài khoản") còn #64748B, 6 nút vô hiệu còn #16A34A 40% → `fix-review-4.js`.
Sau fix-review-4: chữ nhiều màu và nút vô hiệu đã đúng; ô màu trong palette vẫn chưa thêm vì các ô là GROUP (script tìm FRAME) → `fix-review-5.js` chỉ sửa palette.
Sau fix-review-5: palette đủ 3 ô mới, text-muted #5B6B80; màn Tìm kiếm + Chi tiết đạt AA, không tràn lề. Còn 2 chỉnh nhỏ (`fix-review-6.js`): mô tả ô text-subtle tràn thẻ; 13 icon nét (stroke) còn #64748B. Màu gốc #64748B của 4 dòng chữ hai màu không hiển thị (mọi ký tự đã có màu riêng) nên để nguyên.

Việc của code (`AppColors` trong `lib/core/theme.dart`):
- Sửa: `textMuted` 0xFF5B6B80, `outlineStrong` 0xFFD1DCE8, `primaryDisabled` = primaryDark 40% (0x6615803D); nút chính dùng nền `primaryDark`.
- Thêm: primarySurface F0FDF4, primaryOutline BBF7D0, surfaceVariant F8FAFC, placeholder CBD5E1, protein 0284C7 / proteinContainer E0F2FE / onProteinContainer 075985 / proteinOutline BAE6FD, carbs D97706 / carbsContainer FEF3C7 / onCarbsContainer 92400E / carbsOutline FDE68A, fat 6366F1 / fatContainer EEF2FF / onFatContainer 4F46E5 / fatOutline C7D2FE, onErrorContainer BE123C.

## 5. Việc cần chốt với nhóm

1. Nút "Thêm vào bữa…" ghi `meal_logs` thế nào (câu hỏi số 4 trong api-contract). Chưa chốt thì vẽ nút, code để "Sắp có".
2. Tìm kiếm không dấu: `recipes` chưa có cột kiểu `name_unaccented` → cần cột hoặc `unaccent` để gõ "pho" ra "phở".
3. Danh sách giá trị `category` thật (hiện mặc định `mon_man`) để vẽ chip nhóm món đúng.
4. "Yêu thích", tác giả, tags: để Sprint sau hay cần bảng mới.
5. Nhỏ: `AppColors.outlineStrong` trong code là #CBD5E1, palette ghi #D1DCE8 → nên thống nhất.
