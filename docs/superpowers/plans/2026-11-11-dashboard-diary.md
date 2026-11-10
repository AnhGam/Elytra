# Dashboard, Ghi bữa ăn, Nhật ký – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thay `HomePlaceholder` và tab Nhật ký "Sắp có" bằng Dashboard, màn Ghi bữa ăn (3 nguồn) và Nhật ký (Theo ngày + Thống kê). Mọi thao tác ghi, sửa, xoá đi qua một `DiaryStore` dùng chung.

**Architecture:** Logic thuần Dart (lời chào, mốc 30 ngày, ngân sách, khẩu phần, thống kê) viết theo TDD. Dữ liệu qua interface `MealLogRepository` / `FoodSearchRepository`; bản Supabase là singleton cấp file. `DiaryStore` (ChangeNotifier ở gốc app, chia sẻ bằng `DiaryScope`) cache `DayLog` theo ngày và `History` theo khoảng, áp quy tắc cập nhật §5.4 của spec, giữ các món đang chờ xoá. Mỗi màn có controller `ChangeNotifier` riêng; màn chỉ đọc store và controller.

**Tech Stack:** Flutter 3.47 / Dart 3.13, supabase_flutter 2.18 (functions_client 2.7.1), go_router 18.0.2, fl_chart, intl, flutter_test. Không thêm package.

**Spec:** `docs/superpowers/specs/2026-11-11-dashboard-diary-design.md` (đọc kèm). Ký hiệu "§" bên dưới trỏ vào mục của spec. Thiết kế: `docs/design/sprint5/README.md` và `docs/design/sprint5/screens/*.png`.

**Cách thực thi:**
- Task 1–11 (dữ liệu và logic): subagent-driven, có reviewer cho từng task. Dừng sau Task 11 để báo tóm tắt và số test.
- Task 12–16 (UI): làm native ở phiên mới, dừng sau **mỗi** task để nhóm chạy app so với Figma.
- Task 17: kiểm tra cuối nhánh.

## Global Constraints

- Mọi lệnh `flutter` chạy trong `app/`. Mỗi task kết thúc với `flutter analyze` sạch và `flutter test` qua.
- KHÔNG sửa `supabase/`.
- Màu chỉ dùng `AppColors` (`app/lib/core/theme.dart`). Font Be Vietnam Pro đã đặt trong theme, widget không gọi `GoogleFonts` trực tiếp.
- Số kiểu VN dùng `NumberFormat(..., 'vi')`: "38,5 g", "1.968 kcal".
- Chuỗi giao diện và comment viết tiếng Việt. Commit viết tiếng Anh theo dạng `loại(phạm vi): mô tả`, **không** có dòng `Co-Authored-By`. Phạm vi: `core`, `meal-logs`, `dashboard`, `diary`, `profile`, `recipes`.
- UI không gọi `supabase` trực tiếp, chỉ qua repository, store, catalog hoặc controller.
- "Bây giờ" chỉ lấy từ `vnNow()` (UTC+7) và được tiêm qua tham số `DateTime Function() now` để test. Không gọi `toLocal()`. Ngày dạng chuỗi `YYYY-MM-DD` chỉ tạo bằng `isoDate()`.
- Mốc 30 ngày chỉ nằm trong `withinEditWindow` (Task 1).
- Widget test không dùng `buildAppTheme()` (google_fonts tải font qua mạng) và không chạm `supabase` toàn cục. Mọi thứ cần Supabase đều được tiêm bản giả.
- Skeleton là khối tĩnh (không shimmer), các màn mới không dùng `CircularProgressIndicator`, để `pumpAndSettle` không treo.
- Vùng chạm ≥ 48 × 48.

## Review Focus

1. Dashboard, Thống kê, thẻ "7 ngày qua" và dải ngày luôn cùng số sau khi thêm, sửa hoặc xoá, kể cả khi thêm từ Chi tiết món và khi món đang chờ xoá. Test ở Task 7, 8, 11.
2. Retry sau lỗi mạng với nội dung y nguyên thì gửi đúng `client_request_id` cũ. Đổi lượng, bữa hoặc món thì sinh khoá mới. `IDEMPOTENCY_CONFLICT` hiện lỗi chứ không crash. Test ở Task 3, 9.
3. Bấm "Thêm" hai lần khi request đầu chưa xong chỉ gửi một request. Test ở Task 9, 11.
4. Qua 0h hoặc app quay lại từ nền thì "hôm nay" chuyển sang ngày mới. Ngày cũ vẽ theo `days[].target_kcal` của chính nó. Test ở Task 6, 7.
5. `target = 0` hoặc thiếu mục tiêu: không chia cho 0, vòng và thanh không quá 100 %, trục biểu đồ hợp lệ khi dữ liệu toàn 0. Test ở Task 5, 6.
6. Body lỗi lạ, số NUMERIC dạng chuỗi, `recipe_id` null hoặc thiếu bữa đều không làm app crash. Test ở Task 2, 3.
7. Từ khoá rỗng, chỉ có dấu câu, hoặc gõ không dấu ("pho") vẫn ra kết quả hợp lý ở cả 3 tab. Test ở Task 4, 9.
8. Lời chào và avatar không bao giờ lấy từ email. Test ở Task 1.
9. Đăng xuất gửi hết các `DELETE` đang treo trước `signOut()`; `clear()` chỉ bỏ, không gửi. Test ở Task 8, 12.
10. Ngày thứ 30 trước hôm nay vẫn sửa được, ngày thứ 31 thì không. Test ở Task 1.

---

## Cấu trúc file

```
app/lib/core/
  greeting.dart                 (mới) displayName, shortName, greeting
  edit_window.dart              (mới) parseIsoDate, shiftDate, withinEditWindow
  router.dart                   (sửa) /home, /diary, /profile, /log
app/lib/main.dart               (sửa) DiaryStore + DiaryScope, AppLifecycleListener
app/lib/features/meal_logs/
  meal_log_models.dart          (mới) Macros, Budget, LogSource, MealLogItem, MealLog, DayLog, HistoryDay, History, FoodKind, FoodHit, LogRequest
  meal_log_repository.dart      (sửa) MealLogOp, lỗi mới, AddResult, UpdateResult, getDay/getHistory/add/updateItem/deleteItem
  food_search_repository.dart   (mới)
  budget_view.dart              (mới) logic thuần
  portion_math.dart             (mới) logic thuần
  history_stats.dart            (mới) logic thuần
  request_keys.dart             (mới) RequestKeys
  diary_store.dart              (mới) DiaryStore, LoadStatus, DayEntry, HistoryEntry, PendingDelete, DiaryViewRequest
  diary_scope.dart              (mới)
  log_meal_controller.dart      (mới)
  log_meal_screen.dart          (mới) + widgets/food_row.dart, widgets/portion_sheet.dart
app/lib/features/home/
  dashboard_screen.dart         (mới) + widgets/calorie_ring.dart, macro_bar.dart, meal_card.dart, week_card.dart
  home_placeholder.dart         (xoá)
app/lib/features/diary/
  diary_controller.dart         (mới)
  diary_screen.dart             (mới) + widgets/day_strip.dart, day_meals.dart, edit_item_sheet.dart, history_chart.dart, stats_view.dart
app/lib/features/profile/profile_screen.dart   (mới)
app/lib/features/recipes/recipe.dart, recipe_repository.dart, recipe_detail_controller.dart, recipe_detail_screen.dart  (sửa)
app/lib/features/nutrition/result_screen.dart, app/lib/features/auth/profile_gate.dart  (sửa: xoá cache)
app/test/core/…, app/test/meal_logs/…, app/test/home/…, app/test/diary/…, app/test/profile/…
app/test/helpers/fake_meal_log_repository.dart (viết lại), fake_food_search_repository.dart (mới), meal_log_fixtures.dart (mới), test_app.dart (sửa)
```

---

### Task 1: Lời chào, mốc 30 ngày, tên trong hồ sơ

**Files:**
- Create: `app/lib/core/greeting.dart`, `app/lib/core/edit_window.dart`
- Modify: `app/lib/features/recipes/recipe.dart` (`UserNutritionProfile`), `app/lib/features/recipes/recipe_repository.dart` (`fetchProfile` select)
- Test: `app/test/core/greeting_test.dart`, `app/test/core/edit_window_test.dart`, `app/test/recipes/recipe_model_test.dart` (thêm ca)

**Interfaces:**
- Produces:
  - `String? displayName(String? fullName)`: `trim()`; rỗng hoặc chứa `@` thì trả `null`, còn lại trả chuỗi đã trim.
  - `String shortName(String name)`: từ cuối sau khi tách theo khoảng trắng.
  - `String greeting(DateTime t)`: theo mốc giờ §5.5, chỉ đọc `hour` và `minute`.
  - `String avatarInitial(String name)`: chữ cái đầu của `shortName(name)`, viết hoa.
  - `DateTime? parseIsoDate(String s)`: đúng dạng `^\d{4}-\d{2}-\d{2}$` và là ngày có thật thì trả `DateTime.utc(y, m, d)`, còn lại `null`.
  - `String shiftDate(String iso, int days)`: cộng hoặc trừ ngày trên `DateTime.utc` rồi `isoDate`. `iso` sai dạng thì ném `ArgumentError`.
  - `bool withinEditWindow(String date, String today)`: đúng khi `shiftDate(today, -30) ≤ date ≤ today`. Chuỗi sai dạng thì `false`.
  - `UserNutritionProfile.fullName` (`String?`, tham số tuỳ chọn `this.fullName` trong constructor const), parse từ `row['full_name']`. Chỉ nhận `String`, kiểu khác thì `null`. `fetchProfile` select thêm `full_name`.

- [ ] **Step 1: Viết test fail**

