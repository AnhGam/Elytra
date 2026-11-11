import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';

/// Thẻ "7 ngày qua": biểu đồ cột mini, trung bình và số ngày trong mục tiêu.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.view,
    required this.today,
    required this.onTap,
  });

  final History view;
  final String today;
  final VoidCallback onTap;

  static const _chartHeight = 96.0;

  String get _summary {
    final avg = averageKcal(view.days, today);
    final hits = targetHits(view.days, today);
    final avgText = avg == null ? '–' : formatKcal(avg);
    return 'TB $avgText kcal/ngày · ${hits.hits}/${hits.counted} ngày trong mục tiêu';
  }

  @override
  Widget build(BuildContext context) {
    final days = view.days;
    final maxY = chartMaxY(days);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7 ngày qua',
                          style: TextStyle(
                            fontSize: 17,
                            height: 24 / 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _summary,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _chartHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          titlesData: const FlTitlesData(show: false),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              bottom: BorderSide(color: AppColors.outline),
                            ),
                          ),
                          barTouchData: BarTouchData(enabled: false),
                          barGroups: [
                            for (final (i, d) in days.indexed)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: d.kcal.clamp(0, maxY).toDouble(),
                                    width: 20,
                                    color: switch (barKind(d, today)) {
                                      BarKind.today => AppColors.primaryOutline,
                                      BarKind.over => AppColors.error,
                                      BarKind.normal => AppColors.primary,
                                    },
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        duration: Duration.zero,
                      ),
                    ),
                    // Đường mục tiêu nét đứt theo mục tiêu của từng ngày
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: TargetStepPainter(
                            targets: [for (final d in days) d.targetKcal],
                            maxY: maxY,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final d in days)
                    Expanded(
                      child: Text(
                        _label(d.date),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: d.date == today
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: d.date == today
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Legend(
                    color: AppColors.primary,
                    label: 'Không vượt (≤ 110 %)',
                  ),
                  _Legend(color: AppColors.error, label: 'Vượt > 110 %'),
                  _Legend(color: AppColors.primaryOutline, label: 'Hôm nay'),
                  _Legend(color: null, label: 'Mục tiêu'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String date) {
    final d = parseIsoDate(date);
    return d == null ? '' : weekdayShort(d);
  }
}

/// Vẽ đường mục tiêu nét đứt dạng bậc: mỗi ô cột một đoạn ở mức mục tiêu của ngày đó.
class TargetStepPainter extends CustomPainter {
  TargetStepPainter({required this.targets, required this.maxY});

  final List<double> targets;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    if (targets.isEmpty || maxY <= 0) return;
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1;
    final slot = size.width / targets.length;
    const dash = 4.0, gap = 3.0;
    double? prevY;
    for (final (i, t) in targets.indexed) {
      if (t <= 0) {
        prevY = null;
        continue;
      }
      final y = size.height * (1 - (t / maxY).clamp(0.0, 1.0));
      final x0 = i * slot, x1 = (i + 1) * slot;
      // Nối bậc khi mục tiêu đổi giữa hai ngày
      if (prevY != null && prevY != y) {
        canvas.drawLine(Offset(x0, prevY), Offset(x0, y), paint);
      }
      for (var x = x0; x < x1; x += dash + gap) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dash).clamp(x0, x1), y),
          paint,
        );
      }
      prevY = y;
    }
  }

  @override
  bool shouldRepaint(TargetStepPainter old) =>
      old.maxY != maxY || !_sameList(old.targets, targets);

  static bool _sameList(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  /// null = nét đứt (đường mục tiêu).
  final Color? color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const Text(
            '---',
            style: TextStyle(
              fontSize: 12,
              height: 1,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
