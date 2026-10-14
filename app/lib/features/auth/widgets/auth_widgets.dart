import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/theme.dart';

/// Kiểm tra email đơn giản: có dạng a@b.c
final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Thanh trên: nút Quay lại (40x40) + tiêu đề 20 Bold
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.fallbackRoute});

  final String title;

  /// Nơi quay về khi không có màn trước trong ngăn xếp (vd. mở thẳng bằng go)
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(fallbackRoute),
          ),
          const SizedBox(width: 4),
          Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Nhãn phía trên ô nhập (13 SemiBold)
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

/// Kiểu ô nhập theo thiết kế: cao 52, bo 14, viền #E8EEF4, icon đầu dòng
InputDecoration authInputDecoration({
  required IconData icon,
  String? hint,
  String? helper,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.outlineStrong),
    helperText: helper,
    helperStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    prefixIcon: Icon(icon, size: 18, color: AppColors.textSubtle),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
    enabledBorder: border(AppColors.outline),
    focusedBorder: border(AppColors.primary, 1.5),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, 1.5),
    // Lỗi có cả icon (qua errorText) và chữ, không chỉ dựa vào màu đỏ
    errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
  );
}

/// Ô mật khẩu có nút mắt ẩn/hiện
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.hint,
    this.helper,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: widget.validator,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: authInputDecoration(
        icon: Icons.lock_outline,
        hint: widget.hint,
        helper: widget.helper,
        suffix: IconButton(
          tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.textSubtle,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Nút chính: cao 56, bo tròn, xoay vòng khi đang gọi
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // Khi khóa (đang gọi / form chưa hợp lệ): vẫn xanh nhưng nhạt đi,
          // thay vì màu xám mặc định của Flutter
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        // Đang gọi thì khóa nút để tránh bấm hai lần
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

/// Thông báo lỗi từ server: icon + chữ đỏ trên nền hồng nhạt
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