```dart
// greeting_test.dart
test('displayName bỏ email, rỗng, null', () {
  expect(displayName(null), isNull);
  expect(displayName('   '), isNull);
  expect(displayName('24521740@gm.uit.edu.vn'), isNull);
  expect(displayName('  Nguyễn Văn Thuận '), 'Nguyễn Văn Thuận');
});
test('shortName và avatarInitial lấy từ cuối', () {
  expect(shortName('Nguyễn Văn Thuận'), 'Thuận');
  expect(shortName('An'), 'An');
  expect(avatarInitial('nguyễn văn thuận'), 'T');
});
test('greeting theo mốc giờ', () {
  String at(int h, int m) => greeting(DateTime.utc(2026, 11, 11, h, m));
  expect(at(4, 0), 'Chào buổi sáng');
  expect(at(10, 59), 'Chào buổi sáng');
  expect(at(11, 0), 'Chào buổi trưa');
  expect(at(13, 59), 'Chào buổi trưa');
  expect(at(14, 0), 'Chào buổi chiều');
  expect(at(17, 59), 'Chào buổi chiều');
  expect(at(18, 0), 'Chào buổi tối');
  expect(at(3, 59), 'Chào buổi tối');
});

// edit_window_test.dart
test('ngày thứ 30 sửa được, ngày thứ 31 thì không', () {
  expect(withinEditWindow('2026-10-12', '2026-11-11'), isTrue);  // 30 ngày
  expect(withinEditWindow('2026-10-11', '2026-11-11'), isFalse); // 31 ngày
  expect(withinEditWindow('2026-11-11', '2026-11-11'), isTrue);
  expect(withinEditWindow('2026-11-12', '2026-11-11'), isFalse); // tương lai
  expect(withinEditWindow('2026-13-01', '2026-11-11'), isFalse);
  expect(withinEditWindow('hôm qua', '2026-11-11'), isFalse);
});
test('shiftDate qua tháng và năm', () {
  expect(shiftDate('2026-03-01', -1), '2026-02-28');
  expect(shiftDate('2026-12-31', 1), '2027-01-01');
  expect(parseIsoDate('2026-02-30'), isNull);
});

// recipe_model_test.dart (thêm)
test('profile đọc full_name, kiểu lạ thì null', () {
  expect(UserNutritionProfile.fromRow({'full_name': 'An'}).fullName, 'An');
  expect(UserNutritionProfile.fromRow({'full_name': 3}).fullName, isNull);
});
```

- [ ] **Step 2: Chạy `flutter test test/core/greeting_test.dart test/core/edit_window_test.dart test/recipes/recipe_model_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(core): greeting, 30-day edit window and profile name`

---

### Task 2: Models nhật ký (`meal_log_models.dart`)

**Files:**
- Create: `app/lib/features/meal_logs/meal_log_models.dart`, `app/test/helpers/meal_log_fixtures.dart`
- Test: `app/test/meal_logs/meal_log_models_test.dart`

**Interfaces:**
- Consumes: `MealType` (`core/meal_time.dart`).
- Produces (tất cả bất biến, parse bằng `_num` riêng của file: `num` → double, chuỗi số → double, còn lại → 0):
  - `class Macros { const Macros({this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0}); static const zero; factory Macros.fromJson(Object? j); Macros operator +(Macros o); Macros operator -(Macros o); Macros scale(double k); }`. Khoá JSON: `kcal`, `protein_g`, `carbs_g`, `fat_g`.
  - `class Budget { final Macros target, consumed, remaining; factory Budget.fromJson(Object? j); Budget withConsumed(Macros c); }`. Thiếu `remaining` thì lấy `target − consumed`. `withConsumed` tính lại `remaining`.
  - `enum LogSource { recipe, dish, ingredient }`.
  - `class MealLogItem { id, source, recipeId?, dishId?, ingredientId?, name, imageUrl?, servings?, amountG?, macros, createdAt?, mealType?, date?; factory MealLogItem.fromJson(Map<String, dynamic> j); bool get byServings; MealLogItem copyWith({double? servings, double? amountG, Macros? macros}); }`.
    - `source` lạ: có `amount_g` thì là `ingredient`, không thì `recipe`.
    - `byServings` = `source == LogSource.recipe`.
    - `mealType` đọc từ `meal_type` (lạ thì `null`), `date` đọc từ `date`.
  - `class MealLog { final double kcal; final List<MealLogItem> items; static const empty; }`.
  - `class DayLog { final String date; final Budget budget; final Map<MealType, MealLog> meals; factory DayLog.fromJson(Map<String, dynamic> j); DayLog upsert(MealLogItem item, MealType meal, Budget budget); DayLog without(String itemId); MealLogItem? find(String itemId); MealType? mealOf(String itemId); bool get isEmpty; }`.
    - `meals` luôn đủ 4 bữa.
    - `upsert`: thay item cùng `id`, hoặc thêm vào cuối bữa; `MealLog.kcal` cộng lại từ items; `budget` lấy theo tham số.
    - `without`: bỏ item, cộng lại `kcal` của bữa, budget tính lại bằng `withConsumed(consumed − item.macros)`.
  - `class HistoryDay { date, kcal, proteinG, carbsG, fatG, itemCount, targetKcal; factory fromJson; HistoryDay copyWith({double? kcal, double? proteinG, double? carbsG, double? fatG, int? itemCount}); }`.
  - `class History { from, to, targetKcal, days; factory fromJson; }`.
  - `enum FoodKind { dish, ingredient }`. `class FoodHit { id, kind, name, per100 (Macros); factory FoodHit.fromRow(Map<String, dynamic> r, FoodKind kind); }`. Các cột: `name_vi`, `calories_per_100g`, `protein_per_100g`, `carbs_per_100g`, `fat_per_100g`.
  - `class LogRequest { final LogSource source; final String refId; final double? servings; final int? amountG; final MealType meal; final String date; const LogRequest.recipe(...), .dish(...), .ingredient(...); Map<String, Object> toBody(String clientRequestId); operator ==; hashCode; }`.
    - `toBody` gồm `meal_type`, đúng một trong `recipe_id`/`dish_id`/`ingredient_id`, `servings` hoặc `amount_g`, `date`, `client_request_id`.
  - Fixtures:
    - `MealLogItem item({String id = 'i1', String name = 'Món', LogSource source = LogSource.recipe, double kcal = 100, double proteinG = 0, double carbsG = 0, double fatG = 0, double? servings, double? amountG, String? date})`. Mặc định món nấu có `servings: 1`.
    - `DayLog dayLog({String date = '2026-11-11', double target = 1968, List<(MealType, MealLogItem)> items = const []})`: budget tính từ items.
    - `HistoryDay hday(String date, double kcal, {double target = 1968, int? items})`: `items` null thì là `kcal > 0 ? 1 : 0`.

- [ ] **Step 1: Viết test fail**

```dart
test('budget: remaining âm, NUMERIC dạng chuỗi, thiếu remaining', () {
  final b = Budget.fromJson({
    'target': {'kcal': '1968', 'protein_g': 130},
    'consumed': {'kcal': 2118.4, 'protein_g': '140.5'},
  });
  expect(b.remaining.kcal, closeTo(-150.4, 1e-9));
  expect(b.remaining.proteinG, closeTo(-10.5, 1e-9));
});
test('item: recipe_id null, source lạ, kiểu lạ không ném', () {
  final i = MealLogItem.fromJson({'id': 'x', 'source': 'recipe', 'recipe_id': null, 'name': 'Phở bò', 'servings': '1.5', 'kcal': 675});
  expect(i.recipeId, isNull);
  expect(i.servings, 1.5);
  expect(MealLogItem.fromJson({'id': 'y', 'source': '??', 'amount_g': 150, 'name': 'A'}).source, LogSource.ingredient);
  expect(() => MealLogItem.fromJson({'id': 'z', 'kcal': [1], 'name': null}), returnsNormally);
});
test('DayLog luôn đủ 4 bữa', () {
  final d = DayLog.fromJson({'date': '2026-11-11', 'budget': {}, 'meals': {'lunch': {'kcal': 675, 'items': []}}});
  expect(d.meals.keys, unorderedEquals(MealType.values));
  expect(d.meals[MealType.dinner]!.items, isEmpty);
});
test('without trừ budget và kcal bữa; upsert thay theo id', () {
  final a = item(id: 'a', kcal: 300), b = item(id: 'b', kcal: 200);
  final d = dayLog(items: [(MealType.lunch, a), (MealType.lunch, b)]);
  final w = d.without('a');
  expect(w.meals[MealType.lunch]!.kcal, 200);
  expect(w.budget.consumed.kcal, 200);
  expect(w.budget.remaining.kcal, 1768);
  final u = d.upsert(a.copyWith(macros: const Macros(kcal: 450)), MealType.lunch, d.budget);
  expect(u.meals[MealType.lunch]!.items.map((i) => i.id), ['a', 'b']);
  expect(u.meals[MealType.lunch]!.kcal, 650);
});
test('LogRequest: == theo nội dung, toBody đúng khoá', () {
  const r = LogRequest.dish(refId: 'd1', amountG: 300, meal: MealType.dinner, date: '2026-11-11');
  expect(r, const LogRequest.dish(refId: 'd1', amountG: 300, meal: MealType.dinner, date: '2026-11-11'));
  expect(r == const LogRequest.dish(refId: 'd1', amountG: 200, meal: MealType.dinner, date: '2026-11-11'), isFalse);
  expect(r.toBody('k'), {'meal_type': 'dinner', 'dish_id': 'd1', 'amount_g': 300, 'date': '2026-11-11', 'client_request_id': 'k'});
});
test('FoodHit từ dòng RPC có số dạng chuỗi', () {
  final f = FoodHit.fromRow({'id': 'x', 'name_vi': 'Phở bò', 'calories_per_100g': '110.5', 'protein_per_100g': null}, FoodKind.dish);
  expect(f.per100.kcal, 110.5);
  expect(f.per100.proteinG, 0);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/meal_log_models_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): diary models with tolerant parsing`

---

### Task 3: `MealLogRepository` đầy đủ + bản giả

**Files:**
- Modify: `app/lib/features/meal_logs/meal_log_repository.dart`, `app/lib/features/recipes/recipe_detail_controller.dart` (gọi `add(LogRequest.recipe(...servings: 1...))` thay cho `addRecipe`), `app/test/recipes/recipe_detail_controller_test.dart` (chỉ sửa assertion theo bản giả mới)
- Rewrite: `app/test/helpers/fake_meal_log_repository.dart`
- Test: `app/test/meal_logs/meal_log_repository_test.dart`

