# Sprint 4 – Thiết kế màn Tìm kiếm món & Chi tiết món

- Kế hoạch, quyết định thiết kế và việc cần làm khi code: [sprint4-ke-hoach-mon-an.md](sprint4-ke-hoach-mon-an.md)
- Nguồn: Figma **Elytra**, trang "Sprint 4 – Món ăn" (833:2): https://www.figma.com/design/pXJPotFfWA1Xmsottbf0mX/Elytra?node-id=833-2
- Ảnh trong `screens/` xuất PNG 2x (khung 390 × 827) ngày 27/10/2026. Cần số đo chính xác thì mở Figma theo node ID.

| Ảnh | Khung Figma | Node |
|---|---|---|
| `screens/search-01-co-ket-qua.png` | RecipeSearchScreen – Có kết quả | 836:2 |
| `screens/search-02-chua-nhap-dang-focus.png` | RecipeSearchScreen – Chưa nhập (đang focus) | 839:557 |
| `screens/search-03-bo-loc.png` | RecipeSearchScreen – Bộ lọc | 837:184 |
| `screens/search-04-sap-xep.png` | RecipeSearchScreen – Sắp xếp | 837:304 |
| `screens/search-05-khong-co-ket-qua.png` | RecipeSearchScreen – Không có kết quả | 839:673 |
| `screens/search-06-dang-tai.png` | RecipeSearchScreen – Đang tải | 839:892 |
| `screens/search-07-mat-mang.png` | RecipeSearchScreen – Mất mạng | 839:1099 |
| `screens/detail-01-mac-dinh-toan-trang.png` | RecipeDetailScreen – Mặc định (toàn trang, cao 1809) | 844:916 |
| `screens/detail-02-co-canh-bao-di-ung.png` | RecipeDetailScreen – Có cảnh báo dị ứng | 844:1102 |
| `screens/detail-03-doi-khau-phan-da-cuon.png` | RecipeDetailScreen – Đổi khẩu phần (đã cuộn) | 844:1294 |
| `screens/detail-04-dang-tai.png` | RecipeDetailScreen – Đang tải | 844:1487 |

Component dùng chung (RecipeCard, Chip, NavigationBar, FAB) nằm ở khung "Components – Sprint 4" (835:2), chưa xuất ảnh.

## Cập nhật sau kế hoạch

- Giá trị `category` thật (dữ liệu seed 45 món, PR #4): `mon_man` 19 · `mon_kho` 10 · `mon_an_sang` 9 · `mon_chay` 4 · `mon_canh` 1 · `mon_xao` 1 · `mon_nuong` 1. Ẩn chip của nhóm không có món; việc gộp các nhóm ít món còn chờ chốt với back-end.
- Chip nhóm món trong ảnh (Cơm, Phở, Bún, Cá kho…) và ảnh món là dữ liệu mẫu; khi code dùng nhãn theo các giá trị `category` ở trên và `image_url` thật.
