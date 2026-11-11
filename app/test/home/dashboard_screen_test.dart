import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/home/dashboard_screen.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/meal_log_fixtures.dart';

void main() {
  // 19h giờ VN ngày 11/11/2026 (thứ Tư) → bữa tối
  final now = DateTime.utc(2026, 11, 11, 19);
  const today = '2026-11-11';
  late FakeMealLogRepository repo;
  late FakeRecipeRepository recipeRepo;
  late DiaryStore store;

  setUp(() {
    repo = FakeMealLogRepository();
    recipeRepo = FakeRecipeRepository();
    store = DiaryStore(repo: repo, now: () => now, scheduleMidnight: false);
  });
  tearDown(() => store.dispose());

  Future<void> pumpDashboard(WidgetTester t, {double width = 390}) async {
    t.view.physicalSize = Size(width, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: DiaryScope(
        store: store,
        child: RecipeScope(
          catalog: RecipeCatalog(repo: recipeRepo),
          child: const DashboardScreen(),
        ),
      ),
    ));
    await t.pumpAndSettle();
  }

  testWidgets('vượt mục tiêu: nhãn Vượt % và tâm vòng', (t) async {
    repo.days[today] = dayLog(
        date: today, target: 1968, items: [(MealType.lunch, item(kcal: 2118))]);
    await pumpDashboard(t);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('kcal vượt mức'), findsOneWidget);
    expect(find.text('Vượt 8 %'), findsOneWidget);
  });

  testWidgets('chưa ghi gì: vòng còn đủ mục tiêu, 4 bữa Chưa ghi món nào', (t) async {
    await pumpDashboard(t);
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
    expect(find.text('1.968'), findsOneWidget);
    expect(find.text('kcal còn lại'), findsOneWidget);
  });

  testWidgets('bữa đến giờ có nhãn "· đến giờ"', (t) async {
    await pumpDashboard(t);
    expect(find.text('Bữa tối · đến giờ'), findsOneWidget);
    expect(find.text('Bữa sáng'), findsOneWidget);
  });

  testWidgets('thẻ bữa: tên món nối bằng " · " và số kcal / ngân sách', (t) async {
    repo.days[today] = dayLog(date: today, items: [
      (MealType.breakfast, item(id: 'a', name: 'Bánh mì trứng', kcal: 400)),
      (MealType.breakfast, item(id: 'b', name: 'Sữa đậu nành', kcal: 87)),
    ]);
    await pumpDashboard(t);
    expect(find.text('Bánh mì trứng · Sữa đậu nành'), findsOneWidget);
    expect(find.text('487'), findsOneWidget);
    expect(find.text('/ 492 kcal'), findsOneWidget);
  });

  testWidgets('PROFILE_NOT_FOUND: nút Khai báo thể trạng, ẩn 7 ngày qua', (t) async {
    repo.failWith = const MealLogProfileMissing();
    await pumpDashboard(t);
    expect(find.text('Khai báo thể trạng'), findsOneWidget);
    expect(find.text('7 ngày qua'), findsNothing);
  });

  testWidgets('mất mạng lần đầu: khối Thử lại, bấm thì tải lại', (t) async {
    repo.failWith = const MealLogOffline();
    await pumpDashboard(t);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Không có kết nối mạng'), findsOneWidget);

    repo.failWith = null;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
  });

  testWidgets('lỗi riêng thẻ 7 ngày qua chỉ ẩn thẻ đó', (t) async {
    repo.failOnce['getHistory'] = const MealLogOffline();
    await pumpDashboard(t);
    expect(find.text('7 ngày qua'), findsNothing);
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
  });

  testWidgets('thẻ 7 ngày qua: trung bình và số ngày trong mục tiêu', (t) async {
    repo.onHistory = (from, to) => History(from: from, to: to, targetKcal: 1968, days: [
          hday('2026-11-05', 2000),
          hday('2026-11-06', 2400), // vượt
          hday('2026-11-07', 0),
          hday('2026-11-08', 1900),
          hday('2026-11-09', 1950),
          hday('2026-11-10', 1700), // dưới 90 %
          hday(today, 0),
        ]);
    await pumpDashboard(t);
    expect(find.text('7 ngày qua'), findsOneWidget);
    // (2000 + 2400 + 1900 + 1950 + 1700) / 5 = 1990
    expect(find.text('TB 1.990 kcal/ngày · 3/5 ngày trong mục tiêu'), findsOneWidget);
  });

  testWidgets('lời chào không bao giờ lộ email', (t) async {
    recipeRepo.profile =
        const UserNutritionProfile(targetKcal: 1968, fullName: 'sv@gm.uit.edu.vn');
    await pumpDashboard(t);
    expect(find.textContaining('@'), findsNothing);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Chào buổi tối'), findsOneWidget);
  });

  testWidgets('có tên: lời chào theo từ cuối và avatar chữ cái', (t) async {
    recipeRepo.profile = const UserNutritionProfile(fullName: 'Nguyễn Văn Thuận');
    await pumpDashboard(t);
    expect(find.text('Chào buổi tối, Thuận'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('Thứ Tư, 11 tháng 11'), findsOneWidget);
  });

  testWidgets('Trợ lý AI: snackbar Sắp có', (t) async {
    await pumpDashboard(t);
    await t.tap(find.byTooltip('Trợ lý AI'));
    await t.pump();
    expect(find.text('Sắp có'), findsOneWidget);
  });

  testWidgets('món đang chờ xoá bị trừ khỏi Dashboard', (t) async {
    final a = item(id: 'a', name: 'Phở bò', kcal: 450);
    repo.days[today] = dayLog(date: today, items: [(MealType.dinner, a)]);
    await pumpDashboard(t);
    expect(find.text('Phở bò'), findsOneWidget);
    final p = store.deleteDeferred(a, date: today);
    await t.pumpAndSettle();
    expect(find.text('Phở bò'), findsNothing);
    expect(find.text('Chưa ghi món nào'), findsNWidgets(4));
    p.undo();
    await t.pumpAndSettle();
    expect(find.text('Phở bò'), findsOneWidget);
  });

  testWidgets('màn hẹp 320 có dữ liệu, vượt mục tiêu: không tràn bố cục', (t) async {
    repo.days[today] = dayLog(date: today, items: [
      (MealType.lunch, item(id: 'a', name: 'Cơm tấm sườn bì chả trứng ốp la', kcal: 12345)),
    ]);
    await pumpDashboard(t, width: 320);
    expect(t.takeException(), isNull);
    expect(find.text('7 ngày qua'), findsOneWidget);
  });
}