**Interfaces:**
- Consumes: models Task 2.
- Produces:
  - `enum MealLogOp { read, add, update, delete }`.
  - Thêm vào `sealed class MealLogException`: `MealLogItemNotFound`, `MealLogTooOld`, `class MealLogInvalid { final String? field; }`. Giữ `MealLogOffline`, `MealLogProfileMissing`, `MealLogFailed(code, message)`.
  - `MealLogException mapMealLogError(Object e, {MealLogOp op = MealLogOp.add})`: đọc `code`, `message`, `field` (chỉ nhận `String`). Bảng ánh xạ:

    | Lỗi | Kết quả |
    |---|---|
    | `PROFILE_NOT_FOUND` | `ProfileMissing` |
    | `ITEM_NOT_FOUND` | `ItemNotFound` |
    | `VALIDATION_ERROR` + `field == 'date'` + op `update`/`delete` | `TooOld` |
    | `VALIDATION_ERROR` khác | `Invalid(field)` |
    | `IDEMPOTENCY_CONFLICT` và mọi mã khác | `Failed(code, message)` |
    | Lỗi transport | `Offline` (như cũ) |

  - `class AddResult { final MealLogItem item; final Budget budget; final bool replayed; }`. `item.mealType` và `item.date` lấy từ response.
  - `class UpdateResult { final MealLogItem item; final Budget budget; }`.
  - `abstract class MealLogRepository { Future<DayLog> getDay(String date); Future<History> getHistory(String from, String to); Future<AddResult> add(LogRequest req, {required String clientRequestId}); Future<UpdateResult> updateItem(MealLogItem item, {double? servings, int? amountG}); Future<void> deleteItem(String id); }`.
  - `SupabaseMealLogRepository` gọi `supabase.functions.invoke` đúng như "Gọi từ Flutter" trong api-contract §4: GET qua `queryParameters`, PATCH/DELETE qua `meal-logs/items/$id`. Timeout 15 giây. Lỗi ném `mapMealLogError(e, op: …)`. Response không phải `Map` thì ném `MealLogFailed('BAD_RESPONSE')`.
  - `updateItem` gửi `{'servings': s}` khi `item.byServings`, ngược lại gửi `{'amount_g': g}`.
  - Bản giả: `class FakeMealLogRepository implements MealLogRepository`.
    - `final List<(String op, Object arg)> calls`: op là `'getDay'|'getHistory'|'add'|'update'|'delete'`; arg là `date`, `(from, to)`, `(LogRequest, key)`, `(id, servings, amountG)` hoặc `id`.
    - `Map<String, DayLog> days` (`getDay` thiếu ngày thì trả `dayLog(date: d)` rỗng).
    - `History Function(String from, String to)? onHistory` (mặc định mọi ngày bằng 0, `target_kcal` 1968).
    - `Completer<void>? gate`; `MealLogException? failWith`; `Map<String, MealLogException> failOnce` (ném một lần theo op).
    - `add` mặc định tạo item `id: 'item-<n>'`, kcal 100, lưu vào `days[req.date]` và trả budget mới.
    - `delete` bỏ item khỏi `days`.
    - Ghi `calls` **trước** khi chờ `gate`.

- [ ] **Step 1: Viết test fail**

```dart
FunctionException fx(Map<String, Object?> err, [int s = 400]) => FunctionException(status: s, details: {'error': err});
test('field=date: TooOld chỉ khi update/delete', () {
  final e = fx({'code': 'VALIDATION_ERROR', 'field': 'date'});
  expect(mapMealLogError(e, op: MealLogOp.update), isA<MealLogTooOld>());
  expect(mapMealLogError(e, op: MealLogOp.delete), isA<MealLogTooOld>());
  final add = mapMealLogError(e, op: MealLogOp.add);
  expect(add, isA<MealLogInvalid>());
  expect((add as MealLogInvalid).field, 'date');
});
test('ITEM_NOT_FOUND, IDEMPOTENCY_CONFLICT', () {
  expect(mapMealLogError(fx({'code': 'ITEM_NOT_FOUND'}, 404), op: MealLogOp.update), isA<MealLogItemNotFound>());
  final c = mapMealLogError(fx({'code': 'IDEMPOTENCY_CONFLICT', 'field': 'client_request_id'}, 422));
  expect((c as MealLogFailed).code, 'IDEMPOTENCY_CONFLICT');
});
test('field không phải chuỗi, body lạ không crash', () {
  expect(mapMealLogError(fx({'code': 'VALIDATION_ERROR', 'field': 7})), isA<MealLogInvalid>());
  expect(mapMealLogError(const FunctionException(status: 500, details: '<html>')), isA<MealLogFailed>());
  expect(mapMealLogError(const FunctionException(status: 500, details: {'error': 'x'})), isA<MealLogFailed>());
});
// Giữ nguyên các test mapMealLogError cũ (mất mạng, PROFILE_NOT_FOUND Map/JSON, giữ code).
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces. Viết lại bản giả, sửa `RecipeDetailController` sang `add(...)`, chỉ sửa assertion trong `recipe_detail_controller_test.dart` (đọc `calls` theo dạng mới), giữ nguyên ý nghĩa của test.
- [ ] **Step 4: Chạy `flutter test`** (toàn bộ) – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): day, history, add, patch and delete client`

---

### Task 4: `FoodSearchRepository`

**Files:**
- Create: `app/lib/features/meal_logs/food_search_repository.dart`, `app/test/helpers/fake_food_search_repository.dart`
- Test: `app/test/meal_logs/food_search_repository_test.dart`

**Interfaces:**
- Consumes: `FoodHit`, `FoodKind` (Task 2), `wordsOf`, `removeDiacritics` (`recipes/recipe_text.dart`).
- Produces:
  - `const kFoodPageSize = 20;`
  - `String? normalizeFoodQuery(String q)`: `wordsOf(q)` rỗng thì `null`, ngược lại `q.trim()`.
  - `sealed class FoodSearchException`; `FoodSearchOffline`; `FoodSearchFailed`. `FoodSearchException mapFoodSearchError(Object e)`: `SocketException`, `TimeoutException`, `ClientException` của `postgrest`/`http` (qua `e.toString()` chứa `SocketException`/`ClientException`) → Offline; còn lại → Failed.
  - `abstract class FoodSearchRepository { Future<List<FoodHit>> searchDishes(String query, {int limit = kFoodPageSize, int offset = 0}); Future<List<FoodHit>> searchIngredients(String query, {bool? featured, int limit = kFoodPageSize, int offset = 0}); }`.
  - `SupabaseFoodSearchRepository` + `final foodSearchRepo = …`: `supabase.rpc('search_dishes', params: {'p_query': normalizeFoodQuery(q), 'p_limit', 'p_offset'})`; `search_ingredients` thêm `'p_is_featured': featured`. Dòng không phải Map thì bỏ qua. Timeout 15 giây.
  - Bản giả: `FakeFoodSearchRepository { List<FoodHit> dishes, ingredients; Set<String> featuredIds; final List<(String fn, String? q, bool? featured, int offset)> calls; Completer<void>? gate; FoodSearchException? failWith; }`. Lọc bằng `removeDiacritics` + `contains`, sắp A–Z, cắt theo `offset`/`limit`.

- [ ] **Step 1: Viết test fail**

```dart
test('từ khoá rỗng hoặc chỉ dấu câu → null', () {
  expect(normalizeFoodQuery(''), isNull);
  expect(normalizeFoodQuery('  , . '), isNull);
  expect(normalizeFoodQuery('  phở bò '), 'phở bò');
});
test('lỗi mạng và lỗi khác', () {
  expect(mapFoodSearchError(const SocketException('x')), isA<FoodSearchOffline>());
  expect(mapFoodSearchError(TimeoutException('x')), isA<FoodSearchOffline>());
  expect(mapFoodSearchError(StateError('x')), isA<FoodSearchFailed>());
});
test('bản giả: không dấu vẫn khớp, phân trang', () async {
  final f = FakeFoodSearchRepository()..dishes = [for (final n in ['Phở bò', 'Bún chả', 'Phở gà']) FoodHit.fromRow({'id': n, 'name_vi': n}, FoodKind.dish)];
  expect((await f.searchDishes('pho')).map((h) => h.name), ['Phở bò', 'Phở gà']);
  expect((await f.searchDishes('', limit: 2, offset: 2)).map((h) => h.name), ['Phở gà']);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/food_search_repository_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): prepared dish and ingredient search client`

---

### Task 5: Logic thuần `budget_view` + `portion_math` (TDD)

**Files:**
- Create: `app/lib/features/meal_logs/budget_view.dart`, `app/lib/features/meal_logs/portion_math.dart`
- Test: `app/test/meal_logs/budget_view_test.dart`, `app/test/meal_logs/portion_math_test.dart`

**Interfaces:**
- Consumes: `Macros`, `Budget`, `MealLog`, `FoodHit` (Task 2); `MealType`, `mealBudgetKcal` (`meal_time.dart`); `Recipe` (`kcal`/`proteinG`/`carbsG`/`fatG` là số theo **1 phần**).
- Produces, `budget_view.dart`:
  - `String formatKcal(num v)`: số nguyên kiểu VN, `'1.968'`.
  - `String formatGram(num v)`: 1 chữ số thập phân và bỏ `,0`, ví dụ `'58,5'`, `'130'`.
  - `double progressRatio(double consumed, double? target)`: kẹp trong 0–1; `target` `null` hoặc ≤ 0 thì trả 0.
  - `bool isOver(double consumed, double? target)`: `target > 0 && consumed > target`.
  - `int overPct(double consumed, double target)`: `((consumed / target − 1) × 100).round()`; `target ≤ 0` thì 0.
  - `String gramRemainingLabel(double remaining)`: `'Còn 61,6 g'`; âm thì `'Vượt 12 g'`.
  - `({String value, String caption}) ringCenter(Budget b)`: `('816', 'kcal còn lại')` hoặc `('150', 'kcal vượt mức')`.
- Produces, `portion_math.dart`:
  - `const kMinServings = 0.25, kMaxServings = 10.0, kServingStep = 0.25, kMinGram = 1, kMaxGram = 2000;`
  - `const kServingChips = [0.5, 1.0, 1.5, 2.0]; const kGramChips = [200, 300, 400, 500];`
  - `double stepServings(double current, int direction)`: ±`kServingStep`, kẹp hai đầu.
  - `int? parseGram(String text)`: số nguyên trong 1–2000, còn lại `null`.
  - `String formatServings(double s)`: `'1,5 phần'`, `'0,25 phần'`, `'1 phần'`.
  - `String servingChipLabel(double s)`: `'½'`, `'1'`, `'1½'`, `'2'`.
  - `Macros previewRecipe(Recipe r, double servings)`; `Macros previewPer100(FoodHit f, int grams)`.
  - `String afterAddLabel({required Budget day, required MealLog meal, required MealType type, required Macros add})`: `'Sau khi thêm: bữa tối còn 230 kcal · cả ngày còn 456 kcal'`. Từng vế âm thì đổi thành `'vượt x kcal'`. `day.target.kcal ≤ 0` thì chỉ còn vế cả ngày.

- [ ] **Step 1: Viết test fail**

