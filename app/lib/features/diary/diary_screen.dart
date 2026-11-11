import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/diary/diary_controller.dart';
import 'package:elytra/features/diary/widgets/day_meals.dart';
import 'package:elytra/features/diary/widgets/day_strip.dart';
import 'package:elytra/features/diary/widgets/edit_item_sheet.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/log_meal_screen.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';

/// Tab Nhật ký: "Theo ngày" và "Thống kê" (§7.3).
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DiaryController? _c;
  DiaryStore? _store;

  /// Món vừa vuốt xoá, đang chờ snackbar đóng.
  PendingDelete? _pending;

  DiaryController get c => _c!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final store = _store = DiaryScope.of(context);
    _c = DiaryController(store: store)..addListener(_onChanged);
    store.viewRequest.addListener(_onRequest);
    // Yêu cầu gửi trước khi màn được dựng (vd. Dashboard → goBranch): áp sau frame đầu
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRequest());
  }

  @override
  void dispose() {
    _store?.viewRequest.removeListener(_onRequest);
    // Rời màn: gửi DELETE của món đang chờ (lỗi thì bỏ qua, màn đã đóng)
    unawaited(_pending?.commit().catchError((Object _) {}));
    _c?.removeListener(_onChanged);
    _c?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onRequest() {
    final store = _store;
    if (!mounted || store == null) return;
    final r = store.viewRequest.value;
    if (r == null) return;
    store.viewRequest.value = null;
    c.apply(r);
  }

  /// "Hôm nay" hoặc "T2, 9/11".
  String _dayLabel(String date) {
    final d = parseIsoDate(date);
    if (date == c.store.today || d == null) return 'Hôm nay';
    return '${weekdayShort(d)}, ${d.day}/${d.month}';
  }

  /// "Hôm nay · 10/11" hoặc "T2 · 9/11".
  String _summaryTitle(String date) {
    final d = parseIsoDate(date);
    if (d == null) return date;
    final head = date == c.store.today ? 'Hôm nay' : weekdayShort(d);
    return '$head · ${d.day}/${d.month}';
  }

  Future<void> _pickDate() async {
    final today = parseIsoDate(c.store.today)!;
    final sel = parseIsoDate(c.selectedDate) ?? today;
    final last = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(sel.year, sel.month, sel.day),
      firstDate: DateTime(last.year - 1, last.month, last.day),
      lastDate: last,
    );
    if (picked != null && mounted) c.selectDate(isoDate(picked));
  }

  Future<void> _openLog(MealType meal, String date) async {
    final messenger = ScaffoldMessenger.of(context);
    final store = c.store;
    final r = await context.push<LogMealResult>(
      '/log?meal=${meal.apiValue}&date=$date',
    );
    if (r == null || !mounted) return;
    showLogResultSnackBar(messenger, store, r, meal);
  }

  void _edit(MealLogItem item, MealType meal, String date) {
    showEditItemSheet(
      context,
      store: c.store,
      item: item,
      meal: meal,
      date: date,
      dayLabel: _dayLabel(date),
    );
  }

  void _dismiss(MealLogItem item, String date) {
    final store = c.store;
    final messenger = ScaffoldMessenger.of(context);
    final p = store.deleteDeferred(item, date: date);
    _pending = p;
    messenger.hideCurrentSnackBar();
    final ctrl = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        // Có action thì Flutter mặc định giữ snackbar tới khi bấm; spec cần tự đóng sau 4 giây
        persist: false,
        content: Text('Đã xoá ${item.name}'),
        action: SnackBarAction(label: 'Hoàn tác', onPressed: p.undo),
      ),
    );
    ctrl.closed.then((reason) {
      if (identical(_pending, p)) _pending = null;
      if (reason == SnackBarClosedReason.action) return;
      // Hết giờ, bị vuốt hoặc bị snackbar khác thay: gửi DELETE
      p.commit().catchError((Object _) {
        // Màn đã đóng (hoặc store đã clear khi đăng xuất) thì không báo
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Không xoá được. Thử lại')),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final byDay = c.segment == DiarySegment.byDay;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Nhật ký',
                            style: TextStyle(
                              fontSize: 26,
                              height: 34 / 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chọn ngày',
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _Segmented(
                        value: c.segment,
                        onChanged: c.setSegment,
                      ),
                    ),
                    if (byDay) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _strip(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: byDay ? _byDay() : const _StatsPlaceholder()),
          ],
        ),
      ),
    );
  }

  Widget _strip() {
    final dates = c.stripDates;
    final hist = c.store.historyView(dates.first, c.stripEnd);
    final byDate = {
      for (final d in hist?.days ?? const <HistoryDay>[]) d.date: d,
    };
    final today = c.store.today;
    return DayStrip(
      dates: dates,
      selected: c.selectedDate,
      today: today,
      dotOf: (d) {
        final h = byDate[d];
        if (d == today) return DotKind.today;
        return h == null ? DotKind.none : dotKind(h, today);
      },
      onSelect: c.selectDate,
      onShift: c.shiftStrip,
    );
  }

  Widget _byDay() {
    final date = c.selectedDate;
    final entry = c.store.day(date);
    final log = entry.log;
    if (log == null) {
      return switch (entry.status) {
        LoadStatus.profileMissing => const _ProfileMissing(),
        LoadStatus.offline || LoadStatus.failed => _ErrorBlock(
          offline: entry.status == LoadStatus.offline,
          onRetry: () => c.store.refreshDay(date),
        ),
        _ => const _Skeleton(),
      };
    }
    final editable = c.canEdit(date);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => c.store.refreshDay(date),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          DaySummaryCard(title: _summaryTitle(date), budget: log.budget),
          for (final m in MealType.values) ...[
            const SizedBox(height: 12),
            MealGroup(
              type: m,
              log: log.meals[m] ?? MealLog.empty,
              editable: editable,
              onAdd: () => _openLog(m, date),
              onTapItem: (it) => _edit(it, m, date),
              onDismissItem: (it) => _dismiss(it, date),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            editable
                ? 'Chạm món để sửa lượng hoặc xoá · vuốt trái để xoá nhanh'
                : kTooOldNote,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Theo ngày | Thống kê".
class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});

  final DiarySegment value;
  final ValueChanged<DiarySegment> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(DiarySegment s, String label) {
      final selected = s == value;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(s),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: selected
                  ? BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    )
                  : null,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          seg(DiarySegment.byDay, 'Theo ngày'),
          seg(DiarySegment.stats, 'Thống kê'),
        ],
      ),
    );
  }
}

