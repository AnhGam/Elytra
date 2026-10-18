import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/steps/step1_basic_info.dart';
import 'package:elytra/features/onboarding/steps/step2_body_metrics.dart';
import 'package:elytra/features/onboarding/steps/step3_activity.dart';
import 'package:elytra/features/onboarding/steps/step4_goal.dart';
import 'package:elytra/features/onboarding/steps/step5_target_weight.dart';
import 'package:elytra/features/onboarding/steps/step6_workout_plan.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';
import 'package:elytra/main.dart';

/// Wizard khai báo thể trạng: 4 bước (Duy trì) hoặc 6 bước (Giảm / Tăng cân).
/// Phần "khung" (thanh trên, thanh tiến độ, nút đáy) dùng chung cho mọi bước;
/// nội dung từng bước nằm trong thư mục steps/.
class BodyInfoScreen extends StatefulWidget {
  const BodyInfoScreen({super.key});

  @override
  State<BodyInfoScreen> createState() => _BodyInfoScreenState();
}

class _BodyInfoScreenState extends State<BodyInfoScreen> {
  // Đã khai báo trước đó (vd. quay lại từ màn Đăng ký) thì điền lại dữ liệu cũ
  late final BodyInfoDraft _draft = pendingBodyInfo.value != null
      ? BodyInfoDraft.from(pendingBodyInfo.value!)
      : BodyInfoDraft();
  final _pages = PageController();
  int _step = 1;

  @override
  void dispose() {
    _pages.dispose();
    _draft.dispose();
    super.dispose();
  }

  /// Tiêu đề thanh trên và nhãn xám bên phải cho từng bước
  (String, String) _labels(int step) {
    final route = _draft.goal == Goal.gainWeight
        ? 'Lộ trình tăng cân'
        : 'Lộ trình giảm cân';
    return switch (step) {
      1 => ('Hồ Sơ Cá Nhân', 'Chuẩn hóa BMR'),
      2 => ('Chỉ Số Cá Nhân', 'Thể trạng cơ bản'),
      3 => ('Thói Quen Vận Động', 'Hệ số vận động'),
      4 => ('Mục Tiêu Của Bạn', 'Mục tiêu calo'),
      5 => ('Cân Nặng Mục Tiêu', route),
      _ => ('Kế Hoạch Tập Luyện', route),
    };
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pages.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_step < _draft.totalSteps) {
      _goTo(_step + 1);
    } else {
      context.push('/result', extra: _draft.toBodyInfo());
    }
  }

  Future<void> _back() async {
    if (_step > 1) {
      _goTo(_step - 1);
      return;
    }
    // Bước 1: đã đăng nhập (nhưng chưa có hồ sơ) thì hỏi có muốn đăng xuất
    if (supabase.auth.currentSession != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text(
            'Bạn cần khai báo thể trạng để dùng Elytra. '
            'Thoát bây giờ sẽ đăng xuất khỏi tài khoản.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ở lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );
      if (ok == true) await authRepo.signOut(); // router tự về /welcome
      return;
    }
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    // Mỗi lần bản nháp đổi (chọn giới tính, đổi tuổi…), cả màn vẽ lại
    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        final total = _draft.totalSteps;
        final (title, pill) = _labels(_step);
        final isLast = _step == total;
        return PopScope(
          canPop: false, // tự xử lý nút Back của Android ở _back()
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: title,
                    fallbackRoute: '/welcome',
                    onBack: _back,
                  ),
                  // Thanh tiến độ cao 6
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _step / total,
                        minHeight: 6,
                        color: AppColors.primary,
                        backgroundColor: AppColors.outline,
                      ),
                    ),
                  ),
                  // "Bước x/y" + nhãn xám
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'Bước $_step/$total',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const Spacer(),
                        InfoPill(pill),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nội dung từng bước; chỉ chuyển bằng nút, không vuốt ngang
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Step1BasicInfo(draft: _draft),
                        Step2BodyMetrics(draft: _draft),
                        Step3Activity(draft: _draft),
                        Step4Goal(draft: _draft),
                        Step5TargetWeight(draft: _draft),
                        Step6WorkoutPlan(draft: _draft),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: PrimaryButton(
                      label: isLast ? 'Xem kết quả' : 'Tiếp tục',
                      onPressed: _draft.isStepValid(_step) ? _next : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
