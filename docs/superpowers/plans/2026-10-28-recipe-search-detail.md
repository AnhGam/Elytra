# Màn Tìm kiếm món & Chi tiết món – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng khung 4 tab, màn Tìm kiếm món và Chi tiết món (nguyên liệu, cách nấu, dinh dưỡng, ghi 1 phần vào bữa) trên dữ liệu Supabase production.

**Architecture:** Logic thuần Dart (chuẩn hóa chữ, `RecipeQuery`, `formatIngredient`, bữa theo giờ, dinh dưỡng) viết TDD. Dữ liệu qua interface `RecipeRepository`/`MealLogRepository` (bản Supabase là singleton cấp file); cache phiên trong `RecipeCatalog` (ChangeNotifier) chia sẻ bằng `RecipeScope` (InheritedNotifier) đặt trong `builder:` của `MaterialApp.router`. Controller `ChangeNotifier` cho từng màn. Router go_router `StatefulShellRoute.indexedStack`.

**Tech Stack:** Flutter 3.47 / Dart 3.13, supabase_flutter 2.18 (functions_client 2.7.1), go_router 18.0.2, intl, flutter_svg, flutter_test. Không thêm package.

**Spec:** `docs/superpowers/specs/2026-10-28-recipe-search-detail-design.md` (đọc kèm; số mục "§" bên dưới trỏ vào spec).

**Cách thực thi (nhóm chốt 28/10):** Task 1–11 subagent-driven (reviewer từng task), dừng sau Task 11 và báo tóm tắt + số test. Task 12–15 (và 16) làm native ở phiên mới, dừng sau **mỗi** task để nhóm chạy app so với Figma.

## Global Constraints

- Mọi lệnh `flutter` chạy trong `app/`. Mỗi task kết thúc với `flutter analyze` sạch và `flutter test` qua.
- KHÔNG sửa `supabase/`. KHÔNG merge `origin/feat/meal-logs-sprint-5`.
- Màu chỉ từ `AppColors` (`app/lib/core/theme.dart`); font Be Vietnam Pro đã đặt trong theme, widget không gọi `GoogleFonts` trực tiếp.
- Số kiểu VN qua `NumberFormat(..., 'vi')`: "38,5 g", "1.968 kcal".
- Chuỗi giao diện và comment tiếng Việt; commit `loại(phạm vi): mô tả` tiếng Anh, kết thúc bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- UI không gọi `supabase` trực tiếp; chỉ qua repository/catalog/controller.
- "Bây giờ" = `vnNow()` (UTC+7), một chỗ duy nhất, không gọi `toLocal()`.
- Widget test không dùng `buildAppTheme()` (google_fonts tải font qua mạng) và không chạm `supabase` toàn cục; mọi thứ cần Supabase được tiêm bản giả.
- Skeleton là khối tĩnh (không shimmer), trạng thái tải không dùng `CircularProgressIndicator` trong màn Tìm kiếm/Chi tiết, để `pumpAndSettle` không treo.

## Review Focus

1. Tên món hoặc từ khóa ở dạng Unicode tổ hợp (NFD, dấu tách rời) → gõ "pho" vẫn phải ra "Phở". Test ở Task 1 và Task 4.
2. Dòng RPC/bảng có `image_url`, `description` null, số NUMERIC trả về dạng chuỗi, `instructions` rỗng/không phải mảng → không crash. Test ở Task 3.
3. Từ khóa chỉ gồm khoảng trắng/dấu câu ("  , . ") → coi như không có từ khóa, không lọc rỗng danh sách. Test ở Task 4.
4. `target_calories` = 0 → không chia cho 0, ẩn dòng "≈ X%". Test ở Task 7.
5. Bấm "Thêm" hai lần liên tiếp khi request đầu chưa xong → chỉ một request. Test ở Task 11.

---

## Cấu trúc file

```
app/lib/core/
  theme.dart                    (sửa) token màu mới
  meal_time.dart                (mới) MealType, vnNow, mealTypeAt, mealBudgetKcal, isoDate
  uuid.dart                     (mới) uuidV4
  router.dart                   (sửa) AuthGate, buildRouter, shell 4 tab
  app_shell.dart                (mới) NavigationBar + Back
  coming_soon_screen.dart       (mới)
app/lib/main.dart               (sửa) ElytraApp StatefulWidget, RecipeScope trong builder:
app/lib/features/recipes/
  recipe_text.dart              removeDiacritics, slugify, displayTitle, formatDuration
  recipe.dart                   Difficulty, Recipe, RecipeIngredient, RecipeStep, RecipeDetail, Allergen, UserNutritionProfile
  recipe_query.dart             MatchLevel, matchTitle, RecipeFilters, RecipeSort, RecipeQuery
  ingredient_format.dart        IngredientLine, formatAmount, formatIngredient
  recipe_nutrition.dart         EnergySplit, energySplit, pctOfTarget, MealFit, mealFit, sodiumHighForMeal
  recipe_repository.dart        RecipeRepository, SupabaseRecipeRepository, recipeRepo
  recipe_catalog.dart           CatalogStatus, RecipeCatalog, RecipeScope
  recipe_search_controller.dart
  recipe_detail_controller.dart
  recipe_search_screen.dart
  recipe_detail_screen.dart
  widgets/recipe_card.dart, widgets/recipe_chips.dart, widgets/filter_sheet.dart,
  widgets/sort_sheet.dart, widgets/allergen_sheet.dart, widgets/skeletons.dart,
  widgets/detail_sections.dart
app/lib/features/meal_logs/meal_log_repository.dart
app/test/core/…, app/test/recipes/…, app/test/meal_logs/…, app/test/helpers/…
```

---

### Task 1: Chuẩn hóa chữ (`recipe_text.dart`)

**Files:**
- Create: `app/lib/features/recipes/recipe_text.dart`
- Test: `app/test/recipes/recipe_text_test.dart`

**Interfaces:**
- Produces: `String removeDiacritics(String s)` (thường hóa + bỏ dấu + `đ→d`, giữ khoảng trắng/dấu câu); `String composeVietnamese(String s)` (đưa chữ tiếng Việt dạng tổ hợp NFD hoặc nửa tổ hợp về dạng dựng sẵn NFC, ký tự khác giữ nguyên); `List<String> wordsOf(String s)` (thường hóa → `composeVietnamese`, tách bởi mọi ký tự không thuộc `\p{L}`, `\p{M}`, `\p{N}`; bỏ phần rỗng – mọi từ trả về ở dạng NFC); `String slugify(String s)`; `String displayTitle(String s)`; `String formatDuration(int minutes)`.

- [ ] **Step 1: Viết test fail**

```dart
test('removeDiacritics bỏ dấu, đ→d, cả dạng NFD', () {
  expect(removeDiacritics('Phở Bò ĐẬU hũ'), 'pho bo dau hu');
  expect(removeDiacritics('Phở'), 'pho'); // "Phở" dạng tổ hợp
});
test('wordsOf thường hóa, giữ dấu, tách theo ký tự không phải chữ/số', () {
  expect(wordsOf('  Cá basa, KHO-tộ! '), ['cá', 'basa', 'kho', 'tộ']);
  expect(wordsOf(' , . '), isEmpty);
  expect(wordsOf('Phở Bò'), ['phở', 'bò']);
});
test('composeVietnamese: NFD và nửa tổ hợp → NFC', () {
  expect(composeVietnamese('Phở'), 'Phở');        // o + móc + hỏi
  expect(composeVietnamese('ở'), 'ở');              // ơ dựng sẵn + hỏi
  expect(composeVietnamese('Tiếng Việt'), 'Tiếng Việt'); // thứ tự dấu khác nhau
  expect(composeVietnamese('Ằ'), 'Ằ');
  expect(composeVietnamese('Phở bò'), 'Phở bò');               // đã NFC giữ nguyên
  expect(composeVietnamese('x́'), 'x́');             // không có trong bảng → giữ nguyên
});
test('slugify', () {
  expect(slugify('  Phở  BÒ '), 'pho-bo');
  expect(slugify('Đậu hũ'), 'dau-hu');
  expect(slugify('--Cơm (chiên)--'), 'com-chien');
});
test('displayTitle chỉ cắt khoảng trắng và viết hoa chữ đầu', () {
  expect(displayTitle('  bò  xào Mông Cổ '), 'Bò xào Mông Cổ');
  expect(displayTitle('cơm chiên Dương Châu'), 'Cơm chiên Dương Châu');
  expect(displayTitle('ếch xào'), 'Ếch xào');
  expect(displayTitle('Cá Nục Kho'), 'Cá Nục Kho');
  expect(displayTitle('   '), '');
});
test('formatDuration', () {
  expect(formatDuration(40), '40 phút');
  expect(formatDuration(60), '1 giờ');
  expect(formatDuration(200), '3 giờ 20 phút');
  expect(formatDuration(0), '0 phút');
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_text_test.dart`** – Expected: FAIL (chưa có file).
- [ ] **Step 3: Cài đặt** – `composeVietnamese`: duyệt chuỗi; với mỗi chữ cơ sở (a e i o u y, hoa/thường, hoặc ă â ê ô ơ ư dựng sẵn) gom các dấu tổ hợp ngay sau nó; tách thành dấu phụ (U+0306 trăng, U+0302 mũ, U+031B móc) và dấu thanh (U+0300 huyền, U+0301 sắc, U+0309 hỏi, U+0303 ngã, U+0323 nặng), không phụ thuộc thứ tự; áp dấu phụ trước (a→ă/â, e→ê, o→ô/ơ, u→ư), rồi tra bảng 12 nguyên âm × 5 thanh (hoa và thường) đặt trong `recipe_text.dart`; tổ hợp không có trong bảng → giữ nguyên các ký tự gốc. `removeDiacritics`: `toLowerCase()`, xóa ký tự tổ hợp U+0300–U+036F, rồi map bảng chữ có dấu tiếng Việt (a ă â e ê i o ô ơ u ư y × 5 thanh, `đ`) sang không dấu. `slugify` = `removeDiacritics` → thay chuỗi ký tự không thuộc `[a-z0-9]` bằng `-` → bỏ `-` đầu/cuối.
- [ ] **Step 4: Chạy lại** – Expected: PASS.
- [ ] **Step 5: Commit** – `feat(recipes): text normalization helpers`

---

### Task 2: Bữa theo giờ Việt Nam (`meal_time.dart`)

**Files:**
- Create: `app/lib/core/meal_time.dart`
- Test: `app/test/core/meal_time_test.dart`

