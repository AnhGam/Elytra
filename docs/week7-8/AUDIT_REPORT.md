# Báo cáo kiểm thử & rà soát backend (26/10/2026)

Phạm vi: toàn bộ backend Supabase (RPC, RLS, Edge Functions, Storage, Auth, dữ liệu) + phần app ghi thẳng vào DB.
Cách làm: unit test từng hàm → test kết hợp theo flow → flow hoàn chỉnh + tấn công trên production (user tạm, tự xóa) → kiểm chứng lại từng nghi vấn.

## Kết quả kiểm chứng

| # | Nghi vấn | Kết luận | Mức |
| --- | --- | --- | --- |
| V1 | Nguyên liệu không map → món thiếu dị ứng + thiếu calo | **ĐÚNG** | **Cao** |
| V3 | `meal-logs` trả 500 thay vì 401/400 | **ĐÚNG** | Thấp |
| V4 | Dashboard và biểu đồ "hôm nay" lệch mục tiêu khi đổi hồ sơ giữa ngày | **ĐÚNG** (do thiết kế, đã ghi contract) | Thấp |
| V5 | PATCH sửa được món > 30 ngày, POST thì không | **ĐÚNG** | Thấp |
| V6 | PATCH nhiều lần làm số trôi (1159 → 1158.84) | **ĐÚNG** | Thấp |
| V7 | `profiles` không ràng buộc target/tuổi; app tự tính và ghi thẳng | **ĐÚNG** (chỉ ảnh hưởng chính user đó) | Thấp |
| V8 | Đăng ký không cần xác nhận email | **ĐÚNG** | Trung bình |
| V9 | api-contract sai so với hệ thống | **ĐÚNG** | Thấp (tài liệu) |
| V2 | Edge `calculate-bmr-tdee` ghi rác vào hồ sơ | **SAI một phần**: không ghi được (Postgres từ chối), nhưng các lỗi khác có thật, xem dưới | Thấp |
| V12 | `get_ingredient_details` trả cả nguyên liệu đã vô hiệu; không có → `null`/200 | ĐÚNG ở code, hiện 0 nguyên liệu vô hiệu | Thấp (tiềm ẩn) |
| V14 | Món chưa duyệt lộ qua `search_recipes` và REST | ĐÚNG ở code, hiện 0 món chưa duyệt | **Cao khi làm Sprint 7** |
| V10 | anon gọi được `meal_item_json` | **SAI**: hàm chỉ định dạng lại input, không đọc DB | — |
| V11 | 9 nguyên liệu lệch Atwater > 25% | **SAI**: đều là rượu/bia, calo đến từ cồn (7 kcal/g) | — |

## Chi tiết các điểm ĐÚNG

### V1 – Món chứa hải sản/đậu nành không có tag dị ứng, calo bị tính thiếu (Cao)
- 69/605 dòng `recipe_ingredients` có `ingredient_id = NULL` (58 tên). Dòng không map = 0 kcal và không kế thừa dị ứng.
- Bảng gốc có đủ 38 loại cá, đều gắn `seafood` → lỗi ở bước map tên khi crawl, không phải thiếu dữ liệu.
- Tái hiện: `search_recipes(p_exclude_allergen_ids => [1 /*seafood*/])` vẫn trả:
  - **Cá Biển Kho Cà Chua** (700 g cá không map) – `allergens=[]`, hiện 120 kcal/khẩu, ước tính thật ≈ 310 kcal.
  - **Mắm kho** (900 g cá bông lau + 400 g mắm cá không map) – `allergens=[]`.
- **Bún bò Huế chay**: tàu hủ ky lá/non (đậu nành) và chả quế chay không map → `allergens=[]` (thiếu `soy`).
- Hệ quả: người dị ứng nhận món nguy hiểm; meal log chụp lại calo sai của các món này.

### V3 – Mã lỗi sai trong `meal-logs`
- Dùng anon key làm token → RPC trả `42501` (không map) → **500** thay vì 401.
- Body `null` → `b.meal_type` ném TypeError → **500** thay vì 400.

### V4 – Hai mục tiêu khác nhau cho cùng ngày
Đổi target 1992 → 2500 giữa ngày: Dashboard hiện 2500, lịch sử hôm nay hiện 1992 (snapshot lúc ghi món đầu). Nếu đổi giữa các bữa, lịch sử lấy `MAX`.

### V5 – Cửa sổ 30 ngày không nhất quán
`log_meal` chặn ngày < hôm nay − 30, `update_meal_log_item` không kiểm tra ngày (đã sửa món ngày 2020-01-01 thành công).

### V6 – Sai số tích lũy khi sửa khẩu phần
PATCH nhân tỉ lệ trên giá trị đã làm tròn 2 chữ số: 333 g → 7 → 1999 → 3 → 1777 → 13 → 333 g cho kcal 1159 → 1158.84.

### V7 – `profiles` không có ràng buộc giá trị
User ghi được `target_calories = -5000`, `age = -3`, `bmr = 99999.9` cho chính mình (RLS chặn đúng việc ghi hồ sơ người khác). App hiện tự tính mục tiêu rồi upsert thẳng (`nutrition_repository.dart`).