```dart
test('progressRatio: chia 0 và vượt 100 %', () {
  expect(progressRatio(500, 0), 0);
  expect(progressRatio(500, null), 0);
  expect(progressRatio(2500, 2000), 1);
  expect(progressRatio(500, 2000), 0.25);
});
test('nhãn còn/vượt và tâm vòng', () {
  expect(gramRemainingLabel(61.6), 'Còn 61,6 g');
  expect(gramRemainingLabel(-12), 'Vượt 12 g');
  expect(overPct(2240, 1968), 14);
  final b = Budget.fromJson({'target': {'kcal': 1968}, 'consumed': {'kcal': 2118}});
  expect(ringCenter(b), (value: '150', caption: 'kcal vượt mức'));
  expect(formatKcal(1968), '1.968');
  expect(formatGram(130.0), '130');
});
test('stepper dừng ở 0,25 và 10', () {
  expect(stepServings(0.25, -1), 0.25);
  expect(stepServings(10, 1), 10);
  expect(stepServings(1.5, 1), 1.75);
});
test('parseGram giới hạn 1–2000', () {
  for (final s in ['', '0', '2001', 'abc', '-5', '1.5']) {
    expect(parseGram(s), isNull, reason: s);
  }
  expect(parseGram('2000'), 2000);
  expect(parseGram(' 1 '), 1);
});
test('xem trước 1,5 phần và dòng sau khi thêm', () {
  final r = recipe(kcal: 240, proteinG: 39, carbsG: 6, fatG: 7);
  final m = previewRecipe(r, 1.5);
  expect(m.kcal, 360);
  expect(m.proteinG, 58.5);
  final day = Budget.fromJson({'target': {'kcal': 1968}, 'consumed': {'kcal': 1152}});
  expect(afterAddLabel(day: day, meal: MealLog.empty, type: MealType.dinner, add: m),
      'Sau khi thêm: bữa tối còn 230 kcal · cả ngày còn 456 kcal');
});
test('xem trước theo gam', () {
  final f = FoodHit.fromRow({'id': 'x', 'name_vi': 'Cơm', 'calories_per_100g': 130}, FoodKind.ingredient);
  expect(previewPer100(f, 200).kcal, 260);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/budget_view_test.dart test/meal_logs/portion_math_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): budget and portion math`

---

### Task 6: Logic thuần `history_stats` (TDD)

**Files:**
- Create: `app/lib/features/meal_logs/history_stats.dart`
- Test: `app/test/meal_logs/history_stats_test.dart`

**Interfaces:**
- Consumes: `HistoryDay` (Task 2), `shiftDate` (Task 1).
- Produces:
  - `({String from, String to}) rangeEnding(String today, int days)`: `days` kẹp trong 1–31.
  - `bool countsForStats(HistoryDay d, String today)`: `(d.itemCount > 0 || d.kcal > 0) && d.date != today`.
  - `bool inTarget(HistoryDay d)`: `d.targetKcal > 0 && |kcal − target| ≤ 0,1 × target`.
  - `double? averageKcal(List<HistoryDay> days, String today)`: không có ngày nào được tính thì `null`.
  - `({int hits, int counted}) targetHits(List<HistoryDay> days, String today)`.
  - `enum BarKind { normal, over, today }`. `BarKind barKind(HistoryDay d, String today)`: hôm nay → `today`; `target > 0 && kcal > 1,1 × target` → `over`; còn lại → `normal`.
  - `enum DotKind { none, ok, over, today }`. `DotKind dotKind(HistoryDay d, String today)`: hôm nay → `today`; không ghi gì → `none`; `inTarget` → `ok`; vượt 110 % → `over`; còn lại (dưới 90 %) → `none`.
  - `class MacroAverages { final double proteinG, carbsG, fatG; final int proteinPct, carbsPct, fatPct; }`. `MacroAverages? macroAverages(List<HistoryDay> days, String today)`: trung bình các ngày được tính; % năng lượng theo P × 4, C × 4, F × 9, làm tròn; tổng năng lượng = 0 thì cả ba % là 0.
  - `double chartMaxY(List<HistoryDay> days)`: `max(kcal, targetKcal)` của mọi ngày, làm tròn **lên** bội 1000, tối thiểu 1000.
  - `List<int> xLabelIndexes(int n)`: `n ≤ 7` thì mọi chỉ số; ngược lại các `i` có `(n − 1 − i) % 7 == 0` (neo ở hôm nay, cách 7 ngày theo `diary-05`).

- [ ] **Step 1: Viết test fail**

```dart
const today = '2026-11-10';
final week = [
  hday('2026-11-04', 1900), hday('2026-11-05', 2240), hday('2026-11-06', 1780),
  hday('2026-11-07', 0, items: 0), hday('2026-11-08', 1990), hday('2026-11-09', 2050, target: 2200),
  hday(today, 1152),
];
test('trung bình và ngày trong mục tiêu bỏ hôm nay và ngày trống', () {
  expect(averageKcal(week, today), closeTo((1900 + 2240 + 1780 + 1990 + 2050) / 5, 1e-9));
  expect(targetHits(week, today), (hits: 4, counted: 5)); // 2240 > 110 % → không tính
});
test('mục tiêu theo từng ngày', () {
  expect(inTarget(hday('d', 2050, target: 2200)), isTrue);
  expect(barKind(hday('d', 2200, target: 1968), today), BarKind.over);
  expect(barKind(hday('d', 2200, target: 2200), today), BarKind.normal);
});
test('cột và chấm', () {
  expect(barKind(week.last, today), BarKind.today);
  expect(dotKind(week[3], today), DotKind.none);
  expect(dotKind(week[1], today), DotKind.over);
  expect(dotKind(hday('d', 1000), today), DotKind.none); // dưới 90 %
  expect(dotKind(week[0], today), DotKind.ok);
});
test('dữ liệu toàn 0 không lỗi trục', () {
  final zeros = [for (var i = 0; i < 7; i++) hday(shiftDate(today, -i), 0, target: 0, items: 0)];
  expect(chartMaxY(zeros), 1000);
  expect(averageKcal(zeros, today), isNull);
  expect(macroAverages(zeros, today), isNull);
});
test('khoảng ngày và nhãn trục', () {
  expect(rangeEnding(today, 7), (from: '2026-11-04', to: today));
  expect(rangeEnding(today, 99).from, shiftDate(today, -30));
  expect(xLabelIndexes(30), [1, 8, 15, 22, 29]);
  expect(xLabelIndexes(7), [0, 1, 2, 3, 4, 5, 6]);
  expect(chartMaxY(week), 3000);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/history_stats_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): history statistics`

---

### Task 7: `DiaryStore` + `DiaryScope` + nối vào app

**Files:**
- Create: `app/lib/features/meal_logs/diary_store.dart`, `app/lib/features/meal_logs/diary_scope.dart`
- Modify: `app/lib/main.dart`, `app/test/helpers/test_app.dart` (thêm tham số `DiaryStore? store`, bọc `DiaryScope`)
- Test: `app/test/meal_logs/diary_store_test.dart`

**Interfaces:**
- Consumes: Task 1–3, 6.
- Produces:
  - `enum LoadStatus { idle, loading, ready, offline, profileMissing, failed }`.
  - `class DayEntry { final LoadStatus status; final DayLog? log; }`, `class HistoryEntry { final LoadStatus status; final History? history; }`. Làm mới lỗi thì đổi `status` nhưng **giữ** `log`/`history` cũ.
  - `enum DiarySegment { byDay, stats }`. `class DiaryViewRequest { final DiarySegment segment; final String? date; final int? rangeDays; }`.
  - `class DiaryStore extends ChangeNotifier`:
    - `DiaryStore({required MealLogRepository repo, Stream<String?>? userIdChanges, DateTime Function() now = vnNow})`.
    - `String get today`.
    - `DayEntry day(String date)`: chưa có thì `DayEntry(idle)`. `log` trả về đã trừ món chờ xoá (Task 8).
    - `HistoryEntry history(String from, String to)`.
    - `History? historyView(String from, String to)`: các ngày có trong cache `DayLog` (ready) được thay `kcal`/macro/`itemCount` bằng số từ `DayLog`, trong đó bắt buộc có hôm nay. Trừ món chờ xoá (Task 8).
    - `Future<void> ensureDay(String date)`, `refreshDay(date)`, `ensureHistory(from, to)`, `refreshHistory(from, to)`. `ensure…` chỉ tải khi `idle`, `offline` hoặc `failed`. Gọi trùng thì dùng chung Future.
    - `Future<AddResult> add(LogRequest req, {required String clientRequestId})`, `Future<void> update(MealLogItem item, {double? servings, int? amountG})`, `Future<void> delete(MealLogItem item, {required String date})`, `Future<void> undoAdd(AddResult r)`. Thao tác thất bại thì ném `MealLogException` và không đổi cache.
    - `void checkDayChange()`, `void clear()`.
    - `final ValueNotifier<DiaryViewRequest?> viewRequest`; `void requestDiaryView(DiaryViewRequest r)`.
  - Quy tắc (§5.4):
    1. Ngày cập nhật lấy từ `result.item.date` (không phải `req.date`), bữa lấy từ `result.item.mealType ?? req.meal`.
    2. `add`/`update`: `upsert` với `budget` server trả về, `notifyListeners`, rồi `refreshDay(date)` chạy nền (không await).
    3. `delete`: gọi repo; thành công thì `without(id)` rồi `refreshDay(date)` chạy nền.
    4. Sau 2 hoặc 3: mọi khoảng `History` đã cache có chứa `date` thì `refreshHistory` chạy nền.
    5. Bộ đếm `_generation`: `clear()` tăng bộ đếm; mọi kết quả (kể cả chạy nền) của request bắt đầu trước đó bị bỏ.
    6. `PROFILE_NOT_FOUND` → `profileMissing`; `Offline` → `offline`; lỗi khác → `failed`.
  - Đổi ngày: constructor hẹn `Timer` tới 0h giờ VN kế tiếp (tính từ `now()`), tới giờ thì gọi `checkDayChange()` rồi hẹn lại. `checkDayChange` đổi `today` nếu `isoDate(now())` khác, rồi `refreshDay(today mới)` và `refreshHistory(rangeEnding(today mới, 7))`. `dispose` huỷ timer.
  - `userIdChanges`: giá trị `null` hoặc khác user lần trước thì `clear()` (như `RecipeCatalog`).
  - `class DiaryScope extends InheritedNotifier<DiaryStore> { const DiaryScope({required DiaryStore store, required Widget child}); static DiaryStore of(BuildContext); static DiaryStore? maybeOf(BuildContext); }`.
  - `main.dart`: `_ElytraAppState` tạo `DiaryStore(repo: mealLogRepo, userIdChanges: …)` cạnh catalog. `builder:` bọc `DiaryScope` bên ngoài `RecipeScope`. Thêm `AppLifecycleListener(onResume: store.checkDayChange)`. `dispose` cả hai.

- [ ] **Step 1: Viết test fail**

