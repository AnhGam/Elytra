import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/theme.dart';

/// Tiêu đề lớn + mô tả ở đầu mỗi bước (24 Black + 13 Regular)
class StepHeading extends StatelessWidget {
  const StepHeading({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Nhãn mục: icon xanh + chữ 14 SemiBold, bên phải có thể có chip
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.icon,
    required this.text,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// Chip nhỏ bo tròn (vd. "Thanh niên (18–29)", "Chuẩn hóa BMR")
class InfoPill extends StatelessWidget {
  const InfoPill(this.text, {super.key, this.green = false});

  final String text;

  /// true: nền xanh nhạt chữ xanh; false: nền xám chữ xám đậm
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: green ? AppColors.primaryContainer : AppColors.outline,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: green ? FontWeight.w600 : FontWeight.w500,
          color: green ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Nút tròn nền xám dùng cho bộ tăng/giảm (−5, −, +, +5)
class CircleStepButton extends StatelessWidget {
  const CircleStepButton({
    super.key,
    required this.size,
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.label,
    this.outlined = false,
  });

  final double size;
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;

  /// false: bước 1, 2, 5
  /// true: bước 6
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? AppColors.textSubtle
        : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: outlined
            ? const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              )
            : null,
        child: Material(
          color: outlined ? AppColors.surface : AppColors.background,
          shape: outlined
              ? const CircleBorder(side: BorderSide(color: AppColors.outline))
              : const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: outlined ? 16 : 20, color: color)
                    : Text(
                        label ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hàng 5 phần: [−5] [−] (giữa) [+] [+5]. Nút tự khóa khi chạm biên.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    required this.center,
    this.smallSize = 40,
    this.largeSize = 48,
    this.gap = 8,
  });

  /// Cỡ nút ±5 và ±1 (bước 1: 40/48; bước 2: 36/36)
  final double smallSize;
  final double largeSize;

  /// Khoảng cách giữa nút ±5 và nút ±1 (bước 1: 8; bước 2: 6 theo thiết kế)
  final double gap;

  final num value;
  final num min;
  final num max;

  /// Đơn vị cho chú thích TalkBack, vd. "tuổi", "cm"
  final String unit;
  final ValueChanged<num> onChanged;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    VoidCallback? by(num delta) {
      // Nút mờ ngay khi bấm sẽ vượt biên (vd. còn cách max 3 thì "+5" mờ)
      final canMove = value + delta >= min && value + delta <= max;
      return canMove ? () => onChanged(value + delta) : null;
    }

    final minus5 = CircleStepButton(
      size: smallSize,
      label: '-5',
      tooltip: 'Giảm 5 $unit',
      onPressed: by(-5),
    );
    final minus1 = CircleStepButton(
      size: largeSize,
      icon: Icons.remove,
      tooltip: 'Giảm 1 $unit',
      onPressed: by(-1),
    );
    final plus1 = CircleStepButton(
      size: largeSize,
      icon: Icons.add,
      tooltip: 'Tăng 1 $unit',
      onPressed: by(1),
    );
    final plus5 = CircleStepButton(
      size: smallSize,
      label: '+5',
      tooltip: 'Tăng 5 $unit',
      onPressed: by(5),
    );

    return Row(
      children: [
        _ButtonPair(
          outer: minus5,
          outerSize: smallSize,
          outerTap: by(-5),
          inner: minus1,
          innerSize: largeSize,
          innerTap: by(-1),
          gap: gap,
          leftSide: true,
        ),
        Expanded(child: Center(child: center)),
        _ButtonPair(
          outer: plus5,
          outerSize: smallSize,
          outerTap: by(5),
          inner: plus1,
          innerSize: largeSize,
          innerTap: by(1),
          gap: gap,
          leftSide: false,
        ),
      ],
    );
  }
}

/// Thanh trượt xanh + nhãn hai đầu (vd. "18 tuổi" … "80 tuổi")
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.minLabel,
    required this.maxLabel,
    required this.semanticLabel,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final String minLabel;
  final String maxLabel;
  final String semanticLabel;