### V8 – Cấu hình Auth
- `mailer_autoconfirm = true`: đăng ký nhận session ngay, không xác nhận email → đăng ký được bằng email người khác (chủ thật vẫn lấy lại bằng quên mật khẩu), tạo tài khoản rác dễ.
- `supabase/config.toml` ghi `minimum_password_length = 6`, remote đang là 8 → cấu hình local lệch remote.
- Advisor: chưa bật Leaked password protection.

### V9 – api-contract lệch hệ thống
- Endpoint `/calc-nutrition` không tồn tại; cái đang deploy là `calculate-bmr-tdee` với tham số/response khác (`save_to_profile`, `{success, data}`, lỗi dạng chuỗi).
- `Goal` ghi `gain_muscle`, DB chỉ nhận `gain_weight` (bị CHECK chặn).
- Ví dụ mục 1 sai số: input mẫu cho target 1991.6 / protein 130, contract ghi 2092 / 156.9.

### V2 – Edge Function `calculate-bmr-tdee` (app không gọi)
- Lệch 0.1 so với SQL/app ở 39/810 trường hợp (làm tròn số thực JS).
- Input rác (`age: "abc"`, `goal: "fly"`) vẫn trả `success: true` với giá trị `null`, BMI `null` bị phân loại "Béo phì".
- JSON hỏng → 500 kèm message nội bộ.
- `save_to_profile` lỗi khi lưu vẫn trả `success: true` (không kiểm tra lỗi update).
- `verify_jwt = false`.

### V12, V14 – Tiềm ẩn
- `search_recipes` và policy SELECT của `recipes` không lọc `is_verified`; Sprint 7 thêm món chờ duyệt thì món chưa duyệt sẽ lộ ra và người dùng ghi bữa sẽ gặp `RECIPE_NOT_FOUND`.
- `get_ingredient_details` không lọc `is_active` (khác `search_ingredients` và RLS).

## Đã kiểm, không có vấn đề
- Phép tính BMR/TDEE/macro: **app (Dart) và SQL khớp 100%** trên 810 bộ input.
- Dữ liệu món: per-serving × servings = total; tổng theo nguyên liệu khớp total; snapshot 100 g khớp bảng gốc; dị ứng kế thừa khớp với nguyên liệu **đã map**.
- RLS: không đọc/sửa/xóa được profile, dị ứng, meal log của người khác; không ghi được vào recipes/ingredients/allergens/recipe_allergens; anon không đọc được profiles.
- Không có service key / token / secret nào trong repo và lịch sử git (chỉ anon key, vốn công khai).
- `meal-logs`: validation biên (servings 0.25, ngày −30/−31, định dạng ngày, uuid), idempotency (cùng key khác nội dung → 422, key tách theo user), xóa user → dữ liệu xóa theo.
- Lỗ hổng cũ đã vá vẫn đóng: `exec_seed_sql`, 2 RPC ghi, upload Storage bằng anon.

## Môi trường chưa kiểm được
- `flutter test` không chạy: Flutter máy (3.44.4) thấp hơn yêu cầu `sdk ^3.13.5`. Đã thay bằng chạy calculator Dart độc lập.

---

## Nguyên nhân gốc & kết quả sửa (26/10/2026)

Kiểm chứng sau khi sửa: `test_migrations_replay.mjs` (dựng lại DB từ đầu + kiểm từng lỗi), `test_ingredient_parser.js`, `test_meal_logs_sql.mjs`, `test_meal_logs_e2e.mjs` và kịch bản kiểm trên production — **tất cả PASS**. Flutter đã nâng lên 3.47.8: `flutter test` 24/24 pass, `flutter analyze` không lỗi.

