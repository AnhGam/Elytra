# Sprint 5 – Thiết kế Dashboard, Ghi bữa ăn, Nhật ký

- Nguồn: Figma **Elytra**, trang "Sprint 5 – Dashboard & Nhật ký" (865:2): https://www.figma.com/design/pXJPotFfWA1Xmsottbf0mX/Elytra?node-id=865-2
- Kế hoạch và quyết định: `sprint5-ke-hoach-dashboard-nhat-ky.md` (project "Đồ án 1"). API: `docs/api-contract.md`, mục 4.
- Ảnh trong `screens/` (PNG 2x, khung 390 × 827) dựng lại từ Elytra.fig sau fix-review-1 (11/11/2026). Ảnh dùng để xem nhanh, cần số đo chính xác thì mở Figma theo node ID.

## Khung

| Ảnh | Khung Figma | Node |
|---|---|---|
| `components.png` | Components – Sprint 5 | 865:3 |
| `dashboard-01-co-du-lieu-toan-trang.png` | DashboardScreen – Có dữ liệu (toàn trang, cao 1488) | 867:26 |
| `dashboard-02-vuot-muc-tieu.png` | DashboardScreen – Vượt mục tiêu | 867:240 |
| `dashboard-03-chua-ghi-gi.png` | DashboardScreen – Chưa ghi gì hôm nay | 867:422 |
| `dashboard-04-dang-tai.png` | DashboardScreen – Đang tải | 869:413 |
| `dashboard-05-mat-mang.png` | DashboardScreen – Mất mạng | 869:480 |
| `dashboard-06-chua-co-ho-so.png` | DashboardScreen – Chưa có hồ sơ (`PROFILE_NOT_FOUND`) | 869:522 |
| `dashboard-07-sau-khi-them-snackbar.png` | DashboardScreen – Sau khi thêm món (snackbar Hoàn tác) | 869:563 |
| `log-01-chua-nhap.png` | LogMealScreen – Chưa nhập | 875:1320 |
| `log-02-co-ket-qua-mon-an-san.png` | LogMealScreen – Có kết quả (Món ăn sẵn) | 875:1449 |
| `log-03-khong-co-ket-qua.png` | LogMealScreen – Không có kết quả | 875:1550 |
| `log-04-sheet-chon-luong-phan.png` | LogMealScreen – Sheet chọn lượng (Món nấu) | 875:1598 |
| `log-05-sheet-chon-luong-gam.png` | LogMealScreen – Sheet chọn lượng (gam) | 875:1801 |
| `log-06-dang-gui.png` | LogMealScreen – Đang gửi | 875:1968 |
| `diary-01-theo-ngay-toan-trang.png` | DiaryScreen – Theo ngày (toàn trang, cao 1246) | 875:2171 |
| `diary-02-sua-mon-sheet.png` | DiaryScreen – Sửa món (sheet) | 875:2407 |
| `diary-03-ngay-chua-ghi.png` | DiaryScreen – Ngày chưa ghi | 875:2648 |
| `diary-04-thong-ke-7-ngay.png` | DiaryScreen – Thống kê 7 ngày | 875:2725 |
| `diary-05-thong-ke-30-ngay.png` | DiaryScreen – Thống kê 30 ngày | 875:2838 |
| `diary-06-thong-ke-chua-co-du-lieu.png` | DiaryScreen – Thống kê chưa có dữ liệu | 875:2967 |

Component (khung 865:3):