**Interfaces:**
- Produces:
  - `enum MealType { breakfast, lunch, dinner, snack }` với `String get apiValue` (`'breakfast'`…), `String get labelVi` (`'sáng'`, `'trưa'`, `'tối'`, `'phụ'`), `int get sharePct` (25, 35, 30, 10).
  - `DateTime vnNow()` = `DateTime.now().toUtc().add(const Duration(hours: 7))`.
  - `MealType mealTypeAt(DateTime t)` (chỉ đọc `t.hour`, `t.minute`).
  - `int? mealBudgetKcal(double? targetKcal, MealType m)` = `(target × sharePct / 100).round()`; null nếu target null hoặc ≤ 0.
  - `String isoDate(DateTime t)` = `YYYY-MM-DD` từ `t.year/month/day`.

- [ ] **Step 1: Viết test fail**

```dart
MealType at(int h, int m) => mealTypeAt(DateTime.utc(2026, 10, 28, h, m));
test('mốc biên', () {
  expect(at(3, 59), MealType.snack);
  expect(at(4, 0), MealType.breakfast);
  expect(at(10, 29), MealType.breakfast);
  expect(at(10, 30), MealType.lunch);
  expect(at(14, 29), MealType.lunch);
  expect(at(14, 30), MealType.snack);
  expect(at(16, 59), MealType.snack);
  expect(at(17, 0), MealType.dinner);
  expect(at(21, 29), MealType.dinner);
  expect(at(21, 30), MealType.snack);
  expect(at(23, 59), MealType.snack);
  expect(at(0, 0), MealType.snack);
});
test('ngân sách bữa', () {
  expect(mealBudgetKcal(1968, MealType.lunch), 689);
  expect(mealBudgetKcal(2000, MealType.snack), 200);
  expect(mealBudgetKcal(null, MealType.lunch), isNull);
  expect(mealBudgetKcal(0, MealType.lunch), isNull);
});
test('isoDate đệm 0', () => expect(isoDate(DateTime.utc(2026, 3, 5, 23)), '2026-03-05'));
test('vnNow lệch UTC đúng 7 giờ', () {
  final diff = vnNow().difference(DateTime.now().toUtc());
  expect((diff.inMinutes - 420).abs() <= 1, isTrue);
});
```

- [ ] **Step 2: Chạy `flutter test test/core/meal_time_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(core): meal type by Vietnam time`

---

### Task 3: Model món (`recipe.dart`) + fixture test

**Files:**
- Create: `app/lib/features/recipes/recipe.dart`, `app/test/helpers/recipe_fixtures.dart`
- Test: `app/test/recipes/recipe_model_test.dart`

**Interfaces:**
- Consumes: `slugify` (Task 1, để bỏ tiền tố bước).
- Produces:
  - `enum Difficulty { easy, medium, hard }`, `String get labelVi` ('Dễ','Vừa','Khó'), `static Difficulty fromApi(String? v)` (lạ/null → easy).
  - Mọi model dưới đây bất biến, có `const` constructor tham số đặt tên (test dùng `const Allergen(id: 1, nameVi: 'Hải sản')`, `const UserNutritionProfile(targetKcal: 1968)`; trường nullable là tham số tùy chọn).
  - `class Recipe`: `id, title, slug, String? imageUrl, String? description, category, cuisine, int servings, int prepMinutes, int cookMinutes, Difficulty difficulty, double kcal, proteinG, carbsG, fatG, fiberG, sodiumMg, Set<int> allergenIds, Set<int> condimentAllergenIds`; `int get totalMinutes`.
  - `factory Recipe.fromSearchRow(Map<String, dynamic> row)` – cột của `search_recipes` (`calories_per_serving`, `protein_g_per_serving`, `fat_g_per_serving`, `carbs_g_per_serving`, `fiber_g_per_serving`, `sodium_mg_per_serving`, `prep_time_minutes`, `cook_time_minutes`, `allergens`, `condiment_allergens`).
  - `class RecipeIngredient { int orderIndex; String rawText, nameRaw; double? amount; String? unit; double amountG; }` + `fromRow` (`order_index`, `raw_text`, `ingredient_name_raw`, `amount`, `unit`, `amount_g`).
  - `class RecipeStep { int number; String title; String description; }` + `static List<RecipeStep> parseSteps(Object? json)`.
  - `class RecipeDetail { Recipe recipe; List<RecipeIngredient> ingredients; List<RecipeStep> steps; }` + `factory RecipeDetail.fromRow(Map row)` cho select `*, recipe_ingredients(*), recipe_allergens(allergen_id, via_condiment)`: `allergenIds` = mọi `allergen_id`, `condimentAllergenIds` = dòng `via_condiment == true`, nguyên liệu sắp theo `order_index`.
  - `class Allergen { int id; String nameVi; String? description; }` + `fromRow` (`id`, `name_vi`, `description`).
  - `class UserNutritionProfile { double? targetKcal, proteinG, carbsG, fatG, fiberG; }` + `fromRow` (`target_calories`, `target_protein_g`, `target_carbs_g`, `target_fat_g`, `target_fiber_g`).
  - Số đọc qua một hàm nội bộ nhận `num` hoặc `String` (NUMERIC có thể về dạng chuỗi); null → 0 cho cột NOT NULL, null cho cột nullable.
  - Fixture: `Recipe recipe({String id = 'r1', String title = 'Cá basa kho tộ', String? slug, double kcal = 240, double protein = 39, double carbs = 6, double fat = 7, double fiber = 0.7, double sodium = 1540, int prep = 10, int cook = 30, int servings = 2, Difficulty difficulty = Difficulty.easy, String category = 'mon_kho', Set<int> allergens = const {}, Set<int> condiment = const {}})`, `slug` mặc định `slugify(title)`.

- [ ] **Step 1: Viết test fail**

```dart
test('fromSearchRow đọc số dạng chuỗi và null', () {
  final r = Recipe.fromSearchRow({
    'id': 'a', 'title': 'Phở bò', 'slug': 'pho-bo', 'image_url': null, 'description': null,
    'category': 'mon_man', 'cuisine': 'vietnamese', 'servings': 2,
    'prep_time_minutes': 10, 'cook_time_minutes': 190, 'difficulty': 'medium',
    'calories_per_serving': '332.50', 'protein_g_per_serving': 31, 'fat_g_per_serving': 5.5,
    'carbs_g_per_serving': 41, 'fiber_g_per_serving': null, 'sodium_mg_per_serving': 900,
    'allergens': [1, 6], 'condiment_allergens': [1],
  });
  expect(r.kcal, 332.5);
  expect(r.fiberG, 0);
  expect(r.totalMinutes, 200);
  expect(r.difficulty, Difficulty.medium);
  expect(r.allergenIds, {1, 6});
  expect(r.condimentAllergenIds, {1});
  expect(r.imageUrl, isNull);
});
test('parseSteps: bỏ "Bước N:", gộp dòng trống, chịu được dữ liệu hỏng', () {
  final steps = RecipeStep.parseSteps([
    {'step_number': 2, 'title': 'Bước 2: Giã hành ớt', 'description': 'A\n\n\n\nB'},
    {'step_number': 1, 'title': 'Sơ chế cá', 'description': ' C '},
  ]);
  expect(steps.map((s) => s.number), [1, 2]);
  expect(steps[0].title, 'Sơ chế cá');
  expect(steps[0].description, 'C');
  expect(steps[1].title, 'Giã hành ớt');
  expect(steps[1].description, 'A\n\nB');
  expect(RecipeStep.parseSteps(null), isEmpty);
  expect(RecipeStep.parseSteps({'x': 1}), isEmpty);
  expect(RecipeStep.parseSteps('[]'), isEmpty);
});
test('RecipeDetail.fromRow: dị ứng từ gia vị, nguyên liệu theo order_index', () {
  final d = RecipeDetail.fromRow({
    ...searchRowMinimal, // khai báo trong test: các cột bắt buộc của recipes
    'instructions': [],
    'recipe_ingredients': [
      {'order_index': 2, 'raw_text': 'Tỏi: 3 tép', 'ingredient_name_raw': 'Tỏi', 'amount': 3, 'unit': 'tép', 'amount_g': 15},
      {'order_index': 1, 'raw_text': 'Cá: 400g', 'ingredient_name_raw': 'Cá', 'amount': '400', 'unit': 'g', 'amount_g': '400'},
    ],
    'recipe_allergens': [
      {'allergen_id': 1, 'via_condiment': true},
      {'allergen_id': 2, 'via_condiment': false},
    ],
  });
  expect(d.ingredients.map((i) => i.nameRaw), ['Cá', 'Tỏi']);
  expect(d.ingredients.first.amount, 400);
  expect(d.recipe.allergenIds, {1, 2});
  expect(d.recipe.condimentAllergenIds, {1});
  expect(d.steps, isEmpty);
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_model_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces. Bỏ tiền tố bằng `RegExp(r'^\s*bước\s*\d+\s*[:.\-–]\s*', caseSensitive: false)`; gộp `\n{3,}` → `\n\n`, rồi `trim()`. `parseSteps` nhận `List` hoặc chuỗi JSON của list; còn lại → `[]`; sắp theo `step_number`.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): recipe models and row parsing`

---

### Task 4: `RecipeQuery` – so khớp từ khóa và bộ lọc

**Files:**
- Create: `app/lib/features/recipes/recipe_query.dart`
- Test: `app/test/recipes/recipe_query_filter_test.dart`

**Interfaces:**
- Consumes: `wordsOf`, `removeDiacritics` (Task 1); `Recipe`, `Difficulty` (Task 3); fixture `recipe(...)`.
- Produces:
  - `enum MatchLevel { startsWith, wholeWords, wordPrefix }` (thứ tự = độ ưu tiên, `startsWith` tốt nhất).
  - `MatchLevel? matchTitle(String title, String query)` – null = không khớp; ném lỗi không bao giờ. Gọi với query không có từ nào → trả `MatchLevel.wordPrefix` (coi như khớp).
  - `class RecipeFilters { final double? minKcal, maxKcal; final int? maxTotalMinutes; final Set<Difficulty> difficulties; final String? category; const RecipeFilters({...}); RecipeFilters copyWith({Object? minKcal = _unset, Object? maxKcal = _unset, Object? maxTotalMinutes = _unset, Set<Difficulty>? difficulties, Object? category = _unset}); int get sheetBadgeCount; }` – `sheetBadgeCount` đếm nhóm khác mặc định: calo (min hoặc max), thời gian, độ khó (0–3).
  - `enum RecipeSort { bestMatch, kcalAsc, kcalDesc, proteinPer100Desc, carbsPer100Asc, fatPer100Asc, quickest }` + `labelVi`: 'Phù hợp nhất', 'Calo: thấp → cao', 'Calo: cao → thấp', 'Protein / 100 kcal cao nhất', 'Carbs / 100 kcal thấp nhất', 'Fat / 100 kcal thấp nhất', 'Nấu nhanh nhất'.
  - `abstract final class RecipeQuery { static List<Recipe> apply(List<Recipe> recipes, {String query = '', RecipeFilters filters = const RecipeFilters(), RecipeSort sort = RecipeSort.bestMatch, Set<int> excludeAllergenIds = const {}, int? mealBudgetKcal}); }` – Task này chỉ cần lọc; sắp xếp tạm theo tên (Task 5 hoàn thiện).

