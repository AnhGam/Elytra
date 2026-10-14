import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/pending_onboarding.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';
import 'package:elytra/features/onboarding/body_info.dart';

/// Màn Đăng nhập (frame LoginScreen trong Elytra.fig)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Cập nhật trạng thái nút mỗi khi người dùng gõ
    for (final c in [_email, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Nút chỉ bấm được khi email hợp lệ và đã nhập mật khẩu
  bool get _canSubmit =>
      emailRegExp.hasMatch(_email.text.trim()) && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await authRepo.signIn(_email.text, _password.text);
      // Thành công: router thấy có phiên → tự chuyển sang /gate
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _forgotPassword() {
    // TODO(4.6): showForgotPasswordSheet(context, _email.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng quên mật khẩu sắp có.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AuthHeader(title: 'Đăng Nhập', fallbackRoute: '/welcome'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
                  children: [
                    const Text('Chào mừng trở lại',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Đăng nhập để xem kế hoạch dinh dưỡng của bạn.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 20),
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
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                      onSubmitted: _submit,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Quên mật khẩu?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  // Chỉ hiện khi đã khai báo thể trạng (vào từ màn Tạo tài khoản)
                  ValueListenableBuilder<BodyInfo?>(
                    valueListenable: pendingBodyInfo,
                    builder: (context, info, _) {
                      if (info == null) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            children: [
                              TextSpan(
                                text: 'Tạo tài khoản',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  PrimaryButton(
                    label: 'Đăng nhập',
                    loading: _loading,
                    // Chưa nhập đủ: nút xanh nhạt 40% và không bấm được
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
