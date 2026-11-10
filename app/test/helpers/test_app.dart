import 'package:elytra/core/router.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_meal_log_repository.dart';

/// Trạng thái đăng nhập giả cho widget test.
class FakeAuth extends ChangeNotifier implements AuthGate {
  FakeAuth({required this.isLoggedIn});

  @override
  bool isLoggedIn;

  @override
  bool recovering = false;
}

/// Dựng app với router thật, catalog riêng và trang chủ giả (không gọi Supabase).
/// [store] null thì dùng store mới trên [FakeMealLogRepository], không hẹn giờ 0h.
Future<GoRouter> pumpTestApp(
  WidgetTester t, {
  required AuthGate auth,
  required RecipeCatalog catalog,
  DiaryStore? store,
  String initialLocation = '/recipes',
}) async {
  final diary = store ??
      DiaryStore(repo: FakeMealLogRepository(), scheduleMidnight: false);
  if (store == null) addTearDown(diary.dispose);
  final router = buildRouter(
    auth: auth,
    initialLocation: initialLocation,
    homeBuilder: (_) => const Text('HOME'),
  );
  addTearDown(router.dispose);
  await t.pumpWidget(MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => DiaryScope(
      store: diary,
      child: RecipeScope(catalog: catalog, child: child!),
    ),
  ));
  return router;
}