Quy tắc khớp (§8.1): `q = wordsOf(query)`, `t = wordsOf(title)` (cả hai đã về NFC nhờ `wordsOf`, nên so có dấu không lệch dạng Unicode). Một từ `qi` "bằng"/"là đầu của" từ `tj`: nếu `removeDiacritics(qi) != qi` (có dấu) so `qi` với `tj`; ngược lại so `qi` với `removeDiacritics(tj)`. `startsWith`: `q.length ≤ t.length`, `q[i]` bằng `t[i]` với mọi i < cuối, và từ cuối là đầu của `t[last]`. `wholeWords`: mỗi `qi` bằng một `tj` nào đó. `wordPrefix`: mỗi `qi` là đầu của một `tj` nào đó. Không bao giờ dùng `slug`.

- [ ] **Step 1: Viết test fail**

```dart
group('matchTitle', () {
  test('không dấu khớp có dấu, theo đầu từ', () {
    expect(matchTitle('Cá basa kho tộ', 'ca kho'), MatchLevel.wholeWords);
    expect(matchTitle('Canh gà', 'ca'), MatchLevel.startsWith);
    expect(matchTitle('Phở bò tái', 'pho bo'), MatchLevel.startsWith);
    expect(matchTitle('Bún bò Huế', 'bo hue'), MatchLevel.wholeWords);
    expect(matchTitle('Cá basa kho tộ', 'kho ba'), MatchLevel.wordPrefix);
  });
  test('từ có dấu thì so có dấu, xét theo từng từ', () {
    expect(matchTitle('Canh gà', 'cá'), isNull);
    expect(matchTitle('Phở bò', 'phở bo'), MatchLevel.startsWith);
    expect(matchTitle('Đậu hũ nhồi thịt', 'dau'), MatchLevel.startsWith);
    expect(matchTitle('Đậu hũ nhồi thịt', 'đau'), isNull);
  });
  test('mọi từ phải khớp', () => expect(matchTitle('Phở bò', 'pho ga'), isNull));
  test('tên dạng NFD', () => expect(matchTitle('Phở bò', 'pho bo'), MatchLevel.startsWith));
  test('từ khóa có dấu với tên NFD', () => expect(matchTitle('Phở bò', 'phở'), MatchLevel.startsWith));
  test('từ khóa NFD với tên NFC', () => expect(matchTitle('Phở bò', 'phở bò'), MatchLevel.startsWith));
  test('không khớp giữa từ', () => expect(matchTitle('Rau muống xào', 'uong'), isNull));
});
group('lọc', () {
  final a = recipe(id: 'a', title: 'Gà luộc', kcal: 500, prep: 10, cook: 20, difficulty: Difficulty.easy, category: 'mon_man', allergens: {2});
  final b = recipe(id: 'b', title: 'Cá kho', kcal: 500.4, prep: 15, cook: 16, difficulty: Difficulty.hard, category: 'mon_kho', allergens: {1});
  final c = recipe(id: 'c', title: 'Canh chua', kcal: 120, prep: 5, cook: 10, difficulty: Difficulty.medium, category: 'mon_canh');
  List<String> ids(List<Recipe> r) => r.map((e) => e.id).toList()..sort();
  test('từ khóa rỗng hoặc chỉ dấu câu → không lọc', () {
    expect(ids(RecipeQuery.apply([a, b, c], query: '  , . ')), ['a', 'b', 'c']);
  });
  test('không khớp qua slug', () {
    final s = recipe(id: 's', title: 'Bò lúc lắc', slug: 'cach-lam-ca-ngon');
    expect(RecipeQuery.apply([s], query: 'ca'), isEmpty);
  });
  test('calo biên đúng bằng min/max, một đầu, min = max', () {
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxKcal: 500))), ['a', 'c']);
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(minKcal: 500))), ['a', 'b']);
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(minKcal: 500, maxKcal: 500))), ['a']);
  });
  test('thời gian = prep + cook, biên tính là thỏa', () {
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxTotalMinutes: 30))), ['a', 'c']);
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxTotalMinutes: 15))), ['c']);
  });
  test('độ khó chọn nhiều, rỗng = mọi độ khó', () {
    expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(difficulties: {Difficulty.easy, Difficulty.hard}))), ['a', 'b']);
  });
  test('nhóm món', () => expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(category: 'mon_kho'))), ['b']));
  test('dị ứng', () => expect(ids(RecipeQuery.apply([a, b, c], excludeAllergenIds: {1, 9})), ['a', 'c']));
  test('danh sách rỗng', () => expect(RecipeQuery.apply(const []), isEmpty));
  test('sheetBadgeCount', () {
    expect(const RecipeFilters().sheetBadgeCount, 0);
    expect(const RecipeFilters(minKcal: 200, maxKcal: 500, maxTotalMinutes: 30, category: 'mon_kho').sheetBadgeCount, 2);
    expect(const RecipeFilters(difficulties: {Difficulty.easy}).sheetBadgeCount, 1);
  });
  test('copyWith xóa được giá trị về null', () {
    expect(const RecipeFilters(maxKcal: 500).copyWith(maxKcal: null).maxKcal, isNull);
  });
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_query_filter_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): keyword matching and filters`

---

### Task 5: `RecipeQuery` – sắp xếp

**Files:**
- Modify: `app/lib/features/recipes/recipe_query.dart`
- Test: `app/test/recipes/recipe_query_sort_test.dart`

**Interfaces:**
- Consumes/Produces: `RecipeQuery.apply` (Task 4), nay sắp đúng theo `sort`.

Quy tắc (§8.1): hòa ở mọi tiêu chí → theo `removeDiacritics(title)` A–Z. `bestMatch`: (1) có từ khóa → `MatchLevel` (startsWith < wholeWords < wordPrefix); (2) `mealBudgetKcal` khác null → nhóm `kcal ≤ budget` trước nhóm vượt, trong nhóm `|kcal − budget|` tăng dần; (3) budget null → tên. `proteinPer100Desc` = `proteinG / kcal × 100` giảm dần; `carbsPer100Asc`, `fatPer100Asc` tăng dần; món `kcal == 0` luôn cuối ở cả 3 tiêu chí này. `quickest` = `totalMinutes` tăng dần.

- [ ] **Step 1: Viết test fail**

```dart
List<String> order(List<Recipe> r, {String q = '', RecipeSort s = RecipeSort.bestMatch, int? budget}) =>
    RecipeQuery.apply(r, query: q, sort: s, mealBudgetKcal: budget).map((e) => e.id).toList();

test('bestMatch: mức khớp trước, rồi ngân sách', () {
  final x = recipe(id: 'x', title: 'Bò kho', kcal: 300);          // startsWith
  final y = recipe(id: 'y', title: 'Phở bò', kcal: 680);          // wholeWords
  final z = recipe(id: 'z', title: 'Phở bòn bon', kcal: 689);     // wordPrefix (dù gần ngân sách nhất)
  expect(order([z, y, x], q: 'bo', budget: 689), ['x', 'y', 'z']);
});
test('bestMatch: ≤ ngân sách trước, gần ngân sách trước; đúng bằng thuộc nhóm ≤', () {
  final a = recipe(id: 'a', title: 'A', kcal: 689);
  final b = recipe(id: 'b', title: 'B', kcal: 600);
  final c = recipe(id: 'c', title: 'C', kcal: 700);
  final d = recipe(id: 'd', title: 'D', kcal: 200);
  expect(order([d, c, b, a], budget: 689), ['a', 'b', 'd', 'c']);
});
test('bestMatch: ngân sách null → tên A–Z (bỏ dấu)', () {
  expect(order([recipe(id: 'b', title: 'Đậu'), recipe(id: 'a', title: 'Cá')]), ['a', 'b']);
});
test('hòa → theo tên', () {
  expect(order([recipe(id: 'b', title: 'Bún', kcal: 300), recipe(id: 'a', title: 'Bánh', kcal: 300)], s: RecipeSort.kcalAsc), ['a', 'b']);
});
test('calo tăng/giảm', () {
  final l = [recipe(id: 'h', title: 'H', kcal: 500), recipe(id: 'l', title: 'L', kcal: 100)];
  expect(order(l, s: RecipeSort.kcalAsc), ['l', 'h']);
  expect(order(l, s: RecipeSort.kcalDesc), ['h', 'l']);
});
test('/100 kcal, món 0 kcal cuối', () {
  final p = recipe(id: 'p', title: 'P', kcal: 200, protein: 40, carbs: 10, fat: 2);  // 20 / 5 / 1
  final q = recipe(id: 'q', title: 'Q', kcal: 400, protein: 40, carbs: 60, fat: 20); // 10 / 15 / 5
  final z = recipe(id: 'z', title: 'Z', kcal: 0, protein: 0, carbs: 0, fat: 0);
  expect(order([z, q, p], s: RecipeSort.proteinPer100Desc), ['p', 'q', 'z']);
  expect(order([z, q, p], s: RecipeSort.carbsPer100Asc), ['p', 'q', 'z']);
  expect(order([z, q, p], s: RecipeSort.fatPer100Asc), ['p', 'q', 'z']);
});
test('nấu nhanh nhất theo prep + cook', () {
  expect(order([recipe(id: 's', title: 'S', prep: 30, cook: 30), recipe(id: 'f', title: 'F', prep: 5, cook: 40)], s: RecipeSort.quickest), ['f', 's']);
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_query_sort_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** một comparator ghép theo thứ tự quy tắc; tính `matchTitle` một lần mỗi món.
- [ ] **Step 4: Chạy lại cả `test/recipes/`** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): sorting including best match`

---

### Task 6: `formatIngredient`

**Files:**
- Create: `app/lib/features/recipes/ingredient_format.dart`
- Test: `app/test/recipes/ingredient_format_test.dart`

