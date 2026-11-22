# Rà soát calo toàn bộ món (dữ liệu 23/11/2026)

Nguồn: D:/Antigravity/DA1/briefs/data/recipes_export_2026-11-23.json, 45 món đã duyệt. Chỉ là danh sách để xem, CHƯA sửa gì trong DB.

## Tóm tắt
| Cờ | Ý nghĩa | Số món |
| --- | --- | --- |
| `KCAL_LOW` | Calo/khẩu phần < 150 (trừ gia vị/ăn kèm) | 3 |
| `KCAL_HIGH` | Calo/khẩu phần > 1000 | 0 |
| `MACRO_MISMATCH` | 4P + 4C + 9F lệch > 20% so với calo/khẩu phần | 0 |
| `FAT_HEAVY` | Năng lượng từ chất béo (9F) > 60% tổng calo | 3 |
| `ONE_INGREDIENT` | Có nguyên liệu chiếm > 70% tổng calo từ nguyên liệu | 9 |
| `BIG_AMOUNT` | Có nguyên liệu > 600 g/khẩu phần | 3 |
| `ZERO_ROW` | Nguyên liệu không phải gia vị nhưng tính 0 g hoặc 0 kcal | 18 |
| `NO_INGREDIENT_ID` | Nguyên liệu không phải gia vị chưa ánh xạ (đang tính 0 kcal) | 18 |
| `SODIUM_HIGH` | Natri > 2300 mg/khẩu phần | 16 |
| `TOTAL_MISMATCH` | total_calories lệch > 2% + 1 so với khẩu phần × số phần | 0 |

Món không có cờ nào: 15/45

## Danh sách món có cờ (nhiều cờ nhất trước, cùng số cờ thì theo tên)

