import 'dart:async';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/food_search_repository.dart';
import 'package:elytra/features/meal_logs/log_meal_screen.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_food_search_repository.dart';
import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/meal_log_fixtures.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
  const today = '2026-11-11';
  late FakeMealLogRepository repo;
  late FakeRecipeRepository recipeRepo;
  late FakeFoodSearchRepository search;
  late DiaryStore store;

  setUp(() {
    repo = FakeMealLogRepository();
    recipeRepo = FakeRecipeRepository()
      ..recipes = [
        recipe(id: 'r1', title: 'Cá basa kho tộ'),
        recipe(
          id: 'r2',
          title: 'Phở gà',
          kcal: 332,
          protein: 31,
          carbs: 41,
          fat: 5,
        ),
      ];
    search = FakeFoodSearchRepository()
      ..dishes = [
        const FoodHit(
          id: 'd1',
          kind: FoodKind.dish,
          name: 'Phở bò',
          per100: Macros(kcal: 110, proteinG: 6, carbsG: 16, fatG: 2.6),
        ),
      ];
    store = DiaryStore(
      repo: repo,
      now: () => DateTime.utc(2026, 11, 11, 19),
      scheduleMidnight: false,
    );
  });
  tearDown(() => store.dispose());

  /// Màn gốc có nút mở /log (Navigator thường), để kiểm tra kết quả pop về.
  Future<List<Object?>> pumpLog(WidgetTester t, {double width = 390}) async {
    t.view.physicalSize = Size(width, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final results = <Object?>[];
    final catalog = RecipeCatalog(repo: recipeRepo);
    addTearDown(catalog.dispose);
    // Scope đặt trên Navigator giống app thật (MaterialApp.builder)
    await t.pumpWidget(
      MaterialApp(
        builder: (_, child) => DiaryScope(
          store: store,
          child: RecipeScope(catalog: catalog, child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final r = await Navigator.of(context).push(
                    MaterialPageRoute<Object?>(
                      builder: (_) => LogMealScreen(
                        meal: MealType.dinner,
                        date: today,
                        search: search,
                      ),
                    ),
                  );
                  results.add(r);
                },
                child: const Text('MỞ'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('MỞ'));
    await t.pumpAndSettle();
    return results;
  }

  Future<List<Object?>> openSheetFor(
    WidgetTester t,
    String name, {
    String? tab,
  }) async {
    final results = await pumpLog(t);
    if (tab != null) {
      await t.tap(find.text(tab));
      await t.pumpAndSettle();
    }
    await t.tap(find.text(name));
    await t.pumpAndSettle();
    return results;
  }

  Finder addButton([String label = 'Thêm vào bữa tối']) =>
      find.widgetWithText(FilledButton, label);

  List<(String, Object)> adds() => [
    for (final c in repo.calls)
      if (c.$1 == 'add') c,
  ];

  testWidgets('chưa nhập: tab Món nấu có nhãn Gợi ý, dòng macro và kcal/phần', (
    t,
  ) async {
    await pumpLog(t);
    expect(find.text('Gợi ý'), findsOneWidget);
    expect(find.text('P 39 · C 6 · F 7 g'), findsOneWidget);
    expect(find.text('kcal/phần'), findsNWidgets(2));
    expect(find.text('Hôm nay · bữa tối còn 590 kcal'), findsOneWidget);
  });

  testWidgets('bấm Thêm 2 lần chỉ 1 request, nút hiện Đang thêm…', (t) async {
    repo.gate = Completer();
    await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(addButton());
    await t.pump();
    expect(find.text('Đang thêm…'), findsOneWidget);
    await t.tap(find.text('Đang thêm…'), warnIfMissed: false);
    await t.pump();
    expect(adds(), hasLength(1));
    repo.gate!.complete();
    await t.pumpAndSettle();
  });

  testWidgets('thêm thành công: đóng sheet, pop màn kèm LogMealResult', (
    t,
  ) async {
    final results = await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(find.text('1½'));
    await t.pump();
    await t.tap(addButton());
    await t.pumpAndSettle();
    expect(find.byType(LogMealScreen), findsNothing);
    expect(results, hasLength(1));
    final r = results.single as LogMealResult;
    expect(r.name, 'Cá basa kho tộ');
    final req = (adds().single.$2 as (LogRequest, String)).$1;
    expect(
      req,
      const LogRequest.recipe(
        refId: 'r1',
        servings: 1.5,
        meal: MealType.dinner,
        date: today,
      ),
    );
  });

  testWidgets('chip bữa trong sheet đổi bữa của request và nhãn nút', (
    t,
  ) async {
    await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(find.text('Sáng'));
    await t.pump();
    await t.tap(addButton('Thêm vào bữa sáng'));
    await t.pumpAndSettle();
    expect(
      (adds().single.$2 as (LogRequest, String)).$1.meal,
      MealType.breakfast,
    );
  });

  testWidgets('ô gam: 0 và 2001 khoá nút, có dòng giới hạn', (t) async {
    await openSheetFor(t, 'Phở bò', tab: 'Món ăn sẵn');
    for (final v in ['0', '2001', '']) {
      await t.enterText(find.byType(TextField).last, v);
      await t.pump();
      expect(
        t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text('Nhập từ 1 đến 2.000 g.'), findsOneWidget);
    }
    await t.enterText(find.byType(TextField).last, '400');
    await t.pump();
    expect(
      t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(find.text('440'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('10,4'), findsOneWidget);
  });

  testWidgets('xem trước 1,5 phần', (t) async {
    await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(find.text('1½'));
    await t.pump();
    expect(find.text('360'), findsOneWidget);
    expect(find.text('58,5'), findsOneWidget);
    expect(
      find.text('Sau khi thêm: bữa tối còn 230 kcal · cả ngày còn 1.608 kcal'),
      findsOneWidget,
    );
  });

  testWidgets('stepper dừng ở 0,25', (t) async {
    await openSheetFor(t, 'Cá basa kho tộ');
    for (var i = 0; i < 6; i++) {
      await t.tap(find.byTooltip('Bớt'), warnIfMissed: false);
      await t.pump();
    }
    expect(find.text('0,25'), findsOneWidget);
  });

  testWidgets('mất mạng khi thêm: giữ sheet, báo lỗi, retry giữ khoá', (
    t,
  ) async {
    repo.failOnce['add'] = const MealLogOffline();
    await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(addButton());
    await t.pumpAndSettle();
    expect(find.text('Không có mạng. Thử lại'), findsOneWidget);
    expect(addButton(), findsOneWidget);
    await t.tap(addButton());
    await t.pumpAndSettle();
    final keys = [for (final a in adds()) (a.$2 as (LogRequest, String)).$2];
    expect(keys, hasLength(2));
    expect(keys[0], keys[1]);
  });

  testWidgets('rời màn sau lỗi mạng không lỗi framework và làm mới ngày', (
    t,
  ) async {
    repo.failOnce['add'] = const MealLogOffline();
    await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(addButton());
    await t.pumpAndSettle();
    repo.calls.clear();
    // Đóng cả sheet lẫn màn cùng lúc
    Navigator.of(t.element(find.text('Cá basa kho tộ').last))
        .popUntil((r) => r.isFirst);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('MỞ'), findsOneWidget);
    expect(
      repo.calls.where((c) => c.$1 == 'getDay' && c.$2 == today),
      isNotEmpty,
    );
  });

  testWidgets('PROFILE_NOT_FOUND khi thêm: đóng sheet và màn', (t) async {
    repo.failOnce['add'] = const MealLogProfileMissing();
    final results = await openSheetFor(t, 'Cá basa kho tộ');
    await t.tap(addButton());
    await t.pumpAndSettle();
    expect(find.byType(LogMealScreen), findsNothing);
    expect(results, [null]);
  });

  testWidgets('không có kết quả', (t) async {
    await pumpLog(t);
    await t.enterText(find.byType(TextField).first, 'zzz');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.textContaining('Không tìm thấy'), findsOneWidget);
    // Gợi ý thử tab khác: chạm chip thì chuyển tab
    await t.tap(find.widgetWithText(OutlinedButton, 'Món ăn sẵn'));
    await t.pumpAndSettle();
    expect(search.calls.last.$1, 'search_dishes');
  });

  testWidgets('có kết quả: nhãn số kết quả cho từ khoá', (t) async {
    await pumpLog(t);
    await t.tap(find.text('Món ăn sẵn'));
    await t.pumpAndSettle();
    expect(find.text('Món ăn sẵn (A–Z)'), findsOneWidget);
    await t.enterText(find.byType(TextField).first, 'pho');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('1 kết quả cho “pho”'), findsOneWidget);
    expect(find.text('kcal/100 g'), findsOneWidget);
  });

  testWidgets('mất mạng khi tìm: khối lỗi + Thử lại trong tab', (t) async {
    search.failWith = const FoodSearchOffline();
    await pumpLog(t);
    await t.tap(find.text('Món ăn sẵn'));
    await t.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    search.failWith = null;
    await t.tap(find.text('Thử lại'));
    await t.pumpAndSettle();
    expect(find.text('Phở bò'), findsOneWidget);
  });

  testWidgets('tải thêm lỗi: dòng Thử lại cuối danh sách', (t) async {
    search.dishes = [
      for (var i = 0; i < 25; i++) hit('Món ${i.toString().padLeft(2, '0')}'),
    ];
    await pumpLog(t);
    await t.tap(find.text('Món ăn sẵn'));
    await t.pumpAndSettle();
    search.failWith = const FoodSearchOffline();
    await t.dragUntilVisible(
      find.text('Món 19'),
      find.byType(Scrollable).last,
      const Offset(0, -300),
    );
    await t.pumpAndSettle();
    await t.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await t.pumpAndSettle();
    expect(find.text('Không tải thêm được. Thử lại'), findsOneWidget);
    search.failWith = null;
    await t.tap(find.text('Không tải thêm được. Thử lại'));
    await t.pumpAndSettle();
    await t.drag(find.byType(Scrollable).last, const Offset(0, -2000));
    await t.pumpAndSettle();
    expect(find.text('Món 24'), findsOneWidget);
  });

  testWidgets('đổi bữa ở tiêu đề', (t) async {
    await pumpLog(t);
    await t.tap(find.text('Thêm vào bữa tối'));
    await t.pumpAndSettle();
    await t.tap(find.text('Bữa trưa').last);
    await t.pumpAndSettle();
    expect(find.text('Thêm vào bữa trưa'), findsOneWidget);
  });

  testWidgets('màn hẹp 320: danh sách và sheet gam không tràn', (t) async {
    await pumpLog(t, width: 320);
    await t.tap(find.text('Món ăn sẵn'));
    await t.pumpAndSettle();
    await t.tap(find.text('Phở bò'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Khối lượng ăn được'), findsOneWidget);
  });
}