| # | Nguyên nhân gốc | Cách sửa | Trạng thái |
| --- | --- | --- | --- |
| V1 | Từ điển `ingredient_parser.js` dùng **mã FCT đoán tay**: 116/285 mục trỏ sai (`gà`→Thịt cừu, `lạc`→Quả đại, `mè`→Bột đậu xanh, `nước dừa`→Cô nhắc, `dầu ăn`→Dầu lạc+vừng gây báo dị ứng giả). So khớp kiểu **chuỗi con** (`ớt` khớp "bớt") + so khớp mờ bỏ dấu. Dị ứng **chỉ** kế thừa từ nguyên liệu đã map → dòng không map mất tag. | Từ điển viết lại theo **tên** FCT, có kiểm tra lúc nạp; so khớp theo từ; quy tắc món chay; lưới an toàn dị ứng theo từ khóa. Map lại 605 dòng + tính lại dinh dưỡng/dị ứng 45 món bằng migration sinh tự động. Thêm nguyên liệu quy đổi "Cơm tẻ" (FCT chỉ có gạo sống). Trigger chặn recipe mới có nguyên liệu NULL/không tồn tại. | Đã sửa |
| V1b | Một tag dị ứng gộp hai nghĩa: "gây dị ứng" và "món hải sản". Nước mắm/mắm tôm/dầu hào làm món bị coi là món hải sản. | `recipe_allergens.via_condiment`: tag vẫn có (người dị ứng vẫn được lọc), nhưng đánh dấu là chỉ đến từ gia vị. `search_recipes` trả thêm `condiment_allergens`. | Đã sửa |
| V1c | Từ khóa soy dùng từ đơn `tương`: khớp nhầm "cá biển thịt chắc **tương tự**" (Cá Biển Kho bị gắn soy) và "tương xí muội" (sốt mận). Bảng FCT gốc thiếu tag sesame cho chính nguyên liệu "Vừng". Phát hiện khi kiểm lại theo câu hỏi của người dùng. | Thay `tương` bằng các loại tương cụ thể (tương bần, tương hột...). Thêm tag sesame cho Vừng. Rà lại mọi tag chỉ đến từ từ khóa: còn 3, đều đúng. | Đã sửa |
| V19 | `seed_ingredients` chèn **không có id** (DB tự sinh), `seed_recipes` lại gắn cứng UUID của production → dựng DB mới từ repo **lỗi khóa ngoại**. | Seed nguyên liệu dùng đúng UUID production. Dựng lại toàn bộ DB từ migrations đã chạy được. | Đã sửa |
| V2 | Edge `calculate-bmr-tdee` tự cài lại công thức bằng số thực JS (bản thứ 3 cạnh SQL và Dart), không kiểm kiểu, bỏ qua lỗi lưu. | Gọi RPC `calculate_nutrition_targets` (một nguồn công thức), validate đầy đủ, lỗi lưu trả 500. 810/810 khớp SQL và app. | Đã sửa |
| V3 | `42501` (token anon không có quyền RPC) không được map; body `null` vẫn đọc `b.meal_type`. | Map `42501` → 401; body phải là JSON object → 400. | Đã sửa |
| V4 | Dashboard dùng mục tiêu hiện tại, lịch sử dùng snapshot → hai con số cho cùng ngày. | Một quy tắc chung (`day_target_kcal`): ngày đã qua = snapshot, hôm nay = hiện tại. | Đã sửa |
| V5 | `update_meal_log_item` không kiểm cửa sổ ngày như `log_meal`. | Chặn sửa món cũ hơn 30 ngày. | Đã sửa |
| V6 | Nhân tỉ lệ trên giá trị đã làm tròn `NUMERIC(8,2)`. | Lưu `NUMERIC(14,6)`. 333→7→1999→3→1777→13→333 g cho đúng 499.5 kcal. | Đã sửa |
| V7 | `profiles` không có CHECK, app ghi thẳng. | CHECK tuổi 10–100, calo 800–10000, macro/bmr/tdee trong khoảng (đã kiểm production không dòng nào vi phạm). | Đã sửa |
| V9 | Contract viết trước cho endpoint dự kiến, không cập nhật khi deploy bản thật. | Mục 1 mô tả đúng `calculate-bmr-tdee`; `Goal` = `gain_weight`; ví dụ số liệu đúng; mục 4 cập nhật quy tắc mục tiêu, lỗi 401/400 mới. | Đã sửa |
| V12 | `get_ingredient_details` không lọc `is_active`. | Thêm điều kiện `is_active`. | Đã sửa |
| V14 | Policy SELECT `USING (true)`, `search_recipes` không lọc `is_verified`; còn món demo do script test cũ để lại; `p_limit` không giới hạn. | Policy/RPC chỉ trả món đã duyệt; xóa món demo; `p_limit` tối đa 100. | Đã sửa |
| V8 | Cấu hình Auth chỉnh trên Dashboard, không đồng bộ về `config.toml`; `mailer_autoconfirm = true`. | `config.toml` đổi độ dài mật khẩu tối thiểu 6 → 8 cho khớp remote. **Chưa bật xác nhận email** (cần quyết định, xem dưới). | Một phần |

### Giới hạn đã biết
- 85 dòng nguyên liệu cố ý không map (nước, sả, gia vị lượng nhỏ, rau ăn kèm, đồ chay giả mặn không rõ thành phần). Thiếu calo đáng kể: nước mía (500 g), nước cốt dừa (100 g), táo đỏ (900 g, nghi lỗi parse khối lượng) — FCT không có món tương đương.
- Một số map là gần đúng về dinh dưỡng (vd `mắm cá linh` → Mắm tép chua, `bánh mì` → Bánh mì xíu mại) nhưng đúng nhóm dị ứng.
- Đồ chay giả mặn (`sườn non chay`, `chả quế chay`) thường làm từ đậu nành/bột mì nhưng không rõ thành phần nên không gắn tag.
- **Phần ăn được (`edible_portion_pct`) không được áp khi tính dinh dưỡng món** (đúng spec `DATA_SPECIFICATION.md` 2.2: khối lượng trong hệ thống là phần ăn được). Nhưng dữ liệu crawl lẫn hai kiểu: `gà 2000g`, `đuôi heo 1000g` là khối lượng mua cả xương (tính dư, vd Đuôi heo hầm 1365 kcal/khẩu), còn `tỏi băm 10g` là phần ăn được. Cần chốt quy ước và duyệt từng dòng trước khi áp tỉ lệ.
