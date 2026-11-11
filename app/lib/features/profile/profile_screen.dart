import 'package:flutter/material.dart';

import 'package:elytra/core/greeting.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';

/// Tab Cá nhân bản tối thiểu: tên (hoặc email nhỏ) và nút Đăng xuất.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.signOut, this.email});

  /// Mặc định `authRepo.signOut` (tiêm vào để test).
  final Future<void> Function()? signOut;

  /// Mặc định email của phiên hiện tại (tiêm vào để test, tránh chạm Supabase).
  final String? Function()? email;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    // Tải hồ sơ để có tên; không chờ, lỗi thì chỉ hiện email
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RecipeScope.maybeOf(context)?.ensureLoaded().catchError((Object _) {});
    });
  }

  Future<void> _onSignOut() async {
    setState(() => _signingOut = true);
    try {
      // Gửi hết các lệnh xoá đang chờ Hoàn tác trước khi mất phiên
      await DiaryScope.of(context).flushPendingDeletes();
      await (widget.signOut ?? authRepo.signOut)();
      // Router thấy mất phiên → tự đưa về /welcome
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đăng xuất được. Thử lại sau.')),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName(RecipeScope.maybeOf(context)?.profile?.fullName);
    final email = (widget.email ?? () => authRepo.currentEmail)();
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (name != null)
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
              else if (email != null)
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: AppColors.textMuted,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _signingOut ? null : _onSignOut,
                  child: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
