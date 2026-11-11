import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Vòng calo Ø 144, nét 14, đầu tròn; giữa vòng là số và chú thích.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.ratio,
    required this.over,
    required this.value,
    required this.caption,
  });

  /// Tỉ lệ đã nạp / mục tiêu, kẹp 0–1 trước khi vẽ.
  final double ratio;

  /// Vượt mục tiêu: cả vòng tô `error`.
  final bool over;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textColor = over ? AppColors.onErrorContainer : AppColors.textPrimary;
    return SizedBox.square(
      dimension: 144,
      child: CustomPaint(
        painter: _RingPainter(
          ratio: over ? 1 : ratio.clamp(0.0, 1.0),
          over: over,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: over
                      ? AppColors.onErrorContainer
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.ratio, required this.over});

  final double ratio;
  final bool over;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = AppColors.outline;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (ratio <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = ratio >= 1 ? StrokeCap.butt : StrokeCap.round
      ..color = over ? AppColors.error : AppColors.primary;
    // Bắt đầu từ 12 giờ, chạy theo chiều kim đồng hồ
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * ratio, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio || old.over != over;
}
