import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'package:elytra/main.dart';

/// Lắng nghe auth để go_router tự chạy lại redirect khi đăng nhập/đăng xuất
class AuthNotifier extends ChangeNotifier {
  /// Bật khi người dùng mở app từ link đặt lại mật khẩu (4.6)
  bool recovering = false;

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

final router = GoRouter(
  initialLocation: '/welcome',
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final loc = state.matchedLocation;
    // Đang đặt lại mật khẩu: chỉ ở lại màn đặt mật khẩu mới
    if (authNotifier.recovering) {
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
    GoRoute(path: '/home', builder: (_, _) => const HomePlaceholder()),
  ],
);