**Interfaces:**
- Consumes: `RecipeIngredient` (Task 3), `slugify` (Task 1).
- Produces: `class IngredientLine { String name; String? amountText; String? gramText; String? note; }`; `String formatAmount(double v)`; `IngredientLine formatIngredient(RecipeIngredient row, double factor)`.

Quy tắc (§8.3), cộng một điểm của plan: khi `raw_text` không có `:` mà `slugify(raw_text) == slugify(ingredient_name_raw)` thì ghi chú cũng coi là trống → "Tùy thích". Đơn vị đếm được: `{củ, quả, trái, cây, miếng, chén, bát, bó, nhánh, tép, lát, con, cái, lá, khúc, gói, hộp}`; đơn vị khác không hiện dòng gam. `amountG ≤ 0` → không hiện dòng gam. `amount` khác null mà `unit` null → `amountText` chỉ có số.

- [ ] **Step 1: Viết test fail**

```dart
RecipeIngredient ing(String raw, String name, double? amount, String? unit, double g) =>
    RecipeIngredient(orderIndex: 0, rawText: raw, nameRaw: name, amount: amount, unit: unit, amountG: g);

test('formatAmount', () {
  expect(formatAmount(0.5), '½');
  expect(formatAmount(1.5), '1½');
  expect(formatAmount(2.25), '2,3');
  expect(formatAmount(1000), '1.000');
  expect(formatAmount(3), '3');
});
test('đơn vị đếm được có dòng gam, nhân hệ số', () {
  final l = formatIngredient(ing('Đậu hũ: 4 miếng (400g)', 'Đậu hũ', 4, 'miếng', 400), 0.5);
  expect([l.name, l.amountText, l.gramText, l.note], ['Đậu hũ', '2 miếng', '200 g', null]);
});
test('g/kg không có dòng gam', () {
  expect(formatIngredient(ing('Thịt xay: 200g', 'Thịt xay', 200, 'g', 200), 1.5).amountText, '300 g');
  final kg = formatIngredient(ing('1 kg cá nục, sơ chế sạch', 'cá nục', 1, 'kg', 1000), 2);
  expect([kg.name, kg.amountText, kg.gramText], ['Cá nục', '2 kg', null]);
});
test('muỗng: chuẩn hóa tên, không dòng gam, ½', () {
  expect(formatIngredient(ing('Hạt nêm: 1 muỗng cà phê', 'Hạt nêm', 1, 'muỗng cà', 30), 1.5).amountText, '1½ muỗng cà phê');
  final mc = formatIngredient(ing('1/2 muỗng canh hạt nêm', 'hạt nêm', 0.5, 'muỗng canh', 7.5), 1);
  expect([mc.amountText, mc.gramText], ['½ muỗng canh', null]);
  expect(formatIngredient(ing('x', 'Đường', 2, 'gram', 2), 1).amountText, '2 g');
});
test('phần / ít / amount null: ghi chú từ raw_text, không nhân', () {
  final p = formatIngredient(ing('Hành lá: để riêng phần gốc và phần lá, xắt nhỏ', 'Hành lá', 1, 'phần', 30), 3);
  expect([p.amountText, p.gramText, p.note], [null, null, 'để riêng phần gốc và phần lá, xắt nhỏ']);
  final y = formatIngredient(ing('3 lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 'lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 3, 'phần', 90), 2);
  expect([y.name, y.note], ['Lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', '3 lòng đỏ trứng gà (lòng trắng để riêng dùng sau)']);
  expect(formatIngredient(ing('Tiêu xay: 1 ít', 'Tiêu xay', 1, 'ít', 2), 2).note, '1 ít');
  expect(formatIngredient(ing('Ớt (lượng tùy thích)', 'Ớt (lượng tùy thích)', 1, 'ít', 2), 1).note, 'Tùy thích');
  expect(formatIngredient(ing('Muối:', 'Muối', null, null, 0), 1).note, 'Tùy thích');
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/ingredient_format_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** – `formatAmount`: làm tròn 1 chữ số; phần lẻ đúng 0,5 → phần nguyên (bỏ nếu 0) + `½`; còn lại `NumberFormat('#,##0.#', 'vi')`. Dòng gam: `NumberFormat('#,##0', 'vi')` + ' g'.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): ingredient line formatting`

---

### Task 7: Dinh dưỡng màn Chi tiết (`recipe_nutrition.dart`)

**Files:**
- Create: `app/lib/features/recipes/recipe_nutrition.dart`
- Test: `app/test/recipes/recipe_nutrition_test.dart`

**Interfaces:**
- Consumes: `Recipe` (Task 3), `MealType` (Task 2).
- Produces:
  - `const double kSodiumDailyMaxMg = 2000;`
  - `class EnergySplit { int proteinPct, carbsPct, fatPct; }`, `EnergySplit? energySplit(Recipe r)` (P×4, C×4, F×9; tổng 0 → null; mỗi phần `round()`).
  - `int? pctOfTarget(double value, double? target)` (target null/≤0 → null; `round()`).
  - `sealed class MealFit`; `class MealFitWithin extends MealFit { int pct; }`; `class MealFitOver extends MealFit { int overKcal; }`; `MealFit? mealFit(double kcal, int? budget)` (budget null/≤0 → null; `kcal ≤ budget` → Within, ngược lại Over với `(kcal − budget).round()`).
  - `bool sodiumHighForMeal(double sodiumMg, MealType m)` = `sodiumMg > kSodiumDailyMaxMg × m.sharePct / 100`.

- [ ] **Step 1: Viết test fail**

```dart
test('tỉ lệ năng lượng như Figma (P39 C6 F7)', () {
  final s = energySplit(recipe(protein: 39, carbs: 6, fat: 7))!;
  expect([s.proteinPct, s.carbsPct, s.fatPct], [64, 10, 26]);
  expect(energySplit(recipe(protein: 0, carbs: 0, fat: 0)), isNull);
});
test('% mục tiêu', () {
  expect(pctOfTarget(240, 1968), 12);
  expect(pctOfTarget(39, null), isNull);
  expect(pctOfTarget(39, 0), isNull);
});
test('mealFit', () {
  expect((mealFit(240, 689) as MealFitWithin).pct, 35);
  expect((mealFit(689, 689) as MealFitWithin).pct, 100);
  expect((mealFit(800.4, 689) as MealFitOver).overKcal, 111);
  expect(mealFit(240, null), isNull);
  expect(mealFit(240, 0), isNull);
});
test('natri theo phần của bữa', () {
  expect(sodiumHighForMeal(700, MealType.lunch), isFalse); // ngưỡng 700
  expect(sodiumHighForMeal(701, MealType.lunch), isTrue);
  expect(sodiumHighForMeal(201, MealType.snack), isTrue);  // ngưỡng 200
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_nutrition_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): nutrition helpers for detail screen`

---

### Task 8: `RecipeRepository`, `RecipeCatalog`, `RecipeScope`

**Files:**
- Create: `app/lib/features/recipes/recipe_repository.dart`, `app/lib/features/recipes/recipe_catalog.dart`, `app/test/helpers/fake_recipe_repository.dart`
- Test: `app/test/recipes/recipe_catalog_test.dart`

**Interfaces:**
- Consumes: model Task 3.
- Produces:
  - `const int kRecipeFetchLimit = 100;`
  - `abstract class RecipeRepository` đúng 6 hàm ở §5.1 (`fetchAll`, `fetchDetail`, `fetchProfile`, `fetchAllergens`, `fetchUserAllergenIds`, `saveUserAllergenIds`).
  - `class SupabaseRecipeRepository implements RecipeRepository` + `final recipeRepo = SupabaseRecipeRepository();` (constructor không chạm `supabase`). Truy vấn:
    - `fetchAll`: `supabase.rpc('search_recipes', params: {'p_limit': kRecipeFetchLimit})`; đủ 100 dòng → `debugPrint('search_recipes trả $kRecipeFetchLimit món, có thể thiếu món')`.
    - `fetchDetail`: `from('recipes').select('*, recipe_ingredients(*), recipe_allergens(allergen_id, via_condiment)').eq('id', id).eq('is_verified', true).maybeSingle()`; id không phải UUID hợp lệ → trả null không gọi mạng.
    - `fetchProfile`: `from('profiles').select('target_calories, target_protein_g, target_carbs_g, target_fat_g, target_fiber_g').eq('id', uid).maybeSingle()`.
    - `fetchAllergens`: `from('allergens').select('id, name_vi, description').order('id')`.
    - `fetchUserAllergenIds` / `saveUserAllergenIds`: bảng `user_allergens` của `uid`; lưu: tập rỗng → `delete().eq('user_id', uid)` (xóa hết, **không** dùng not-in với danh sách rỗng); tập khác rỗng → xóa `allergen_id` không còn chọn (`.not('allergen_id', 'in', …)`) rồi `upsert` các dòng đang chọn.
  - `enum CatalogStatus { idle, loading, ready, error }`
  - `class RecipeCatalog extends ChangeNotifier { RecipeCatalog({required RecipeRepository repo, Stream<String?>? userIdChanges}); RecipeRepository get repo; CatalogStatus get status; List<Recipe> get recipes; UserNutritionProfile? get profile; List<Allergen> get allergens; Set<int> get userAllergenIds; Future<void> ensureLoaded(); Future<void> refresh(); Future<void> saveAllergens(Set<int> ids); void clear(); }`
    - `ensureLoaded`: chỉ tải khi `idle` hoặc `error`; gọi đồng thời nhiều lần chỉ tải một lần.
    - `refresh`: tải lại cả 4 nguồn (món, hồ sơ, danh mục dị ứng, dị ứng user). Lỗi khi đã `ready` → giữ dữ liệu cũ, vẫn `ready`, `rethrow`. Lỗi lần đầu → `error`.
    - `userIdChanges`: giá trị null hoặc khác user id lần trước → `clear()` (về `idle`, xóa dữ liệu, `notifyListeners`).
  - `class RecipeScope extends InheritedNotifier<RecipeCatalog> { const RecipeScope({required RecipeCatalog catalog, required Widget child}); static RecipeCatalog of(BuildContext context); }`
  - Test helper: `class FakeRecipeRepository implements RecipeRepository` với các trường công khai `List<Recipe> recipes`, `Map<String, RecipeDetail> details`, `UserNutritionProfile? profile`, `List<Allergen> allergens`, `Set<int> userAllergenIds`, `Object? failWith` (ném ở mọi hàm khi khác null), `int fetchAllCalls`; mọi hàm trả `Future.value`.

- [ ] **Step 1: Viết test fail**

