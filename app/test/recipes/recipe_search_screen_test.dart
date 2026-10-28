import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/widgets/recipe_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeRecipeRepository repo;

  setUp(() {
    repo = FakeRecipeRepository()
      ..recipes = [
        recipe(id: 'a', title: 'Cá basa kho tộ'),
        recipe(id: 'b', title: 'Phở bò tái', category: 'mon_an_sang'),
      ];
  });

  Future<void> pumpSearch(WidgetTester t) async {
    // Khung điện thoại như Figma (390 × 844), thay cho 800 × 600 mặc định
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: repo));
    await t.pumpAndSettle();
  }

  Future<void> typeQuery(WidgetTester t, String q) async {
    await t.enterText(find.byKey(const Key('recipeSearchField')), q);
    await t.pump(const Duration(milliseconds: 350));
  }

  testWidgets('hiện danh sách và số món', (t) async {
    await pumpSearch(t);
    expect(find.text('2 món'), findsOneWidget);
    expect(find.text('Cá basa kho tộ'), findsOneWidget);
  });

  testWidgets('gõ từ khóa lọc danh sách', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'pho');
    expect(find.text('1 món'), findsOneWidget);
    expect(find.text('Phở bò tái'), findsOneWidget);
    expect(find.text('Cá basa kho tộ'), findsNothing);
  });

  testWidgets('chưa hết 300 ms thì chưa lọc', (t) async {
    await pumpSearch(t);
    await t.enterText(find.byKey(const Key('recipeSearchField')), 'pho');
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('2 món'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 250));
    expect(find.text('1 món'), findsOneWidget);
  });

  testWidgets('chuyển tab rồi quay lại vẫn giữ từ khóa', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'pho');
    await t.tap(find.text('Trang chủ'));
    await t.pumpAndSettle();
    await t.tap(find.text('Món ăn'));
    await t.pumpAndSettle();
    expect(
        t.widget<TextField>(find.byKey(const Key('recipeSearchField'))).controller!.text,
        'pho');
    expect(find.text('1 món'), findsOneWidget);
  });

  testWidgets('chưa khai báo dị ứng → chip "Khai báo dị ứng"', (t) async {
    await pumpSearch(t);
    expect(find.text('Khai báo dị ứng'), findsOneWidget);
    expect(find.text('Bỏ món dị ứng'), findsNothing);
  });

  testWidgets('đã khai báo dị ứng → chip "Bỏ món dị ứng" lọc món', (t) async {
    repo.recipes = [
      recipe(id: 'a', title: 'Cá basa kho tộ', allergens: {4}),
      recipe(id: 'b', title: 'Phở bò tái'),
    ];
    repo.userAllergenIds = {4};
    await pumpSearch(t);
    expect(find.text('Bỏ món dị ứng'), findsOneWidget);
    expect(find.text('1 món'), findsOneWidget);
    await t.tap(find.text('Bỏ món dị ứng'));
    await t.pump();
    expect(find.text('2 món'), findsOneWidget);
  });

  testWidgets('chip ≤ 500 kcal lọc món', (t) async {
    repo.recipes = [
      recipe(id: 'a', title: 'Cá basa kho tộ', kcal: 500),
      recipe(id: 'b', title: 'Phở bò tái', kcal: 650),
    ];
    await pumpSearch(t);
    // Chip nằm cuối hàng cuộn ngang
    final chip = find.text('≤ 500 kcal', skipOffstage: false);
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pump();
    expect(find.text('1 món'), findsOneWidget);
  });

  testWidgets('chip nhóm món lọc theo category', (t) async {
    await pumpSearch(t);
    await t.tap(find.widgetWithText(CategoryChip, 'Món ăn sáng'));
    await t.pump();
    expect(find.text('1 món'), findsOneWidget);
    expect(find.text('Phở bò tái'), findsOneWidget);
  });

  testWidgets('lỗi tải lần đầu → nút Thử lại', (t) async {
    repo.failWith = Exception('mất mạng');
    await pumpSearch(t);
    expect(find.text('Không có kết nối mạng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    repo.failWith = null;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('2 món'), findsOneWidget);
  });

  testWidgets('không có kết quả do từ khóa → không có nút Xóa bộ lọc', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'zzz');
    expect(find.text('Không tìm thấy món phù hợp'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsNothing);
  });

  testWidgets('không có kết quả do bộ lọc → Xóa bộ lọc giữ từ khóa', (t) async {
    repo.recipes = [
      recipe(id: 'a', title: 'Cá basa kho tộ'),
      recipe(id: 'b', title: 'Phở bò tái', kcal: 900),
    ];
    await pumpSearch(t);
    await typeQuery(t, 'pho');
    final chip = find.text('≤ 500 kcal', skipOffstage: false);
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pump();
    expect(find.text('Không tìm thấy món phù hợp'), findsOneWidget);
    await t.tap(find.text('Xóa bộ lọc'));
    await t.pump();
    expect(find.text('1 món'), findsOneWidget);
    expect(find.text('Phở bò tái'), findsOneWidget);
    expect(
        t.widget<TextField>(find.byKey(const Key('recipeSearchField'))).controller!.text,
        'pho');
  });

  testWidgets('focus khi chưa nhập → Tìm gần đây và Món phổ biến', (t) async {
    await pumpSearch(t);
    await typeQuery(t, 'pho');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pump();
    await t.tap(find.byTooltip('Xóa từ khóa'));
    await t.tap(find.byKey(const Key('recipeSearchField')));
    await t.pump();
    expect(find.text('Tìm gần đây'), findsOneWidget);
    expect(find.text('Món phổ biến'), findsOneWidget);
    expect(find.text('Tìm theo nguyên liệu'), findsNothing);

    // Chạm một dòng tìm gần đây → đặt lại từ khóa
    await t.tap(find.text('pho'));
    await t.pump();
    expect(find.text('1 món'), findsOneWidget);
  });

  testWidgets('chạm thẻ món → mở chi tiết, che thanh điều hướng', (t) async {
    await pumpSearch(t);
    await t.tap(find.text('Phở bò tái'));
    await t.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('thẻ món: ảnh thay thế, thời gian, khẩu phần, độ khó', (t) async {
    repo.recipes = [
      recipe(id: 'a', title: 'Cá basa kho tộ', prep: 20, cook: 180,
          difficulty: Difficulty.medium),
    ];
    await pumpSearch(t);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    expect(find.text('3 giờ 20 phút'), findsOneWidget);
    expect(find.text('2 phần'), findsOneWidget);
    expect(find.text('Vừa'), findsOneWidget);
    expect(find.text('P 39 g'), findsOneWidget);
  });
}
