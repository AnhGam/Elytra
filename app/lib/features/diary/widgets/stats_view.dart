import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/diary/diary_controller.dart';
import 'package:elytra/features/diary/widgets/diary_blocks.dart';
import 'package:elytra/features/diary/widgets/history_chart.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/widgets/portion_inputs.dart';

/// Phần "Thống kê" của tab Nhật ký: chip 7/30 ngày, hai thẻ số, biểu đồ, macro trung bình.
class StatsView extends StatefulWidget {
  const StatsView({
    super.key,
    required this.controller,
    required this.onOpenDay,
    required this.onLogToday,
  });

  final DiaryController controller;

  /// Chạm lại cột đang chọn: mở ngày đó ở "Theo ngày".
  final ValueChanged<String> onOpenDay;

  /// Nút "Ghi bữa đầu tiên" khi chưa có dữ liệu.
  final VoidCallback onLogToday;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  DiaryController get c => widget.controller;
  DiaryStore get store => c.store;

  @override
  void initState() {
    super.initState();
    // Mục tiêu macro so sánh lấy từ budget hôm nay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(store.ensureDay(store.today));
    });
  }

  String _rangeLabel(String from, String to) {
    final f = parseIsoDate(from), t = parseIsoDate(to);
    if (f == null || t == null) return '';
    if (c.rangeDays <= 7) {
      return '${weekdayShort(f)} ${f.day}/${f.month} – ${weekdayShort(t)} ${t.day}/${t.month}';
    }
    return '${f.day}/${f.month} – ${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context) {
    final r = c.statsRange;
    final entry = store.history(r.from, r.to);
    final view = store.historyView(r.from, r.to);
    final todayEntry = store.day(store.today);

    final Widget body;
    if (entry.status == LoadStatus.profileMissing ||
        todayEntry.status == LoadStatus.profileMissing) {
      body = const DiaryProfileMissing();
    } else if (view == null) {
      body =
          entry.status == LoadStatus.offline ||
              entry.status == LoadStatus.failed
          ? DiaryErrorBlock(
              offline: entry.status == LoadStatus.offline,
              onRetry: () => store.refreshHistory(r.from, r.to),
            )
          : const DiarySkeleton();
    } else {
      body = _content(view, r.from, r.to, todayEntry.log?.budget.target);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Wrap(
            spacing: 8,
            children: [
              for (final n in const [7, 30])
                PortionPill(
                  label: '$n ngày',
                  selected: c.rangeDays == n,
                  onTap: () => c.setRange(n),
                ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _content(History view, String from, String to, Macros? target) {
    final days = view.days;
    final today = store.today;
    final todayDay = days.where((d) => d.date == today).firstOrNull;
    final hits = targetHits(days, today);
    final todayEmpty =
        todayDay == null || (todayDay.kcal <= 0 && todayDay.itemCount <= 0);
    if (hits.counted == 0 && todayEmpty) {
      return DiaryMessageCard(
        icon: const Icon(
          Icons.bar_chart,
          size: 28,
          color: AppColors.textSecondary,
        ),
        iconBg: AppColors.background,
        title: 'Chưa đủ dữ liệu để vẽ biểu đồ',
        body: 'Ghi bữa ăn vài ngày, biểu đồ calo và macro sẽ hiện ở đây.',
        action: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.onLogToday,
            style: primarySheetButtonStyle(),
            icon: const Icon(Icons.add),
            label: const Text('Ghi bữa đầu tiên'),
          ),
        ),
      );
    }
    final avg = averageKcal(days, today);
    final macros = macroAverages(days, today);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => store.refreshHistory(from, to),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NumberCard(
                  label: 'Trung bình',
                  value: avg == null ? '–' : formatKcal(avg),
                  caption: 'kcal/ngày (không tính hôm nay)',
                ),
                const SizedBox(width: 12),
                _NumberCard(
                  label: 'Trong mục tiêu',
                  value: '${hits.hits}/${hits.counted} ngày',
                  caption: 'trong khoảng ±10 % mục tiêu',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(child: _CardTitle('Calo mỗi ngày')),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _rangeLabel(from, to),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                HistoryChart(
                  key: ValueKey('chart-$from'),
                  days: days,
                  today: today,
                  onOpenDay: widget.onOpenDay,
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
                    _Legend(
                      color: AppColors.primaryOutline,
                      label: 'Hôm nay (đang ghi)',
                    ),
                    _Legend(color: null, label: 'Mục tiêu ngày'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chạm vào cột để xem số, chạm lần nữa để mở ngày đó ở “Theo ngày”.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (macros != null) ...[
            const SizedBox(height: 12),
            _MacroCard(avg: macros, target: target),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
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
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

/// Thanh xếp chồng theo % năng lượng và 3 dòng "Protein · 27 % … 128 g / 130 g".
class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.avg, required this.target});

  final MacroAverages avg;

  /// Mục tiêu macro hiện tại (budget hôm nay); null thì không hiện phần so sánh.
  final Macros? target;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Protein',
        avg.proteinPct,
        avg.proteinG,
        target?.proteinG,
        AppColors.protein,
        AppColors.onProteinContainer,
      ),
      (
        'Carbs',
        avg.carbsPct,
        avg.carbsG,
        target?.carbsG,
        AppColors.carbs,
        AppColors.onCarbsContainer,
      ),
      (
        'Fat',
        avg.fatPct,
        avg.fatG,
        target?.fatG,
        AppColors.fat,
        AppColors.onFatContainer,
      ),
    ];
    final total = avg.proteinPct + avg.carbsPct + avg.fatPct;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle('Macro trung bình mỗi ngày'),
          const SizedBox(height: 12),
          if (total > 0)
            SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final (i, r) in rows.indexed)
                    if (r.$2 > 0) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: r.$2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: r.$5,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: r.$5,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${r.$1} · ${r.$2} %',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${formatGram(r.$3.roundToDouble())} g',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: r.$6,
                    ),
                  ),
                  if (r.$4 != null && r.$4! > 0)
                    Text(
                      ' / ${formatGram(r.$4!.roundToDouble())} g',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
