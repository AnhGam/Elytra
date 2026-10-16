import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/auth_repository.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';

Future<void> showForgotPasswordSheet(BuildContext context, String email) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ForgotPasswordSheet(initialEmail: email),
    );

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _valid => emailRegExp.hasMatch(_email.text.trim());

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await authRepo.sendResetEmail(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(top: false, child: _sent ? _buildSent() : _buildForm()),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quên mật khẩu?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Nhập email, Elytra sẽ gửi link đặt lại mật khẩu.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          AuthErrorBox(_error!),
          const SizedBox(height: 16),
        ],
        const FieldLabel('Email'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _valid ? _send() : null,
          decoration: authInputDecoration(
            icon: Icons.mail_outline,
            hint: 'ban@email.com',
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Gửi link đặt lại',
          loading: _sending,
          onPressed: _valid ? _send : null,
        ),
      ],
    );
  }

  Widget _buildSent() {
    const muted = TextStyle(
      fontSize: 13,
      height: 1.6,
      color: AppColors.textMuted,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primaryDark,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kiểm tra email của bạn',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đã gửi link đặt lại mật khẩu tới',
          textAlign: TextAlign.center,
          style: muted,
        ),
        Text(
          _email.text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: muted.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Text(
          'Link có hiệu lực trong 1 giờ.',
          textAlign: TextAlign.center,
          style: muted,
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AuthErrorBox(_error!),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chưa nhận được email?',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: _sending ? null : _send,
              child: const Text(
                'Gửi lại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Đã hiểu',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