```dart
test('ensureLoaded tải một lần dù gọi song song', () async {
  final repo = FakeRecipeRepository()..recipes = [recipe()];
  final c = RecipeCatalog(repo: repo);
  await Future.wait([c.ensureLoaded(), c.ensureLoaded()]);
  expect(repo.fetchAllCalls, 1);
  expect(c.status, CatalogStatus.ready);
});
test('refresh lỗi khi đã có dữ liệu → giữ dữ liệu, rethrow', () async {
  final repo = FakeRecipeRepository()..recipes = [recipe()];
  final c = RecipeCatalog(repo: repo);
  await c.ensureLoaded();
  repo.failWith = Exception('mạng');
  await expectLater(c.refresh(), throwsException);
  expect(c.status, CatalogStatus.ready);
  expect(c.recipes, hasLength(1));
});
test('lỗi lần đầu → error, ensureLoaded lại được', () async {
  final repo = FakeRecipeRepository()..failWith = Exception('mạng');
  final c = RecipeCatalog(repo: repo);
  await c.ensureLoaded();
  expect(c.status, CatalogStatus.error);
  repo.failWith = null;
  await c.ensureLoaded();
  expect(c.status, CatalogStatus.ready);
});
test('refresh tải lại cả dị ứng và hồ sơ', () async {
  final repo = FakeRecipeRepository();
  final c = RecipeCatalog(repo: repo);
  await c.ensureLoaded();
  repo
    ..userAllergenIds = {1}
    ..profile = const UserNutritionProfile(targetKcal: 1968);
  await c.refresh();
  expect(c.userAllergenIds, {1});
  expect(c.profile?.targetKcal, 1968);
});
test('saveAllergens ghi repo và cập nhật', () async {
  final repo = FakeRecipeRepository();
  final c = RecipeCatalog(repo: repo);
  await c.saveAllergens({4, 1});
  expect(repo.userAllergenIds, {1, 4});
  expect(c.userAllergenIds, {1, 4});
});
test('đăng xuất hoặc đổi user → clear', () async {
  final users = StreamController<String?>();
  final c = RecipeCatalog(repo: FakeRecipeRepository()..userAllergenIds = {1}, userIdChanges: users.stream);
  users.add('u1');
  await c.ensureLoaded();
  users.add('u1');
  await pumpEventQueue();
  expect(c.status, CatalogStatus.ready);
  users.add('u2');
  await pumpEventQueue();
  expect(c.status, CatalogStatus.idle);
  expect(c.userAllergenIds, isEmpty);
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_catalog_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS. Chạy `flutter analyze` – sạch.
- [ ] **Step 5: Commit** – `feat(recipes): recipe repository and session catalog`

---

### Task 9: `MealLogRepository` + UUID v4

**Files:**
- Create: `app/lib/core/uuid.dart`, `app/lib/features/meal_logs/meal_log_repository.dart`, `app/test/helpers/fake_meal_log_repository.dart`
- Test: `app/test/core/uuid_test.dart`, `app/test/meal_logs/meal_log_repository_test.dart`

**Interfaces:**
- Consumes: `MealType` (Task 2).
- Produces:
  - `String uuidV4([Random? random])` – 16 byte từ `random ?? Random.secure()`, byte 6 `(b & 0x0F) | 0x40`, byte 8 `(b & 0x3F) | 0x80`, hex thường 8-4-4-4-12.
  - `sealed class MealLogException implements Exception`; `class MealLogOffline extends MealLogException`; `class MealLogProfileMissing extends MealLogException`; `class MealLogFailed extends MealLogException { final String? code; final String? message; }`.
  - `MealLogException mapMealLogError(Object e)`: `FunctionsFetchException`, `SocketException`, `TimeoutException`, `http.ClientException` → Offline; `FunctionException` có `details` (Map hoặc chuỗi JSON) với `error.code == 'PROFILE_NOT_FOUND'` → ProfileMissing; `FunctionException` khác → Failed(code, message từ details nếu có); còn lại → Failed(null, null).
  - `abstract class MealLogRepository { Future<void> addRecipe({required String recipeId, required MealType mealType, required String date, required String clientRequestId}); }`
  - `class SupabaseMealLogRepository implements MealLogRepository` + `final mealLogRepo = SupabaseMealLogRepository();` – gọi `supabase.functions.invoke('meal-logs', body: {'meal_type': mealType.apiValue, 'recipe_id': recipeId, 'servings': 1, 'date': date, 'client_request_id': clientRequestId})`, timeout 15 s, mọi lỗi ném `mapMealLogError(e)`.
  - Test helper: `class FakeMealLogRepository implements MealLogRepository { final List<Map<String, Object>> calls = []; Completer<void>? gate; MealLogException? failWith; }` – mỗi lần gọi thêm `{'recipeId': …, 'mealType': MealType, 'date': …, 'clientRequestId': …}` vào `calls` **trước** khi chờ `gate` (nếu khác null), rồi ném `failWith` nếu khác null.

- [ ] **Step 1: Viết test fail**

```dart
// uuid_test.dart
final re = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
test('định dạng v4 và variant trên nhiều lần sinh', () {
  for (var i = 0; i < 200; i++) {
    expect(uuidV4(), matches(re));
  }
});
test('bit version/variant đúng cả khi random toàn 0xFF', () {
  expect(uuidV4(_MaxRandom()), 'ffffffff-ffff-4fff-bfff-ffffffffffff'); // _MaxRandom.nextInt(n) = n - 1
});
test('hai lần sinh khác nhau', () => expect(uuidV4() == uuidV4(), isFalse));
// _MaxRandom: lớp trong file test, `implements Random`, nextInt(max) => max - 1.

// meal_log_repository_test.dart
test('mất mạng', () {
  expect(mapMealLogError(const FunctionsFetchException(details: 'x')), isA<MealLogOffline>());
  expect(mapMealLogError(const SocketException('x')), isA<MealLogOffline>());
  expect(mapMealLogError(TimeoutException('x')), isA<MealLogOffline>());
});
test('PROFILE_NOT_FOUND từ details Map hoặc chuỗi JSON', () {
  const map = {'error': {'code': 'PROFILE_NOT_FOUND', 'message': 'Chưa có mục tiêu'}};
  expect(mapMealLogError(const FunctionException(status: 404, details: map)), isA<MealLogProfileMissing>());
  expect(mapMealLogError(FunctionException(status: 404, details: jsonEncode(map))), isA<MealLogProfileMissing>());
});
test('lỗi khác giữ code', () {
  final e = mapMealLogError(const FunctionException(status: 404, details: {'error': {'code': 'RECIPE_NOT_FOUND'}}));
  expect((e as MealLogFailed).code, 'RECIPE_NOT_FOUND');
  expect(mapMealLogError(StateError('?')), isA<MealLogFailed>());
});
```

- [ ] **Step 2: Chạy `flutter test test/core/uuid_test.dart test/meal_logs/`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces (import `package:http/http.dart` đã có qua supabase_flutter; nếu analyzer báo `depend_on_referenced_packages` thì bỏ nhánh `ClientException` và để rơi vào Failed – ghi chú trong commit).
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): add-recipe endpoint client and uuid v4`

---

### Task 10: `RecipeSearchController`

**Files:**
- Create: `app/lib/features/recipes/recipe_search_controller.dart`
- Test: `app/test/recipes/recipe_search_controller_test.dart`

**Interfaces:**
- Consumes: `RecipeCatalog` (Task 8), `RecipeQuery`/`RecipeFilters`/`RecipeSort` (Task 4–5), `mealTypeAt`, `mealBudgetKcal`, `vnNow` (Task 2).
- Produces:
  - `const kCategoryLabels = {'mon_man': 'Món mặn', 'mon_kho': 'Món kho', 'mon_an_sang': 'Món ăn sáng', 'mon_chay': 'Món chay', 'mon_canh': 'Món canh', 'mon_xao': 'Món xào', 'mon_nuong': 'Món nướng'};` + `String categoryLabel(String v)` (lạ → nguyên văn).
  - `class RecipeSearchController extends ChangeNotifier`:
    - `RecipeSearchController({required RecipeCatalog catalog, DateTime Function() now = vnNow})` – nghe catalog, gỡ khi `dispose`.
    - `String query`, `void setQuery(String q)`, `void submitQuery()` (thêm vào gần đây), `void recordOpened()` (thêm `query` hiện tại vào gần đây nếu không rỗng).
    - `List<String> recentSearches` (lưu dạng `trim()`, bỏ chuỗi rỗng, tối đa 5, mới nhất trước, trùng so `toLowerCase()` → xóa bản cũ), `void removeRecent(String q)`, `void clearRecents()`.
    - `RecipeFilters filters`, `void applyFilters(RecipeFilters f)`; `RecipeSort sort`, `void setSort(RecipeSort s)`.
    - Chip nhanh: `bool get under500` (`filters.maxKcal == 500`), `void toggleUnder500()`; `bool get under30Min` (`filters.maxTotalMinutes == 30`), `void toggleUnder30Min()`; `bool fridge`, `void toggleFridge()` (không ảnh hưởng kết quả).
    - Dị ứng: `bool excludeAllergens` (mặc định true), `void toggleExcludeAllergens()`, `bool get hasDeclaredAllergens` (= `catalog.userAllergenIds.isNotEmpty`).
    - `int? get mealBudgetKcal` (= `mealBudgetKcal(catalog.profile?.targetKcal, mealTypeAt(now()))`).
    - `List<Recipe> get results` (gọi `RecipeQuery.apply` với `excludeAllergenIds` = dị ứng user nếu bật và đã khai báo, ngược lại rỗng), `int countFor(RecipeFilters f)` (cho nút "Xem N món").
    - `List<String> get categories` – các `category` có món trong `catalog.recipes`, theo thứ tự khóa của `kCategoryLabels`, giá trị lạ xếp cuối A–Z.
    - `List<Recipe> get popular` – 3 món đầu của `RecipeQuery.apply(catalog.recipes, excludeAllergenIds: …, mealBudgetKcal: …)` (lọc dị ứng giống `results`; sửa sau review cuối nhánh).

- [ ] **Step 1: Viết test fail** (catalog thật + `FakeRecipeRepository`, `await catalog.ensureLoaded()` trong `setUp`; `now: () => DateTime.utc(2026, 10, 28, 12)` → bữa trưa)

