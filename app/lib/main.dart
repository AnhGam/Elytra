import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elytra/core/router.dart';
import 'package:elytra/core/theme.dart';
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

  @override
  void dispose() {
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
      builder: (context, child) => RecipeScope(catalog: _catalog, child: child!),
    );
  }
}