/// Phần Thống kê làm ở Task 16.
class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

/// Khung thẻ thông báo giữa màn (mất mạng, chưa có hồ sơ).
class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.action,
  });

  final Widget icon;
  final Color iconBg;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 24 / 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.offline, required this.onRetry});

  final bool offline;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: const Icon(
        Icons.wifi_off,
        size: 28,
        color: AppColors.textSecondary,
      ),
      iconBg: AppColors.background,
      title: offline ? 'Không có kết nối mạng' : 'Không tải được nhật ký',
      body: offline
          ? 'Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.'
          : 'Đã có lỗi khi tải nhật ký. Thử lại sau ít phút.',
      action: SizedBox(
        width: 160,
        height: 48,
        child: OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.outlineStrong),
            shape: const StadiumBorder(),
          ),
          child: const Text(
            'Thử lại',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ProfileMissing extends StatelessWidget {
  const _ProfileMissing();

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: const Icon(
        Icons.trending_up,
        size: 26,
        color: AppColors.primaryDark,
      ),
      iconBg: AppColors.primaryContainer,
      title: 'Chưa có mục tiêu dinh dưỡng',
      body:
          'Khai báo thể trạng (khoảng 1 phút) để Elytra tính calo, protein, '
          'carbs, fat mỗi ngày cho bạn.',
      action: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () => context.go('/onboarding'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.surface,
            shape: const StadiumBorder(),
          ),
          child: const Text(
            'Khai báo thể trạng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Skeleton tĩnh: thẻ tóm tắt và 2 nhóm bữa.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  static Widget _bar(double w, double h, {double r = 6}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColors.outline,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  static Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.outline),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(120, 14),
              const SizedBox(height: 12),
              _bar(double.infinity, 8, r: 4),
              const SizedBox(height: 16),
              _bar(200, 12),
            ],
          ),
        ),
        for (var i = 0; i < 2; i++) ...[
          const SizedBox(height: 12),
          _card(
            Row(
              children: [
                _bar(40, 40, r: 12),
                const SizedBox(width: 12),
                _bar(100, 14),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