  /// Luôn nhận số nguyên
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSubtle,
    );
    return Column(
      children: [
        // Tự vẽ thanh trượt
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final t = max > min
                ? ((value - min) / (max - min)).clamp(0.0, 1.0)
                : 0.0;

            void setFromDx(double dx) {
              final raw = min + (dx / width).clamp(0.0, 1.0) * (max - min);
              final v = raw.roundToDouble();
              if (v != value) onChanged(v);
            }

            return Semantics(
              slider: true,
              label: semanticLabel,
              value: '${value.round()}',
              increasedValue: '${(value + 1).clamp(min, max).round()}',
              decreasedValue: '${(value - 1).clamp(min, max).round()}',
              onIncrease: value < max ? () => onChanged(value + 1) : null,
              onDecrease: value > min ? () => onChanged(value - 1) : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => setFromDx(d.localPosition.dx),
                onHorizontalDragStart: (d) => setFromDx(d.localPosition.dx),
                onHorizontalDragUpdate: (d) => setFromDx(d.localPosition.dx),
                child: SizedBox(
                  width: width,
                  height: 24,
                  child: CustomPaint(painter: _SliderPainter(t)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: label),
            Text(maxLabel, style: label),
          ],
        ),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final x = size.width * t;
    const h = 6.0;
    final track = RRect.fromLTRBR(
      0,
      cy - h / 2,
      size.width,
      cy + h / 2,
      const Radius.circular(h / 2),
    );
    canvas.drawRRect(track, Paint()..color = AppColors.sliderInactive);
    final active = RRect.fromLTRBR(
      0,
      cy - h / 2,
      x,
      cy + h / 2,
      const Radius.circular(h / 2),
    );
    canvas.drawRRect(active, Paint()..color = AppColors.primary);

    final c = Offset(x, cy);
    canvas.drawCircle(
      c.translate(0, 2),
      10,
      Paint()
        ..color = const Color(0x6616A34A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(c, 10, Paint()..color = Colors.white);
    canvas.drawCircle(c, 8, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_SliderPainter old) => old.t != t;
}

class WizardCard extends StatelessWidget {
  const WizardCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }
}

class MeasureCard extends StatelessWidget {
  const MeasureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  static final _fmt = NumberFormat('#,##0.#', 'vi');

  @override
  Widget build(BuildContext context) {
    return WizardCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StepperRow(
            value: value,
            min: min,
            max: max,
            unit: unit,
            smallSize: 36,
            largeSize: 36,
            gap: 6,
            onChanged: (v) => onChanged(v.toDouble()),
            center: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmt.format(value),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          LabeledSlider(
            value: value,
            min: min,
            max: max,
            minLabel: '${_fmt.format(min)} $unit',
            maxLabel: '${_fmt.format(max)} $unit',
            semanticLabel: title,
            onChanged: (v) => onChanged(v.roundToDouble()),
          ),
        ],
      ),
    );
  }
}

/// Thẻ chọn một trong nhiều (vd. mức vận động): vòng tròn chọn bên trái,
/// tên + mô tả ở giữa, ô nhỏ bên phải. Chọn rồi thì nền xanh nhạt, viền xanh.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Chữ trong ô bên phải
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.primaryDark : AppColors.textPrimary;
    final subColor = selected ? AppColors.primaryDark : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            child: Row(
              children: [
                // Vòng tròn chọn
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : AppColors.surface,
                    border: selected
                        ? null
                        : Border.all(color: AppColors.outlineStrong),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 64,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surface
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trailing!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vùng chạm tối thiểu theo Material/Android
const kMinTouchTarget = 48.0;

class TouchTarget extends StatelessWidget {
  const TouchTarget({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Center(child: child),
      ),
    );
  }
}

class _ButtonPair extends StatelessWidget {
  const _ButtonPair({
    required this.outer,
    required this.outerSize,
    required this.outerTap,
    required this.inner,
    required this.innerSize,
    required this.innerTap,
    required this.gap,
    required this.leftSide,
  });

  final Widget outer;
  final double outerSize;
  final VoidCallback? outerTap;
  final Widget inner;
  final double innerSize;
  final VoidCallback? innerTap;
  final double gap;
  final bool leftSide;

  @override
  Widget build(BuildContext context) {
    const t = kMinTouchTarget;
    final outerHitWidth = outerSize / 2 + t / 2;
    final innerCenter = outerSize + gap + innerSize / 2;
    final width = innerCenter + t / 2;

    Widget hit(VoidCallback? onTap, Alignment align, Widget child) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Align(alignment: align, child: child),
        );

    return SizedBox(
      width: width,
      height: t,
      child: Stack(
        children: [
          // Nút ngoài (−5 / +5)
          Positioned(
            left: leftSide ? 0 : null,
            right: leftSide ? null : 0,
            top: 0,
            width: outerHitWidth,
            height: t,
            child: hit(
              outerTap,
              leftSide ? Alignment.centerLeft : Alignment.centerRight,
              outer,
            ),
          ),
          // Nút trong (− / +), vẽ sau nên được ưu tiên ở phần chồng nhau
          Positioned(
            left: leftSide ? innerCenter - t / 2 : null,
            right: leftSide ? null : innerCenter - t / 2,
            top: 0,
            width: t,
            height: t,
            child: hit(innerTap, Alignment.center, inner),
          ),
        ],
      ),
    );
  }
}
