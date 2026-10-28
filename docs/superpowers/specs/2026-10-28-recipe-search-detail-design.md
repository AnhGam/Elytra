# Thiết kế: màn Tìm kiếm món & Chi tiết món (Sprint 4)

Ngày: 28/10/2026 · Nhánh: `feat/recipe-search-detail-ui`
Nguồn giao diện: `docs/design/sprint4/README.md`, `docs/design/sprint4/sprint4-ke-hoach-mon-an.md`, ảnh trong `docs/design/sprint4/screens/`.
Nguồn dữ liệu: migration `search_recipes` và đặc tả `/meal-logs` (mục 4 `docs/api-contract.md`) trên nhánh `origin/feat/meal-logs-sprint-5` (PR #4, chưa merge, **không merge vào nhánh này**). Đọc bằng `git show origin/feat/meal-logs-sprint-5:<đường dẫn>`.

Ghi chú: "(quyết định của Claude)" đánh dấu chỗ người viết tự chọn, chưa được nhóm chốt riêng.

## 1. Mục đích

Người dùng tìm món Việt theo tên, lọc theo calo/thời gian/độ khó/nhóm món/dị ứng, xem chi tiết món (nguyên liệu, cách nấu, dinh dưỡng mỗi phần so với mục tiêu của mình) và ghi 1 phần vào bữa hiện tại. Đây cũng là sprint dựng khung điều hướng 4 tab cho cả app.

## 2. Mục tiêu / Không làm / Thất bại nếu

**Mục tiêu**
- Màn Tìm kiếm và Chi tiết bám khung Figma (Sprint 4 – Món ăn, 833:2), dữ liệu thật từ Supabase production.
- Khung 4 tab (Trang chủ · Nhật ký · Món ăn · Cá nhân).
- Logic lọc, sắp xếp, định dạng nguyên liệu, chọn bữa là Dart thuần, viết TDD.
- Khai báo dị ứng (bottom sheet) vì app chưa có chỗ nào ghi `user_allergens`.

**Không làm (sprint này)**
- Sửa bất cứ thứ gì trong `supabase/`.
- Tìm theo nguyên liệu (RPC chưa hỗ trợ).
- Logic "Từ tủ lạnh", "Món phổ biến", nút AI: chỉ có giao diện.
- Lưu "Tìm gần đây" xuống máy (chỉ giữ trong phiên).
- `video_url`, yêu thích, tác giả, tags.
- Nội dung thật cho tab Nhật ký, Cá nhân (màn "Sắp có").
- Thay màu hard-code trong các màn cũ (onboarding, result) bằng token mới.

**Thất bại nếu (dù chạy được)**
- Logic lọc/sắp xếp nằm trong widget, không test được, hoặc đổi sang lọc trên server phải sửa UI.
- Đăng xuất/đăng nhập, ProfileGate, đặt lại mật khẩu bị hỏng do đổi router.
- Món chứa chất dị ứng đã khai báo vẫn hiện khi bật "Bỏ món dị ứng".
- Bấm "Thêm" nhiều lần khi mạng chập chờn ghi trùng bữa ăn.
- Số liệu không theo định dạng Việt Nam hoặc dùng màu ngoài `AppColors`.

## 3. Ràng buộc

- Nhóm xác nhận (28/10): bản cuối `search_recipes` (có `condiment_allergens`, cột `recipe_allergens.via_condiment`, RLS chỉ món đã duyệt) và Edge Function `meal-logs` **đã chạy trên production**, dù migration chỉ nằm ở nhánh PR #4. Vì vậy nút "Thêm" gọi thật, không để "Sắp có" như mục 5.1 của kế hoạch Sprint 4.

- Back-end là Supabase production. `search_recipes` (bản cuối) nhận `p_query, p_category, p_is_vegetarian, p_max_calories, p_exclude_allergen_ids, p_limit, p_offset`; trả các cột của món + `video_url`, `is_vegetarian`, `allergens INT[]` (mọi chất, kể cả từ gia vị), `condiment_allergens INT[]` (chất chỉ đến từ gia vị); chỉ món `is_verified`; sắp theo `title`; `p_limit` tối đa 100.
- `recipe_allergens` chỉ đọc được với món đã duyệt; `user_allergens` người dùng tự đọc/ghi (policy `FOR ALL`); `allergens` (8 chất, id 1–8) ai cũng đọc.
- `/meal-logs`: app không insert thẳng bảng; gọi `supabase.functions.invoke('meal-logs', body: …)`. Lỗi trả `{error: {code, message, field}}`.
- `instructions` là JSON `[{step_number, title, description}]`, `description` dài, có nhiều `\n\n`.
- Dữ liệu nguyên liệu seed (604 dòng, remap không sửa amount/unit/amount_g/raw_text): `ít` 80 dòng (1 ít = 2 g), `phần` 85 dòng (thường 1 phần = 30 g mặc định, có dòng tách lượng sai như "3 lòng đỏ trứng gà"), 129 dòng `raw_text` không có `:`, `muỗng cà` bị cắt chữ và tính 30 g.
- Quy ước repo: màu từ `AppColors`, font Be Vietnam Pro, số kiểu VN (`NumberFormat(..., 'vi')`), chuỗi và comment tiếng Việt; `flutter analyze` sạch, `flutter test` qua.

## 4. Phương án đã cân nhắc

| | Cách làm | Được | Mất |
|---|---|---|---|
| **A (đã chọn)** | Theo idiom hiện có: repository singleton cấp file, `ChangeNotifier` cho cache và controller, không thêm thư viện | Khớp code auth/onboarding, nhóm đọc quen; logic thuần vẫn test được | Truyền phụ thuộc thủ công |
| B | Riverpod cho DI, cache, controller | Override dễ trong test, hợp khi app lớn | Thêm thư viện và lối viết mới, lệch code cũ |
| (loại) | Toàn bộ `setState` trong widget | Nhanh | Không test được lọc/cache, trái yêu cầu TDD |

Nhóm chọn **A**, chỉnh: cache **không toàn cục** mà nằm trong `RecipeScope` (InheritedNotifier) tạo trong `ElytraApp`, bọc qua `builder:` của `MaterialApp.router` (để cả màn Chi tiết trên root navigator, bottom sheet và dialog đều đọc được); widget test tự tạo catalog riêng nên không dùng chung cache. Lọc/sắp xếp làm **trên máy** sau một lần tải (≈ 45 món), vì RPC thiếu tham số; xem mục 11.

## 5. Kiến trúc

```
lib/main.dart               ElytraApp thành StatefulWidget: tạo RecipeCatalog, bọc RecipeScope qua builder: của MaterialApp.router
lib/core/router.dart        StatefulShellRoute 4 nhánh + redirect hiện có
lib/core/app_shell.dart     Scaffold + NavigationBar, xử lý Back
lib/core/meal_time.dart     vnNow(), mealTypeAt(DateTime), tỉ lệ bữa (thuần trừ vnNow)
lib/features/recipes/
  recipe.dart               model Recipe (từ search_recipes / bảng recipes), RecipeIngredient, RecipeStep
  recipe_query.dart         RecipeQuery + RecipeFilters + RecipeSort (thuần)
  slugify.dart              chuẩn hóa từ khóa (thuần)
  ingredient_format.dart    formatIngredient (thuần)
  recipe_repository.dart    interface RecipeRepository + SupabaseRecipeRepository + recipeRepo
  recipe_catalog.dart       RecipeCatalog (ChangeNotifier) + RecipeScope (InheritedNotifier)
  recipe_search_controller.dart, recipe_detail_controller.dart
  recipe_search_screen.dart, recipe_detail_screen.dart
  widgets/                  RecipeCard, MacroRow, các bottom sheet (Lọc, Sắp xếp, Dị ứng), skeleton
lib/features/meal_logs/meal_log_repository.dart   POST /meal-logs
```

Tên file là gợi ý; người dựng được đổi miễn giữ ranh giới: **UI không gọi Supabase trực tiếp**, chỉ qua repository/catalog/controller.

### 5.1 Repository (interface, không giữ trạng thái)

```dart
abstract class RecipeRepository {
  Future<List<Recipe>> fetchAll();                 // search_recipes(p_limit: 100), không truyền lọc nào
  Future<RecipeDetail?> fetchDetail(String id);    // recipes + recipe_ingredients (order_index) + recipe_allergens; null nếu không thấy
  Future<UserNutritionProfile?> fetchProfile();    // profiles.target_calories/protein/carbs/fat/fiber
  Future<List<Allergen>> fetchAllergens();         // bảng allergens
  Future<Set<int>> fetchUserAllergenIds();
  Future<void> saveUserAllergenIds(Set<int> ids);  // xóa các dòng thừa + upsert dòng mới của user hiện tại
}
```
- `fetchAll` trả đúng 100 món → `debugPrint` cảnh báo "search_recipes trả 100 món, có thể thiếu món".
- Bản Supabase: `final recipeRepo = SupabaseRecipeRepository();` cấp file, như `nutritionRepo`.
- `MealLogRepository.addRecipe({recipeId, mealType, date, clientRequestId})` gọi POST `/meal-logs` với `servings: 1`, trả `Budget` (hiện chưa dùng ngoài việc báo thành công). Ném lỗi có kiểu: `ProfileNotFound`, `NetworkError`, `MealLogError(code, message)`.

### 5.2 RecipeCatalog + RecipeScope

- Tạo **một lần** trong State của `ElytraApp`, dispose cùng app. Chia sẻ bằng `RecipeScope extends InheritedNotifier<RecipeCatalog>` đặt trong `builder:` của `MaterialApp.router` (trên root navigator: shell, màn Chi tiết, bottom sheet, dialog đều đọc được), đọc qua `RecipeScope.of(context)`.
- Nghe `supabase.auth.onAuthStateChange`: `signedOut` hoặc user id đổi so với lần tải trước → `clear()` (xóa món, hồ sơ, dị ứng, về trạng thái chưa tải).
- Giữ: `recipes`, `profile`, `allergens` (8 chất), `userAllergenIds`, trạng thái `loading / error / ready`.
- `load()` lần đầu (khi tab Món ăn được mở lần đầu), `refresh()` khi kéo xuống: tải lại **cả** món, hồ sơ và dị ứng của user.
- `saveAllergens(ids)` ghi qua repo rồi cập nhật `userAllergenIds` và `notifyListeners`.

### 5.3 Controller

- `RecipeSearchController` (ChangeNotifier): tạo/dispose trong State của tab Món ăn (shell giữ nhánh sống nên còn từ khóa, lọc, vị trí cuộn). Giữ `query`, `RecipeFilters`, `RecipeSort`, `recentSearches` (tối đa 5, mới nhất trước, bỏ trùng; quyết định của Claude), cờ "Bỏ món dị ứng" (mặc định bật). Kết quả = `RecipeQuery.apply(catalog.recipes, …)`; nghe catalog để tính lại.
- Từ khóa vào "Tìm gần đây" khi người dùng submit hoặc mở một món từ kết quả đang có từ khóa (quyết định của Claude). Gõ có debounce 300 ms (quyết định của Claude).
- `RecipeDetailController`: tạo mới mỗi lần mở chi tiết. Nhận `id` + `Recipe?` (từ `extra`); tải `fetchDetail(id)`; giữ `cookServings` (khởi đầu = `recipe.servings`, 1–20; quyết định của Claude), tập bước đã đánh dấu, trạng thái thêm bữa (`idle / sending / done`), `clientRequestId` hiện tại.
- Cả hai controller có unit test riêng với repo giả.

## 6. Khung điều hướng

- `StatefulShellRoute.indexedStack` 4 nhánh: `/home` (HomePlaceholder, giữ đường dẫn vì auth/ProfileGate `go('/home')`), `/diary` ("Sắp có"), `/recipes` (Tìm kiếm), `/profile` ("Sắp có"). Tên `/diary`, `/profile` là quyết định của Claude.
- `/recipes/:id` là route con của `/recipes`, `parentNavigatorKey: rootNavigatorKey`: che thanh điều hướng, Back về đúng màn Tìm kiếm với trạng thái cũ. `extra` là `Recipe` khi mở từ danh sách.
- `redirect` hiện có áp dụng cho mọi route của shell: chưa đăng nhập → `/welcome`.
- Back Android trong shell: tab ≠ Trang chủ → chuyển về Trang chủ; đang ở Trang chủ → thoát app. Dùng `PopScope` trong shell.
- NavigationBar Material 3, icon Material Symbols như Figma; chỉ báo tab dùng `primaryContainer`.
- Widget test: (1) gõ từ khóa ở Món ăn, chuyển sang Trang chủ rồi quay lại → từ khóa còn; (2) mở thẳng `/recipes/<id>` (không extra) → tải và hiện tên món từ repo giả.

## 7. Màn Tìm kiếm

Bố cục theo Figma 836:2. Điểm khác Figma:
- Placeholder "Tìm tên món…" (không còn "hoặc nguyên liệu").
- Trạng thái chưa nhập (839:557): giữ "Tìm gần đây" (có "Xóa tất cả", nút × từng dòng) và "Món phổ biến"; **bỏ** mục "Tìm theo nguyên liệu".
- "Món phổ biến": chỉ giao diện. (quyết định của Claude) Hiện 3 món đầu của danh sách đã tải theo sort "Phù hợp nhất", không gắn logic phổ biến.

Thành phần:
- Ô tìm kiếm + nút lọc (icon `ic_tune`, badge = số nhóm lọc đang khác mặc định trong sheet Bộ lọc: calo, thời gian, độ khó; quyết định của Claude).
- Hàng chip lọc nhanh: "Bỏ món dị ứng" (bật sẵn) · "Từ tủ lạnh" (bật/tắt được về hình thức, **không ảnh hưởng kết quả**; quyết định của Claude) · "≤ 500 kcal" (`maxKcal = 500`; calo là số thập phân, 500,0 vẫn thỏa) · "≤ 30 phút". Chip nhanh và sheet Bộ lọc dùng chung một `RecipeFilters`.
  - Chưa khai báo dị ứng (`userAllergenIds` rỗng): chip hiện "Khai báo dị ứng", bấm mở sheet "Dị ứng của bạn".
- Hàng chip nhóm món: "Tất cả" + các `category` có ít nhất 1 món trong dữ liệu đã tải; nhãn: `mon_man` Món mặn · `mon_kho` Món kho · `mon_an_sang` Món ăn sáng · `mon_chay` Món chay · `mon_canh` Món canh · `mon_xao` Món xào · `mon_nuong` Món nướng; giá trị lạ hiện nguyên văn.
- Dòng "N món" + nút sắp xếp (nhãn = tiêu chí đang chọn).
- `RecipeCard`: ảnh `image_url` cao 144 (lỗi/null → nền `surfaceVariant` + icon), chip nhóm món, tên trên ảnh (`displayTitle`, tối đa 2 dòng, `…`), kcal 14/700 + P/C/F chấm màu, tổng thời gian ("40 phút", "3 giờ 20 phút"), "N phần", độ khó (Dễ/Vừa/Khó).
- Sheet Bộ lọc (837:184): Calo tối thiểu/tối đa (2 ô số nguyên 0–1.500, để trống = không giới hạn; min > max → báo lỗi dưới ô, nút "Xem" vô hiệu; quyết định của Claude), Thời gian nấu (Bất kỳ/≤15/≤30/≤60), Độ khó (chọn nhiều; quyết định của Claude), Nguyên liệu trong tủ lạnh (chỉ giao diện, không có dữ liệu), công tắc dị ứng (dòng phụ liệt kê tên chất đã khai báo + "sửa" mở sheet Dị ứng). Nội dung cuộn, footer "Xóa lọc" / "Xem N món" cố định; N tính trực tiếp khi đổi lọc. Thay đổi chỉ áp dụng khi bấm "Xem".
- Sheet Sắp xếp (837:304): 7 tiêu chí, xem 8.1.
- FAB AI: chỉ giao diện (bấm không làm gì, hoặc SnackBar "Sắp có"; quyết định của Claude: SnackBar).
- Trạng thái: đang tải lần đầu → skeleton (839:892); lỗi mạng khi chưa có cache → màn Mất mạng (839:1099) + "Thử lại"; lỗi khi kéo tải lại mà đã có cache → giữ danh sách cũ + SnackBar; 0 kết quả → 839:673 (gợi ý xóa lọc / đổi từ khóa).

## 8. Logic thuần (TDD)

### 8.1 RecipeQuery

`RecipeQuery.apply(List<Recipe>, {String query, RecipeFilters filters, RecipeSort sort, Set<int> excludeAllergenIds, int? mealBudgetKcal}) → List<Recipe>`; "N món" = độ dài kết quả. Không đọc giờ hệ thống.

Lọc (AND):
- Từ khóa: **không** so với cột `slug` (slug là slug bài viết gốc, vd `cach-lam-ca-chim-kho-…`, 42/44 slug chứa "ca" → nhiễu). Chỉ so với tên món, theo từng từ:
  - Tách từ: thường hóa, mọi ký tự không phải chữ/số là dấu ngăn cách. Ra danh sách từ của tên và của từ khóa.
  - Không còn từ nào → bỏ qua lọc.
  - Khớp khi **mỗi** từ của từ khóa là phần đầu của **ít nhất một** từ trong tên.
  - Từ gõ vào có dấu (kể cả `đ`) → so với từ của tên ở dạng có dấu (đã thường hóa); không dấu → so với dạng đã bỏ dấu. Vd "ca kho" khớp "Cá basa kho tộ"; "ca" khớp cả "Canh gà" (chấp nhận); "cá" không khớp "Canh gà"; "phở bo" khớp "Phở bò". Xét dấu **theo từng từ** (quyết định của Claude, cách hiểu "từ khóa có dấu thì so có dấu" khi chỉ một phần từ khóa có dấu).
- `slugify` (bỏ dấu tiếng Việt, `đ→d`, ký tự không phải chữ/số → `-`, gộp và bỏ `-` đầu/cuối; "  Phở  BÒ " → `pho-bo`) vẫn dùng cho: dạng bỏ dấu khi so từ, so tiền tố "Tên:" trong `formatIngredient`, và `p_query` khi chuyển lọc lên server.
- Dị ứng: loại món có `allergens` giao với `excludeAllergenIds` (chỉ khi bật "Bỏ món dị ứng"; mảng `allergens` đã gồm chất từ gia vị).
- Calo: `minKcal ≤ calories_per_serving ≤ maxKcal`, mỗi đầu có thể null, biên tính là thỏa.
- Thời gian: `prep_time_minutes + cook_time_minutes ≤ maxTotalMinutes`.
- Độ khó: thuộc tập đã chọn (rỗng = mọi độ khó).
- Nhóm món: bằng `category` đang chọn (null = Tất cả).

Sắp xếp (mọi tiêu chí, hòa thì theo tên A–Z, so sánh trên `slugify(title)` để không lệch vì dấu):
- **Phù hợp nhất**
  1. Có từ khóa: mức khớp `tên bắt đầu bằng từ khóa` (dãy từ của từ khóa khớp đầu dãy từ của tên) > `khớp nguyên từ` (mọi từ gõ vào trùng nguyên một từ trong tên) > `khớp đầu từ` (còn lại); cùng mức → bước 2.
  2. Có `mealBudgetKcal`: món `kcal ≤ ngân sách` đứng trước món vượt; trong mỗi nhóm, `|kcal − ngân sách|` nhỏ hơn lên trước.
  3. `mealBudgetKcal` null: theo tên A–Z.
  4. Bằng nhau mọi tiêu chí: theo tên.
- Calo thấp → cao; Calo cao → thấp.
- Protein / 100 kcal cao nhất; Carbs / 100 kcal thấp nhất; Fat / 100 kcal thấp nhất. Món 0 kcal: (quyết định của Claude) đặt cuối danh sách cho cả 3 tiêu chí.
- Nấu nhanh nhất: tổng thời gian tăng dần.

Test bắt buộc: mỗi bộ lọc (cả biên đúng bằng min/max, chỉ một đầu, min = max, kcal thập phân 500,0 với "≤ 500"); từ khóa có dấu/không dấu/hoa/khoảng trắng thừa/`đ`; "ca" khớp "Canh gà", "cá" không khớp; nhiều từ phải khớp đủ; không bao giờ khớp qua `slug`; 3 mức khớp của Phù hợp nhất; từng quy tắc Phù hợp nhất, kể cả kcal **đúng bằng** ngân sách (thuộc nhóm ≤) và ngân sách null; hòa → theo tên; 7 tiêu chí; danh sách rỗng.

`displayTitle(title)`: tên món trong DB dài và viết hoa không thống nhất → chỉ cắt khoảng trắng thừa (đầu/cuối và gộp khoảng trắng liên tiếp) và viết hoa chữ cái đầu; **không** viết thường phần còn lại, để giữ tên riêng ("cơm chiên Dương Châu" → "Cơm chiên Dương Châu", "  bò  xào Mông Cổ " → "Bò xào Mông Cổ"). Viết hoa không thống nhất trong DB giữ nguyên cho tới khi có cột tên ngắn (mục 13). Test: khoảng trắng thừa, chữ đầu thường/đã hoa/có dấu ("ếch" → "Ếch"), tên riêng giữa câu giữ nguyên, chuỗi rỗng.

### 8.2 Bữa theo giờ

`MealType mealTypeAt(DateTime t)`: 04:00 ≤ t < 10:30 sáng; < 14:30 trưa; < 17:00 phụ; < 21:30 tối; còn lại (kể cả 00:00–04:00) phụ. Tỉ lệ: sáng 25, trưa 35, tối 30, phụ 10 (%). `mealBudgetKcal = round(target_calories × tỉ lệ)`. `date` gửi `/meal-logs` = `YYYY-MM-DD` của **cùng** `DateTime` đó. Test từng mốc biên (03:59, 04:00, 10:29, 10:30, 14:30, 17:00, 21:29, 21:30, 23:59, 00:00).

"Bây giờ" theo **giờ Việt Nam**, khớp server (`vn_today()`): `DateTime vnNow() => DateTime.now().toUtc().add(const Duration(hours: 7));` đặt ở **một chỗ duy nhất** (`meal_time.dart`); không gọi `toLocal()`. Đọc giờ/phút/ngày từ giá trị này (là `DateTime` UTC đã dịch 7 giờ). Các hàm thuần nhận `DateTime` làm tham số, không tự gọi `vnNow()`.

Thời điểm lấy "bây giờ": màn Tìm kiếm tính một lần khi build danh sách; màn Chi tiết tính khi mở màn và dùng lại cho dòng "≈ X%", ngưỡng natri và nút Thêm (quyết định của Claude, để ba chỗ không lệch nhau nếu mở màn đúng lúc qua mốc giờ).

### 8.3 formatIngredient

`IngredientLine formatIngredient(RecipeIngredient row, double factor)` → `{name, amountText?, gramText?, note?}`:
1. Tên: `ingredient_name_raw`, viết hoa chữ cái đầu.
2. Chuẩn hóa unit: `gram` → `g`; `muỗng cà`, `muỗng cafe` → `muỗng cà phê`; còn lại giữ nguyên.
3. Lượng = `amount × factor`; định dạng VN, `.5` → `½` ("1½ muỗng canh", "½ củ"), tối đa 1 chữ số thập phân ("2,3 kg").
4. Dòng gam mờ (`amount_g × factor`, "60 g") chỉ với đơn vị đếm được (củ, quả, trái, cây, miếng, chén, bó, nhánh, tép, lát, con, cái…); ẩn với g/kg/ml/lít và mọi loại muỗng.
5. unit `phần` hoặc `ít`, hoặc `amount` null: không có số, không nhân hệ số; `note` = `raw_text` bỏ tiền tố "Tên:" nếu phần trước dấu `:` trùng tên (so sau slugify), chữ mờ; còn trống → "Tùy thích".

`factor = cookServings / recipe.servings`. Test dùng các mẫu thật: "Đậu hũ: 4 miếng (400g)", "Thịt xay: 200g", "Hành lá: để riêng phần gốc…" (phần), "Hạt nêm: 1 muỗng cà phê" (muỗng cà), dòng `ít`, dòng không có `:`, dòng tách lượng sai "3 lòng đỏ trứng gà", factor 0,5 và 1,5.

## 9. Màn Chi tiết

Bố cục theo Figma 844:916 (toàn trang), 844:1102 (dị ứng), 844:1294 (đổi khẩu phần, đã cuộn), 844:1487 (đang tải).

- Hero 240 + nút quay lại (vùng chạm 48), chip nhóm món, tên (`displayTitle`, tối đa 2 dòng), dòng phụ "`cuisine` · độ khó" (`vietnamese` → "Việt Nam"; giá trị khác hiện nguyên văn; quyết định của Claude).
- Banner dị ứng (`errorContainer`, chữ `onErrorContainer`): khi `recipe.allergens ∩ userAllergenIds` ≠ ∅, kể cả khi chip lọc tắt. Nội dung "Có <tên chất>, …" theo `allergens.name_vi`; chất thuộc `condiment_allergens` (từ chi tiết: `recipe_allergens.via_condiment`) thêm "(từ gia vị)". Không chặn nút Thêm, không hỏi xác nhận.
- Lưới 4 ô Calo/Protein/Carbs/Fat (màu macro theo token mới, ô Fat viền `fatOutline`).
- Dòng bữa: `kcal ≤ mealBudget` → "≈ X% calo bữa <tên bữa> của bạn (<budget> kcal)"; `kcal > mealBudget` → "Vượt Y kcal so với bữa <tên bữa>" màu cảnh báo (`onErrorContainer` trên `errorContainer`; quyết định của Claude). Không có `target_calories` → ẩn dòng.
- Meta: "Chuẩn bị N phút · Nấu N phút · N phần".
- Nguyên liệu: nhãn "Nấu cho" + stepper −/+ (chỉ nhân lượng nguyên liệu); dòng theo `formatIngredient`.
- Cách nấu: "N bước"; mỗi bước: số trong ô vuông, `title` đậm (bỏ tiền tố "Bước N:" nếu có; quyết định của Claude), `description` bên dưới, gộp dòng trống liên tiếp thành một khoảng cách đoạn. Chạm để đánh dấu xong (gạch ngang, ô check), chỉ trong màn.
- Thông tin dinh dưỡng (mỗi khẩu phần): thanh tỉ lệ năng lượng (P×4, C×4, F×9); 6 dòng Calo, Protein, Carbs, Fat, Chất xơ, Natri với số + % mục tiêu ngày + thanh. Mục tiêu từ `profiles.target_*`; natri so 2.000 mg/ngày. Chất có mục tiêu null → chỉ hiện số. Natri vượt phần của bữa hiện tại (`2.000 × tỉ lệ bữa`) → dòng cảnh báo "Natri cao – …". Chú thích cuối: "Số liệu ước tính từ nguyên liệu · mục tiêu ngày <kcal> kcal, natri tối đa 2.000 mg".
- Nút ghim đáy "Thêm 1 phần vào bữa <tên bữa>" (nền `primaryDark`):
  - Bấm: sinh `client_request_id` (UUID v4) **một lần**, gửi `{meal_type, recipe_id, servings: 1, date, client_request_id}`; nút hiện đang gửi, chặn bấm lặp.
  - `client_request_id`: UUID v4 tự sinh từ 16 byte `Random.secure()` (không thêm thư viện), **đặt đúng bit**: byte 6 = `(b & 0x0F) | 0x40` (version 4), byte 8 = `(b & 0x3F) | 0x80` (variant `10xx`); in chữ thường dạng 8-4-4-4-12. Test: khớp regex `^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$` trên nhiều lần sinh, hai lần sinh khác nhau.
  - Thành công (201 hoặc 200 replayed) → SnackBar "Đã thêm 1 phần vào bữa trưa"; reset `client_request_id` để lần bấm sau là một lần ghi mới.
  - Mất mạng / timeout → SnackBar "Không có kết nối" + "Thử lại" (gửi **lại đúng** `client_request_id` cũ).
  - `PROFILE_NOT_FOUND` → SnackBar "Bạn cần hoàn tất hồ sơ trước" + "Khai báo" → `context.go('/gate')` (ProfileGate tự quyết đi tiếp).
  - Lỗi khác → SnackBar thông báo chung.
- Trạng thái: có `extra` → hiện ngay hero/tên/calo/lưới 4 ô, skeleton cho phần còn lại; không có `extra` → skeleton toàn màn; lỗi/mất mạng → thông báo + "Thử lại"; không tìm thấy/chưa duyệt → "Không tìm thấy món" + nút quay lại.

## 10. Sheet "Dị ứng của bạn"

Mở từ chip "Khai báo dị ứng" và từ dòng phụ trong sheet Bộ lọc. 8 dòng checkbox theo `allergens` (`name_vi`, mô tả nhỏ `description`), nút "Lưu". Lưu qua `RecipeCatalog.saveAllergens` → `user_allergens`; lỗi → giữ sheet mở + thông báo. Lưu xong chip đổi thành "Bỏ món dị ứng" (bật). (Giao diện sheet chưa có trong Figma: dựng theo kiểu sheet Bộ lọc; quyết định của Claude.)

## 11. Màu (`AppColors`)

Theo mục "Việc của code" trong kế hoạch:
- Sửa: `textMuted` 0xFF5B6B80, `outlineStrong` 0xFFD1DCE8, `primaryDisabled` 0x6615803D. Nút chính chữ trắng dùng nền `primaryDark`.
- Thêm: `primarySurface` F0FDF4, `primaryOutline` BBF7D0, `surfaceVariant` F8FAFC, `placeholder` CBD5E1, `protein` 0284C7 / `proteinContainer` E0F2FE / `onProteinContainer` 075985 / `proteinOutline` BAE6FD, `carbs` D97706 / `carbsContainer` FEF3C7 / `onCarbsContainer` 92400E / `carbsOutline` FDE68A, `fat` 6366F1 / `fatContainer` EEF2FF / `onFatContainer` 4F46E5 / `fatOutline` C7D2FE, `onErrorContainer` BE123C.
- `textSubtle` chỉ dùng cho icon/đường kẻ, không dùng cho chữ.
- Đổi `textMuted`/`outlineStrong`/`primaryDisabled` ảnh hưởng các màn cũ: đây là chủ đích của kế hoạch; kiểm tra nhanh bằng mắt các màn onboarding/auth sau khi đổi.

## 12. Kiểm thử

- Unit (TDD, viết trước): `slugify`, `RecipeQuery`, `formatIngredient`, `displayTitle`, `mealTypeAt` + ngân sách bữa, định dạng thời gian ("3 giờ 20 phút"), sinh UUID v4.
- Unit controller với repo giả: `RecipeSearchController` (đổi lọc/sort/từ khóa, tìm gần đây, chip dị ứng khi chưa khai báo), `RecipeDetailController` (stepper, giữ `client_request_id` khi retry, reset sau thành công, map lỗi).
- Widget: chuyển tab giữ từ khóa; mở thẳng `/recipes/:id`.
- Widget test router (giả lập trạng thái đăng nhập): chưa đăng nhập vào `/recipes` → `/welcome`; đã đăng nhập, `/home` vẫn mở trong shell.
- `flutter analyze` sạch, `flutter test` qua (chạy trong `app/`).
- Kiểm tra tay (ghi kết quả vào PR):
  - [ ] Đặt lại mật khẩu: mở link khôi phục → chỉ ở `/reset-password`; đặt xong → vào app bình thường.
  - [ ] Đăng ký mới (khai báo → kết quả → đăng ký) → ProfileGate → `/home` có thanh 4 tab.
  - [ ] Đăng xuất rồi đăng nhập tài khoản khác → danh sách dị ứng, mục tiêu là của tài khoản mới.
  - [ ] Back Android: tab Món ăn → Trang chủ → thoát app; Chi tiết → Back về Tìm kiếm còn từ khóa.

## 13. Đề xuất cho back-end

Gửi nhóm back-end (không sửa trong nhánh này):
1. `search_recipes` thêm `p_min_calories`, `p_max_total_time` (prep + cook), `p_difficulty`, `p_sort` và trả tổng số món (vd cột `total_count` qua `COUNT(*) OVER()`), để chuyển lọc/sắp xếp sang server khi số món tăng. Khi có, chỉ sửa `SupabaseRecipeRepository` (và `RecipeQuery` thành lớp mỏng), UI không đổi.
2. Tìm theo nguyên liệu (khớp `recipe_ingredients.ingredient_name_raw` / `ingredients.name_unaccented`).
3. Cột tên ngắn cho món (vd `short_title`, viết hoa chuẩn): `title` hiện là tiêu đề bài viết, dài và viết hoa không thống nhất; `slug` là slug bài viết nên `search_recipes` khớp `slug` bằng `ILIKE` gây nhiễu (gõ "ca" ra gần hết món) → nên khớp theo tên ngắn/không dấu.
4. Dữ liệu nguyên liệu làm lệch dinh dưỡng:
   - `muỗng cà` (muỗng cà phê) đang tính 30 g/muỗng, đúng ≈ 5 g; đơn vị bị cắt chữ.
   - Hạt nêm `muỗng cà` tính 30 g → natri món bị đẩy lên hàng nghìn mg.
   - 85 dòng `phần` mặc định 30 g; một số dòng tách lượng sai (vd "3 lòng đỏ trứng gà").

## 14. Hướng mở

- Khi Nhật ký/Dashboard cần chia sẻ hồ sơ và meal-logs, cân nhắc Riverpod cho cả app; quyết định cùng nhóm.
- Lưu "Tìm gần đây" xuống máy; logic "Từ tủ lạnh", "Món phổ biến", trợ lý AI.

## 15. Để người dựng tự quyết

Thứ tự commit/PR, tên widget con, cách dựng skeleton, chi tiết animation, cách chia file trong `widgets/`, thông điệp lỗi cụ thể ngoài các trường hợp đã nêu.
