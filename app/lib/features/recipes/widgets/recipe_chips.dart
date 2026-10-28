import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Chip hình viên thuốc cao 32, vùng chạm cao 48
class _Pill extends StatelessWidget {
  const _Pill({
    required this.selected,
    required this.onTap,
    required this.background,
    required this.border,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            // widthFactor 1: chip ôm nội dung, không giãn hết chiều ngang (vd. trong Wrap)
            widthFactor: 1,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip lọc nhanh: đang bật thì nền xanh nhạt và có dấu tích
class QuickFilterChip extends StatelessWidget {
  const QuickFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Icon đầu chip khi chưa bật (vd. dấu + của "Khai báo dị ứng")
  final IconData? icon;

  /// Kiểu trong sheet Bộ lọc: chữ 13, chip thường màu textSecondary
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primaryDark
        : (compact ? AppColors.textSecondary : AppColors.textPrimary);
    final leading = selected ? Icons.check : icon;
    return _Pill(
      selected: selected,
      onTap: onTap,
      background: selected ? AppColors.primaryContainer : AppColors.surface,
      border: selected ? AppColors.primaryOutline : AppColors.outlineStrong,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip nhóm món: đang chọn thì nền đậm chữ trắng
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pill(
      selected: selected,
      onTap: onTap,
      background: selected ? AppColors.textPrimary : AppColors.surfaceVariant,
      border: selected ? AppColors.textPrimary : AppColors.outline,
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.surface : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