```dart
test('lọc dị ứng chỉ khi bật và đã khai báo', () async {
  repo
    ..recipes = [recipe(id: 'a', allergens: {1}), recipe(id: 'b', title: 'B')]
    ..userAllergenIds = {1};
  await catalog.refresh();
  expect(ctl.results.map((r) => r.id), ['b']);
  ctl.toggleExcludeAllergens();
  expect(ctl.results, hasLength(2));
});
test('chưa khai báo dị ứng', () => expect(ctl.hasDeclaredAllergens, isFalse));
test('chip ≤ 500 kcal bật/tắt maxKcal = 500', () {
  ctl.toggleUnder500();
  expect(ctl.filters.maxKcal, 500);
  ctl.toggleUnder500();
  expect(ctl.filters.maxKcal, isNull);
});
test('tìm gần đây: tối đa 5, mới nhất trước, bỏ trùng', () {
  for (final q in ['a', 'b', 'c', 'd', 'e', 'f', ' B ']) {
    ctl..setQuery(q)..submitQuery();
  }
  expect(ctl.recentSearches, ['B', 'f', 'e', 'd', 'c']);
  ctl.setQuery('');
  ctl.recordOpened();
  expect(ctl.recentSearches, hasLength(5));
});
test('ngân sách bữa trưa từ hồ sơ', () async {
  repo.profile = const UserNutritionProfile(targetKcal: 1968);
  await catalog.refresh();
  expect(ctl.mealBudgetKcal, 689);
});
test('nhóm món chỉ hiện nhóm có món, theo thứ tự cố định', () async {
  repo.recipes = [recipe(id: 'a', category: 'mon_kho'), recipe(id: 'b', category: 'zzz'), recipe(id: 'c', category: 'mon_man')];
  await catalog.refresh();
  expect(ctl.categories, ['mon_man', 'mon_kho', 'zzz']);
});
test('countFor không đổi filters hiện tại', () async {
  repo.recipes = [recipe(id: 'a', kcal: 100), recipe(id: 'b', kcal: 900)];
  await catalog.refresh();
  expect(ctl.countFor(const RecipeFilters(maxKcal: 500)), 1);
  expect(ctl.results, hasLength(2));
});
test('catalog đổi → controller notify', () async {
  var n = 0;
  ctl.addListener(() => n++);
  await catalog.refresh();
  expect(n, greaterThan(0));
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_search_controller_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): search screen controller`

---

### Task 11: `RecipeDetailController`

**Files:**
- Create: `app/lib/features/recipes/recipe_detail_controller.dart`
- Test: `app/test/recipes/recipe_detail_controller_test.dart`

**Interfaces:**
- Consumes: `RecipeCatalog` (Task 8), `MealLogRepository`/`MealLogException` (Task 9), `uuidV4`, `MealType`/`mealTypeAt`/`isoDate`/`vnNow` (Task 2), `recipe_nutrition.dart` (Task 7).
- Produces:
  - `enum DetailStatus { loading, ready, notFound, error }`
  - `sealed class AddMealResult`; `AddMealSuccess`, `AddMealOffline`, `AddMealProfileMissing`, `AddMealFailed`, `AddMealIgnored` (đang gửi thì bỏ qua).
  - `class AllergenWarning { final String name; final bool viaCondiment; }`
  - `class RecipeDetailController extends ChangeNotifier`:
    - `RecipeDetailController({required String id, Recipe? initial, required RecipeCatalog catalog, required MealLogRepository mealLogs, DateTime Function() now = vnNow, String Function() newRequestId = uuidV4})` – gọi `now()` **một lần** trong constructor, lưu `mealType` và `logDate = isoDate(...)`.
    - `Recipe? get recipe` (detail nếu có, ngược lại `initial`), `RecipeDetail? get detail`, `DetailStatus get status`.
    - `Future<void> load()` – song song `catalog.repo.fetchDetail(id)` và `catalog.ensureLoaded()` (lỗi catalog không làm hỏng màn); null → `notFound`; ném → `error`.
    - `int get cookServings` (khởi đầu `recipe?.servings ?? 1`, đặt lại theo detail khi tải xong nếu chưa chỉnh), `void incServings()`/`decServings()` trong 1–20, `double get factor` = `cookServings / recipe.servings`.
    - `Set<int> get doneSteps`, `void toggleStep(int number)`.
    - `MealType get mealType`, `String get logDate`, `int? get mealBudget` (từ `catalog.profile`).
    - `List<AllergenWarning> get allergenWarnings` – `recipe.allergenIds ∩ catalog.userAllergenIds`, tên từ `catalog.allergens` (thiếu tên → bỏ qua), `viaCondiment` theo `recipe.condimentAllergenIds`, sắp theo id.
    - `bool get sending`; `Future<AddMealResult> addOneServing()` – đang gửi → `AddMealIgnored`; chưa có `clientRequestId` thì sinh mới; Offline giữ nguyên id cho lần thử lại; Success sinh lại ở lần bấm sau (xóa id); ProfileMissing/Failed giữ id.

- [ ] **Step 1: Viết test fail** (`setUp` tạo `repo = FakeRecipeRepository()` với `details['r1']` (servings 2, allergens {1, 2}, condiment {1}), `catalog = RecipeCatalog(repo: repo)`, `meal = FakeMealLogRepository()`; helper `make({Recipe? initial, DateTime Function()? now})` dựng controller id `'r1'`, mặc định `now: () => DateTime.utc(2026, 10, 28, 12)`, `newRequestId` trả lần lượt `'id-1'`, `'id-2'`…; `c = make()`)

```dart
test('load: có detail → ready; không thấy → notFound; lỗi → error', () async { ... });
test('mở bằng extra hiện ngay recipe trước khi load', () {
  final c = make(initial: recipe(id: 'r1', title: 'Cá kho'));
  expect(c.recipe!.title, 'Cá kho');
  expect(c.status, DetailStatus.loading);
});
test('khẩu phần 1–20, factor', () async {
  await c.load(); // detail servings = 2
  c.incServings();
  expect(c.factor, 1.5);
  for (var i = 0; i < 30; i++) { c.decServings(); }
  expect(c.cookServings, 1);
});
test('bữa và ngày từ cùng một now()', () {
  final c = make(now: () => DateTime.utc(2026, 10, 28, 23, 50));
  expect(c.mealType, MealType.snack);
  expect(c.logDate, '2026-10-28');
});
test('gửi đúng body, thành công thì lần sau id mới', () async {
  expect(await c.addOneServing(), isA<AddMealSuccess>());
  await c.addOneServing();
  expect(meal.calls.map((x) => x['clientRequestId']), ['id-1', 'id-2']);
  expect(meal.calls.first['mealType'], MealType.lunch);
  expect(meal.calls.first['date'], '2026-10-28');
});
test('mất mạng thì thử lại dùng lại id cũ', () async {
  meal.failWith = MealLogOffline();
  expect(await c.addOneServing(), isA<AddMealOffline>());
  meal.failWith = null;
  await c.addOneServing();
  expect(meal.calls.map((x) => x['clientRequestId']), ['id-1', 'id-1']);
});
test('PROFILE_NOT_FOUND', () async {
  meal.failWith = MealLogProfileMissing();
  expect(await c.addOneServing(), isA<AddMealProfileMissing>());
});
test('bấm hai lần khi đang gửi → một request', () async {
  meal.gate = Completer<void>();
  final first = c.addOneServing();
  expect(await c.addOneServing(), isA<AddMealIgnored>());
  meal.gate!.complete();
  await first;
  expect(meal.calls, hasLength(1));
});
test('cảnh báo dị ứng có cờ gia vị, kể cả khi chip lọc tắt', () async {
  repo
    ..userAllergenIds = {1, 2}
    ..allergens = const [Allergen(id: 1, nameVi: 'Hải sản'), Allergen(id: 2, nameVi: 'Trứng')];
  // detail: allergens {1, 2}, condiment {1}
  await c.load();
  expect(c.allergenWarnings.map((w) => (w.name, w.viaCondiment)), [('Hải sản', true), ('Trứng', false)]);
});
```
(Thân test `load` viết đủ 3 trường hợp với `repo.details`, `repo.failWith`.)

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_detail_controller_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(recipes): detail screen controller with add-to-meal`

---

### Task 12: Router, khung 4 tab, `RecipeScope` trong app

**Files:**
- Modify: `app/lib/core/router.dart`, `app/lib/main.dart`
- Create: `app/lib/core/app_shell.dart`, `app/lib/core/coming_soon_screen.dart`, `app/test/helpers/test_app.dart`
- Test: `app/test/core/router_test.dart`

**Interfaces:**
- Consumes: `RecipeCatalog`, `RecipeScope`, `recipeRepo` (Task 8).
- Produces:
  - `abstract class AuthGate implements Listenable { bool get isLoggedIn; bool get recovering; }`; `AuthNotifier` hiện có `implements AuthGate` (`isLoggedIn` = `supabase.auth.currentSession != null`), giữ `authNotifier`, `finishRecovery`.
  - `GoRouter buildRouter({required AuthGate auth, String initialLocation = '/welcome', WidgetBuilder? homeBuilder})` – `homeBuilder` mặc định `HomePlaceholder`; giữ nguyên logic `redirect` hiện có (đổi `supabase.auth.currentSession != null` thành `auth.isLoggedIn`, `authNotifier.recovering` thành `auth.recovering`), `refreshListenable: auth`. `final router = buildRouter(auth: authNotifier);`
  - Shell `StatefulShellRoute.indexedStack` 4 nhánh: `/home`, `/diary` (`ComingSoonScreen(title: 'Nhật ký')`), `/recipes` (`RecipeSearchScreen()` – Task 13 tạo; trong task này dùng tạm `ComingSoonScreen(title: 'Món ăn')`), `/profile` (`ComingSoonScreen(title: 'Cá nhân')`). Route con `GoRoute(path: ':id', parentNavigatorKey: rootKey, builder: …)` dưới `/recipes` – task này dùng `ComingSoonScreen(title: id)`; Task 15 thay bằng `RecipeDetailScreen(id: …, initial: state.extra as Recipe?)`. `rootKey` tạo trong `buildRouter`.
  - `class AppShell extends StatelessWidget { const AppShell({super.key, required this.navigationShell}); final StatefulNavigationShell navigationShell; }` – `Scaffold` + `NavigationBar` (Material 3, 4 đích: Trang chủ `Icons.home_outlined`, Nhật ký `Icons.menu_book_outlined`, Món ăn `Icons.restaurant`, Cá nhân `Icons.person_outline`; `indicatorColor: AppColors.primaryContainer`), `PopScope(canPop: navigationShell.currentIndex == 0, onPopInvokedWithResult: (didPop, _) { if (!didPop) navigationShell.goBranch(0); })`.
  - `ElytraApp` thành `StatefulWidget`: State tạo `RecipeCatalog(repo: recipeRepo, userIdChanges: supabase.auth.onAuthStateChange.map((s) => s.session?.user.id))`, dispose khi State dispose; `MaterialApp.router(..., builder: (context, child) => RecipeScope(catalog: _catalog, child: child!))`.
  - Test helper: `class FakeAuth extends ChangeNotifier implements AuthGate { bool isLoggedIn; bool recovering = false; }`; `Future<GoRouter> pumpTestApp(WidgetTester t, {required AuthGate auth, required RecipeCatalog catalog, String initialLocation = '/recipes'})` – `buildRouter(auth: auth, initialLocation: initialLocation, homeBuilder: (_) => const Text('HOME'))`, `MaterialApp.router` **không** theme, cùng `builder:` bọc `RecipeScope`; trả router để test đọc `router.routerDelegate.currentConfiguration.uri.path`.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('chưa đăng nhập vào /recipes → /welcome', (t) async {
  final r = await pumpTestApp(t, auth: FakeAuth(isLoggedIn: false), catalog: RecipeCatalog(repo: FakeRecipeRepository()));
  await t.pumpAndSettle();
  expect(r.routerDelegate.currentConfiguration.uri.path, '/welcome');
});
testWidgets('đã đăng nhập: /home mở trong shell có 4 tab', (t) async {
  await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: FakeRecipeRepository()), initialLocation: '/home');
  await t.pumpAndSettle();
  expect(find.text('HOME'), findsOneWidget);
  expect(find.byType(NavigationBar), findsOneWidget);
  for (final l in ['Trang chủ', 'Nhật ký', 'Món ăn', 'Cá nhân']) {
    expect(find.text(l), findsOneWidget);
  }
});
testWidgets('Back ở tab khác Trang chủ → về Trang chủ', (t) async {
  final r = await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: FakeRecipeRepository()), initialLocation: '/diary');
  await t.pumpAndSettle();
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
  expect(r.routerDelegate.currentConfiguration.uri.path, '/home');
});
testWidgets('/recipes/:id che thanh điều hướng', (t) async {
  await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: FakeRecipeRepository()), initialLocation: '/recipes/r1');
  await t.pumpAndSettle();
  expect(find.byType(NavigationBar), findsNothing);
});
```