```dart
late FakeMealLogRepository repo; late DiaryStore s; var clock = DateTime.utc(2026, 11, 11, 12);
setUp(() { repo = FakeMealLogRepository(); s = DiaryStore(repo: repo, now: () => clock); });
const add1 = LogRequest.recipe(refId: 'r1', servings: 1, meal: MealType.lunch, date: '2026-11-11');

test('ensureDay song song chỉ một request', () async {
  await Future.wait([s.ensureDay('2026-11-11'), s.ensureDay('2026-11-11')]);
  expect(repo.calls.where((c) => c.$1 == 'getDay'), hasLength(1));
});
test('add cập nhật ngay cho mọi người nghe; cột hôm nay lấy từ DayLog', () async {
  await s.ensureDay(s.today);
  final r = rangeEnding(s.today, 7);
  await s.ensureHistory(r.from, r.to); // history mặc định: hôm nay 0 kcal
  var a = 0, b = 0;
  s..addListener(() => a++)..addListener(() => b++);
  await s.add(add1, clientRequestId: 'k1');
  expect(a, greaterThan(0)); expect(b, a);
  expect(s.day(s.today).log!.budget.consumed.kcal, 100);
  expect(s.historyView(r.from, r.to)!.days.last.kcal, 100);
});
test('add/delete làm mới mọi khoảng history chứa ngày đó', () async {
  for (final n in [7, 30]) { final r = rangeEnding(s.today, n); await s.ensureHistory(r.from, r.to); }
  repo.calls.clear();
  final res = await s.add(add1, clientRequestId: 'k1');
  await pumpEventQueue();
  expect(repo.calls.where((c) => c.$1 == 'getHistory'), hasLength(2));
  repo.calls.clear();
  await s.delete(res.item, date: s.today);
  await pumpEventQueue();
  expect(repo.calls.where((c) => c.$1 == 'getHistory'), hasLength(2));
});
test('store chuyển nguyên khoá cho repo', () async {
  repo.failOnce['add'] = const MealLogOffline();
  await expectLater(s.add(add1, clientRequestId: 'k1'), throwsA(isA<MealLogOffline>()));
  await s.add(add1, clientRequestId: 'k1');
  expect(repo.calls.where((c) => c.$1 == 'add').map((c) => (c.$2 as (LogRequest, String)).$2), ['k1', 'k1']);
});
test('qua 0h đổi hôm nay', () async {
  await s.ensureDay(s.today);
  clock = DateTime.utc(2026, 11, 12, 0, 1);
  s.checkDayChange();
  expect(s.today, '2026-11-12');
  await pumpEventQueue();
  expect(repo.calls.any((c) => c.$1 == 'getDay' && c.$2 == '2026-11-12'), isTrue);
});
test('đổi user: clear và bỏ kết quả về muộn', () async {
  final users = StreamController<String?>();
  final st = DiaryStore(repo: repo, userIdChanges: users.stream, now: () => clock);
  users.add('u1'); await pumpEventQueue();
  repo.gate = Completer();
  final f = st.ensureDay('2026-11-11');
  users.add('u2'); await pumpEventQueue();
  repo.gate!.complete(); await f;
  expect(st.day('2026-11-11').status, LoadStatus.idle);
});
test('PROFILE_NOT_FOUND và mất mạng giữ dữ liệu cũ', () async {
  repo.failOnce['getDay'] = const MealLogProfileMissing();
  await s.ensureDay(s.today);
  expect(s.day(s.today).status, LoadStatus.profileMissing);
  await s.refreshDay(s.today);
  repo.failOnce['getDay'] = const MealLogOffline();
  await s.refreshDay(s.today);
  expect(s.day(s.today).status, LoadStatus.offline);
  expect(s.day(s.today).log, isNotNull);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/diary_store_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces, nối vào `main.dart` và `test_app.dart`.
- [ ] **Step 4: Chạy `flutter test`** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): shared diary store`

---

### Task 8: Xoá có Hoàn tác trong `DiaryStore`

**Files:**
- Modify: `app/lib/features/meal_logs/diary_store.dart`
- Test: `app/test/meal_logs/diary_store_pending_test.dart`

**Interfaces:**
- Consumes: Task 7.
- Produces:
  - `class PendingDelete { final MealLogItem item; final String date; void undo(); Future<void> commit(); }`. `commit` thất bại thì món hiện lại (`notifyListeners`) rồi ném lỗi. Gọi `undo`/`commit` lần thứ hai thì không làm gì.
  - `PendingDelete deleteDeferred(MealLogItem item, {required String date})`: món bị ẩn ngay. Nếu có món treo khác thì gọi `commit()` món đó trước (không await; lỗi thì món đó hiện lại).
  - `Future<void> flushPendingDeletes()`: commit mọi món treo, chờ xong, nuốt lỗi.
  - `day(date).log` và `historyView` trừ các món treo: `DayLog.without`, và trừ `macros`/`itemCount` ở `HistoryDay` cùng ngày, **kể cả** ngày lấy từ `/history` (chưa có trong cache `DayLog`).
  - `clear()` bỏ mọi món treo, không gửi `DELETE`.

- [ ] **Step 1: Viết test fail**

```dart
test('treo: ẩn ở mọi view; undo trả lại, không request', () async {
  final it = item(id: 'a', kcal: 300, date: s.today);
  repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, it)]);
  final r = rangeEnding(s.today, 7);
  await s.ensureDay(s.today); await s.ensureHistory(r.from, r.to);
  final p = s.deleteDeferred(it, date: s.today);
  expect(s.day(s.today).log!.find('a'), isNull);
  expect(s.historyView(r.from, r.to)!.days.last.kcal, 0);
  p.undo();
  expect(s.day(s.today).log!.find('a'), isNotNull);
  expect(repo.calls.where((c) => c.$1 == 'delete'), isEmpty);
});
test('ngày cũ chỉ có trong /history cũng bị trừ', () async {
  repo.onHistory = (f, t) => History(from: f, to: t, targetKcal: 1968, days: [hday(f, 500, items: 2)]);
  await s.ensureHistory('2026-11-05', '2026-11-05');
  s.deleteDeferred(item(id: 'b', kcal: 200), date: '2026-11-05');
  final d = s.historyView('2026-11-05', '2026-11-05')!.days.single;
  expect(d.kcal, 300); expect(d.itemCount, 1);
});
test('commit gửi DELETE; lỗi thì món hiện lại', () async {
  final it = item(id: 'a'); repo.days[s.today] = dayLog(date: s.today, items: [(MealType.lunch, it)]);
  await s.ensureDay(s.today);
  repo.failOnce['delete'] = const MealLogOffline();
  await expectLater(s.deleteDeferred(it, date: s.today).commit(), throwsA(isA<MealLogOffline>()));
  expect(s.day(s.today).log!.find('a'), isNotNull);
});
test('vuốt món thứ hai thì món đầu được commit', () async {
  s.deleteDeferred(item(id: 'a'), date: s.today);
  s.deleteDeferred(item(id: 'b'), date: s.today);
  await pumpEventQueue();
  expect(repo.calls.where((c) => c.$1 == 'delete').map((c) => c.$2), ['a']);
});
test('flush gửi hết; clear chỉ bỏ', () async {
  s.deleteDeferred(item(id: 'a'), date: s.today);
  await s.flushPendingDeletes();
  expect(repo.calls.where((c) => c.$1 == 'delete'), hasLength(1));
  s.deleteDeferred(item(id: 'b'), date: s.today);
  s.clear();
  await pumpEventQueue();
  expect(repo.calls.where((c) => c.$1 == 'delete'), hasLength(1));
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/diary_store_pending_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy `flutter test`** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): deferred delete with undo`

---

### Task 9: `RequestKeys` + `LogMealController`

**Files:**
- Create: `app/lib/features/meal_logs/request_keys.dart`, `app/lib/features/meal_logs/log_meal_controller.dart`
- Test: `app/test/meal_logs/request_keys_test.dart`, `app/test/meal_logs/log_meal_controller_test.dart`

**Interfaces:**
- Consumes: `DiaryStore` (Task 7), `FoodSearchRepository` (Task 4), `RecipeCatalog`/`RecipeQuery` (Sprint 4), `LogRequest`, `uuidV4`.
- Produces:
  - `class RequestKeys { RequestKeys({String Function() newId = uuidV4}); String keyFor(LogRequest req); void succeeded(); void markNetworkError(); bool get hadNetworkError; }`. Cùng `req` (`==`) với lần trước thì trả khoá cũ, khác thì sinh khoá mới. `succeeded` xoá cặp đã lưu và cờ lỗi.
  - `enum FoodTab { recipes, dishes, ingredients }`. `enum SearchStatus { loading, ready, offline, failed }`.
  - `class FoodTabState { final SearchStatus status; final List<Recipe> recipes; final List<FoodHit> hits; final bool hasMore; final String? sectionLabel; }`.
  - `sealed class LogOutcome`: `LogAdded(AddResult result)`, `LogOfflineOutcome`, `LogProfileMissingOutcome`, `LogFailedOutcome`, `LogIgnored`.
  - `class LogMealController extends ChangeNotifier`:
    - Constructor: `LogMealController({required DiaryStore store, required RecipeCatalog catalog, required FoodSearchRepository search, required MealType meal, required String date, Duration debounce = const Duration(milliseconds: 300), RequestKeys? keys})`.
    - Trạng thái: `MealType meal` (setter, `notify`); `String get date`; `FoodTab tab`; `void setTab(FoodTab t)`; `String get query`; `void setQuery(String q)` (debounce); `FoodTabState stateOf(FoodTab t)`.
    - Tải: `Future<void> loadMore()`; `Future<void> retry()`.
    - Gửi: `bool get sending`; `Future<LogOutcome> submit(LogRequest req)`; `Future<void> onSheetClosed()`.
  - Hành vi:
    - Món nấu:
      - Từ khoá rỗng: `catalog.recipes` theo thứ tự, nhãn `'Gợi ý'`.
      - Có từ khoá: `RecipeQuery.apply(catalog.recipes, query: q)`, nhãn `null`.
      - `hasMore = false`. Trạng thái của catalog quyết định `status`.
    - Món ăn sẵn:
      - Từ khoá rỗng: nhãn `'Món ăn sẵn (A–Z)'`. Có từ khoá: nhãn `null`.
      - Trang 20; `hasMore` khi trang trả về đủ 20.
    - Nguyên liệu:
      - Từ khoá rỗng: `featured: true`, nhãn `'Gợi ý'`. Trang đầu rỗng thì gọi lại với `featured: null`, nhãn `'Nguyên liệu (A–Z)'`, và các trang sau cũng dùng `featured: null`.
      - Có từ khoá: `featured: null`.
    - Chỉ tab đang mở mới gọi tìm kiếm. Đổi từ khoá thì xoá kết quả các tab khác, tải lại khi mở tab đó.
    - Mỗi request mang số thứ tự; kết quả về sau khi đã có request mới hơn (đổi từ khoá hoặc đổi tab) thì bỏ.
    - `submit`:
      - Đang `sending` thì trả `LogIgnored`, không gọi store.
      - Gọi `store.add(req, clientRequestId: keys.keyFor(req))`.
      - Thành công: `succeeded()`, trả `LogAdded`.
      - `Offline`: `markNetworkError()`, trả `LogOfflineOutcome`.
      - `ProfileMissing` → `LogProfileMissingOutcome`. Lỗi khác, kể cả `IDEMPOTENCY_CONFLICT` → `LogFailedOutcome`.
    - `onSheetClosed`: nếu `hadNetworkError` thì `store.refreshDay(date)` và reset cờ.

