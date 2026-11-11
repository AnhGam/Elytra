import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/nutrition/nutrition_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/main.dart';

/// Màn chờ ngắn ngay sau đăng ký/đăng nhập, quyết định màn tiếp theo.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, this.hasProfile});

  /// Đã khai báo thể trạng chưa; mặc định hỏi bảng `profiles` (tiêm vào để test).
  final Future<bool> Function()? hasProfile;

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    setState(() => _error = null);
    try {
      // 1. Vừa khai báo thể trạng rồi đăng ký/đăng nhập: lưu hồ sơ trước
      final pending = pendingBodyInfo.value;
      if (pending != null) {
        await nutritionRepo.save(pending); // ghi thể trạng + mục tiêu vào profiles
        pendingBodyInfo.value = null; // chỉ xóa SAU KHI lưu thành công
        if (!mounted) return;
        // Mục tiêu vừa đổi: bỏ hồ sơ và nhật ký cũ trong bộ nhớ đệm để lần sau tải lại
        RecipeScope.maybeOf(context)?.clear();
        DiaryScope.maybeOf(context)?.clear();
        context.go('/home');
        return;
      }
    } catch (e) {
      // Lỗi: giữ nguyên pendingBodyInfo để người dùng không phải khai báo lại
      if (mounted) setState(() => _error = 'Không lưu được hồ sơ. Kiểm tra mạng và thử lại.');
      return;
    }
    // 2. Đăng nhập lại / mở lại app: đã có hồ sơ thì vào Home, chưa có thì khai báo.
    bool hasProfile;
    try {
      hasProfile = await (widget.hasProfile ?? _hasProfileInDb)();
    } catch (_) {
      // Không kiểm tra được (thường là mất mạng): vẫn vào Home. Dashboard tự hiện
      // khối mất mạng + Thử lại, hoặc nút "Khai báo thể trạng" khi server báo
      // PROFILE_NOT_FOUND, nên không cần chặn ở đây.
      hasProfile = true;
    }
    if (!mounted) return;
    context.go(hasProfile ? '/home' : '/onboarding');
  }

  // Bảng `profiles` có trigger tạo sẵn 1 dòng khi đăng ký, nên "có dòng"
  // chưa có nghĩa là đã khai báo: kiểm tra thêm target_calories.
  static Future<bool> _hasProfileInDb() async {
    final row = await supabase
        .from('profiles')
        .select('target_calories')
        .eq('id', supabase.auth.currentUser!.id)
        .maybeSingle();
    return row != null && row['target_calories'] != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _decide, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}