- [ ] **Step 2: Chạy `flutter test test/core/router_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy `flutter test` (toàn bộ) và `flutter analyze`** – PASS, sạch.
- [ ] **Step 5: Kiểm tra tay nhanh** (`flutter run --dart-define-from-file=env.json`): đăng nhập → `/home` có 4 tab; đăng xuất → `/welcome`.
- [ ] **Step 6: Commit** – `feat(core): four-tab shell with go_router and recipe scope`

---

### Task 13: Màu mới + `RecipeCard` + màn Tìm kiếm

**Files:**
- Modify: `app/lib/core/theme.dart`, `app/lib/core/router.dart` (nhánh `/recipes` → `RecipeSearchScreen`)
- Create: `app/lib/features/recipes/recipe_search_screen.dart`, `app/lib/features/recipes/widgets/recipe_card.dart`, `app/lib/features/recipes/widgets/recipe_chips.dart`, `app/lib/features/recipes/widgets/skeletons.dart`
- Test: `app/test/recipes/recipe_search_screen_test.dart`

**Interfaces:**
- Consumes: `RecipeSearchController` (Task 10), `RecipeScope` (Task 8), `displayTitle`, `formatDuration` (Task 1), `pumpTestApp` (Task 12).
- Produces: `class RecipeSearchScreen extends StatefulWidget` (State tạo/dispose `RecipeSearchController`, gọi `catalog.ensureLoaded()` lần đầu); `class RecipeCard extends StatelessWidget { const RecipeCard({required Recipe recipe, required VoidCallback onTap}); }`; key `Key('recipeSearchField')` trên `TextField`.

Việc cần làm:
- `AppColors` theo §11: sửa `textMuted` 0xFF5B6B80, `outlineStrong` 0xFFD1DCE8, `primaryDisabled` 0x6615803D; thêm `primarySurface`, `primaryOutline`, `surfaceVariant`, `placeholder`, `protein`, `proteinContainer`, `onProteinContainer`, `proteinOutline`, `carbs`, `carbsContainer`, `onCarbsContainer`, `carbsOutline`, `fat`, `fatContainer`, `onFatContainer`, `fatOutline`, `onErrorContainer` với đúng mã ở §11.
- Bố cục theo `docs/design/sprint4/screens/search-01…07` và §7: tiêu đề "Món ăn"; ô tìm (bo 12, placeholder "Tìm tên món…", nút × khi có chữ, debounce 300 ms gọi `setQuery`, `onSubmitted` → `submitQuery`); nút lọc `ic_tune.svg` + badge `filters.sheetBadgeCount` (ẩn khi 0); hàng chip nhanh ("Bỏ món dị ứng"/"Khai báo dị ứng", "Từ tủ lạnh", "≤ 500 kcal", "≤ 30 phút"); hàng chip nhóm ("Tất cả" + `categories`, chip chọn nền `textPrimary` chữ trắng); dòng "N món" + nút sắp xếp (nhãn `sort.labelVi`); `RefreshIndicator` gọi `catalog.refresh()` (lỗi → SnackBar "Không tải lại được. Kiểm tra mạng."); FAB AI (SnackBar "Sắp có").
- Chip/nút cao 32 nhưng vùng chạm ≥ 48.
- Ô tìm có focus và `query` rỗng → trạng thái 839:557: "Tìm gần đây" (+ "Xóa tất cả", × từng dòng, chạm → đặt query), "Món phổ biến" (`popular`, chạm mở chi tiết); không có mục "Tìm theo nguyên liệu".
- Trạng thái: `idle/loading` → skeleton tĩnh; `error` chưa có dữ liệu → màn mất mạng + "Thử lại" (`ensureLoaded`); 0 kết quả → "Không tìm thấy món nào" + nút "Xóa bộ lọc" (đặt `RecipeFilters()`, query rỗng).
- `RecipeCard`: ảnh cao 144 (`Image.network` có `errorBuilder`; null → nền `surfaceVariant` + icon), chip nhóm, `displayTitle` trên ảnh (2 dòng, ellipsis); kcal 14/700 + "kcal", chấm `protein/carbs/fat` + "P 39 g" (số `NumberFormat('#,##0.#', 'vi')`); `formatDuration(totalMinutes)`, "N phần", `difficulty.labelVi`.
- Chạm thẻ: `controller.recordOpened()` rồi `context.push('/recipes/${r.id}', extra: r)`.
- Bấm chip "Khai báo dị ứng", nút lọc, nút sắp xếp: task này chỉ nối tới hàm mở sheet rỗng `showModalBottomSheet` placeholder; Task 14 thay nội dung.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('hiện danh sách và số món', (t) async {
  repo.recipes = [recipe(id: 'a', title: 'Cá basa kho tộ'), recipe(id: 'b', title: 'Phở bò tái')];
  await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: repo));
  await t.pumpAndSettle();
  expect(find.text('2 món'), findsOneWidget);
  expect(find.text('Cá basa kho tộ'), findsOneWidget);
});
testWidgets('gõ từ khóa lọc danh sách', (t) async {
  ...
  await t.enterText(find.byKey(const Key('recipeSearchField')), 'pho');
  await t.pump(const Duration(milliseconds: 350));
  expect(find.text('1 món'), findsOneWidget);
});
testWidgets('chuyển tab rồi quay lại vẫn giữ từ khóa', (t) async {
  ...
  await t.enterText(find.byKey(const Key('recipeSearchField')), 'pho');
  await t.pump(const Duration(milliseconds: 350));
  await t.tap(find.text('Trang chủ'));
  await t.pumpAndSettle();
  await t.tap(find.text('Món ăn'));
  await t.pumpAndSettle();
  expect(t.widget<TextField>(find.byKey(const Key('recipeSearchField'))).controller!.text, 'pho');
  expect(find.text('1 món'), findsOneWidget);
});
testWidgets('chưa khai báo dị ứng → chip "Khai báo dị ứng"', (t) async { ... expect(find.text('Khai báo dị ứng'), findsOneWidget); });
testWidgets('lỗi tải lần đầu → nút Thử lại', (t) async { repo.failWith = Exception(); ... expect(find.text('Thử lại'), findsOneWidget); });
testWidgets('không có kết quả', (t) async { ... 'zzz' ... expect(find.text('Không tìm thấy món nào'), findsOneWidget); });
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_search_screen_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo mô tả trên.
- [ ] **Step 4: Chạy `flutter test` và `flutter analyze`** – PASS, sạch.
- [ ] **Step 5: Kiểm tra tay** trên máy ảo với dữ liệu thật, so với `search-01`, `search-02`, `search-05`, `search-06`, `search-07`; xem nhanh các màn onboarding/auth sau khi đổi `textMuted`/`outlineStrong`/`primaryDisabled`.
- [ ] **Step 6: Commit** – `feat(recipes): recipe search screen and palette tokens`

---

### Task 14: Sheet Bộ lọc, Sắp xếp, Dị ứng

**Files:**
- Create: `app/lib/features/recipes/widgets/filter_sheet.dart`, `app/lib/features/recipes/widgets/sort_sheet.dart`, `app/lib/features/recipes/widgets/allergen_sheet.dart`
- Modify: `app/lib/features/recipes/recipe_search_screen.dart` (thay placeholder Task 13)
- Test: `app/test/recipes/recipe_sheets_test.dart`

**Interfaces:**
- Consumes: `RecipeSearchController` (Task 10), `RecipeCatalog.saveAllergens`, `allergens`, `userAllergenIds` (Task 8).
- Produces:
  - `Future<RecipeFilters?> showFilterSheet(BuildContext context, {required RecipeSearchController controller})` – trả bộ lọc khi bấm "Xem N món", null khi đóng. Nội dung theo §7 / `search-03`: Calo tối thiểu/tối đa (`TextField` số nguyên, `Key('minKcal')`, `Key('maxKcal')`, 0–1.500, trống = null, min > max → lỗi "Tối thiểu phải nhỏ hơn tối đa" và nút vô hiệu); Thời gian (Bất kỳ/≤ 15/≤ 30/≤ 60 phút); Độ khó (chọn nhiều); "Nguyên liệu trong tủ lạnh" (chỉ giao diện, chữ mờ "Sắp có"); công tắc "Loại món chứa chất tôi dị ứng" (bật/tắt `excludeAllergens`, dòng phụ là tên chất đã khai báo · "sửa" mở sheet dị ứng; chưa khai báo → "Chưa khai báo · khai báo"). Nội dung cuộn, footer cố định "Xóa lọc" (về `RecipeFilters(category: hiện tại)`) / "Xem N món" (`FilledButton`, `controller.countFor(draft)`, nền `primaryDark`).
  - `Future<RecipeSort?> showSortSheet(BuildContext context, RecipeSort current)` – 7 dòng radio theo `labelVi`.
  - `Future<void> showAllergenSheet(BuildContext context)` – đọc `RecipeScope.of(context)`; 8 checkbox (`nameVi`, `description` nhỏ), nút "Lưu" gọi `saveAllergens`; lỗi → giữ sheet, hiện "Không lưu được. Thử lại."; thành công → đóng. Nếu `catalog.allergens` rỗng (chưa tải) → gọi `ensureLoaded()` trước.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('Bộ lọc: đếm "Xem N món" khi đổi lọc, áp dụng khi bấm', (t) async {
  repo.recipes = [recipe(id: 'a', kcal: 100), recipe(id: 'b', title: 'B', kcal: 900)];
  ... mở sheet (tap icon lọc) ...
  await t.enterText(find.byKey(const Key('maxKcal')), '500');
  await t.pump();
  expect(find.text('Xem 1 món'), findsOneWidget);
  expect(find.text('2 món'), findsOneWidget); // danh sách chưa đổi
  await t.tap(find.text('Xem 1 món'));
  await t.pumpAndSettle();
  expect(find.text('1 món'), findsOneWidget);
});
testWidgets('Bộ lọc: min > max vô hiệu nút', (t) async {
  ... enterText minKcal '600', maxKcal '500' ...
  expect(find.text('Tối thiểu phải nhỏ hơn tối đa'), findsOneWidget);
  expect(t.widget<FilledButton>(find.ancestor(of: find.textContaining('Xem'), matching: find.byType(FilledButton))).onPressed, isNull);
});
testWidgets('Sắp xếp: chọn "Calo: thấp → cao" đổi nhãn nút', (t) async { ... });
testWidgets('Dị ứng: lưu → chip đổi thành "Bỏ món dị ứng"', (t) async {
  repo.allergens = const [Allergen(id: 1, nameVi: 'Hải sản (Tôm, Cua, Mực, Cá)'), Allergen(id: 2, nameVi: 'Trứng')];
  ... tap 'Khai báo dị ứng', tap 'Trứng', tap 'Lưu', pumpAndSettle ...
  expect(repo.userAllergenIds, {2});
  expect(find.text('Bỏ món dị ứng'), findsOneWidget);
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_sheets_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy `flutter test` và `flutter analyze`** – PASS, sạch.
- [ ] **Step 5: Kiểm tra tay** so với `search-03`, `search-04`; ghi/đọc dị ứng thật trên production bằng tài khoản thử:
  - [ ] chọn 2 chất → Lưu → kéo xuống tải lại vẫn còn 2 chất;
  - [ ] bỏ chọn hết → Lưu → không lỗi, chip trở lại "Khai báo dị ứng", kéo xuống tải lại vẫn rỗng (bảng `user_allergens` không còn dòng của user).
- [ ] **Step 6: Commit** – `feat(recipes): filter, sort and allergen sheets`

---

### Task 15: Màn Chi tiết món

**Files:**
- Create: `app/lib/features/recipes/recipe_detail_screen.dart`, `app/lib/features/recipes/widgets/detail_sections.dart`
- Modify: `app/lib/core/router.dart` (route `:id` → `RecipeDetailScreen`)
- Test: `app/test/recipes/recipe_detail_screen_test.dart`

**Interfaces:**
- Consumes: `RecipeDetailController` (Task 11), `formatIngredient` (Task 6), `recipe_nutrition.dart` (Task 7), `displayTitle` (Task 1), `mealLogRepo` (Task 9).
- Produces: `class RecipeDetailScreen extends StatefulWidget { const RecipeDetailScreen({super.key, required this.id, this.initial, this.mealLogs}); final String id; final Recipe? initial; final MealLogRepository? mealLogs; }` – State tạo controller (`mealLogs ?? mealLogRepo`, catalog từ `RecipeScope.of(context)` trong `didChangeDependencies` lần đầu), gọi `load()`, dispose khi đóng.

Việc cần làm, theo `detail-01…04` và §9:
- Hero 240 + nút quay lại (vùng chạm 48, `context.pop()`), chip nhóm `categoryLabel`, `displayTitle` (2 dòng), "`Việt Nam` · `difficulty.labelVi`" (`cuisine == 'vietnamese'` → "Việt Nam", khác → nguyên văn).
- Banner dị ứng (`errorContainer` / `onErrorContainer`) khi `allergenWarnings` không rỗng: "Có Hải sản (Tôm, Cua, Mực, Cá) (từ gia vị), Trứng".
- Lưới 4 ô: Calo (`primaryContainer` viền `primaryOutline`), Protein, Carbs, Fat (nền/viền/chữ token tương ứng; Fat viền `fatOutline`, số `onFatContainer`).
- Dòng bữa: `mealFit(kcal, mealBudget)` – Within → "≈ X% calo bữa <labelVi> của bạn (<budget> kcal)" nền `primarySurface`; Over → "Vượt Y kcal so với bữa <labelVi>" nền `errorContainer` chữ `onErrorContainer`; null → ẩn.
- Meta: "Chuẩn bị N phút · Nấu N phút · N phần".
- Nguyên liệu: tiêu đề + "Nấu cho" + stepper −/+ (`Key('servingsDec')`, `Key('servingsInc')`, chữ "N phần"); mỗi dòng `formatIngredient(row, factor)`: tên trái; phải `amountText` (xanh đậm `primaryDark`) + `gramText` mờ; hoặc `note` mờ.
- Cách nấu: "N bước"; thẻ mỗi bước (ô số vuông xanh / ô check khi xong, `title` đậm, `description`, chạm → `toggleStep`, xong thì gạch ngang); chú thích "Chạm vào bước để đánh dấu đã làm xong".
- Thông tin dinh dưỡng ("Mỗi khẩu phần"): thanh tỉ lệ năng lượng (`energySplit`), 6 dòng (Calo, Protein, Carbs, Fat, Chất xơ, Natri) số + `pctOfTarget` + thanh (natri so `kSodiumDailyMaxMg`); target null → chỉ số; `sodiumHighForMeal` → "Natri cao – nên ăn kèm rau và giảm nước kho" màu `onErrorContainer`; chú thích "Số liệu ước tính từ nguyên liệu · mục tiêu ngày <kcal> kcal, natri tối đa 2.000 mg" (không có target → bỏ vế mục tiêu).
- Nút ghim đáy "Thêm 1 phần vào bữa <labelVi>" (nền `primaryDark`, vô hiệu khi `sending` hoặc chưa có `recipe`): kết quả → SnackBar: Success "Đã thêm 1 phần vào bữa <labelVi>"; Offline "Không có kết nối" + action "Thử lại" (gọi lại `addOneServing`); ProfileMissing "Bạn cần hoàn tất hồ sơ trước" + action "Khai báo" → `context.go('/gate')`; Failed "Không thêm được. Thử lại sau."; Ignored → không làm gì.
- Trạng thái: có `initial` → hero/tên/lưới hiện ngay, skeleton tĩnh cho phần dưới; không → skeleton toàn màn; `error` → "Không tải được món" + "Thử lại" (`load()`); `notFound` → "Không tìm thấy món" + "Quay lại".

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('mở thẳng /recipes/:id (không extra) vẫn tải được', (t) async {
  repo.details = {'r1': detailFixture()}; // title 'Cá basa kho tộ', 2 nguyên liệu, 2 bước
  await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: repo), initialLocation: '/recipes/r1');
  await t.pumpAndSettle();
  expect(find.text('Cá basa kho tộ'), findsOneWidget);
  expect(find.text('Nguyên liệu'), findsOneWidget);
  expect(find.text('2 bước'), findsOneWidget);
});
testWidgets('id không tồn tại → "Không tìm thấy món"', (t) async { ... initialLocation: '/recipes/zzz' ... });
testWidgets('stepper nhân lượng nguyên liệu, dinh dưỡng giữ 1 phần', (t) async {
  ... detail servings 2, nguyên liệu 'Cá basa phi lê' 400 g, kcal 240 ...
  await t.tap(find.byKey(const Key('servingsInc')));
  await t.pump();
  expect(find.text('600 g'), findsOneWidget);
  expect(find.text('240'), findsWidgets);
});
testWidgets('banner dị ứng có "(từ gia vị)"', (t) async { ... expect(find.textContaining('(từ gia vị)'), findsOneWidget); });
testWidgets('Thêm thành công → SnackBar', (t) async {
  final meal = FakeMealLogRepository();
  ... pump RecipeDetailScreen(id: 'r1', mealLogs: meal) trong MaterialApp + RecipeScope ...
  await t.tap(find.textContaining('Thêm 1 phần vào bữa'));
  await t.pumpAndSettle();
  expect(find.textContaining('Đã thêm 1 phần'), findsOneWidget);
  expect(meal.calls, hasLength(1));
});
```

