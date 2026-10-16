import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/router.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';

/// Màn Đặt mật khẩu mới: mở khi người dùng bấm link trong email
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _password.text.length >= 8 && _confirm.text == _password.text;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || !_canSave) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await authRepo.updatePassword(_password.text);
      authNotifier.finishRecovery(); // tắt cờ → router hết ép vào màn này
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu.')));
      context.go('/gate');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Bỏ đặt lại: đăng xuất phiên tạm để không lọt vào Home
  Future<void> _cancel() async {
    await authRepo.signOut();
    authNotifier.finishRecovery();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    // Chặn cử chỉ vuốt Back của Android, cho chạy _cancel thay vào đó
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AuthHeader(
                title: 'Đặt Mật Khẩu Mới',
                fallbackRoute: '/login',
                onBack: _cancel,
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
                    children: [
                      const Text('Tạo mật khẩu mới',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text('Mật khẩu mới phải khác mật khẩu cũ.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        AuthErrorBox(_error!),
                        const SizedBox(height: 16),
                      ],
                      const FieldLabel('Mật khẩu mới'),
                      PasswordField(
                        controller: _password,
                        hint: 'Nhập mật khẩu mới',
                        helper: 'Tối thiểu 8 ký tự',
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v ?? '').length >= 8
                            ? null
                            : 'Mật khẩu cần tối thiểu 8 ký tự',
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Nhập lại mật khẩu mới'),
                      PasswordField(
                        controller: _confirm,
                        hint: 'Nhập lại mật khẩu mới',
                        validator: (v) =>
                            v == _password.text ? null : 'Mật khẩu nhập lại không khớp',
                        onSubmitted: _save,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: PrimaryButton(
                  label: 'Lưu mật khẩu mới',
                  loading: _saving,
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
