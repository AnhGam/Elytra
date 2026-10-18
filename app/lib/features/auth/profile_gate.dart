import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/features/nutrition/nutrition_repository.dart';
import 'package:elytra/main.dart';

/// Màn chờ ngắn ngay sau đăng ký/đăng nhập, quyết định màn tiếp theo.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

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
        if (mounted) context.go('/home');
        return;
      }
      // 2. Đăng nhập lại: đã có hồ sơ thì vào Home, chưa có thì khai báo.
      // Bảng `profiles` có trigger tạo sẵn 1 dòng khi đăng ký, nên "có dòng"
      // chưa có nghĩa là đã khai báo: kiểm tra thêm target_calories.
      final row = await supabase
          .from('profiles')
          .select('target_calories')
          .eq('id', supabase.auth.currentUser!.id)
          .maybeSingle();
      if (!mounted) return;
      final hasProfile = row != null && row['target_calories'] != null;
      context.go(hasProfile ? '/home' : '/onboarding');
    } catch (e) {
      // Lỗi: giữ nguyên pendingBodyInfo để người dùng không phải khai báo lại
      if (mounted) setState(() => _error = 'Không lưu được hồ sơ. Kiểm tra mạng và thử lại.');
    }
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
