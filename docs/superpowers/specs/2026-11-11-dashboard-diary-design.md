# Sprint 5: Dashboard, Ghi bữa ăn, Nhật ký – Thiết kế triển khai

Ngày: 11/11/2026 · Nhánh `feat/dashboard-diary-ui` (tách từ `main`, PR #4 và #5 đã merge).
Thiết kế: `docs/design/sprint5/README.md` (node Figma, quy ước) và `docs/design/sprint5/screens/*.png`.
API: `docs/api-contract.md` mục 4 (`/meal-logs`); RPC `search_dishes`, `search_ingredients` trong `supabase/migrations/`.

## 1. Mục đích

Đến Sprint 4, người dùng đã tìm món và ghi được 1 phần vào bữa, nhưng chưa xem lại được mình đã ăn gì: tab Trang chủ chỉ có nút Đăng xuất, tab Nhật ký là "Sắp có". Sprint 5 làm cho phần ghi chép dùng được hằng ngày. Người dùng mở app là thấy hôm nay còn bao nhiêu kcal và macro, ghi một món trong vài lần chạm (món nấu, món ăn sẵn hoặc nguyên liệu), rồi xem lại, sửa hoặc xoá từng ngày và theo dõi xu hướng 7 hoặc 30 ngày.

Mọi con số dinh dưỡng lưu lại đều do server tính (snapshot lúc ghi). App chỉ tính bản xem trước để hiển thị.

## 2. Mục tiêu / Không làm / Thất bại nếu

**Mục tiêu**
- Dashboard ở `/home`: thẻ "Hôm nay" (vòng calo còn lại, đã nạp, mục tiêu, 3 thanh macro), 4 thẻ bữa có nút +, thẻ "7 ngày qua", và đủ 7 trạng thái trong ảnh `dashboard-*`.
- Màn Ghi bữa ăn ở `/log`, mở trên root navigator: tìm trong 3 tab (Món nấu, Món ăn sẵn, Nguyên liệu), sheet chọn lượng có xem trước dinh dưỡng, sau khi ghi có snackbar Hoàn tác.
- Tab Nhật ký `/diary`: "Theo ngày" (dải 7 ngày, chọn ngày bằng lịch, 4 bữa, sửa lượng hoặc xoá) và "Thống kê" (biểu đồ cột 7/30 ngày, trung bình, số ngày trong mục tiêu, macro trung bình).
- Tab Cá nhân bản tối thiểu có nút Đăng xuất (chuyển từ `HomePlaceholder`), sau đó xoá `HomePlaceholder`.
- Nút "Thêm 1 phần vào bữa…" ở Chi tiết món đi qua `DiaryStore`, nên Dashboard cập nhật ngay.

**Không làm (Ngoài phạm vi)**
- Ô nhập tên hoặc sửa tên hiển thị. Để cho sprint tab Cá nhân; sprint này chỉ đọc `profiles.full_name`.
- Ghi bữa bằng ảnh hoặc giọng nói, gợi ý 1 chạm, mục "Gần đây" trong màn Ghi bữa.
- Mục tiêu theo tuần, cân nặng theo thời gian.
- Trợ lý AI: FAB chỉ hiện snackbar "Sắp có".
- Đổi bữa hoặc ngày của món đã ghi (API không hỗ trợ; muốn đổi thì xoá rồi ghi lại).
- Sửa `supabase/`.

**Thất bại nếu** (kể cả khi chạy được)
- Dashboard và Nhật ký (Theo ngày hoặc Thống kê) hiện số khác nhau cho cùng một ngày sau khi thêm, sửa hoặc xoá.
- Bấm "Thêm" hai lần hoặc retry khi mạng chập chờn mà món bị ghi trùng.
- Qua 0h hoặc mở lại app từ nền mà Dashboard vẫn hiện "hôm nay" của ngày cũ.
- Ngày cũ bị vẽ theo mục tiêu hiện tại thay vì `days[].target_kcal` của chính ngày đó.
- Lời chào lộ email hoặc mã số sinh viên.

## 3. Ràng buộc

- Giữ nguyên quy ước trong `CLAUDE.md` và Global Constraints của plan Sprint 4 (chép lại ở plan Sprint 5), trừ hai điểm:
  - Bỏ ràng buộc "không merge `origin/feat/meal-logs-sprint-5`" (đã merge).
  - Commit và PR **không** có dòng `Co-Authored-By`.
- Không thêm package: `fl_chart`, `intl`, `go_router` đã có.
- "Bây giờ" chỉ lấy từ `vnNow()`, ngày dạng chuỗi chỉ qua `isoDate()`.
- Màu chỉ dùng token trong `AppColors`. Ảnh thiết kế không có màu nào ngoài palette.
- Vùng chạm ≥ 48. Skeleton là khối tĩnh, không dùng `CircularProgressIndicator` trên các màn mới, để `pumpAndSettle` không treo.
- Widget test không dùng `buildAppTheme()` và không chạm `supabase` toàn cục.

## 4. Phương án đã cân nhắc

Cần chốt cách giữ dữ liệu nhật ký sao cho Dashboard, Nhật ký và Chi tiết món luôn khớp nhau.

| Phương án | Ưu | Nhược |
|---|---|---|
| **A. Một `DiaryStore` dùng chung** (ChangeNotifier ở gốc app, `DiaryScope` kiểu `RecipeScope`). Cache `DayLog` theo ngày và kết quả `/history` theo khoảng ngày. Mọi thao tác ghi, sửa, xoá đi qua store. | Một nguồn sự thật, cùng mẫu với `RecipeCatalog` đã có. POST và PATCH trả `budget` nên cập nhật được ngay. | Store khá to, phải test kỹ phần làm mới cache. |
| B. Mỗi màn tự gọi API, đồng bộ bằng sự kiện ("đã ghi món") | Từng màn đơn giản | Dễ lệch số và gọi trùng. Đúng loại lỗi ở mục "Thất bại nếu". |
| C. Tính lịch sử ở app từ các `DayLog` | Ít gọi `/history` | Phải gọi `GET ?date=` 7 đến 30 lần, và mất `days[].target_kcal`. |

**Chọn A** (theo kế hoạch Sprint 5, mục 3). B và C đều trái với yêu cầu chính là số liệu luôn khớp.

## 5. Kiến trúc

```
app/lib/core/
  greeting.dart               (mới) displayName, shortName, greeting – logic thuần
  edit_window.dart            (mới) withinEditWindow – mốc 30 ngày duy nhất
  router.dart                 (sửa) /home → Dashboard, /diary → Nhật ký, /profile → Cá nhân, /log
app/lib/main.dart             (sửa) tạo DiaryStore, bọc DiaryScope trong builder:
app/lib/features/meal_logs/
  meal_log_models.dart        Macros, Budget, MealLogItem, MealLog, DayLog, HistoryDay, History, FoodHit
  meal_log_repository.dart    (sửa) getDay, getHistory, addRecipe(servings), addDish, addIngredient, updateItem, deleteItem
  food_search_repository.dart searchDishes, searchIngredients
  diary_store.dart            DiaryStore (ChangeNotifier)
  diary_scope.dart            DiaryScope (InheritedNotifier)
  budget_view.dart            logic thuần: tỉ lệ vòng/thanh, còn/vượt
  portion_math.dart           logic thuần: xem trước theo phần/gam, giới hạn
  history_stats.dart          logic thuần: khoảng ngày, trung bình, ngày trong mục tiêu, màu cột, chấm ngày
  log_meal_screen.dart, log_meal_controller.dart
  widgets/portion_sheet.dart, widgets/food_row.dart
app/lib/features/home/
  dashboard_screen.dart
  widgets/calorie_ring.dart, macro_bar.dart, meal_card.dart, week_card.dart
app/lib/features/diary/
  diary_screen.dart, diary_controller.dart
  widgets/day_strip.dart, day_meals.dart, edit_item_sheet.dart, history_chart.dart
app/lib/features/profile/
  profile_screen.dart         bản tối thiểu: tên/email + Đăng xuất
```

Repository là interface không giữ trạng thái, bản Supabase là singleton cấp file (`mealLogRepo`, `foodSearchRepo`). UI không gọi `supabase` trực tiếp.

### 5.1 Models (`meal_log_models.dart`)

Parse chịu được NUMERIC dạng chuỗi, `null` và kiểu lạ (dùng chung một hàm `_num` như `recipe.dart`). Thiếu khoá thì nhận 0 hoặc rỗng, không ném lỗi.
- `Macros { kcal, proteinG, carbsG, fatG }` (double).
- `Budget { target, consumed, remaining }`. `remaining` có thể âm. Nếu server bỏ `remaining` thì tính `target − consumed`.
- `MealLogItem { id, source (recipe|dish|ingredient), recipeId?, dishId?, ingredientId?, name, imageUrl?, servings?, amountG?, kcal, proteinG, carbsG, fatG, createdAt?, mealType?, date? }`. `source` lạ thì xử lý như món theo gam nếu có `amount_g`, ngược lại như món nấu.
- `MealLog { kcal, items }`. `DayLog { date, budget, meals: Map<MealType, MealLog> }` luôn đủ 4 bữa; bữa thiếu trong JSON thì là bữa rỗng.
- `HistoryDay { date, kcal, proteinG, carbsG, fatG, itemCount, targetKcal }`; `History { from, to, targetKcal, days }`.
- `FoodHit { id, kind (dish|ingredient), name, kcal100, protein100, carbs100, fat100 }` lấy từ RPC (`name_vi`, `calories_per_100g`…).

### 5.2 `MealLogRepository` (mở rộng)

| Hàm | Gọi | Trả |
|---|---|---|
| `getDay(date)` | `GET meal-logs?date=` | `DayLog` |
| `getHistory(from, to)` | `GET meal-logs/history` | `History` |
| `addRecipe({recipeId, servings, mealType, date, clientRequestId})` | `POST` | `AddResult { item, budget, replayed }` |
| `addDish` / `addIngredient({id, amountG, …})` | `POST` | `AddResult` |
| `updateItem(id, {servings | amountG})` | `PATCH meal-logs/items/:id` | `{ item, budget }` |
| `deleteItem(id)` | `DELETE meal-logs/items/:id` | — |

- Timeout 15 giây như Sprint 4. Mọi lỗi đi qua `mapMealLogError`. Hàm này cần đọc thêm `field` trong body lỗi (hiện chỉ đọc `code` và `message`) và nhận thêm tham số cho biết đang là thao tác nào. Bổ sung:
  - `MealLogItemNotFound` (`ITEM_NOT_FOUND`).
  - `MealLogTooOld`: `VALIDATION_ERROR` với `field = date`, **chỉ** khi PATCH hoặc DELETE. Ở POST, lỗi `field = date` là `MealLogInvalid('date')`.
  - `MealLogInvalid(field)` (các `VALIDATION_ERROR` khác).
- Body lỗi lạ không làm app crash (giữ nguyên test cũ).
- PATCH gửi `amount_g` cho cả món ăn sẵn lẫn nguyên liệu, gửi `servings` cho món nấu. RPC `update_meal_log_item` dựa vào `amount_g` của món, không dựa vào `source`, nên món ăn sẵn sửa gam được.
- `addRecipe` hiện có (servings cố định 1) đổi thành nhận `servings`. `RecipeDetailController` truyền 1.

### 5.3 `FoodSearchRepository`

- `searchDishes(query, {limit = 20, offset = 0})` gọi RPC `search_dishes`.
- `searchIngredients(query, {featured, limit = 20, offset = 0})` gọi RPC `search_ingredients`. Tham số `featured` được gửi lên dưới tên `p_is_featured`.
- Từ khoá được `trim()`. Từ khoá rỗng hoặc chỉ có dấu câu và khoảng trắng thì gửi `p_query = null` (dùng lại cách chuẩn hoá ở `recipe_text.dart`).
- Lỗi mạng ném `FoodSearchOffline`, lỗi khác ném `FoodSearchFailed`.

### 5.4 `DiaryStore` + `DiaryScope`

Tạo trong `_ElytraAppState` cạnh `RecipeCatalog`, cùng nghe `userIdChanges` để tự `clear()` khi đăng xuất hoặc đổi tài khoản. `DiaryScope.of(context)` dùng giống `RecipeScope`. Store nhận `repo` và một hàm `now` (mặc định `vnNow`) để test được.

**Trạng thái**
- `today`: `isoDate(now())`, tính lại khi làm mới (xem bên dưới).
- Cache `DayLog` theo ngày (`Map<String, DayEntry>`). `DayEntry` có `status` (loading | ready | offline | profileMissing | failed) và `log?`. Khi đang làm mới mà có lỗi thì giữ `log` cũ.
- Cache `History` theo khoảng: `Map<(from, to), HistoryEntry>`. Dashboard dùng khoảng 7 ngày kết thúc hôm nay. Thống kê dùng khoảng 7 ngày hoặc 30 ngày kết thúc hôm nay. Khoảng 7 ngày của Dashboard và của Thống kê là **cùng một khoá**, nên chỉ gọi API một lần.
- Gọi trùng: trong lúc một ngày hoặc một khoảng đang tải, gọi lại thì nhận chung Future đang chạy.
- Bộ đếm `_generation` (giống `RecipeCatalog`): `clear()` tăng bộ đếm. Kết quả của mọi request bắt đầu trước lúc đó (kể cả làm mới chạy nền) đều bị bỏ, không ghi vào cache, để dữ liệu của người dùng cũ không hiện lại.
- `/history` trả `PROFILE_NOT_FOUND` khi chưa có hồ sơ: khoảng đó nhận trạng thái `profileMissing` như ngày.

**API công khai**
- `ensureDay(date)`, `refreshDay(date)`, `ensureHistory(from, to)`, `refreshHistory(from, to)`.
- `add(...)`, `update(item, …)`, `delete(item)`, `undoAdd(item)` (= `delete`).
- `deleteDeferred(item)` trả về một handle có `undo()` và `commit()`, dùng cho vuốt để xoá (§7.3).
  - Món bị ẩn khỏi mọi view ngay lúc gọi: `DayLog` và `historyView` đều trừ món này ra (xem quy tắc 4). Budget/kcal của ngày được tính lại ở app để hiển thị.
  - `DELETE` chỉ được gửi khi `commit()`. Vuốt xoá món khác thì store tự `commit()` món đang treo trước đó.
  - `flushPendingDeletes()`: `commit()` mọi món còn treo rồi chờ các `DELETE` xong (lỗi thì bỏ qua). Nút Đăng xuất `await` hàm này trước `authRepo.signOut()`.
  - `clear()` (khi phiên đã mất hoặc đổi user) chỉ **bỏ** các món treo, không gửi `DELETE` vì không còn token.
  - App bị tắt khi snackbar còn hiện thì `DELETE` không được gửi và món quay lại ở lần mở sau. Chấp nhận được.
- `checkDayChange()`: gọi từ `AppLifecycleListener.onResume` và từ một `Timer` hẹn đúng 0h giờ VN. Nếu `isoDate(now())` khác `today` thì đổi `today`, làm mới ngày mới và khoảng lịch sử của Dashboard.
- `clear()`.

**Quy tắc cập nhật** (một nguồn sự thật)
1. POST hoặc PATCH thành công: thay `budget` của ngày đó bằng `budget` server trả về, và chèn hoặc thay `item` trong bữa tương ứng (cộng lại `MealLog.kcal` từ các item). Sau đó gọi `refreshDay(date)` chạy nền để lấy đúng thứ tự và số liệu của server. Không cần chờ lệnh này xong mới báo thành công.
2. DELETE thành công: bỏ item khỏi cache ngay, rồi `refreshDay(date)` (DELETE không trả `budget`).
3. Sau 1 hoặc 2: mọi khoảng `History` đã cache có chứa `date` thì gọi `refreshHistory` chạy nền.
4. **Cột hôm nay** trong biểu đồ (Dashboard và Thống kê) lấy kcal từ `DayLog` hôm nay trong store nếu đã có, không lấy từ `/history`. Nhờ vậy cột này luôn khớp vòng calo. Store cung cấp sẵn `historyView(from, to)` đã ghép phần này, để màn không phải tự ghép. `historyView` cũng trừ kcal và macro của các món đang chờ xoá ở đúng ngày của chúng, để trong lúc snackbar còn hiện thì Thống kê, thẻ "7 ngày qua" và dải ngày vẫn khớp với "Theo ngày".
5. `item.date` (server trả về) quyết định ngày được cập nhật. Không dùng ngày app gửi đi, vì retry sau 0h có thể ghi vào ngày khác.

**Idempotency**
- `client_request_id` do controller của màn sinh khi bấm "Thêm", gắn với **nội dung** request: nguồn, id món, lượng, bữa, ngày.
- Retry với nội dung y nguyên thì giữ khoá cũ. Sau một lần lỗi mà người dùng đổi lượng, bữa hoặc món thì sinh khoá mới. Controller lưu cặp (nội dung, khoá) và so sánh trước mỗi lần gửi.
- Thành công thì bỏ khoá.
- Store nhận khoá và chuyển nguyên vẹn cho repository.
- Đóng sheet hoặc rời màn sau ít nhất một lần lỗi mạng: gọi `refreshDay(date)`, để món đã lên server (nếu request đầu thực ra đã tới nơi) hiện ra.
- `422 IDEMPOTENCY_CONFLICT` được map thành `MealLogFailed('IDEMPOTENCY_CONFLICT', …)` và hiện "Không thêm được. Thử lại". Lỗi này chỉ xảy ra khi có bug ở app; có test.

**Sau khi khai báo hồ sơ**: ở trạng thái `PROFILE_NOT_FOUND`, Dashboard có nút "Khai báo thể trạng", gọi `context.go('/onboarding')`.
- `ProfileGate` đã gọi `RecipeScope…clear()`; thêm `DiaryScope.maybeOf(context)?.clear()` bên cạnh.
- `ResultScreen` (nhánh đã đăng nhập) hiện chỉ `nutritionRepo.save(...)` rồi `context.go('/home')`, không xoá cache nào. Cần thêm **cả hai** lệnh: `RecipeScope.maybeOf(context)?.clear()` và `DiaryScope.maybeOf(context)?.clear()`. Lệnh đầu cũng sửa luôn lỗi profile cũ còn trong catalog.
- Về `/home` thì store tải lại.

### 5.5 Logic thuần (TDD)

**`greeting.dart`**
- `String? displayName(String? fullName)`: `trim()` chuỗi. Trả `null` nếu kết quả rỗng hoặc chứa `@`; còn lại trả tên đã trim.
- `String greeting(DateTime t)`: chỉ đọc giờ và phút. Mốc giờ do tôi chọn, nhóm có thể đổi:

| Khung giờ | Chuỗi |
|---|---|
| 04:00–10:59 | "Chào buổi sáng" |
| 11:00–13:59 | "Chào buổi trưa" |
| 14:00–17:59 | "Chào buổi chiều" |
| 18:00–03:59 | "Chào buổi tối" |

- Tiêu đề Dashboard = `greeting(vnNow())`, thêm `", $name"` khi `displayName` khác `null`.
- Avatar: chữ cái đầu của **từ cuối** trong tên, viết hoa (tên Việt gọi theo từ cuối: "Nguyễn Văn Thuận" → "T", khớp lời chào "Thuận"). Không có tên thì dùng icon người (`Icons.person_outline`). Lời chào dùng **từ cuối** của tên ("Chào buổi tối, Thuận"); viết thành hàm `shortName(String name)`, có test.
- Không bao giờ dùng email.
- Hiện trạng: màn đăng ký không gửi `full_name`, nên trigger điền email vào `full_name` và mọi tài khoản hiện có đều chứa `@`. Kết quả là sprint này ai cũng thấy lời chào không tên và avatar icon người. Đây là hành vi đúng, không phải lỗi; tên sẽ hiện khi sprint tab Cá nhân cho nhập tên.
- Nguồn tên: thêm `full_name` vào câu `select` profile của `SupabaseRecipeRepository` và thêm trường `fullName` vào `UserNutritionProfile`. Dashboard đọc qua `RecipeScope`: khi mở màn thì tự gọi `catalog.ensureLoaded()` (không chờ). Khi catalog đang tải hoặc bị lỗi, lời chào không có tên và avatar là icon người; trạng thái của catalog không bao giờ chặn Dashboard.

**`edit_window.dart`** (trong `core/`, cạnh `meal_time.dart`)
- `bool withinEditWindow(String date, String today)`: đúng khi `today − 30 ≤ date ≤ today`, cùng mốc với server (`log_date < vn_today() - 30` thì bị từ chối). Ngày thứ 30 trước hôm nay vẫn sửa được, ngày thứ 31 thì không; test cả hai, cùng ngày tương lai và chuỗi sai dạng (trả `false`).
- Là chỗ duy nhất chứa mốc 30 ngày. Dùng cho:
  - kiểm tra tham số `date` của `/log`;
  - ẩn nút + theo bữa trong Nhật ký;
  - khoá sửa và xoá món;
  - cách hiện `MealLogTooOld`.

**`budget_view.dart`**
- `ratio(consumed, target)`: kẹp trong 0–1. `target ≤ 0` hoặc `null` thì trả 0, không chia cho 0.
- `isOver(consumed, target)`: `consumed > target` khi `target > 0`.
- `overPct(consumed, target)`: phần trăm vượt, làm tròn ("Vượt 8 %").
- Nhãn còn/vượt:
  - `remainingLabel(remaining)` → "Còn 61,6 g" hoặc "Vượt 12 g".
  - Bản cho kcal giữa vòng: "816" kèm "kcal còn lại", hoặc "150" kèm "kcal vượt mức".
- Số kiểu VN: kcal là số nguyên có chấm phân cách nghìn; gam lấy 1 chữ số thập phân, bỏ ",0".

**`portion_math.dart`**
- Món nấu: `servings` từ 0,25 đến 10, bước 0,25. Stepper dừng ở hai đầu. Chip ½ · 1 · 1½ · 2.
- Món ăn sẵn và nguyên liệu: `amountG` là số nguyên từ 1 đến 2000. Chip 200 · 300 · 400 · 500 g. Ô nhập rỗng, bằng 0 hoặc lớn hơn 2000 thì nút "Thêm" bị khoá và hiện dòng báo giới hạn.
- Xem trước:
  - Món nấu: `nutrition/phần × servings`.
  - Theo gam: `per100 × g / 100`.
- "Sau khi thêm: bữa X còn a kcal · cả ngày còn b kcal". Âm thì đổi thành "vượt".
- Ngân sách bữa lấy từ `mealBudgetKcal(budget.target.kcal, meal)`.

**`history_stats.dart`**
- `rangeEnding(today, days)`: trả `(from, to)`, giới hạn 1 đến 31 ngày.
- Một ngày được tính vào trung bình và tỉ lệ "trong mục tiêu" khi `itemCount > 0` (hoặc `kcal > 0`) **và** không phải hôm nay.
- `average`: trung bình kcal các ngày được tính. Không có ngày nào thì trả `null`, hiện "–".
- `inTarget(day)`: `|kcal − target| ≤ 10 % target`, với `target = day.targetKcal`. `targetKcal ≤ 0` thì không xếp loại.
- Nhãn "4/5 ngày" = số ngày trong mục tiêu / số ngày được tính.
- `barKind(day, today)`: hôm nay → `today` (`primaryOutline`); `kcal > 110 % target` → `over` (`error`); còn lại → `normal` (`primary`).
- `dotKind(day, today)`, dùng cho dải ngày:
  - Hôm nay → `today` (chấm xanh nhạt).
  - Không ghi gì → không chấm.
  - Trong ±10 % → `ok` (xanh).
  - Vượt 110 % → `over` (đỏ).
  - Dưới 90 % → **không chấm**. Thiết kế không vẽ trường hợp này. Đây là lựa chọn của tôi, xem §11.
- Macro trung bình (Thống kê) tính trên các ngày được tính. Tỉ lệ năng lượng: P × 4, C × 4, F × 9, chia cho tổng.
- Giá trị so sánh "/ 130 g" lấy từ mục tiêu macro **hiện tại** (`budget.target` của hôm nay), vì `/history` không trả mục tiêu macro theo ngày.

## 6. Điều hướng

- `/home` → `DashboardScreen`, `/diary` → `DiaryScreen`, `/profile` → `ProfileScreen`. `HomePlaceholder` bị xoá. `homeBuilder` trong `buildRouter` giữ lại để test.
- `/log?meal=<breakfast|lunch|dinner|snack>&date=YYYY-MM-DD` dùng `parentNavigatorKey: rootKey`, che thanh tab.
  - `meal` sai hoặc thiếu thì dùng `mealTypeAt(vnNow())`.
  - `date` thiếu, sai dạng hoặc `!withinEditWindow(date, today)` thì dùng hôm nay.
  - Màn Ghi bữa trả kết quả qua `context.pop(LogMealResult)`. Màn gọi (Dashboard hoặc Nhật ký) hiện snackbar "Đã thêm {tên} vào bữa {bữa} · Hoàn tác" (4 giây). Bấm Hoàn tác thì gọi `store.undoAdd(item)`.
- Chạm cột biểu đồ ở Thống kê: chuyển segmented sang "Theo ngày" và chọn ngày đó. Ngày nằm ngoài dải hiện tại thì dải nhảy theo quy tắc `stripEnd` ở §7.3.
- "Xem nhật ký" và thẻ "7 ngày qua" trên Dashboard chuyển sang tab Nhật ký bằng `goBranch(1)`: "Xem nhật ký" mở "Theo ngày" hôm nay, thẻ "7 ngày qua" mở "Thống kê" 7 ngày. Trạng thái segmented giữ trong `DiaryController`, đặt trong state của `DiaryScreen`. Tab gửi yêu cầu chuyển qua `DiaryStore.requestDiaryView(...)` (một `ValueNotifier` nhỏ), không truyền qua URL.

## 7. Màn hình

### 7.1 Dashboard (`dashboard-01…07`)

- Đầu trang: lời chào (§5.5), dòng ngày "Thứ Ba, 10 tháng 11" (`DateFormat('EEEE, d MMMM', 'vi')`, viết hoa chữ đầu) và avatar.
- **Thẻ "Hôm nay"**:
  - `CalorieRing` Ø 144, nét 14, đầu tròn, nền `outline`, vẽ bằng `CustomPainter`.
  - Hai ô bên phải: "Đã nạp" (`ic_flame`) và "Mục tiêu" (`ic_target`).
  - 3 `MacroBar`.
  - Khi vượt: vòng tô `error`, cạnh tiêu đề có nhãn "Vượt x %" (`dashboard-02`).
- **"Bữa ăn hôm nay"** gồm 4 `MealCard`:
  - Icon và màu theo README. Dòng "487 / 492 kcal".
  - Tên 1–2 món nối bằng " · " và cắt bằng dấu "…", hoặc "Chưa ghi món nào".
  - Thanh tiến độ và nút + 48 × 48 mở `/log?meal=…`.
  - Thẻ trùng `mealTypeAt(vnNow())` có viền `primary` 1,5 và chữ "· đến giờ".
- **Thẻ "7 ngày qua"** (`WeekCard`): BarChart mini, dòng "TB 1.993 kcal/ngày · 4/5 ngày trong mục tiêu" (đếm theo ±10 %), chú giải "Không vượt (≤ 110 %) · Vượt > 110 % · Hôm nay · Mục tiêu". Bấm vào thì mở Thống kê.
- **FAB** Trợ lý AI: snackbar "Sắp có".
- **Trạng thái**:

| Trạng thái | Hiển thị |
|---|---|
| Đang tải | Skeleton tĩnh (`dashboard-04`) |
| Chưa ghi gì | Vòng 0, ghi "{mục tiêu} kcal còn lại", 4 bữa "Chưa ghi món nào" (`dashboard-03`) |
| Mất mạng | Khối báo lỗi + "Thử lại" (`dashboard-05`). Nếu cache đã có dữ liệu thì vẫn hiện dữ liệu cũ và báo lỗi bằng snackbar. |
| Chưa có hồ sơ | Màn trống + nút "Khai báo thể trạng" (`dashboard-06`) |
| Sau khi thêm | Snackbar Hoàn tác (`dashboard-07`) |

- Lỗi riêng thẻ "7 ngày qua" chỉ ẩn thẻ đó, không chặn cả màn.
- Kéo xuống để làm mới (`RefreshIndicator`): gọi `refreshDay(today)` và làm mới khoảng 7 ngày.

### 7.2 Ghi bữa ăn (`log-01…06`)

- Header: nút quay lại, "Thêm vào bữa tối ▾" (bấm để mở menu chọn bữa) và dòng phụ "Hôm nay · bữa tối còn 591 kcal" (ngày khác hôm nay thì ghi "T2, 9/11"). Số còn lại lấy từ `DayLog` của ngày đó; chưa có thì ẩn phần số.
- Ô tìm kiếm (debounce 300 ms, có nút xoá 48 × 48) và 3 tab:
  - **Món nấu**:
    - Lọc trên `RecipeCatalog` bằng `RecipeQuery` sẵn có, chỉ khớp tên, không lọc thêm.
    - Chưa nhập: nhãn **"Gợi ý"**, danh sách theo thứ tự catalog.
    - Dòng kết quả: "P 39 · C 6 · F 7 g" và "240 kcal/phần".
  - **Món ăn sẵn**:
    - Gọi `searchDishes`. Chưa nhập: nhãn **"Món ăn sẵn (A–Z)"**, `p_query = null`.
    - Phân trang 20 món mỗi lần, cuộn tới cuối thì tải thêm. Hết khi một trang trả về ít hơn 20 món.
    - Dòng kết quả: "kcal/100 g".
  - **Nguyên liệu**:
    - Gọi `searchIngredients`. Chưa nhập: nhãn **"Gợi ý"**, `featured = true`. Nếu kết quả rỗng thì gọi lại với `featured = null` và hiện danh sách A–Z có phân trang, nhãn **"Nguyên liệu (A–Z)"**. Khi có từ khoá: `featured = null`.
    - Phân trang như tab Món ăn sẵn.
  - Không dùng chữ "phổ biến". Ảnh Figma đang ghi "Món phổ biến"; code theo chữ ở trên.
- `FoodRow` (`FoodResultTile`): tên tối đa 2 dòng, dòng phụ macro, cột kcal, nút + (vùng chạm 48). Bấm dòng hoặc nút + đều mở `PortionSheet`.
- Mỗi tab giữ từ khoá chung và kết quả riêng. Chuyển tab thì tab mới tìm lại theo từ khoá hiện tại. Kết quả cũ trả về muộn bị bỏ qua (so số thứ tự request).
- **`PortionSheet`** (`log-04`, `log-05`):
  - Tên món, dòng nguồn ("Món nấu · 240 kcal / phần").
  - Chip bữa Sáng / Trưa / Tối / Phụ, mặc định là bữa của màn.
  - Stepper hoặc ô gam, chip lượng nhanh.
  - 4 ô xem trước kcal / P / C / F, dòng "Sau khi thêm…".
  - Nút ghim "Thêm vào bữa tối". Đang gửi (`log-06`): nút `primaryDark` 40 %, chữ "Đang thêm…", khoá bấm lặp và khoá đóng sheet.
  - Thành công: đóng sheet, `pop` màn với `LogMealResult`.
  - Lỗi mạng: giữ sheet, hiện "Không có mạng. Thử lại". Khoá `client_request_id` giữ hay đổi theo quy tắc Idempotency ở §5.4, kể cả việc `refreshDay` khi đóng sheet.
  - `PROFILE_NOT_FOUND`: đóng sheet và về Dashboard (Dashboard tự hiện trạng thái chưa có hồ sơ).
- Không có kết quả (`log-03`): "Không tìm thấy “…”" kèm gợi ý thử tab khác.
- Mất mạng khi tìm: khối lỗi + Thử lại trong tab đó.
- Đang tải: danh sách skeleton tĩnh.

### 7.3 Nhật ký (`diary-01…06`)

- Tiêu đề "Nhật ký", nút lịch (`showDatePicker`, `lastDate` = hôm nay, `firstDate` = 1 năm trước). Segmented "Theo ngày | Thống kê".

**Theo ngày**
- `DayStrip`: 7 `DayChip` của **7 ngày liên tiếp kết thúc ở `stripEnd`** (theo `diary-01`: T4 4 … H.nay 10). Mặc định `stripEnd` = hôm nay, nên không có ô ngày tương lai. Ô hôm nay ghi "H.nay".
  - Vuốt ngang (hoặc dùng nút) lùi hoặc tiến `stripEnd` 7 ngày, không vượt quá hôm nay.
  - Chọn ngày bằng lịch hoặc chạm cột biểu đồ: nếu ngày đó nằm ngoài dải thì `stripEnd` = min(ngày đó + 3, hôm nay), để ngày được chọn nằm gần giữa dải.
- Chấm dưới mỗi ô theo `dotKind`, dữ liệu lấy từ `History` của khoảng `(stripEnd − 6, stripEnd)`. Dải mặc định trùng khoá 7 ngày của Dashboard, nên không phải gọi thêm API.
- Thẻ tóm tắt ngày: "Hôm nay · 10/11" (hoặc "T2 · 9/11"), "1.152 / 1.968 kcal" với mục tiêu là `budget.target` của ngày đó, kèm thanh kcal và 3 macro nhỏ.
- 4 nhóm bữa. Mỗi nhóm có tiêu đề, kcal của bữa và nút + (mở `/log` với bữa và ngày đó). Ngày ngoài `withinEditWindow` thì ẩn nút +.
- Mỗi món (`DiaryItemTile`): tên, lượng ("1,5 phần" / "150 g") kèm macro, kcal và mũi tên ›.
- Chạm món mở `EditItemSheet` (`diary-02`): stepper hoặc ô gam như `PortionSheet` (không có chip bữa), nút "Lưu" (`PATCH`) và nút "Xoá".
- Vuốt trái món để xoá (`Dismissible`): gọi `store.deleteDeferred(item)`. Món biến mất ngay và có snackbar "Đã xoá {tên} · Hoàn tác" (4 giây).
  - Bấm Hoàn tác: `undo()`, món hiện lại, không gửi request nào.
  - Snackbar đóng vì hết giờ, bị vuốt hoặc bị snackbar khác thay: `commit()` gửi `DELETE`. Rời màn cũng `commit()`.
  - `DELETE` thất bại: món hiện lại kèm snackbar báo lỗi.
  - Không ghi lại bằng POST: POST tính lại dinh dưỡng từ món gốc hiện tại (khác snapshot cũ) và không làm được khi `recipe_id`/`dish_id`/`ingredient_id` đã thành `null`.
  - Nút "Xoá" trong sheet thì xoá luôn (`delete`), không cần xác nhận và không có Hoàn tác.
- Món của ngày ngoài `withinEditWindow(date, today)`: bấm vào không mở sheet, không vuốt được, có ghi chú "Chỉ sửa được món trong 30 ngày gần nhất". Server trả `MealLogTooOld` thì cũng hiện ghi chú này.
- Xoá món cuối của bữa thì bữa về "Chưa ghi món nào".
- Ngày chưa ghi (`diary-03`): thẻ tóm tắt 0 kcal và 4 bữa trống.
- Ghi chú cuối trang: "Chạm món để sửa lượng hoặc xoá · vuốt trái để xoá nhanh".

**Thống kê**
- Chip "7 ngày | 30 ngày", luôn là khoảng kết thúc hôm nay.
- Hai thẻ số: "Trung bình 1.993 kcal/ngày (không tính hôm nay)" và "Trong mục tiêu 4/5 ngày, trong khoảng ±10 % mục tiêu".
- **`HistoryChart`** (`fl_chart` BarChart):
  - Cột theo `barKind`. Đường mục tiêu nét đứt `textSecondary` nối các `targetKcal` theo ngày, nên khi mục tiêu đổi thì đường có bậc (`diary-05`).
  - Trục Y chia 0 / 1.000 / 2.000…, tính từ `max(kcal, target)`. Dữ liệu toàn 0 hoặc target = 0 thì trục vẫn hợp lệ, `maxY` ≥ 1.
  - Nhãn trục X: 7 ngày ghi thứ ("T4", "H.nay"). 30 ngày ghi ngày dạng "d/M", cách 7 ngày một nhãn, theo ảnh `diary-05`.
  - Chạm cột: hiện tooltip "Thứ Năm 5/11 · 2.240 kcal · vượt 14 %", chạm lần nữa thì mở ngày đó ở "Theo ngày".
  - Chú giải bên dưới: "Không vượt (≤ 110 %)" (`primary`, tính cả cột dưới 90 %), "Vượt > 110 %", "Hôm nay (đang ghi)", "Mục tiêu ngày". Ảnh Figma đang ghi "Trong mục tiêu"; code theo chữ ở đây. Thẻ "Trong mục tiêu x/y ngày" vẫn đếm theo ±10 %.
- Thẻ "Macro trung bình mỗi ngày": thanh xếp chồng theo % năng lượng, 3 dòng "Protein · 27 % … 128 g / 130 g".
- Chưa có dữ liệu (`diary-06`): không có ngày nào được tính và hôm nay cũng trống. Hiện khối trống kèm nút "Ghi bữa đầu tiên" (mở `/log`).
- Đang tải: skeleton tĩnh. Mất mạng: khối lỗi + Thử lại.
- Chưa có hồ sơ (`PROFILE_NOT_FOUND` từ `/history` hoặc `GET ?date=`): cả hai segmented hiện khối "Khai báo thể trạng" giống Dashboard. Trên Dashboard, thẻ "7 ngày qua" bị ẩn.

### 7.4 Cá nhân (bản tối thiểu)

Tên (nếu có) hoặc email nhỏ, nút "Đăng xuất": `await store.flushPendingDeletes()` rồi `authRepo.signOut()`. Trong lúc chờ thì nút bị khoá. Phần còn lại làm ở sprint sau.

## 8. Chi tiết món (Sprint 4) nối vào store

`RecipeDetailController.addOneServing` gọi `DiaryStore.add(recipe, servings: 1, …)` thay vì gọi thẳng `MealLogRepository`. Vẫn giữ cách chống bấm hai lần và giữ `client_request_id` như hiện tại. Store được tiêm qua constructor; màn lấy store từ `DiaryScope`. Thêm xong thì Dashboard và Nhật ký thấy số mới mà không cần tải lại.

## 9. Kiểm thử

- **Unit**, theo TDD cho logic thuần:
  - Models: remaining âm, NUMERIC dạng chuỗi, `recipe_id` null, thiếu bữa, `source` lạ.
  - Repository: dùng bản giả `invoke`/`rpc`. Body lỗi lạ không crash; từng `code` map đúng lỗi.
  - `budget_view`, `portion_math`, `history_stats`, `greeting` theo các ca ở §5.5.
  - `DiaryStore`, dùng repo giả và `now` giả:
    - Hai người nghe cùng thấy số mới sau khi thêm.
    - Cột hôm nay lấy từ `DayLog`.
    - POST/PATCH/DELETE làm mới mọi khoảng history có chứa ngày đó.
    - Retry giữ nguyên khoá.
    - `checkDayChange` qua 0h.
    - `clear` khi đổi user.
    - Gọi trùng `ensureDay` chỉ ra 1 request.
    - Đổi nội dung sau lỗi thì sinh khoá mới; `422 IDEMPOTENCY_CONFLICT` map thành `MealLogFailed`.
    - `historyView` trừ món đang chờ xoá; `undo` trả lại số cũ.
    - `flushPendingDeletes` gửi đủ `DELETE`; `clear` không gửi.
  - `withinEditWindow`: ngày thứ 30, ngày thứ 31, ngày tương lai, chuỗi sai dạng.
- **Widget**, không dùng `buildAppTheme()` và tiêm bản giả:
  - Điều hướng: `/home` ra Dashboard, `/log` che thanh tab, tham số sai thì dùng mặc định.
  - Dashboard: trạng thái vượt, trống, lỗi hồ sơ, mất mạng.
  - Ghi bữa: bấm "Thêm" 2 lần chỉ ra 1 request; giới hạn lượng.
  - Nhật ký: xoá món cuối thì bữa trống; món cũ hơn 30 ngày bị khoá.
  - Thống kê: dữ liệu toàn 0 không lỗi trục.
  - Chi tiết món: thêm xong thì Dashboard cập nhật.
- **Thủ công** (giai đoạn D): tài khoản thật trên máy ảo. Ghi đủ 3 nguồn, ghi lùi ngày, ăn vượt mục tiêu, tắt mạng giữa chừng, đổi hồ sơ rồi xem đường mục tiêu của ngày cũ.

## 10. Review Focus (đưa vào plan)

Giữ 5 điểm của Sprint 4, thêm:

6. Dashboard và Thống kê (cả cột hôm nay lẫn số trung bình) luôn cùng số sau khi thêm, sửa hoặc xoá, kể cả khi thêm từ Chi tiết món.
7. Retry POST sau lỗi mạng gửi đúng `client_request_id` cũ, còn lần "Thêm" mới thì dùng khoá mới.
8. Đổi ngày lúc 0h hoặc khi app quay lại từ nền thì "hôm nay" chuyển sang ngày mới; ngày cũ dùng `days[].target_kcal` của chính nó.
9. `target = 0` hoặc thiếu mục tiêu: không chia cho 0, vòng và thanh không vẽ quá 100 %.
10. Lời chào và avatar không bao giờ lấy từ email.
11. Món đang chờ xoá (snackbar còn hiện) bị trừ ở mọi view: Theo ngày, Dashboard, Thống kê, dải ngày. Đăng xuất gửi các `DELETE` treo trước `signOut()`; `clear()` chỉ bỏ, không gửi.
12. Mốc 30 ngày chỉ nằm ở `withinEditWindow`: ngày thứ 30 sửa được, ngày thứ 31 thì không.

## 11. Để người dựng tự quyết

- Cách cắt widget con, tên biến, bố cục file test.
- Debounce cụ thể (khoảng 300 ms) và cách hiện dòng "đang tải thêm" khi phân trang.
- Hiệu ứng chuyển segmented, cách vuốt đổi tuần (`PageView` hay nút).
- **Lựa chọn của tôi, nhóm xem lại khi duyệt:**
  - Mốc giờ lời chào (§5.5).
  - Avatar và lời chào dùng từ cuối của tên.
  - Ngày dưới 90 % mục tiêu: không chấm, cột vẫn tô `primary`.
  - Tên lấy qua `RecipeCatalog.profile.fullName`.
  - Nút "Xoá" trong sheet không cần hộp xác nhận.
  - Vuốt để xoá có Hoàn tác bằng cách hoãn `DELETE` tới khi snackbar đóng (§7.3).
  - Dải ngày là 7 ngày liên tiếp kết thúc ở `stripEnd`, không phải tuần T2 đến CN (theo ảnh `diary-01`).
