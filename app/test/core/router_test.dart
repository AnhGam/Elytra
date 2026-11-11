import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/router.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_recipe_repository.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('chưa đăng nhập vào /recipes → /welcome', (t) async {
    final r = await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: false),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()));
    await t.pumpAndSettle();
    expect(r.routerDelegate.currentConfiguration.uri.path, '/welcome');
  });

  testWidgets('đã đăng nhập: /home mở trong shell có 4 tab', (t) async {
    await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()),
        initialLocation: '/home');
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final l in ['Trang chủ', 'Nhật ký', 'Món ăn', 'Cá nhân']) {
      expect(find.text(l), findsOneWidget);
    }
  });

  testWidgets('Back ở tab khác Trang chủ → về Trang chủ', (t) async {
    final r = await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()),
        initialLocation: '/diary');
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(r.routerDelegate.currentConfiguration.uri.path, '/home');
  });

  testWidgets('/recipes/:id che thanh điều hướng', (t) async {
    await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()),
        initialLocation: '/recipes/r1');
    await t.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('/log che thanh tab', (t) async {
    final r = await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()),
        initialLocation: '/home');
    await t.pumpAndSettle();
    r.push('/log?meal=dinner&date=2026-11-11');
    await t.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('tham số /log sai thì dùng mặc định', () {
    final now = DateTime.utc(2026, 11, 11, 19);
    expect(parseLogParams({'meal': 'brunch', 'date': '2026-12-01'}, now),
        (meal: MealType.dinner, date: '2026-11-11'));
    expect(parseLogParams({'meal': 'lunch', 'date': '2026-10-12'}, now),
        (meal: MealType.lunch, date: '2026-10-12'));
    expect(parseLogParams({'date': '2026-10-11'}, now).date, '2026-11-11');
    expect(parseLogParams({'date': 'abc'}, now).date, '2026-11-11');
  });

  testWidgets('/diary không còn là "Sắp có"', (t) async {
    await pumpTestApp(t,
        auth: FakeAuth(isLoggedIn: true),
        catalog: RecipeCatalog(repo: FakeRecipeRepository()),
        initialLocation: '/diary');
    await t.pumpAndSettle();
    expect(find.text('Sắp có'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