- [ ] **Step 2: Chạy `flutter test test/recipes/recipe_detail_screen_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo mô tả trên.
- [ ] **Step 4: Chạy `flutter test` và `flutter analyze`** – PASS, sạch.
- [ ] **Step 5: Kiểm tra tay** so với `detail-01…04`; bấm "Thêm" với tài khoản thử trên production, bật chế độ máy bay để thử nhánh mất mạng rồi "Thử lại" (xác nhận chỉ một bản ghi qua `GET /meal-logs` hoặc Dashboard Supabase).
- [ ] **Step 6: Commit** – `feat(recipes): recipe detail screen with add-to-meal`

---

### Task 16: Kiểm tra cuối nhánh

**Files:** không tạo file mới (chỉ sửa nếu kiểm tra phát hiện lỗi).

- [ ] **Step 1:** `flutter analyze` – Expected: "No issues found!".
- [ ] **Step 2:** `flutter test` – Expected: mọi test PASS; dán số test vào mô tả PR.
- [ ] **Step 3:** `git diff main --stat -- ../supabase` – Expected: rỗng (không đụng back-end).
- [ ] **Step 4:** Chạy app thật, đi hết checklist kiểm tra tay ở spec §12 (đặt lại mật khẩu, đăng ký mới → ProfileGate → `/home` có 4 tab, đổi tài khoản → dị ứng/mục tiêu mới, Back Android) và ghi kết quả vào mô tả PR.
- [ ] **Step 5:** Commit các sửa nếu có – `fix(recipes): …`.