- [ ] **Step 1: Viết test fail**

```dart
// request_keys_test.dart
test('giữ khoá khi y nguyên, đổi khi khác, bỏ khi thành công', () {
  var n = 0; final k = RequestKeys(newId: () => 'k${n++}');
  const a = LogRequest.recipe(refId: 'r', servings: 1, meal: MealType.lunch, date: '2026-11-11');
  expect(k.keyFor(a), 'k0'); expect(k.keyFor(a), 'k0');
  expect(k.keyFor(const LogRequest.recipe(refId: 'r', servings: 1.5, meal: MealType.lunch, date: '2026-11-11')), 'k1');
  expect(k.keyFor(const LogRequest.recipe(refId: 'r', servings: 1.5, meal: MealType.dinner, date: '2026-11-11')), 'k2');
  k.succeeded();
  expect(k.keyFor(a), 'k3');
});

// log_meal_controller_test.dart (dùng fakeAsync cho debounce)
test('bấm Thêm 2 lần khi chưa xong chỉ 1 request', () async {
  repo.gate = Completer();
  final f1 = c.submit(req); final f2 = await c.submit(req);
  expect(f2, isA<LogIgnored>());
  repo.gate!.complete(); expect(await f1, isA<LogAdded>());
  expect(repo.calls.where((x) => x.$1 == 'add'), hasLength(1));
});
test('lỗi mạng: retry y nguyên giữ khoá, đổi lượng thì khoá mới; đóng sheet thì refreshDay', () async {
  repo.failOnce['add'] = const MealLogOffline();
  expect(await c.submit(req), isA<LogOfflineOutcome>());
  repo.failOnce['add'] = const MealLogOffline();
  await c.submit(req);
  await c.submit(reqOtherAmount);
  final keys = repo.calls.where((x) => x.$1 == 'add').map((x) => (x.$2 as (LogRequest, String)).$2).toList();
  expect(keys[0], keys[1]); expect(keys[2], isNot(keys[1]));
  repo.calls.clear(); repo.failOnce['add'] = const MealLogOffline(); await c.submit(req);
  await c.onSheetClosed();
  expect(repo.calls.any((x) => x.$1 == 'getDay' && x.$2 == c.date), isTrue);
});
test('IDEMPOTENCY_CONFLICT → LogFailedOutcome', () async {
  repo.failOnce['add'] = const MealLogFailed('IDEMPOTENCY_CONFLICT');
  expect(await c.submit(req), isA<LogFailedOutcome>());
});
test('Nguyên liệu: gợi ý rỗng thì chuyển A–Z', () => fakeAsync((fa) {
  search.ingredients = [hit('Cà rốt'), hit('Bắp cải')]; search.featuredIds = {};
  c.setTab(FoodTab.ingredients); fa.flushMicrotasks();
  final st = c.stateOf(FoodTab.ingredients);
  expect(st.sectionLabel, 'Nguyên liệu (A–Z)');
  expect(st.hits.map((h) => h.name), ['Bắp cải', 'Cà rốt']);
  expect(search.calls.map((x) => x.$3), [true, null]);
}));
test('Món ăn sẵn: nhãn A–Z, phân trang 20, gõ không dấu', () => fakeAsync((fa) {
  search.dishes = [for (var i = 0; i < 25; i++) hit('Món ${i.toString().padLeft(2, '0')}')]..add(hit('Phở bò'));
  c.setTab(FoodTab.dishes); fa.flushMicrotasks();
  expect(c.stateOf(FoodTab.dishes).sectionLabel, 'Món ăn sẵn (A–Z)');
  expect(c.stateOf(FoodTab.dishes).hits, hasLength(20));
  expect(c.stateOf(FoodTab.dishes).hasMore, isTrue);
  c.setQuery('pho'); fa.elapse(const Duration(milliseconds: 300)); fa.flushMicrotasks();
  expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
}));
test('kết quả cũ về muộn bị bỏ', () => fakeAsync((fa) {
  c.setTab(FoodTab.dishes); search.gate = Completer();
  c.setQuery('bun'); fa.elapse(const Duration(milliseconds: 300));
  search.gate = null; c.setQuery('pho'); fa.elapse(const Duration(milliseconds: 300)); fa.flushMicrotasks();
  // request 'bun' xong sau cùng
  // (giải phóng gate cũ) → danh sách vẫn là của 'pho'
}));
test('Món nấu: từ khoá rỗng là Gợi ý theo thứ tự catalog', () async {
  expect(c.stateOf(FoodTab.recipes).sectionLabel, 'Gợi ý');
});
```

Test "kết quả cũ về muộn" cần giữ tham chiếu tới `Completer` của request 'bun' rồi `complete()` nó sau cùng. Implementer viết phần này cho đúng ý ở comment.

- [ ] **Step 2: Chạy `flutter test test/meal_logs/request_keys_test.dart test/meal_logs/log_meal_controller_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(meal-logs): log meal controller with request keys`

---

### Task 10: `DiaryController`

**Files:**
- Create: `app/lib/features/diary/diary_controller.dart`
- Test: `app/test/diary/diary_controller_test.dart`

**Interfaces:**
- Consumes: `DiaryStore`, `DiarySegment`, `DiaryViewRequest` (Task 7), `shiftDate`, `withinEditWindow` (Task 1), `rangeEnding` (Task 6).
- Produces: `class DiaryController extends ChangeNotifier`:
  - Constructor: `DiaryController({required DiaryStore store})`. Khởi tạo `selectedDate = stripEnd = store.today`, `segment = byDay`, `rangeDays = 7`, rồi gọi `_load()`.
  - Getter: `DiarySegment segment`, `String selectedDate`, `String stripEnd`, `int rangeDays`.
  - `List<String> get stripDates`: 7 ngày tăng dần, kết thúc ở `stripEnd`.
  - `void selectDate(String d)`:
    - `d` sau `store.today` thì bỏ qua.
    - `d` nằm ngoài `stripDates` thì `stripEnd = min(shiftDate(d, 3), store.today)`.
    - Đặt `selectedDate = d`.
  - `void shiftStrip(int direction)`: `stripEnd ± 7`, không vượt `store.today`. Nếu `selectedDate` rơi ra ngoài dải mới thì đổi thành `stripEnd`.
  - `void setSegment(DiarySegment s)`; `void setRange(int days)` (chỉ nhận 7 hoặc 30).
  - `void apply(DiaryViewRequest r)`: đặt segment, ngày (qua `selectDate`), khoảng ngày.
  - `bool canEdit(String date) => withinEditWindow(date, store.today)`.
  - `({String from, String to}) get statsRange => rangeEnding(store.today, rangeDays)`.
  - `_load()` gọi sau mọi thay đổi: `ensureDay(selectedDate)`, `ensureHistory(stripDates.first, stripEnd)`, và `ensureHistory(statsRange)` khi segment là `stats`.
  - Nghe store: khi `store.today` đổi mà `selectedDate`/`stripEnd` đang là hôm nay cũ thì chuyển theo ngày mới.

- [ ] **Step 1: Viết test fail**

```dart
test('dải mặc định 7 ngày kết thúc hôm nay', () {
  expect(c.stripDates, ['2026-11-05', '2026-11-06', '2026-11-07', '2026-11-08', '2026-11-09', '2026-11-10', '2026-11-11']);
});
test('chọn ngày ngoài dải: stripEnd = ngày + 3, không quá hôm nay', () {
  c.selectDate('2026-10-20');
  expect(c.stripEnd, '2026-10-23'); expect(c.selectedDate, '2026-10-20');
  c.selectDate('2026-11-10'); // ngoài dải
  expect(c.stripEnd, '2026-11-11');
});
test('không chọn được ngày tương lai, không lùi dải quá hôm nay', () {
  c.selectDate('2026-11-12'); expect(c.selectedDate, '2026-11-11');
  c.shiftStrip(1); expect(c.stripEnd, '2026-11-11');
  c.shiftStrip(-1); expect(c.stripEnd, '2026-11-04'); expect(c.selectedDate, '2026-11-04');
});
test('dải mặc định dùng chung khoá history với Dashboard', () async {
  await pumpEventQueue();
  final r = rangeEnding(store.today, 7);
  expect(repo.calls.where((x) => x.$1 == 'getHistory').map((x) => x.$2), [(r.from, r.to)]);
});
test('canEdit theo withinEditWindow', () {
  expect(c.canEdit('2026-10-12'), isTrue); expect(c.canEdit('2026-10-11'), isFalse);
});
```

- [ ] **Step 2: Chạy `flutter test test/diary/diary_controller_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy lại** – PASS.
- [ ] **Step 5: Commit** – `feat(diary): diary view controller`

---

### Task 11: Chi tiết món ghi qua `DiaryStore`

**Files:**
- Modify: `app/lib/features/recipes/recipe_detail_controller.dart`, `app/lib/features/recipes/recipe_detail_screen.dart` (lấy store từ `DiaryScope.of(context)`)
- Test: `app/test/recipes/recipe_detail_controller_test.dart`, `app/test/recipes/recipe_detail_screen_test.dart` (bọc `DiaryScope`)

**Interfaces:**
- Consumes: `DiaryStore` (Task 7), `RequestKeys` (Task 9).
- Produces:
  - Constructor `RecipeDetailController` đổi `required MealLogRepository mealLogs` thành `required DiaryStore store`. `newRequestId` được truyền vào `RequestKeys(newId: …)`.
  - `addOneServing()` gửi `LogRequest.recipe(refId: id, servings: 1, meal: mealType, date: logDate)` qua `store.add`. Giữ nguyên chống bấm hai lần và kiểu `AddMealResult`. Lỗi mạng thì gọi `markNetworkError()`. `dispose` gọi `store.refreshDay(logDate)` nếu `hadNetworkError`.

- [ ] **Step 1: Viết test fail** (thêm vào test controller)

```dart
test('thêm từ Chi tiết món: store thấy số mới', () async {
  final c = build(); await c.load();
  expect(await c.addOneServing(), isA<AddMealSuccess>());
  expect(store.day(c.logDate).log!.budget.consumed.kcal, 100);
});
test('retry sau lỗi mạng giữ khoá', () async {
  repo.failOnce['add'] = const MealLogOffline();
  final c = build(); await c.load();
  await c.addOneServing(); await c.addOneServing();
  final keys = repo.calls.where((x) => x.$1 == 'add').map((x) => (x.$2 as (LogRequest, String)).$2);
  expect(keys.toSet(), hasLength(1));
});
// Giữ test cũ "bấm Thêm hai lần chỉ một request" (đổi sang đọc calls mới).
```

- [ ] **Step 2: Chạy `flutter test test/recipes/`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(recipes): log from recipe detail through diary store`

