import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/home/widgets/week_card.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';

/// "Thứ Năm 5/11" và "2.240 kcal · vượt 14 %".
(String, String) historyTooltipLines(HistoryDay d) {
  final dt = parseIsoDate(d.date);
  final head = dt == null ? d.date : '${weekdayLong(dt)} ${dt.day}/${dt.month}';
  final kcal = '${formatKcal(d.kcal)} kcal';
  if (d.kcal <= 0) return (head, 'Chưa ghi');
  if (d.targetKcal <= 0) return (head, kcal);
  final pct = ((d.kcal / d.targetKcal - 1) * 100).round();
  final tail = pct > 0
      ? 'vượt $pct %'
      : '${(d.kcal / d.targetKcal * 100).round()} % mục tiêu';
  return (head, '$kcal · $tail');
}

/// Biểu đồ cột kcal theo ngày + đường mục tiêu nét đứt theo từng ngày (§7.3).
/// Chạm cột lần đầu hiện tooltip, chạm lại đúng cột đó thì [onOpenDay].
class HistoryChart extends StatefulWidget {
  const HistoryChart({
    super.key,
    required this.days,
    required this.today,
    required this.onOpenDay,
  });

  final List<HistoryDay> days;
  final String today;
  final ValueChanged<String> onOpenDay;

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  int? _selected;

  static const _leftReserved = 40.0;
  static const _bottomReserved = 28.0;
  static const _height = 220.0;

  @override
  void didUpdateWidget(HistoryChart old) {
    super.didUpdateWidget(old);
    if (old.days.length != widget.days.length) _selected = null;
  }

  String _xLabel(int i) {
    final d = widget.days[i];
    if (d.date == widget.today) return 'H.nay';
    final dt = parseIsoDate(d.date);
    if (dt == null) return '';
    return widget.days.length <= 7 ? weekdayShort(dt) : '${dt.day}/${dt.month}';
  }

  void _onTouch(FlTouchEvent e, BarTouchResponse? r) {
    if (e is! FlTapUpEvent) return;
    final i = r?.spot?.touchedBarGroupIndex;
    if (i == null || i < 0 || i >= widget.days.length) {
      setState(() => _selected = null);
      return;
    }
    if (i == _selected) {
      widget.onOpenDay(widget.days[i].date);
    } else {
      setState(() => _selected = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    final maxY = chartMaxY(days);
    final labels = xLabelIndexes(days.length).toSet();
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, box) {
          final plotW = box.maxWidth - _leftReserved;
          final slot = days.isEmpty ? plotW : plotW / days.length;
          final barW = (slot * 0.6).clamp(3.0, 24.0);
          return Stack(
            children: [
              Positioned.fill(
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.outline,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.outline),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _leftReserved,
                          interval: 1000,
                          getTitlesWidget: (v, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              formatKcal(v),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _bottomReserved,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (!labels.contains(i)) {
                              return const SizedBox.shrink();
                            }
                            final isToday = days[i].date == widget.today;
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                _xLabel(i),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      handleBuiltInTouches: false,
                      allowTouchBarBackDraw: true,
                      touchCallback: _onTouch,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textPrimary,
                        tooltipBorderRadius: BorderRadius.circular(12),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, _, _, _) {
                          final (head, body) = historyTooltipLines(
                            days[group.x],
                          );
                          return BarTooltipItem(
                            '$head\n',
                            const TextStyle(
                              fontSize: 12,
                              color: AppColors.surface,
                            ),
                            textAlign: TextAlign.left,
                            children: [
                              TextSpan(
                                text: body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.surface,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (final (i, d) in days.indexed)
                        BarChartGroupData(
                          x: i,
                          showingTooltipIndicators: i == _selected
                              ? const [0]
                              : const [],
                          barRods: [
                            BarChartRodData(
                              toY: d.kcal.clamp(0, maxY).toDouble(),
                              width: barW,
                              color: switch (barKind(d, widget.today)) {
                                BarKind.today => AppColors.primaryOutline,
                                BarKind.over => AppColors.error,
                                BarKind.normal => AppColors.primary,
                              },
                              borderSide: i == _selected
                                  ? const BorderSide(
                                      color: AppColors.textPrimary,
                                      width: 2,
                                    )
                                  : const BorderSide(
                                      width: 0,
                                      color: Colors.transparent,
                                    ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(barW >= 12 ? 6 : 2),
                              ),
                              // Cả cột (kể cả phần trống phía trên) đều nhận chạm
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  duration: Duration.zero,
                ),
              ),
              Positioned(
                left: _leftReserved,
                right: 0,
                top: 0,
                bottom: _bottomReserved,
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
          );
        },
      ),
    );
  }
}
