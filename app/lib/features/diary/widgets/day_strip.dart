import 'package:flutter/material.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';

/// Một ô ngày trong dải: thứ, ngày và chấm trạng thái.
class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.date,
    required this.selected,
    required this.isToday,
    required this.dot,
    required this.onTap,
  });

  final String date;
  final bool selected;
  final bool isToday;
  final DotKind dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = parseIsoDate(date);
    final fg = selected ? AppColors.surface : AppColors.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.textPrimary : AppColors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isToday ? 'H.nay' : (d == null ? '' : weekdayShort(d)),
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: selected ? AppColors.surface : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d == null ? '' : '${d.day}',
                  style: TextStyle(
                    fontSize: 17,
                    height: 22 / 17,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                _Dot(
                  key: ValueKey('dot-$date-${dot.name}'),
                  kind: dot,
                  selected: selected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({super.key, required this.kind, required this.selected});

  final DotKind kind;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (kind == DotKind.none) return const SizedBox(width: 6, height: 6);
    if (selected) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
      );
    }
    // Hôm nay (chưa chốt): vòng xanh rỗng
    if (kind == DotKind.today) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
      );
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: kind == DotKind.over ? AppColors.error : AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Dải 7 ô ngày; vuốt ngang để lùi/tiến 7 ngày.
class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.dates,
    required this.selected,
    required this.today,
    required this.dotOf,
    required this.onSelect,
    required this.onShift,
  });

  final List<String> dates;
  final String selected;
  final String today;
  final DotKind Function(String date) dotOf;
  final ValueChanged<String> onSelect;

  /// -1 lùi, +1 tiến.
  final ValueChanged<int> onShift;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  double _dx = 0; // quãng kéo ngang tích luỹ

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (e) => _dx += e.delta.dx,
      onHorizontalDragEnd: (e) {
        final v = e.primaryVelocity ?? 0;
        // Kéo sang phải (xem ngày cũ hơn) thì lùi, sang trái thì tiến
        if (_dx > 60 || v > 300) w.onShift(-1);
        if (_dx < -60 || v < -300) w.onShift(1);
      },
      child: Row(
        children: [
          for (final (i, d) in w.dates.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: DayChip(
                date: d,
                selected: d == w.selected,
                isToday: d == w.today,
                dot: w.dotOf(d),
                onTap: () => w.onSelect(d),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
