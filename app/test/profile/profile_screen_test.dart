import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/profile/profile_screen.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/meal_log_fixtures.dart';

void main() {
  late FakeMealLogRepository repo;
  late DiaryStore store;
  late FakeRecipeRepository recipes;

  setUp(() {
    repo = FakeMealLogRepository();
    store = DiaryStore(repo: repo, scheduleMidnight: false);
    recipes = FakeRecipeRepository();
  });
  tearDown(() => store.dispose());

  Widget wrap(Widget child) => MaterialApp(
        home: DiaryScope(
          store: store,
          child: RecipeScope(catalog: RecipeCatalog(repo: recipes), child: child),
        ),
      );

  testWidgets('Đăng xuất gửi DELETE treo trước signOut', (t) async {
    final order = <String>[];
    store.deleteDeferred(item(id: 'a'), date: store.today);
    repo.onDelete = (_) => order.add('delete');
    await t.pumpWidget(wrap(ProfileScreen(
      email: () => 'sv@uit.edu.vn',
      signOut: () async => order.add('signOut'),
    )));
    await t.tap(find.text('Đăng xuất'));
    await t.pumpAndSettle();
    expect(order, ['delete', 'signOut']);
  });

  testWidgets('có tên thì hiện tên, không hiện email', (t) async {
    recipes.profile = const UserNutritionProfile(fullName: 'Nguyễn Văn An');
    await t.pumpWidget(wrap(ProfileScreen(email: () => 'sv@uit.edu.vn', signOut: () async {})));
    await t.pumpAndSettle();
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('sv@uit.edu.vn'), findsNothing);
  });

  testWidgets('tên là email thì chỉ hiện email nhỏ', (t) async {
    recipes.profile = const UserNutritionProfile(fullName: 'sv@uit.edu.vn');
    await t.pumpWidget(wrap(ProfileScreen(email: () => 'sv@uit.edu.vn', signOut: () async {})));
    await t.pumpAndSettle();
    expect(find.text('sv@uit.edu.vn'), findsOneWidget);
  });

  testWidgets('đang đăng xuất thì nút bị khoá', (t) async {
    var calls = 0;
    final gate = Future<void>.delayed(const Duration(seconds: 1));
    await t.pumpWidget(wrap(ProfileScreen(
      email: () => null,
      signOut: () async {
        calls++;
        await gate;
      },
    )));
    await t.tap(find.text('Đăng xuất'));
    await t.pump();
    await t.tap(find.text('Đăng xuất'), warnIfMissed: false);
    await t.pump(const Duration(seconds: 2));
    expect(calls, 1);
  });
}