### Gà rang muối (`ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc`)
- Danh mục: mon_man · 3 khẩu phần · 517 kcal/khẩu phần · Đạm 33.5 g · Béo 41.0 g · Bột 3.7 g · Natri 3988 mg
- Cờ:
  - `FAT_HEAVY`: 71% năng lượng từ chất béo
  - `ZERO_ROW`: 4-5 lá chanh (xắt sợi (180.0 g), bột rang muối (30.0 g)
  - `NO_INGREDIENT_ID`: 4-5 lá chanh (xắt sợi (180.0 g)
  - `SODIUM_HIGH`: 3988 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: gà tre (cắt miếng vừa ăn) 480.0 g → 955 kcal (62%); Dầu ăn (đủ để chiên ngập gà) 60.0 g → 538 kcal (35%); bột chiên giòn 15.0 g → 52 kcal (3%)

### Hủ tiếu gà trộn (`-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me`)
- Danh mục: mon_man · 4 khẩu phần · 824 kcal/khẩu phần · Đạm 45.8 g · Béo 35.6 g · Bột 80.1 g · Natri 3291 mg
- Cờ:
  - `BIG_AMOUNT`: Nước lọc: 750.0 g/khẩu phần
  - `ZERO_ROW`: Ăn kèm nước súp (2.0 g), Nước luộc gà (150.0 g), Xà lách (2.0 g)
  - `NO_INGREDIENT_ID`: Ăn kèm nước súp (2.0 g), Nước luộc gà (150.0 g), Xà lách (2.0 g)
  - `SODIUM_HIGH`: 3291 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: Gà 720.0 g → 1433 kcal (43%); Hủ tiếu khô 800.0 g → 1128 kcal (34%); Dầu ăn 41.4 g → 373 kcal (11%)

### Lẩu bò Mông Cổ (`cach-nau-lau-bo-mong-co-thom-ngon-don-gian-tai-nha`)
- Danh mục: mon_man · 4 khẩu phần · 426 kcal/khẩu phần · Đạm 39.4 g · Béo 7.8 g · Bột 50.3 g · Natri 5004 mg
- Cờ:
  - `BIG_AMOUNT`: nước dừa tươi: 625.0 g/khẩu phần
  - `ZERO_ROW`: chao (30.0 g), táo bơm (50.0 g), hoa hồi (200.0 g), táo đỏ (1500.0 g), đông trùng (17.5 g), sa tế (15.0 g)
  - `NO_INGREDIENT_ID`: chao (30.0 g), táo bơm (50.0 g), hoa hồi (200.0 g), táo đỏ (1500.0 g), đông trùng (17.5 g), sa tế (15.0 g)
  - `SODIUM_HIGH`: 5004 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: rìa thăn bò 500.0 g → 590 kcal (35%); nước dừa tươi 2500.0 g → 525 kcal (31%); bao tử dê 190.0 g → 184 kcal (11%)

### Lẩu Thái (`cach-nau-lau-thai-sieu-ngon-tai-nha-chua-cay-dam-da-ai-an-cung-ghien`)
- Danh mục: mon_man · 4 khẩu phần · 743 kcal/khẩu phần · Đạm 69.7 g · Béo 14.5 g · Bột 83.1 g · Natri 4955 mg
- Cờ:
  - `BIG_AMOUNT`: Nước lọc: 625.0 g/khẩu phần
  - `ZERO_ROW`: Rau ăn lẩu (2.0 g)
  - `NO_INGREDIENT_ID`: Rau ăn lẩu (2.0 g)
  - `SODIUM_HIGH`: 4955 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: Bún tươi 800.0 g → 896 kcal (30%); Tôm 450.0 g → 405 kcal (14%); Thịt bò 300.0 g → 354 kcal (12%)

### Sườn non chay rim nước mía xá xíu (`cach-lam-suon-non-chay-rim-nuoc-mia-xa-xiu-man-ngot-an-la-ghien`)
- Danh mục: mon_chay · 4 khẩu phần · 105 kcal/khẩu phần · Đạm 13.0 g · Béo 0.5 g · Bột 12.3 g · Natri 734 mg
- Cờ:
  - `KCAL_LOW`: 105 kcal/khẩu phần
  - `ONE_INGREDIENT`: sườn non chay chiếm 79% calo (100.0 g)
  - `ZERO_ROW`: nước mía (200.0 g), sốt ướp xá xíu (45.0 g)
  - `NO_INGREDIENT_ID`: nước mía (200.0 g), sốt ướp xá xíu (45.0 g)
- 3 nguyên liệu nhiều calo nhất: sườn non chay 100.0 g → 331 kcal (79%); đường 10.0 g → 40 kcal (9%); tỏi 24.0 g → 30 kcal (7%)

### Bún bò Huế chay (`cach-nau-bun-bo-hue-chay-dam-vi-ngon-lanh`)
- Danh mục: mon_chay · 4 khẩu phần · 395 kcal/khẩu phần · Đạm 32.1 g · Béo 8.3 g · Bột 48.1 g · Natri 3448 mg
- Cờ:
  - `ZERO_ROW`: Chả quế chay (2.0 g), Rau ăn kèm (2.0 g), nước mắm chay (45.0 g), hạt điều đỏ DH Foods (30.0 g), gia vị nấu bún bò Huế DH Foods (100.0 g)
  - `NO_INGREDIENT_ID`: Chả quế chay (2.0 g), Rau ăn kèm (2.0 g), nước mắm chay (45.0 g), hạt điều đỏ DH Foods (30.0 g), gia vị nấu bún bò Huế DH Foods (100.0 g)
  - `SODIUM_HIGH`: 3448 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: bò lát chay 100.0 g → 331 kcal (21%); bắp 165.0 g → 330 kcal (21%); tàu hủ ky non 50.0 g → 208 kcal (13%)

### Bún riêu cua đồng (`cach-nau-bun-rieu-cua-dong-thom-ngon-dam-da`)
- Danh mục: mon_an_sang · 4 khẩu phần · 442 kcal/khẩu phần · Đạm 43.2 g · Béo 21.0 g · Bột 19.8 g · Natri 6665 mg
- Cờ:
  - `ZERO_ROW`: giò, xương heo (1200.0 g)
  - `NO_INGREDIENT_ID`: giò, xương heo (1200.0 g)
  - `SODIUM_HIGH`: 6665 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: thịt heo xay 250.0 g → 348 kcal (20%); cua đồng 310.0 g → 270 kcal (15%); đậu hũ viên 250.0 g → 243 kcal (14%)

### Bún riêu cua đồng hải sản (`cach-nau-bun-rieu-cua-dong-hai-san-ngon-dam-da`)
- Danh mục: mon_an_sang · 4 khẩu phần · 511 kcal/khẩu phần · Đạm 51.2 g · Béo 5.7 g · Bột 63.3 g · Natri 6673 mg
- Cờ:
  - `ZERO_ROW`: Hạt điều đỏ (2.0 g)
  - `NO_INGREDIENT_ID`: Hạt điều đỏ (2.0 g)
  - `SODIUM_HIGH`: 6673 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: Bún tươi 800.0 g → 896 kcal (44%); tôm 450.0 g → 405 kcal (20%); mực 390.0 g → 285 kcal (14%)

### Đuôi heo hầm hạt sen táo đỏ (`cach-nau-duoi-heo-ham-hat-sen-tao-do-thom-ngon-bo-duong`)
- Danh mục: mon_man · 4 khẩu phần · 970 kcal/khẩu phần · Đạm 25.7 g · Béo 82.9 g · Bột 30.2 g · Natri 6629 mg
- Cờ:
  - `FAT_HEAVY`: 77% năng lượng từ chất béo
  - `ONE_INGREDIENT`: đuôi heo chiếm 84% calo (700.0 g)
  - `SODIUM_HIGH`: 6629 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: đuôi heo 700.0 g → 3269 kcal (84%); hạt sen 122.0 g → 200 kcal (5%); củ sen 267.0 g → 174 kcal (4%)

### Lẩu gà lá giang (`cach-nau-lau-ga-la-giang-thom-ngon-bo-duong-tru-danh`)
- Danh mục: mon_man · 4 khẩu phần · 706 kcal/khẩu phần · Đạm 48.9 g · Béo 28.4 g · Bột 63.6 g · Natri 3060 mg
- Cờ:
  - `ZERO_ROW`: sa tế (22.5 g)
  - `NO_INGREDIENT_ID`: sa tế (22.5 g)
  - `SODIUM_HIGH`: 3060 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: gà 864.0 g → 1719 kcal (61%); Bún tươi 800.0 g → 896 kcal (32%); đường phèn 37.5 g → 149 kcal (5%)

### Mắm kho (`cach-nau-mam-kho-chuan-vi-dam-chat-dong-que`)
- Danh mục: mon_kho · 4 khẩu phần · 679 kcal/khẩu phần · Đạm 53.8 g · Béo 30.2 g · Bột 48.0 g · Natri 2610 mg
- Cờ:
  - `ZERO_ROW`: đậu bắp (200.0 g), đậu bún (250.0 g), Rau ăn kèm (2.0 g)
  - `NO_INGREDIENT_ID`: đậu bắp (200.0 g), đậu bún (250.0 g), Rau ăn kèm (2.0 g)
  - `SODIUM_HIGH`: 2610 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: thịt ba chỉ 500.0 g → 1300 kcal (48%); cá bông lau 900.0 g → 603 kcal (22%); nước dừa tươi 1300.0 g → 273 kcal (10%)

### Muối tôm khô Campuchia (`cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon`)
- Danh mục: gia_vi_an_kem · 4 khẩu phần · 254 kcal/khẩu phần · Đạm 20.0 g · Béo 1.0 g · Bột 41.2 g · Natri 11629 mg
- Cờ:
  - `ZERO_ROW`: Chấm các loại trái cây chua (2.0 g), Ăn kèm bánh tráng (2.0 g), Làm quà biếu (2.0 g)
  - `NO_INGREDIENT_ID`: Chấm các loại trái cây chua (2.0 g), Ăn kèm bánh tráng (2.0 g), Làm quà biếu (2.0 g)
  - `SODIUM_HIGH`: 11629 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: Đường thốt nốt 150.0 g → 596 kcal (59%); Tôm khô 76.0 g → 264 kcal (26%); Ruốc khô 30.0 g → 92 kcal (9%)

### Ốc nướng tiêu xanh (`cach-lam-oc-nuong-tieu-xanh-sieu-thom-ngon-kho-quen`)
- Danh mục: mon_nuong · 4 khẩu phần · 108 kcal/khẩu phần · Đạm 10.6 g · Béo 1.1 g · Bột 14.0 g · Natri 733 mg
- Cờ:
  - `KCAL_LOW`: 108 kcal/khẩu phần
  - `ZERO_ROW`: sốt ướp thịt nướng (15.0 g)
  - `NO_INGREDIENT_ID`: sốt ướp thịt nướng (15.0 g)
- 3 nguyên liệu nhiều calo nhất: ốc lác 330.0 g → 277 kcal (64%); tiêu xanh 17.5 g → 64 kcal (15%); đường 7.5 g → 30 kcal (7%)

### Cá bống chay chiên sả (`cach-lam-ca-bong-chay-chien-sa-gion-gion-cuc-ngon`)
- Danh mục: mon_chay · 4 khẩu phần · 109 kcal/khẩu phần · Đạm 13.0 g · Béo 0.3 g · Bột 13.6 g · Natri 853 mg
- Cờ:
  - `KCAL_LOW`: 109 kcal/khẩu phần
  - `ONE_INGREDIENT`: cá bống chay chiếm 76% calo (100.0 g)
- 3 nguyên liệu nhiều calo nhất: cá bống chay 100.0 g → 331 kcal (76%); Dầu ăn (ngấm khi chiên) 20.0 g → 70 kcal (16%); đường 7.5 g → 30 kcal (7%)

### Cá nục kho nước mía (`ca-nuc-kho-nuoc-mia-dam-da-ngot-thanh-an-com-hay-banh-mi-deu-cuon`)
- Danh mục: mon_kho · 4 khẩu phần · 366 kcal/khẩu phần · Đạm 40.1 g · Béo 18.6 g · Bột 9.3 g · Natri 1891 mg
- Cờ:
  - `ZERO_ROW`: nước mía (300.0 g)
  - `NO_INGREDIENT_ID`: nước mía (300.0 g)
- 3 nguyên liệu nhiều calo nhất: cá nục 730.0 g → 810 kcal (55%); mỡ heo 55.2 g → 457 kcal (31%); đường thốt nốt 15.0 g → 60 kcal (4%)

### Canh chua cá diêu hồng (`cach-nau-canh-chua-ca-dieu-hong-ngot-thanh-dam-da`)
- Danh mục: mon_canh · 4 khẩu phần · 209 kcal/khẩu phần · Đạm 24.4 g · Béo 2.8 g · Bột 21.4 g · Natri 996 mg
- Cờ:
  - `ZERO_ROW`: đậu bắp (120.0 g), Rau nêm (2.0 g)
  - `NO_INGREDIENT_ID`: đậu bắp (120.0 g), Rau nêm (2.0 g)
- 3 nguyên liệu nhiều calo nhất: cá diêu hồng 456.0 g → 456 kcal (55%); đường 30.0 g → 119 kcal (14%); thơm 300.0 g → 96 kcal (11%)

### Gà hấp muối trộn gỏi bắp chuối (`cach-moi-lam-ga-hap-muoi-tron-goi-bap-chuoi-hap-dan-ngon-me-ly`)
- Danh mục: mon_man · 4 khẩu phần · 434 kcal/khẩu phần · Đạm 38.0 g · Béo 23.6 g · Bột 17.4 g · Natri 3227 mg
- Cờ:
  - `ONE_INGREDIENT`: gà chiếm 83% calo (720.0 g)
  - `SODIUM_HIGH`: 3227 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: gà 720.0 g → 1433 kcal (83%); đường 52.5 g → 208 kcal (12%); bắp chuối 284.0 g → 80 kcal (5%)

### Gà kho sả (`ga-kho-sa-dam-da-thom-lung-mon-com-nha-ai-cung-ghien`)
- Danh mục: mon_kho · 3 khẩu phần · 457 kcal/khẩu phần · Đạm 34.2 g · Béo 30.3 g · Bột 11.9 g · Natri 760 mg
- Cờ:
  - `ZERO_ROW`: Rau ăn kèm (2.0 g)
  - `NO_INGREDIENT_ID`: Rau ăn kèm (2.0 g)
- 3 nguyên liệu nhiều calo nhất: gà (cắt miếng vừa ăn 480.0 g → 955 kcal (70%); dầu ăn 27.6 g → 248 kcal (18%); nước dừa tươi 300.0 g → 63 kcal (5%)

### Mì xào bò (`cach-lam-mi-xao-bo-dam-da-soi-mi-dai-thit-bo-gion-beo`)
- Danh mục: mon_an_sang · 4 khẩu phần · 277 kcal/khẩu phần · Đạm 19.2 g · Béo 6.8 g · Bột 34.7 g · Natri 1150 mg
- Cờ:
  - `ZERO_ROW`: gói gia vị mì (có sẵn trong gói mì) (75.0 g)
  - `NO_INGREDIENT_ID`: gói gia vị mì (có sẵn trong gói mì) (75.0 g)
- 3 nguyên liệu nhiều calo nhất: Mì gói 150.0 g → 521 kcal (47%); Thịt bò 250.0 g → 295 kcal (27%); dầu ăn 13.8 g → 124 kcal (11%)

### Sườn xào chua ngọt (`cach-lam-suon-xao-chua-ngot-cuc-ngon-an-la-ghien`)
- Danh mục: mon_xao · 4 khẩu phần · 231 kcal/khẩu phần · Đạm 14.0 g · Béo 9.8 g · Bột 21.9 g · Natri 1501 mg
- Cờ:
  - `ZERO_ROW`: tương xí muội (45.0 g)
  - `NO_INGREDIENT_ID`: tương xí muội (45.0 g)
- 3 nguyên liệu nhiều calo nhất: sườn non 301.0 g → 563 kcal (61%); đường 45.0 g → 179 kcal (19%); bột năng 45.0 g → 153 kcal (17%)

### Thịt ba chỉ kho tiêu (`cach-lam-thit-ba-chi-kho-tieu-nuoc-set-ngon-vo-doi`)
- Danh mục: mon_kho · 4 khẩu phần · 225 kcal/khẩu phần · Đạm 13.2 g · Béo 16.2 g · Bột 6.5 g · Natri 529 mg
- Cờ:
  - `FAT_HEAVY`: 65% năng lượng từ chất béo
  - `ONE_INGREDIENT`: thịt ba chỉ chiếm 87% calo (300.0 g)
- 3 nguyên liệu nhiều calo nhất: thịt ba chỉ 300.0 g → 780 kcal (87%); đường 15.0 g → 60 kcal (7%); đường 5.0 g → 20 kcal (2%)

### Tôm rim mặn ngọt và salad trộn dầu giấm (`cach-lam-tom-rim-man-ngot-va-salad-tron-dau-giam-ngon-kho-cuong`)
- Danh mục: mon_kho · 4 khẩu phần · 167 kcal/khẩu phần · Đạm 22.3 g · Béo 2.1 g · Bột 14.6 g · Natri 959 mg
- Cờ:
  - `ZERO_ROW`: Rau xà lách (2.0 g)
  - `NO_INGREDIENT_ID`: Rau xà lách (2.0 g)
- 3 nguyên liệu nhiều calo nhất: tôm 450.0 g → 405 kcal (61%); đường 45.0 g → 179 kcal (27%); tỏi 40.0 g → 50 kcal (8%)

### Cá chim kho thơm (`cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc`)
- Danh mục: mon_kho · 4 khẩu phần · 237 kcal/khẩu phần · Đạm 23.9 g · Béo 8.6 g · Bột 16.2 g · Natri 699 mg
- Cờ:
  - `ONE_INGREDIENT`: Cá chim biển (1 con vừa ăn) chiếm 75% calo (500.0 g)
- 3 nguyên liệu nhiều calo nhất: Cá chim biển (1 con vừa ăn) 500.0 g → 715 kcal (75%); Thơm (dứa) 300.0 g → 96 kcal (10%); Đường 15.0 g → 60 kcal (6%)

### Cánh gà om bia (`cach-lam-canh-ga-om-bia-thom-ngon-hap-dan`)
- Danh mục: mon_man · 4 khẩu phần · 422 kcal/khẩu phần · Đạm 39.3 g · Béo 24.9 g · Bột 6.3 g · Natri 247 mg
- Cờ:
  - `ONE_INGREDIENT`: cánh gà giữa chiếm 89% calo (800.0 g)
- 3 nguyên liệu nhiều calo nhất: cánh gà giữa 800.0 g → 1504 kcal (89%); bia 198.0 g → 85 kcal (5%); đường 15.0 g → 60 kcal (4%)

### Gà nấu nấm đông cô thập cẩm (`cach-lam-ga-nau-nam-dong-co-thap-cam-mau-dep-thom-nuc-ngon-vo-doi`)
- Danh mục: mon_man · 4 khẩu phần · 802 kcal/khẩu phần · Đạm 59.0 g · Béo 44.6 g · Bột 41.6 g · Natri 2868 mg
- Cờ:
  - `SODIUM_HIGH`: 2868 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: gà 960.0 g → 1910 kcal (60%); dầu điều 41.4 g → 373 kcal (12%); nước dừa tươi 1500.0 g → 315 kcal (10%)

### Lẩu riêu tôm (`cach-nau-lau-rieu-tom-sieu-ngon-bat-bai`)
- Danh mục: mon_man · 4 khẩu phần · 661 kcal/khẩu phần · Đạm 77.4 g · Béo 12.0 g · Bột 60.3 g · Natri 4123 mg
- Cờ:
  - `SODIUM_HIGH`: 4123 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: tôm càng 1350.0 g → 1215 kcal (46%); Bún 800.0 g → 896 kcal (34%); giò sống 150.0 g → 308 kcal (12%)

### Mì xào hải sản (`cach-lam-mi-xao-hai-san-sieu-ngon-kho-cuong`)
- Danh mục: mon_an_sang · 4 khẩu phần · 442 kcal/khẩu phần · Đạm 39.7 g · Béo 4.9 g · Bột 59.7 g · Natri 3012 mg
- Cờ:
  - `SODIUM_HIGH`: 3012 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: mì 225.0 g → 781 kcal (44%); tôm, mực 630.0 g → 567 kcal (32%); cải thảo, cà rốt 630.0 g → 227 kcal (13%)

### Súp nui gà xé (`cach-nau-sup-nui-ga-xe-dac-biet-thom-ngon-dinh-duong`)
- Danh mục: mon_man · 6 khẩu phần · 701 kcal/khẩu phần · Đạm 42.1 g · Béo 21.5 g · Bột 84.7 g · Natri 2540 mg
- Cờ:
  - `SODIUM_HIGH`: 2540 mg natri/khẩu phần (khuyến nghị cả ngày < 2300)
- 3 nguyên liệu nhiều calo nhất: nui 500.0 g → 1735 kcal (41%); thịt gà 864.0 g → 1719 kcal (41%); bắp vàng 165.0 g → 330 kcal (8%)

### Sườn non kho tiêu (`cach-lam-suon-non-kho-tieu-mem-ngon-man-ngot-hao-com`)
- Danh mục: mon_kho · 4 khẩu phần · 271 kcal/khẩu phần · Đạm 20.2 g · Béo 13.8 g · Bột 16.5 g · Natri 1035 mg
- Cờ:
  - `ONE_INGREDIENT`: sườn non chiếm 74% calo (430.0 g)
- 3 nguyên liệu nhiều calo nhất: sườn non 430.0 g → 804 kcal (74%); đường 45.0 g → 179 kcal (16%); nước màu 15.0 g → 60 kcal (5%)

### Sườn non rim sả ớt (`cach-lam-suon-non-rim-sa-ot-man-ngot-mem-mong-ngon-lanh`)
- Danh mục: mon_kho · 4 khẩu phần · 252 kcal/khẩu phần · Đạm 20.6 g · Béo 14.1 g · Bột 10.7 g · Natri 1036 mg
- Cờ:
  - `ONE_INGREDIENT`: sườn non heo chiếm 80% calo (430.0 g)
- 3 nguyên liệu nhiều calo nhất: sườn non heo 430.0 g → 804 kcal (80%); bột bắp 30.0 g → 110 kcal (11%); đường 15.0 g → 60 kcal (6%)

## Nguyên liệu chưa ánh xạ (không phải gia vị) — gộp toàn bộ món
| Tên (đã chuẩn hóa) | Số món | Tổng g | Món |
| --- | --- | --- | --- |
| rau ăn kèm | 3 | 6.0 | Bún bò Huế chay, Gà kho sả, Mắm kho |
| nước mía | 2 | 500.0 | Cá nục kho nước mía, Sườn non chay rim nước mía xá xíu |
| đậu bắp | 2 | 320.0 | Canh chua cá diêu hồng, Mắm kho |
| sa tế | 2 | 37.5 | Lẩu bò Mông Cổ, Lẩu gà lá giang |
| táo đỏ | 1 | 1500.0 | Lẩu bò Mông Cổ |
| giò, xương heo | 1 | 1200.0 | Bún riêu cua đồng |
| đậu bún | 1 | 250.0 | Mắm kho |
| hoa hồi | 1 | 200.0 | Lẩu bò Mông Cổ |
| 4-5 lá chanh (xắt sợi | 1 | 180.0 | Gà rang muối |
| nước luộc gà | 1 | 150.0 | Hủ tiếu gà trộn |
| gia vị nấu bún bò huế dh foods | 1 | 100.0 | Bún bò Huế chay |
| gói gia vị mì (có sẵn trong gói mì) | 1 | 75.0 | Mì xào bò |
| táo bơm | 1 | 50.0 | Lẩu bò Mông Cổ |
| nước mắm chay | 1 | 45.0 | Bún bò Huế chay |
| sốt ướp xá xíu | 1 | 45.0 | Sườn non chay rim nước mía xá xíu |
| tương xí muội | 1 | 45.0 | Sườn xào chua ngọt |
| chao | 1 | 30.0 | Lẩu bò Mông Cổ |
| hạt điều đỏ dh foods | 1 | 30.0 | Bún bò Huế chay |
| đông trùng | 1 | 17.5 | Lẩu bò Mông Cổ |
| sốt ướp thịt nướng | 1 | 15.0 | Ốc nướng tiêu xanh |
| ăn kèm bánh tráng | 1 | 2.0 | Muối tôm khô Campuchia |
| ăn kèm nước súp | 1 | 2.0 | Hủ tiếu gà trộn |
| chả quế chay | 1 | 2.0 | Bún bò Huế chay |
| chấm các loại trái cây chua | 1 | 2.0 | Muối tôm khô Campuchia |
| hạt điều đỏ | 1 | 2.0 | Bún riêu cua đồng hải sản |
| làm quà biếu | 1 | 2.0 | Muối tôm khô Campuchia |
| rau ăn lẩu | 1 | 2.0 | Lẩu Thái |
| rau nêm | 1 | 2.0 | Canh chua cá diêu hồng |
| rau xà lách | 1 | 2.0 | Tôm rim mặn ngọt và salad trộn dầu giấm |
| xà lách | 1 | 2.0 | Hủ tiếu gà trộn |
