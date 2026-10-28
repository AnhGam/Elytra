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
    // Chạm trượt (bị footer che, ngoài màn) phải làm test fail, không chỉ cảnh báo
    WidgetController.hitTestWarningShouldBeFatal = true;
    repo = FakeRecipeRepository()
      ..recipes = [
        recipe(id: 'a', kcal: 100, cook: 10, prep: 5),
        recipe(id: 'b', title: 'B', kcal: 900, difficulty: Difficulty.hard),
      ]
      ..allergens = const [
        Allergen(id: 1, nameVi: 'Hải sản (Tôm, Cua, Mực, Cá)'),
        Allergen(id: 2, nameVi: 'Trứng', description: 'Trứng gà, vịt, cút'),
      ];
  });

  Future<void> pumpSearch(WidgetTester t) async {
    // Khung điện thoại như Figma (390 × 844)
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: repo));
    await t.pumpAndSettle();
  }

  // Cuộn tới rồi chạm: nội dung sheet có thể nằm dưới footer
  Future<void> tapVisible(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
  }

  Future<void> openFilter(WidgetTester t) async {
    await t.tap(find.byTooltip('Bộ lọc'));
    await t.pumpAndSettle();
  }

  FilledButton viewButton(WidgetTester t) => t.widget<FilledButton>(find.ancestor(
      of: find.textContaining('Xem'), matching: find.byType(FilledButton)));

  group('Bộ lọc', () {
    testWidgets('đếm "Xem N món" khi đổi lọc, áp dụng khi bấm', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      expect(find.text('Xem 2 món'), findsOneWidget);
      await t.enterText(find.byKey(const Key('maxKcal')), '500');
      await t.pump();
      expect(find.text('Xem 1 món'), findsOneWidget);
      expect(find.text('2 món'), findsOneWidget); // danh sách chưa đổi
      await t.tap(find.text('Xem 1 món'));
      await t.pumpAndSettle();
      expect(find.text('1 món'), findsOneWidget);
      expect(find.text('Bộ lọc'), findsNothing);
    });

    testWidgets('bố cục: che thanh tab, chip cùng hàng, "kcal" luôn hiện', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      final sheet = find.byType(BottomSheet);
      // Mở trên root navigator: đáy sheet là đáy màn, không nằm trên thanh tab
      expect(t.getRect(sheet).bottom, 844);
      // Chip ôm nội dung, nằm cùng hàng trong Wrap
      expect(t.getCenter(find.text('≤ 15 phút')).dy, t.getCenter(find.text('Bất kỳ')).dy);
      expect(find.descendant(of: sheet, matching: find.text('kcal')), findsNWidgets(2));
      // Nền và viền ô calo cao đúng 48
      expect(
          t.getSize(find.descendant(
              of: find.byKey(const Key('maxKcal')), matching: find.byType(InputDecorator))).height,
          48);
    });

    testWidgets('chạm ra ngoài ô calo → ô mất focus', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      await t.tap(find.byKey(const Key('maxKcal')));
      await t.pump();
      bool focused() => t
          .widget<EditableText>(find.descendant(
              of: find.byKey(const Key('maxKcal')),
              matching: find.byType(EditableText)))
          .focusNode
          .hasFocus;
      expect(focused(), isTrue);
      await t.tap(find.text('Calo mỗi khẩu phần'));
      await t.pump();
      expect(focused(), isFalse);
    });

    testWidgets('liên kết "sửa" có vùng chạm ≥ 48×48', (t) async {
      repo.userAllergenIds = {2};
      await pumpSearch(t);
      await openFilter(t);
      final link = find.ancestor(of: find.text('sửa'), matching: find.byType(InkWell)).first;
      final size = t.getSize(link);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('min > max: báo lỗi, vô hiệu nút', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      await t.enterText(find.byKey(const Key('minKcal')), '600');
      await t.enterText(find.byKey(const Key('maxKcal')), '500');
      await t.pump();
      expect(find.text('Tối thiểu phải nhỏ hơn tối đa'), findsOneWidget);
      expect(viewButton(t).onPressed, isNull);
      // min = max hợp lệ
      await t.enterText(find.byKey(const Key('maxKcal')), '600');
      await t.pump();
      expect(find.text('Tối thiểu phải nhỏ hơn tối đa'), findsNothing);
      expect(viewButton(t).onPressed, isNotNull);
    });

    testWidgets('quá 1.500 kcal: báo lỗi, vô hiệu nút', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      await t.enterText(find.byKey(const Key('maxKcal')), '1600');
      await t.pump();
      expect(find.text('Nhập số từ 0 đến 1.500'), findsOneWidget);
      expect(viewButton(t).onPressed, isNull);
    });

    testWidgets('đóng sheet không áp dụng thay đổi', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      await t.enterText(find.byKey(const Key('maxKcal')), '500');
      await t.tap(find.byTooltip('Đóng'));
      await t.pumpAndSettle();
      expect(find.text('2 món'), findsOneWidget);
    });

    testWidgets('thời gian và độ khó đổi số đếm; badge nút lọc', (t) async {
      await pumpSearch(t);
      await openFilter(t);
      await tapVisible(t, find.text('≤ 15 phút'));
      await t.pump();
      expect(find.text('Xem 1 món'), findsOneWidget);
      await tapVisible(t, find.text('≤ 15 phút')); // bấm lại → Bất kỳ
      await tapVisible(t, find.widgetWithText(QuickFilterChip, 'Khó'));
      await t.pump();
      expect(find.text('Xem 1 món'), findsOneWidget);
      await t.tap(find.text('Xem 1 món'));
      await t.pumpAndSettle();
      expect(find.text('1 món'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.descendant(of: find.byTooltip('Bộ lọc'), matching: find.text('1')),
          findsOneWidget);
    });

    testWidgets('mở lại sheet hiện bộ lọc đang dùng; Xóa lọc về mặc định', (t) async {
      await pumpSearch(t);
      final chip = find.text('≤ 500 kcal', skipOffstage: false);
      await t.ensureVisible(chip);
      await t.pumpAndSettle();
      await t.tap(chip);
      await t.pump();
      await openFilter(t);
      expect(
          t.widget<TextField>(find.byKey(const Key('maxKcal'))).controller!.text, '500');
      await t.tap(find.text('Xóa lọc'));
      await t.pump();
      expect(t.widget<TextField>(find.byKey(const Key('maxKcal'))).controller!.text, '');
      expect(find.text('Xem 2 món'), findsOneWidget);
      await t.tap(find.text('Xem 2 món'));
      await t.pumpAndSettle();
      expect(find.text('2 món'), findsOneWidget);
    });

    testWidgets('công tắc dị ứng chỉ áp dụng khi bấm Xem', (t) async {
      repo
        ..recipes = [recipe(id: 'a', allergens: {2}), recipe(id: 'b', title: 'B')]
        ..userAllergenIds = {2};
      await pumpSearch(t);
      expect(find.text('1 món'), findsOneWidget);
      await openFilter(t);
      expect(find.textContaining('Trứng'), findsOneWidget); // dòng phụ liệt kê chất
      await tapVisible(t, find.byType(Switch));
      await t.pump();
      expect(find.text('Xem 2 món'), findsOneWidget);
      expect(find.text('1 món'), findsOneWidget);
      await t.tap(find.text('Xem 2 món'));
      await t.pumpAndSettle();
      expect(find.text('2 món'), findsOneWidget);
    });
  });

  group('Sắp xếp', () {
    testWidgets('chọn "Calo: thấp → cao" đổi nhãn nút và thứ tự', (t) async {
      repo.recipes = [
        recipe(id: 'a', title: 'A', kcal: 900),
        recipe(id: 'b', title: 'B', kcal: 100),
      ];
      await pumpSearch(t);
      await t.tap(find.text('Phù hợp nhất'));
      await t.pumpAndSettle();
      expect(find.text('Sắp xếp theo'), findsOneWidget);
      // "→" vẽ bằng icon (font Be Vietnam Pro không có ký tự này)
      expect(
          find.descendant(
              of: find.byType(BottomSheet), matching: find.byIcon(Icons.arrow_forward)),
          findsNWidgets(2));
      expect(find.textContaining('→'), findsNothing);
      await t.tap(find.textContaining('Calo: thấp'));
      await t.pumpAndSettle();
      expect(find.text('Sắp xếp theo'), findsNothing);
      expect(find.textContaining('Calo: thấp'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget); // trên nút sắp xếp
      final a = t.getTopLeft(find.text('A')).dy;
      final b = t.getTopLeft(find.text('B')).dy;
      expect(b, lessThan(a));
    });
  });

  group('Điều hướng sau khi đóng sheet', () {
    testWidgets('chọn sắp xếp → vẫn ở tab Món ăn, mở lại được sheet', (t) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final router = await pumpTestApp(t,
          auth: FakeAuth(isLoggedIn: true), catalog: RecipeCatalog(repo: repo));
      await t.pumpAndSettle();
      String path() => router.routerDelegate.currentConfiguration.uri.path;

      for (var i = 0; i < 2; i++) {
        await t.tap(find.byIcon(Icons.swap_vert));
        await t.pumpAndSettle();
        expect(find.text('Sắp xếp theo'), findsOneWidget);
        await t.tap(find.textContaining(i == 0 ? 'Calo: thấp' : 'Nấu nhanh nhất'));
        await t.pumpAndSettle();
        expect(find.text('Sắp xếp theo'), findsNothing);
        expect(path(), '/recipes');
      }
    });
  });

  group('Dị ứng', () {
    Future<void> openAllergen(WidgetTester t) async {
      await t.tap(find.text('Khai báo dị ứng'));
      await t.pumpAndSettle();
    }

    testWidgets('lưu → chip đổi thành "Bỏ món dị ứng"', (t) async {
      await pumpSearch(t);
      await openAllergen(t);
      expect(find.text('Dị ứng của bạn'), findsOneWidget);
      expect(find.text('Trứng gà, vịt, cút'), findsOneWidget);
      await tapVisible(t, find.text('Trứng'));
      await t.tap(find.text('Lưu'));
      await t.pumpAndSettle();
      expect(repo.userAllergenIds, {2});
      expect(find.text('Dị ứng của bạn'), findsNothing);
      expect(find.text('Bỏ món dị ứng'), findsOneWidget);
    });

    testWidgets('bỏ chọn hết rồi lưu → xóa hết, chip về "Khai báo dị ứng"', (t) async {
      repo.userAllergenIds = {1, 2};
      await pumpSearch(t);
      // Mở từ dòng "sửa" trong sheet Bộ lọc
      await openFilter(t);
      await tapVisible(t, find.text('sửa'));
      await t.pumpAndSettle();
      await tapVisible(t, find.text('Trứng'));
      await tapVisible(t, find.text('Hải sản (Tôm, Cua, Mực, Cá)'));
      await t.tap(find.text('Lưu'));
      await t.pumpAndSettle();
      expect(repo.userAllergenIds, isEmpty);
      expect(find.textContaining('Chưa khai báo'), findsOneWidget); // dòng phụ sheet Bộ lọc
      await t.tap(find.byTooltip('Đóng'));
      await t.pumpAndSettle();
      expect(find.text('Khai báo dị ứng'), findsOneWidget);
    });

    testWidgets('lưu lỗi → giữ sheet và báo lỗi', (t) async {
      await pumpSearch(t);
      await openAllergen(t);
      repo.failWith = Exception('mất mạng');
      await tapVisible(t, find.text('Trứng'));
      await t.tap(find.text('Lưu'));
      await t.pumpAndSettle();
      expect(find.text('Dị ứng của bạn'), findsOneWidget);
      expect(find.text('Không lưu được. Thử lại.'), findsOneWidget);
      expect(find.text('Khai báo dị ứng'), findsOneWidget);
    });
  });
}
