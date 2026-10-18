import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';
import 'package:elytra/features/nutrition/nutrition_calculator.dart';
import 'package:elytra/features/onboarding/body_info.dart';

/// Màn Tạo tài khoản (frame RegisterScreen trong Elytra.fig)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _privacyTap = TapGestureRecognizer()..onTap = _showPrivacy;

  bool _agreed = false;
  bool _loading = false;
  String? _error;

  /// Bật khi Supabase yêu cầu xác nhận email (Confirm email đang bật)
  bool _needsConfirm = false;

  @override
  void initState() {
    super.initState();
    // Cập nhật trạng thái nút mỗi khi người dùng gõ
    for (final c in [_email, _password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      emailRegExp.hasMatch(_email.text.trim()) &&
      _password.text.length >= 8 &&
      _confirm.text == _password.text &&
      _agreed;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final needsConfirm = await authRepo.signUp(_email.text, _password.text);
      // Không cần xác nhận: Supabase đã tạo phiên → router tự chuyển sang /gate
      if (needsConfirm && mounted) setState(() => _needsConfirm = true);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPrivacy() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Text(
          'Điều khoản sử dụng và Chính sách quyền riêng tư của Elytra '
          '(nội dung sẽ được cập nhật).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AuthHeader(title: 'Tạo Tài Khoản', fallbackRoute: '/onboarding'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    const _PlanSummaryPill(),
                    const SizedBox(height: 8),
                    const Text('Lưu kế hoạch của bạn',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Tạo tài khoản để lưu kết quả và nhận gợi ý món ăn.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 20),
                    if (_needsConfirm) ...[
                      const _InfoBox(
                          'Kiểm tra email để kích hoạt tài khoản, rồi quay lại đăng nhập.'),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      AuthErrorBox(_error!),
                      const SizedBox(height: 16),
                    ],
                    const FieldLabel('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => emailRegExp.hasMatch((v ?? '').trim())
                          ? null
                          : 'Email chưa đúng định dạng',
                      decoration: authInputDecoration(
                          icon: Icons.mail_outline, hint: 'ban@email.com'),
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Mật khẩu'),
                    PasswordField(
                      controller: _password,
                      hint: 'Nhập mật khẩu',
                      helper: 'Tối thiểu 8 ký tự',
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').length >= 8
                          ? null
                          : 'Mật khẩu cần tối thiểu 8 ký tự',
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Nhập lại mật khẩu'),
                    PasswordField(
                      controller: _confirm,
                      hint: 'Nhập lại mật khẩu',
                      validator: (v) =>
                          v == _password.text ? null : 'Mật khẩu nhập lại không khớp',
                      onSubmitted: _submit,
                    ),
                    const SizedBox(height: 16),
                    _TermsRow(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v),
                      privacyTap: _privacyTap,
                    ),
                  ],
                ),
              ),
            ),
            // Vùng đáy cố định: link Đăng nhập + nút chính
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản?',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Đăng nhập',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                  PrimaryButton(
                    label: 'Tạo tài khoản',
                    loading: _loading,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip tóm tắt lộ trình lấy từ thể trạng đã khai báo
class _PlanSummaryPill extends StatelessWidget {
  const _PlanSummaryPill();

  static final _kg = NumberFormat('#,##0.#', 'vi');
  static final _kcal = NumberFormat('#,##0', 'vi');

  static String _text(BodyInfo info) => switch (info.goal) {
        Goal.loseWeight => 'Giảm về ${_kg.format(info.targetWeightKg ?? info.weightKg)} kg',
        Goal.gainWeight => 'Tăng lên ${_kg.format(info.targetWeightKg ?? info.weightKg)} kg',
        Goal.maintain =>
          'Duy trì ${_kcal.format(NutritionCalculator.compute(info).targetKcal.round())} kcal/ngày',
      };

  @override
  Widget build(BuildContext context) {
    final info = pendingBodyInfo.value;
    if (info == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 12, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(_text(info),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}

/// Ô tick đồng ý điều khoản; bấm vào chữ cũng tick được
class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.value,
    required this.onChanged,
    required this.privacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final TapGestureRecognizer privacyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: const BorderSide(color: AppColors.outlineStrong, width: 1.5),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text.rich(
                TextSpan(
                  text: 'Tôi đồng ý với Điều khoản sử dụng và ',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: 'Chính sách quyền riêng tư',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      recognizer: privacyTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Thông báo xanh (vd. "Kiểm tra email…")
class _InfoBox extends StatelessWidget {
  const _InfoBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }
}