**→ DỪNG.** Báo tóm tắt Task 1–11 và số test, rồi chờ nhóm trước khi làm UI.

---

### Task 12: Router, tab Cá nhân, xoá cache sau khi lưu hồ sơ (native)

**Files:**
- Modify: `app/lib/core/router.dart`, `app/lib/features/nutrition/result_screen.dart`, `app/lib/features/auth/profile_gate.dart`, `app/test/core/router_test.dart`
- Create: `app/lib/features/profile/profile_screen.dart`. Tạo khung tối thiểu (một `Scaffold`, hoàn thiện ở task sau) cho `DashboardScreen` (`features/home/dashboard_screen.dart`), `DiaryScreen` (`features/diary/diary_screen.dart`) và `LogMealScreen` (`features/meal_logs/log_meal_screen.dart`).
- Delete: `app/lib/features/home/home_placeholder.dart`
- Test: `app/test/core/router_test.dart`, `app/test/profile/profile_screen_test.dart`

**Interfaces:**
- Consumes: `DiaryScope` (Task 7), `withinEditWindow`, `parseIsoDate` (Task 1).
- Produces:
  - Route:
    - `/home` → `homeBuilder ?? DashboardScreen()`.
    - `/diary` → `DiaryScreen()`.
    - `/profile` → `ProfileScreen()`.
    - `GoRoute(path: '/log', parentNavigatorKey: rootKey)` → `LogMealScreen(meal: …, date: …)`.
  - `({MealType meal, String date}) parseLogParams(Map<String, String> q, DateTime now)`, viết trong `router.dart`. `meal` không phải tên `MealType` thì dùng `mealTypeAt(now)`. `date` không qua `withinEditWindow(date, isoDate(now))` thì dùng `isoDate(now)`.
  - `class LogMealResult { final AddResult result; final String name; }`, đặt trong `log_meal_screen.dart`.
  - `ProfileScreen({super.key, Future<void> Function()? signOut})`, mặc định `authRepo.signOut`.
    - Hiện `displayName(catalog.profile?.fullName)`, không có thì hiện email (nhỏ).
    - Nút "Đăng xuất": khoá nút, `await DiaryScope.of(context).flushPendingDeletes()`, rồi `await signOut()`.
  - `ResultScreen` (nhánh đã đăng nhập): sau khi `save` thành công thì gọi `RecipeScope.maybeOf(context)?.clear()` và `DiaryScope.maybeOf(context)?.clear()`, rồi mới `go('/home')`. `ProfileGate` thêm `DiaryScope…clear()` cạnh lệnh `clear()` của catalog.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('/log che thanh tab', (t) async {
  final r = await pumpTestApp(t, auth: FakeAuth(isLoggedIn: true), catalog: catalog, store: store, initialLocation: '/home');
  r.push('/log?meal=dinner&date=2026-11-11'); await t.pumpAndSettle();
  expect(find.byType(NavigationBar), findsNothing);
});
test('tham số /log sai thì dùng mặc định', () {
  final now = DateTime.utc(2026, 11, 11, 19);
  expect(parseLogParams({'meal': 'brunch', 'date': '2026-12-01'}, now), (meal: MealType.dinner, date: '2026-11-11'));
  expect(parseLogParams({'meal': 'lunch', 'date': '2026-10-12'}, now), (meal: MealType.lunch, date: '2026-10-12'));
  expect(parseLogParams({'date': '2026-10-11'}, now).date, '2026-11-11');
});
testWidgets('Đăng xuất gửi DELETE treo trước signOut', (t) async {
  final order = <String>[];
  store.deleteDeferred(item(id: 'a'), date: store.today);
  repo.onDelete = (_) => order.add('delete');
  await t.pumpWidget(wrap(ProfileScreen(signOut: () async => order.add('signOut'))));
  await t.tap(find.text('Đăng xuất')); await t.pumpAndSettle();
  expect(order, ['delete', 'signOut']);
});
// Sửa test cũ trong router_test: '/diary' và '/profile' không còn là "Sắp có".
```

(`repo.onDelete` là một hook `void Function(String id)?` thêm vào bản giả ở task này.)

- [ ] **Step 2: Chạy `flutter test test/core/router_test.dart test/profile/`** – FAIL.
- [ ] **Step 3: Cài đặt** theo Interfaces.
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(core): dashboard, diary, profile and log routes`

**→ DỪNG** để nhóm chạy app: các tab mở được, Đăng xuất hoạt động.

---

### Task 13: Dashboard (native)

**Files:**
- Modify: `app/lib/features/home/dashboard_screen.dart`
- Create: `app/lib/features/home/widgets/calorie_ring.dart`, `macro_bar.dart`, `meal_card.dart`, `week_card.dart`
- Test: `app/test/home/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `DiaryStore` (Task 7–8), `budget_view` (Task 5), `history_stats` (Task 6), `greeting`/`displayName`/`shortName`/`avatarInitial` (Task 1), `RecipeScope` (`profile.fullName`), `LogMealResult` (Task 12).
- Produces: `DashboardScreen` theo §7.1 và các ảnh `dashboard-01…07`.
  - `initState`: `store.ensureDay(today)`, `store.ensureHistory(rangeEnding(today, 7))`, `catalog.ensureLoaded()` (không await, không chặn màn).
  - Widget: `CalorieRing({required double ratio, required bool over, required String value, required String caption})` vẽ bằng `CustomPainter`, Ø 144, nét 14. `MacroBar({required String label, required Color color, required Color track, required double consumed, required double target})`. `MealCard({required MealType type, required MealLog log, required int? budgetKcal, required bool current, required VoidCallback onAdd})`. `WeekCard({required History view, required String today, required VoidCallback onTap})`.
  - Snackbar sau khi thêm: nút + gọi `final r = await context.push<LogMealResult>('/log?meal=…&date=$today')`. Có `r` thì hiện snackbar "Đã thêm ${r.name} vào bữa ${meal.labelVi}" kèm "Hoàn tác" (`store.undoAdd(r.result)`), 4 giây.
  - "Xem nhật ký": `store.requestDiaryView(DiaryViewRequest(segment: byDay, date: today))` rồi `StatefulNavigationShell.of(context).goBranch(1)`. Thẻ "7 ngày qua": như trên, `segment: stats, rangeDays: 7`.

- [ ] **Step 1: Viết test fail** (`MaterialApp` thuần, `DiaryScope` + `RecipeScope` với bản giả)

```dart
testWidgets('vượt mục tiêu: nhãn Vượt % và tâm vòng', (t) async {
  repo.days[today] = dayLog(date: today, target: 1968, items: [(MealType.lunch, item(kcal: 2118))]);
  await pumpDashboard(t);
  expect(find.text('150'), findsOneWidget);
  expect(find.text('kcal vượt mức'), findsOneWidget);
  expect(find.text('Vượt 8 %'), findsOneWidget);
});
testWidgets('chưa ghi gì: 4 bữa Chưa ghi món nào', (t) async {
  await pumpDashboard(t);
  expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
});
testWidgets('PROFILE_NOT_FOUND: nút Khai báo thể trạng, ẩn 7 ngày qua', (t) async {
  repo.failWith = const MealLogProfileMissing();
  await pumpDashboard(t);
  expect(find.text('Khai báo thể trạng'), findsOneWidget);
  expect(find.text('7 ngày qua'), findsNothing);
});
testWidgets('mất mạng lần đầu: khối Thử lại', (t) async {
  repo.failWith = const MealLogOffline();
  await pumpDashboard(t);
  expect(find.text('Thử lại'), findsOneWidget);
});
testWidgets('lời chào không bao giờ lộ email', (t) async {
  recipeRepo.profile = const UserNutritionProfile(targetKcal: 1968, fullName: 'sv@gm.uit.edu.vn');
  await pumpDashboard(t);
  expect(find.textContaining('@'), findsNothing);
  expect(find.byIcon(Icons.person_outline), findsOneWidget);
});
```

- [ ] **Step 2: Chạy `flutter test test/home/`** – FAIL.
- [ ] **Step 3: Cài đặt** theo §7.1, so từng ảnh `dashboard-*.png`.
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(dashboard): today summary, meal cards and week card`

**→ DỪNG** để nhóm chạy app và so với `dashboard-*.png`.

---

### Task 14: Màn Ghi bữa ăn (native)

**Files:**
- Modify: `app/lib/features/meal_logs/log_meal_screen.dart`
- Create: `app/lib/features/meal_logs/widgets/food_row.dart`, `app/lib/features/meal_logs/widgets/portion_sheet.dart`
- Test: `app/test/meal_logs/log_meal_screen_test.dart`

