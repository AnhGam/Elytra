import 'package:elytra/core/router.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Trạng thái đăng nhập giả cho widget test.
class FakeAuth extends ChangeNotifier implements AuthGate {
  FakeAuth({required this.isLoggedIn});

  @override
  bool isLoggedIn;

  @override
  bool recovering = false;
}

/// Dựng app với router thật, catalog riêng và trang chủ giả (không gọi Supabase).
Future<GoRouter> pumpTestApp(
  WidgetTester t, {
  required AuthGate auth,
  required RecipeCatalog catalog,
  String initialLocation = '/recipes',
}) async {
  final router = buildRouter(
    auth: auth,
    initialLocation: initialLocation,
    homeBuilder: (_) => const Text('HOME'),
  );
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => RecipeScope(catalog: catalog, child: child!),
  ));
  return router;
}