| Component | Node | Gợi ý widget Flutter |
|---|---|---|
| `MealCard` (Bữa = Sáng / Trưa / Tối / Phụ) | 866:78 | `MealCard` |
| `MacroRow` (Loại = Protein / Carbs / Fat) | 866:109 | `MacroProgressRow` |
| `FoodRow` | 866:110 | `FoodResultTile` |
| `DiaryItemRow` | 866:126 | `DiaryItemTile` (bọc `Dismissible`) |
| `DayChip` (Đã chọn / Đạt / Vượt / Chưa ghi) | 866:160 | `DayChip` |
| `Button / Chính` | 866:161 | `FilledButton` nền `primaryDark` |
| `NavigationBar / Trang chủ`, `/ Nhật ký` | 865:72, 865:93 | `AppShell` hiện có |
| icon/* (22 icon) | trong 865:3 | Material Symbols Outlined + `assets/icons` (ic_sunrise, ic_sun, ic_moon, ic_snack, ic_flame, ic_target) |

## Quy ước

- Màu: chỉ dùng 31 token ElytraPalette (`AppColors`). Bản Figma không có màu nào nằm ngoài palette. Font: Be Vietnam Pro (Regular / Medium / SemiBold / Bold).
- Bữa: Sáng `primaryContainer` + ic_sunrise `primaryDark` · Trưa `carbsContainer` + ic_sun `carbs` · Tối `proteinContainer` + ic_moon `protein` · Phụ `fatContainer` + ic_snack `fat`. Ngân sách bữa: 25 / 35 / 30 / 10 % mục tiêu ngày (`mealBudgetKcal`).
- Vòng calo: Ø 144, nét 14, đầu tròn, nền `outline`. Giữa vòng là **kcal còn lại**. Khi vượt mục tiêu, cả vòng tô `error`, giữa vòng ghi "x kcal vượt mức" (`onErrorContainer`), cạnh tiêu đề có nhãn "Vượt x %".
- Macro: "đã nạp / mục tiêu g", dòng phụ "Còn x g". Khi vượt thì đổi thành "Vượt x g", số và thanh dùng `error` / `onErrorContainer`.
- Thẻ bữa trùng với giờ hiện tại (`mealTypeAt(vnNow())`) có viền `primary` 1,5 và nhãn "· đến giờ".
- Biểu đồ: cột `primary`, cột > 110 % mục tiêu ngày tô `error`, cột hôm nay tô `primaryOutline` (đang ghi), đường mục tiêu nét đứt `textSecondary` lấy theo `days[].target_kcal` (có thể đổi giữa kỳ). Trung bình và số "ngày trong mục tiêu" (±10 %) **không tính hôm nay và ngày trống**.
- Ô ngày trong dải 7 ngày: chấm xanh = trong ±10 %, đỏ = vượt > 110 %, không chấm = chưa ghi, chấm xanh nhạt = hôm nay (chưa chốt).
- Số kiểu Việt Nam: "1.968 kcal", "58,5 g". Vùng chạm ≥ 48 (nút +, nút xoá từ khoá, chip cao 36 thì bọc vùng chạm 48).
- Sheet chọn lượng: Món nấu dùng stepper phần (0,25–10, bước 0,25; chip ½ / 1 / 1½ / 2). Món ăn sẵn / Nguyên liệu dùng ô gam (1–2.000; chip 200 / 300 / 400 / 500 g). Phần xem trước chỉ để hiển thị, số lưu lấy theo `budget` server trả về.
- Đang gửi: nút `primaryDark` 40 %, chữ "Đang thêm…", khoá bấm lặp. Sau khi thêm: quay về và hiện snackbar "Đã thêm … vào bữa …" + "Hoàn tác" (gọi `DELETE`).
- Nhật ký: sửa món là sheet `PATCH` (chỉ đổi lượng) + nút "Xoá". Muốn đổi bữa thì xoá rồi thêm lại. Món cũ hơn 30 ngày thì ẩn sửa / xoá.

## Dữ liệu mẫu (người mẫu Sprint 3)

Mục tiêu 1.968 kcal · P 130 g · C 239 g · F 55 g. Hôm nay đã nạp 1.152 kcal (P 68,4 · C 142,5 · F 36,2), còn 816 kcal. Đây là số minh hoạ, khi code lấy từ `GET /meal-logs` và `/meal-logs/history`.
