import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';

/// Một dòng macro: "68,4 / 130 g", thanh tiến độ và "Còn x g" / "Vượt x g".
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.color,
    required this.track,
    required this.consumed,
    required this.target,
    this.valueColor,
  });

  final String label;

  /// Màu chấm và thanh.
  final Color color;

  /// Màu nền thanh.
  final Color track;
  final double consumed;
  final double target;

  /// Màu số đã nạp (mặc định = [color]).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final over = isOver(consumed, target);
    final ratio = progressRatio(consumed, target);
    final barColor = over ? AppColors.error : color;
    final numColor = over ? AppColors.onErrorContainer : (valueColor ?? color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatGram(consumed),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: numColor,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${formatGram(target)} g',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 14, height: 20 / 14),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: track)),
                FractionallySizedBox(
                  widthFactor: ratio,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          gramRemainingLabel(target - consumed),
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            color: over ? AppColors.onErrorContainer : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
