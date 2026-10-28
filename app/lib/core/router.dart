import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:elytra/core/app_shell.dart';
import 'package:elytra/core/coming_soon_screen.dart';
import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/features/auth/login_screen.dart';
import 'package:elytra/features/auth/profile_gate.dart';
import 'package:elytra/features/auth/register_screen.dart';
import 'package:elytra/features/auth/reset_password_screen.dart';
import 'package:elytra/features/home/home_placeholder.dart';
import 'package:elytra/features/nutrition/result_screen.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_screen.dart';
import 'package:elytra/features/onboarding/welcome_screen.dart';
import 'package:elytra/features/recipes/recipe_search_screen.dart';
import 'package:elytra/main.dart';

/// Trạng thái đăng nhập mà router cần; tách ra để widget test dùng bản giả
abstract class AuthGate implements Listenable {
  bool get isLoggedIn;
  bool get recovering;
}

/// Lắng nghe auth để go_router tự chạy lại redirect khi đăng nhập/đăng xuất
class AuthNotifier extends ChangeNotifier implements AuthGate {
  /// Bật khi người dùng mở app từ link đặt lại mật khẩu (4.6)
  @override
  bool recovering = false;

  @override
  bool get isLoggedIn => supabase.auth.currentSession != null;

  AuthNotifier() {
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) recovering = true;
      notifyListeners();
    });
  }

  void finishRecovery() {
    recovering = false;
    notifyListeners();
  }
}

final authNotifier = AuthNotifier();

/// Màn vào được khi chưa đăng nhập: khai báo thể trạng và xem kết quả trước
const publicRoutes = {'/welcome', '/onboarding', '/result', '/register', '/login'};

/// Màn chỉ dành cho người chưa đăng nhập
const guestOnlyRoutes = {'/welcome', '/register', '/login'};

GoRouter buildRouter({
  required AuthGate auth,
  String initialLocation = '/welcome',
  WidgetBuilder? homeBuilder,
}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final loc = state.matchedLocation;
      // Đang đặt lại mật khẩu: chỉ ở lại màn đặt mật khẩu mới
      if (auth.recovering) {
        return loc == '/reset-password' ? null : '/reset-password';
      }
      if (!loggedIn && !publicRoutes.contains(loc)) return '/welcome';
      if (loggedIn && guestOnlyRoutes.contains(loc)) return '/gate';
      // Muốn đăng ký phải khai báo thể trạng trước (chặn cả back, deep link)
      if (loc == '/register' && pendingBodyInfo.value == null) return '/onboarding';
      // /result cần dữ liệu thể trạng; mất dữ liệu (vd. hot restart) thì khai báo lại
      if (loc == '/result' && state.extra is! BodyInfo) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const BodyInfoScreen()),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(input: state.extra as BodyInfo),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/reset-password', builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: '/gate', builder: (_, _) => const ProfileGate()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, _) =>
                  homeBuilder?.call(context) ?? const HomePlaceholder(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/diary',
              builder: (_, _) => const ComingSoonScreen(title: 'Nhật ký'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/recipes',
              builder: (_, _) => const RecipeSearchScreen(),
              routes: [
                // Chi tiết món nằm trên root navigator để che thanh điều hướng
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootKey,
                  builder: (_, state) =>
                      ComingSoonScreen(title: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ComingSoonScreen(title: 'Cá nhân'),
            ),
          ]),
        ],
      ),
    ],
  );
}

final router = buildRouter(auth: authNotifier);
