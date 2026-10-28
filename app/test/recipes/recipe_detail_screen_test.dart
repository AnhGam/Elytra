import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';
import '../helpers/test_app.dart';

RecipeDetail detailFixture({
  Set<int> allergens = const {},
  Set<int> condiment = const {},
}) =>
    RecipeDetail(
      recipe: recipe(
        id: 'r1',
        title: 'Cá basa kho tộ',
        servings: 2,
        allergens: allergens,
        condiment: condiment,
      ),
      ingredients: const [
        RecipeIngredient(
          orderIndex: 1,
          rawText: 'Cá basa phi lê: 400g',
          nameRaw: 'Cá basa phi lê',
          amount: 400,
          unit: 'g',
          amountG: 400,
        ),
        RecipeIngredient(
          orderIndex: 2,
          rawText: 'Tỏi: 3 tép',
          nameRaw: 'tỏi',
          amount: 3,
          unit: 'tép',
          amountG: 15,
        ),
      ],
      steps: const [
        RecipeStep(number: 1, title: 'Ướp cá', description: 'Ướp cá với nước mắm.'),
        RecipeStep(number: 2, title: 'Kho', description: 'Kho lửa nhỏ 25 phút.'),
      ],
    );

void main() {
  late FakeRecipeRepository repo;

  setUp(() {
    WidgetController.hitTestWarningShouldBeFatal = true;
    repo = FakeRecipeRepository()
      ..details = {'r1': detailFixture()}
      ..allergens = const [
        Allergen(id: 1, nameVi: 'Hải sản (Tôm, Cua, Mực, Cá)'),
        Allergen(id: 2, nameVi: 'Trứng'),
      ];
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  // Qua router thật: kiểm tra route /recipes/:id
  Future<String Function()> pumpRoute(WidgetTester t, String location) async {
    phone(t);
    final r = await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: repo),
        initialLocation: location);
    await t.pumpAndSettle();
    return () => r.routerDelegate.currentConfiguration.uri.path;
  }

  // Dựng thẳng màn, tiêm repo meal-logs giả
  Future<void> pumpDetail(WidgetTester t, {MealLogRepository? meal}) async {
    phone(t);
    await t.pumpWidget(MaterialApp(
      home: RecipeScope(
        catalog: RecipeCatalog(repo: repo),
        child: RecipeDetailScreen(id: 'r1', mealLogs: meal ?? FakeMealLogRepository()),
      ),
    ));
    await t.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
  }

  testWidgets('mở thẳng /recipes/:id (không extra) vẫn tải được', (t) async {
    await pumpRoute(t, '/recipes/r1');
    expect(find.text('Cá basa kho tộ'), findsOneWidget);
    expect(find.text('Nguyên liệu'), findsOneWidget);
    expect(find.text('2 bước', skipOffstage: false), findsOneWidget);
    expect(find.text('Việt Nam · Dễ'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('id không tồn tại → "Không tìm thấy món", Quay lại về Tìm kiếm', (t) async {
    final path = await pumpRoute(t, '/recipes/zzz');
    expect(find.text('Không tìm thấy món'), findsOneWidget);
    await t.tap(find.text('Quay lại'));
    await t.pumpAndSettle();
    expect(path(), '/recipes');
  });

  testWidgets('lỗi tải → "Không tải được món", Thử lại tải lại', (t) async {
    repo.failWith = Exception('mất mạng');
    await pumpDetail(t);
    expect(find.text('Không tải được món'), findsOneWidget);
    repo.failWith = null;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('Cá basa kho tộ'), findsOneWidget);
  });

  testWidgets('stepper nhân lượng nguyên liệu, dinh dưỡng giữ 1 phần', (t) async {
    await pumpDetail(t);
    expect(find.text('400 g'), findsOneWidget);
    await tapVisible(t, find.byKey(const Key('servingsInc')));
    await t.pump();
    expect(find.text('3 phần'), findsWidgets);
    expect(find.text('600 g'), findsOneWidget);
    expect(find.textContaining('Đã nhân lượng nguyên liệu cho 3 phần'), findsOneWidget);
    expect(find.text('240', skipOffstage: false), findsWidgets); // lưới calo vẫn 1 phần
    await tapVisible(t, find.byKey(const Key('servingsDec')));
    await t.pump();
    expect(find.text('400 g'), findsOneWidget);
    expect(find.textContaining('Đã nhân lượng'), findsNothing);
  });

  testWidgets('chạm bước → đánh dấu xong', (t) async {
    await pumpDetail(t);
    final step = find.text('Ướp cá', skipOffstage: false);
    expect(find.byKey(const ValueKey('stepDone1'), skipOffstage: false), findsNothing);
    await tapVisible(t, step);
    await t.pump();
    expect(find.byKey(const ValueKey('stepDone1'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('banner dị ứng có "(từ gia vị)"', (t) async {
    repo
      ..details = {'r1': detailFixture(allergens: {1, 2}, condiment: {1})}
      ..userAllergenIds = {1, 2};
    await pumpDetail(t);
    expect(find.textContaining('(từ gia vị)'), findsOneWidget);
    expect(find.textContaining('Trứng'), findsOneWidget);
  });

  testWidgets('catalog lỗi → dòng "Chưa kiểm tra được dị ứng", Thử lại gọi refresh', (t) async {
    repo
      ..details = {'r1': detailFixture(allergens: {2})}
      ..failCatalogWith = Exception('mất mạng');
    await pumpDetail(t);
    expect(find.text('Cá basa kho tộ'), findsOneWidget);
    expect(find.textContaining('Chưa kiểm tra được dị ứng của bạn'), findsOneWidget);

    final retry = find.ancestor(of: find.text('Thử lại'), matching: find.byType(InkWell)).first;
    expect(t.getSize(retry).width, greaterThanOrEqualTo(48)); // vùng chạm ≥ 48

    repo
      ..failCatalogWith = null
      ..userAllergenIds = {2};
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.textContaining('Chưa kiểm tra được dị ứng'), findsNothing);
    expect(find.textContaining('Trứng'), findsOneWidget); // banner dị ứng hiện
  });

  testWidgets('dinh dưỡng: % mục tiêu, cảnh báo natri, chú thích', (t) async {
    repo.profile = const UserNutritionProfile(targetKcal: 2000, proteinG: 130);
    await pumpDetail(t);
    // Thẻ dinh dưỡng ở cuối, danh sách dựng lười → cuộn tới trước
    await t.scrollUntilVisible(find.textContaining('Số liệu ước tính'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('12%', skipOffstage: false), findsOneWidget); // 240 / 2000
    expect(find.text('30%', skipOffstage: false), findsOneWidget); // 39 / 130
    expect(find.textContaining('Natri cao', skipOffstage: false), findsOneWidget);
    // Thanh tỉ lệ năng lượng cao 8, thanh % mục tiêu cao 4 và bắt đầu từ mép trái của rãnh
    final split = t.getSize(find.byKey(const ValueKey('split-protein'), skipOffstage: false));
    expect(split.height, closeTo(8, 0.1));
    expect(split.width, greaterThan(0));
    final track = t.getRect(find.byKey(const ValueKey('track-Calo'), skipOffstage: false));
    final fill = t.getRect(find.byKey(const ValueKey('fill-Calo'), skipOffstage: false));
    expect(fill.height, closeTo(4, 0.1));
    expect(fill.left, track.left);
    expect(fill.width, closeTo(track.width * 0.12, 1));
    expect(
        find.textContaining('mục tiêu ngày 2.000 kcal, natri tối đa 2.000 mg',
            skipOffstage: false),
        findsOneWidget);
  });

  testWidgets('Thêm thành công → SnackBar', (t) async {
    final meal = FakeMealLogRepository();
    await pumpDetail(t, meal: meal);
    await t.tap(find.textContaining('Thêm 1 phần vào bữa'));
    await t.pumpAndSettle();
    expect(find.textContaining('Đã thêm 1 phần vào bữa'), findsOneWidget);
    expect(meal.calls, hasLength(1));
  });

  testWidgets('mất mạng → "Không có kết nối", Thử lại gửi lại cùng id', (t) async {
    final meal = FakeMealLogRepository()..failWith = const MealLogOffline();
    await pumpDetail(t, meal: meal);
    await t.tap(find.textContaining('Thêm 1 phần vào bữa'));
    await t.pumpAndSettle();
    expect(find.text('Không có kết nối'), findsOneWidget);
    meal.failWith = null;
    await t.tap(find.widgetWithText(SnackBarAction, 'Thử lại'));
    await t.pumpAndSettle();
    expect(meal.calls, hasLength(2));
    expect(meal.calls[1]['clientRequestId'], meal.calls[0]['clientRequestId']);
    expect(find.textContaining('Đã thêm 1 phần vào bữa'), findsOneWidget);
  });

  testWidgets('rời màn → SnackBar có action biến mất, không gọi lại vào màn đã đóng', (t) async {
    phone(t);
    final meal = FakeMealLogRepository()..failWith = const MealLogOffline();
    final catalog = RecipeCatalog(repo: repo);
    await t.pumpWidget(MaterialApp(
      home: RecipeScope(
        catalog: catalog,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => RecipeScope(
                    catalog: catalog,
                    child: RecipeDetailScreen(id: 'r1', mealLogs: meal),
                  ),
                )),
                child: const Text('Mở món'),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.text('Mở món'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('Thêm 1 phần vào bữa'));
    await t.pumpAndSettle();
    expect(find.text('Không có kết nối'), findsOneWidget);

    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 10));
    await t.pumpAndSettle();
    expect(find.text('Mở món'), findsOneWidget);
    expect(find.text('Không có kết nối'), findsNothing);
    expect(find.widgetWithText(SnackBarAction, 'Thử lại'), findsNothing);
    expect(meal.calls, hasLength(1));
  });

  testWidgets('chưa có hồ sơ → SnackBar "Bạn cần hoàn tất hồ sơ trước"', (t) async {
    final meal = FakeMealLogRepository()..failWith = const MealLogProfileMissing();
    await pumpDetail(t, meal: meal);
    await t.tap(find.textContaining('Thêm 1 phần vào bữa'));
    await t.pumpAndSettle();
    expect(find.text('Bạn cần hoàn tất hồ sơ trước'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Khai báo'), findsOneWidget);
  });
}