**Interfaces:**
- Consumes: `LogMealController` (Task 9), `portion_math` (Task 5), `LogMealResult` (Task 12), `foodSearchRepo`.
- Produces:
  - `LogMealScreen({required MealType meal, required String date, FoodSearchRepository? search})` theo §7.2 và `log-01…06`. `search` mặc định `foodSearchRepo`.
  - `FoodResultTile({required String name, required String macroLine, required String kcalValue, required String kcalUnit, required VoidCallback onTap})`.
  - `PortionSheet`: mở bằng `showModalBottomSheet`; `isDismissible` và `enableDrag` bằng `!controller.sending`.
    - Kết quả `LogAdded` thì `Navigator.pop(sheet)` rồi `context.pop(LogMealResult(...))`.
    - `LogProfileMissingOutcome` thì đóng cả sheet lẫn màn.
    - Sheet đóng (bằng bất kỳ cách nào) thì gọi `controller.onSheetClosed()`.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('bấm Thêm 2 lần chỉ 1 request, nút hiện Đang thêm…', (t) async {
  repo.gate = Completer();
  await openSheetFor(t, 'Cá basa kho tộ');
  await t.tap(find.text('Thêm vào bữa tối')); await t.pump();
  expect(find.text('Đang thêm…'), findsOneWidget);
  await t.tap(find.text('Đang thêm…')); await t.pump();
  expect(repo.calls.where((c) => c.$1 == 'add'), hasLength(1));
  repo.gate!.complete(); await t.pumpAndSettle();
});
testWidgets('ô gam: 0 và 2001 khoá nút, có dòng giới hạn', (t) async {
  await openSheetFor(t, 'Phở bò', tab: 'Món ăn sẵn');
  for (final v in ['0', '2001']) {
    await t.enterText(find.byType(TextField).last, v); await t.pump();
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  }
});
testWidgets('xem trước 1,5 phần', (t) async {
  await openSheetFor(t, 'Cá basa kho tộ');
  await t.tap(find.text('1½')); await t.pump();
  expect(find.text('360'), findsOneWidget);
  expect(find.text('58,5'), findsOneWidget);
});
testWidgets('không có kết quả', (t) async {
  await pumpLog(t); await t.enterText(find.byType(TextField).first, 'zzz');
  await t.pump(const Duration(milliseconds: 300)); await t.pumpAndSettle();
  expect(find.textContaining('Không tìm thấy'), findsOneWidget);
});
```

- [ ] **Step 2: Chạy `flutter test test/meal_logs/log_meal_screen_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo §7.2, so từng ảnh `log-*.png`. Dùng chữ "Gợi ý" thay "Món phổ biến".
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(meal-logs): log meal screen with portion sheet`

**→ DỪNG** để nhóm chạy app: ghi đủ 3 nguồn, Hoàn tác trên Dashboard, so với `log-*.png`.

---

### Task 15: Nhật ký "Theo ngày" (native)

**Files:**
- Modify: `app/lib/features/diary/diary_screen.dart`
- Create: `app/lib/features/diary/widgets/day_strip.dart`, `day_meals.dart`, `edit_item_sheet.dart`
- Test: `app/test/diary/diary_by_day_test.dart`

**Interfaces:**
- Consumes: `DiaryController` (Task 10), `DiaryStore` (Task 7–8), `dotKind` (Task 6), `portion_math` (Task 5).
- Produces: `DiaryScreen` theo §7.3 "Theo ngày" và `diary-01…03`.
  - `DiaryScreen` giữ `DiaryController` trong `State` và nghe `store.viewRequest`: có giá trị thì `controller.apply(r)` rồi đặt lại `null`.
  - `DayChip({required String date, required bool selected, required bool isToday, required DotKind dot, required VoidCallback onTap})`.
  - `DiaryItemTile`: bọc `Dismissible(direction: endToStart)` khi `controller.canEdit(date)`.
  - `EditItemSheet`: "Lưu" gọi `store.update`, "Xoá" gọi `store.delete`. `MealLogTooOld` thì hiện "Chỉ sửa được món trong 30 ngày gần nhất".
  - Vuốt xoá: `final p = store.deleteDeferred(item, date: …)`, rồi hiện snackbar "Đã xoá ${item.name}" kèm "Hoàn tác" (4 giây). Bấm Hoàn tác thì `p.undo()`; các lý do đóng snackbar còn lại thì `p.commit()`, lỗi thì hiện snackbar "Không xoá được. Thử lại". `dispose` của màn gọi `commit()` món đang treo.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('xoá món cuối của bữa → bữa trống', (t) async {
  repo.days[today] = dayLog(date: today, items: [(MealType.lunch, item(id: 'a', name: 'Cơm trắng'))]);
  await pumpDiary(t);
  await t.drag(find.text('Cơm trắng'), const Offset(-500, 0)); await t.pumpAndSettle();
  expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
});
testWidgets('vuốt xoá rồi Hoàn tác: không gửi DELETE', (t) async {
  repo.days[today] = dayLog(date: today, items: [(MealType.lunch, item(id: 'a', name: 'Cơm trắng'))]);
  await pumpDiary(t);
  await t.drag(find.text('Cơm trắng'), const Offset(-500, 0)); await t.pumpAndSettle();
  await t.tap(find.text('Hoàn tác')); await t.pumpAndSettle();
  expect(find.text('Cơm trắng'), findsOneWidget);
  expect(repo.calls.where((c) => c.$1 == 'delete'), isEmpty);
});
testWidgets('món ngày thứ 31 bị khoá', (t) async {
  final old = shiftDate(today, -31);
  repo.days[old] = dayLog(date: old, items: [(MealType.lunch, item(id: 'a', name: 'Cơm trắng'))]);
  await pumpDiary(t, request: DiaryViewRequest(segment: DiarySegment.byDay, date: old));
  await t.tap(find.text('Cơm trắng')); await t.pumpAndSettle();
  expect(find.text('Lưu'), findsNothing);
  expect(find.text('Chỉ sửa được món trong 30 ngày gần nhất'), findsOneWidget);
  expect(find.byIcon(Icons.add), findsNothing);
});
testWidgets('sửa lượng gửi PATCH', (t) async { /* mở sheet, tăng stepper, Lưu → calls có 'update' với servings 1.25 */ });
```

- [ ] **Step 2: Chạy `flutter test test/diary/diary_by_day_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo §7.3, so ảnh `diary-01…03`.
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(diary): by-day view with edit and undoable delete`

**→ DỪNG** để nhóm chạy app và so với `diary-01…03`.

---

### Task 16: Nhật ký "Thống kê" (native)

**Files:**
- Create: `app/lib/features/diary/widgets/history_chart.dart`, `app/lib/features/diary/widgets/stats_view.dart`
- Modify: `app/lib/features/diary/diary_screen.dart`, `app/lib/features/home/widgets/week_card.dart` (dùng chung phần vẽ cột nếu hợp lý)
- Test: `app/test/diary/diary_stats_test.dart`

**Interfaces:**
- Consumes: `store.historyView` (Task 7–8), `history_stats` (Task 6), `DiaryController.statsRange`/`setRange`/`selectDate` (Task 10).
- Produces:
  - `HistoryChart({required List<HistoryDay> days, required String today, required ValueChanged<String> onOpenDay})`: `fl_chart` `BarChart`. Đường mục tiêu nét đứt nối các `targetKcal` (mỗi cột một đoạn ngang) qua `extraLinesData` hoặc `CustomPainter`. `maxY = chartMaxY(days)`. Nhãn X theo `xLabelIndexes`.
    - Chạm lần đầu hiện tooltip; chạm lại đúng cột đó thì `onOpenDay(date)` → `controller.setSegment(byDay)` + `selectDate(date)`.
  - Chú giải: "Không vượt (≤ 110 %)", "Vượt > 110 %", "Hôm nay (đang ghi)", "Mục tiêu ngày".
  - `StatsView`: chip 7/30 ngày, hai thẻ số, biểu đồ, thẻ macro trung bình (giá trị so sánh lấy từ `budget.target` hôm nay). Trống hoặc chưa có hồ sơ thì hiện khối như §7.3.

- [ ] **Step 1: Viết test fail**

```dart
testWidgets('dữ liệu toàn 0 không lỗi trục', (t) async {
  repo.onHistory = (f, to) => History(from: f, to: to, targetKcal: 0, days: [for (var i = 6; i >= 0; i--) hday(shiftDate(to, -i), 0, target: 0, items: 0)]);
  await pumpStats(t);
  expect(t.takeException(), isNull);
  expect(find.text('Ghi bữa đầu tiên'), findsOneWidget);
});
testWidgets('thống kê khớp Theo ngày khi món đang chờ xoá', (t) async {
  // hôm nay có 1 món 300 kcal; deleteDeferred rồi mở Thống kê: cột hôm nay = 0 (đọc qua historyView)
});
testWidgets('chú giải dùng chữ Không vượt', (t) async {
  await pumpStats(t);
  expect(find.text('Không vượt (≤ 110 %)'), findsOneWidget);
  expect(find.text('Trong mục tiêu'), findsOneWidget); // thẻ số, đếm theo ±10 %
});
testWidgets('30 ngày gọi history 30 ngày', (t) async {
  await pumpStats(t); await t.tap(find.text('30 ngày')); await t.pumpAndSettle();
  expect(repo.calls.any((c) => c.$1 == 'getHistory' && c.$2 == (shiftDate(today, -29), today)), isTrue);
});
```

- [ ] **Step 2: Chạy `flutter test test/diary/diary_stats_test.dart`** – FAIL.
- [ ] **Step 3: Cài đặt** theo §7.3, so ảnh `diary-04…06`.
- [ ] **Step 4: Chạy `flutter test`** – PASS. `flutter analyze` sạch.
- [ ] **Step 5: Commit** – `feat(diary): stats view with daily calorie chart`

**→ DỪNG** để nhóm chạy app và so với `diary-04…06`.

---

### Task 17: Kiểm tra cuối nhánh

**Files:**
- Modify: `CLAUDE.md`: thêm vào dòng Sprint 5 đường dẫn spec `docs/superpowers/specs/2026-11-11-dashboard-diary-design.md`; thêm `DiaryStore`/`DiaryScope` vào mục "Kiến trúc app" (một dòng).

- [ ] **Step 1:** `flutter analyze` sạch; `flutter test` toàn bộ PASS. Ghi lại số test.
- [ ] **Step 2:** `grep -rn "supabase\." app/lib/features/home app/lib/features/diary app/lib/features/profile app/lib/features/meal_logs/*_screen.dart app/lib/features/meal_logs/widgets` không có kết quả. `grep -rn "Color(0x" app/lib/features` không có kết quả. `grep -rn "toLocal()" app/lib` không có kết quả.
- [ ] **Step 3:** Chạy app trên máy ảo với tài khoản thật (`flutter run --dart-define-from-file=env.json`), đi hết checklist giai đoạn D:
  - ghi đủ 3 nguồn;
  - ghi lùi ngày;
  - ăn vượt mục tiêu;
  - tắt mạng giữa chừng rồi retry (không ghi trùng);
  - đổi hồ sơ rồi xem đường mục tiêu của ngày cũ;
  - vuốt xoá → Hoàn tác, và vuốt xoá → Đăng xuất ngay.
- [ ] **Step 4: Commit** – `docs: point CLAUDE.md to sprint 5 spec and diary store`
- [ ] **Step 5:** Review toàn nhánh (`/code-review` hoặc reviewer subagent), sửa, rồi mở PR → `main` (nội dung PR không có `Co-Authored-By`).
