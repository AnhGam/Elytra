import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elytra/core/router.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_repository.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  runApp(const ElytraApp());
}

final supabase = Supabase.instance.client;

class ElytraApp extends StatefulWidget {
  const ElytraApp({super.key});

  @override
  State<ElytraApp> createState() => _ElytraAppState();
}

class _ElytraAppState extends State<ElytraApp> {
  // Bộ nhớ đệm món ăn dùng chung cả app; tự xóa khi đăng xuất/đổi tài khoản
  late final RecipeCatalog _catalog = RecipeCatalog(
    repo: recipeRepo,
    userIdChanges: supabase.auth.onAuthStateChange.map((s) => s.session?.user.id),
  );

  // Nhật ký bữa ăn dùng chung cả app; tự xoá khi đăng xuất/đổi tài khoản
  late final DiaryStore _diary = DiaryStore(
    repo: mealLogRepo,
    userIdChanges: supabase.auth.onAuthStateChange.map((s) => s.session?.user.id),
  );

  // Quay lại app thì kiểm tra đã sang ngày mới chưa
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _diary.checkDayChange);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _diary.dispose();
    _catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Elytra',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) => DiaryScope(
        store: _diary,
        child: RecipeScope(catalog: _catalog, child: child!),
      ),
    );
  }
}
