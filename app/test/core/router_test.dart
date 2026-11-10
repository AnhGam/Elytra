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
}
