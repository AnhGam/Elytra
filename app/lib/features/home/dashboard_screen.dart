import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/greeting.dart';
import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/home/widgets/calorie_ring.dart';
import 'package:elytra/features/home/widgets/macro_bar.dart';
import 'package:elytra/features/home/widgets/meal_card.dart';
import 'package:elytra/features/home/widgets/week_card.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/history_stats.dart';
import 'package:elytra/features/meal_logs/log_meal_screen.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';

/// Trang chủ: tóm tắt hôm nay, 4 bữa và thẻ "7 ngày qua" (§7.1).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Không tải trong build: store báo đổi ngay khi chuyển sang loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = DiaryScope.of(context);
      final today = store.today;
      unawaited(store.ensureDay(today));
      final r = rangeEnding(today, 7);
      unawaited(store.ensureHistory(r.from, r.to));
      // Hồ sơ chỉ để lấy tên; tải lỗi thì lời chào không có tên
      RecipeScope.maybeOf(context)?.ensureLoaded().catchError((Object _) {});
    });
  }

  DiaryStore get _store => DiaryScope.of(context);

  Future<void> _refresh() async {
    final store = _store;
    final today = store.today;
    final r = rangeEnding(today, 7);
    await Future.wait([
      store.refreshDay(today),
      store.refreshHistory(r.from, r.to),
    ]);
    if (!mounted) return;
    // Có dữ liệu cũ mà làm mới lỗi: giữ dữ liệu, báo bằng snackbar
    final e = store.day(today);
    if (e.log != null &&
        (e.status == LoadStatus.offline || e.status == LoadStatus.failed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.status == LoadStatus.offline
                ? 'Không có mạng. Đang hiện số liệu cũ.'
                : 'Không làm mới được số liệu.',
          ),
        ),
      );
    }
  }

  Future<void> _openLog(MealType meal) async {
    final store = _store;
    final messenger = ScaffoldMessenger.of(context);
    final r = await context.push<LogMealResult>(
      '/log?meal=${meal.apiValue}&date=${store.today}',
    );
    if (r == null || !mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('Đã thêm ${r.name} vào bữa ${meal.labelVi}'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => store.undoAdd(r.result).catchError((Object _) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Không hoàn tác được. Thử lại sau.'),
                ),
              );
            }),
          ),
        ),
      );
  }

  void _openDiary(DiaryViewRequest req) {
    _store.requestDiaryView(req);
    StatefulNavigationShell.maybeOf(context)?.goBranch(1);
  }

  @override
  Widget build(BuildContext context) {
    final store = DiaryScope.of(context);
    final today = store.today;
    final entry = store.day(today);
    final r = rangeEnding(today, 7);
    final hist = store.history(r.from, r.to);
    final week = store.historyView(r.from, r.to);
    final profileMissing =
        entry.status == LoadStatus.profileMissing ||
        (entry.log == null && hist.status == LoadStatus.profileMissing);

    final Widget body;
    if (entry.log != null) {
      final now = store.now();
      body = _Content(
        log: entry.log!,
        currentMeal: mealTypeAt(now),
        week: hist.status == LoadStatus.profileMissing ? null : week,
        today: today,
        onAdd: _openLog,
        onOpenDay: () => _openDiary(
          DiaryViewRequest(segment: DiarySegment.byDay, date: today),
        ),
        onOpenWeek: () => _openDiary(
          const DiaryViewRequest(segment: DiarySegment.stats, rangeDays: 7),
        ),
      );
    } else if (profileMissing) {
      body = const _ProfileMissingBlock();
    } else if (entry.status == LoadStatus.offline ||
        entry.status == LoadStatus.failed) {
      body = _ErrorBlock(
        offline: entry.status == LoadStatus.offline,
        onRetry: _refresh,
      );
    } else {
      body = const _Skeleton();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: profileMissing
          ? null
          : FloatingActionButton(
              tooltip: 'Trợ lý AI',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Sắp có'))),
              child: const Icon(Icons.auto_awesome),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(now: store.now()),
                const SizedBox(height: 24),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lời chào, dòng ngày và avatar. Tên chỉ lấy từ hồ sơ, không bao giờ từ email.
class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final name = displayName(RecipeScope.maybeOf(context)?.profile?.fullName);
    final hello = greeting(now) + (name == null ? '' : ', ${shortName(name)}');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hello,
                style: const TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                longDateLabel(now),
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: name == null
              ? const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryDark,
                  size: 22,
                )
              : Text(
                  avatarInitial(name),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Khung thẻ trắng bo 20 dùng chung trên Dashboard.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.log,
    required this.currentMeal,
    required this.week,
    required this.today,
    required this.onAdd,
    required this.onOpenDay,
    required this.onOpenWeek,
  });

  final DayLog log;
  final MealType currentMeal;
  final History? week;
  final String today;
  final void Function(MealType) onAdd;
  final VoidCallback onOpenDay;
  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final target = log.budget.target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TodayCard(budget: log.budget),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bữa ăn hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenDay,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size(48, 48),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem nhật ký',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in MealType.values) ...[
          MealCard(
            type: m,
            log: log.meals[m] ?? MealLog.empty,
            budgetKcal: mealBudgetKcal(target.kcal, m),
            current: m == currentMeal,
            onAdd: () => onAdd(m),
          ),
          const SizedBox(height: 12),
        ],
        if (week != null) ...[
          const SizedBox(height: 4),
          WeekCard(view: week!, today: today, onTap: onOpenWeek),
        ],
      ],
    );
  }
}

/// Thẻ "Hôm nay": vòng calo, Đã nạp / Mục tiêu và 3 macro.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final t = budget.target, c = budget.consumed;
    final hasTarget = t.kcal > 0;
    final over = isOver(c.kcal, t.kcal);
    // Chưa có mục tiêu: tâm vòng hiện số đã nạp thay vì "vượt mức"
    final center = hasTarget
        ? ringCenter(budget)
        : (value: formatKcal(c.kcal), caption: 'kcal đã nạp');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hôm nay',
                  style: TextStyle(
                    fontSize: 17,
                    height: 24 / 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (over) _OverBadge(pct: overPct(c.kcal, t.kcal)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CalorieRing(
                ratio: progressRatio(c.kcal, t.kcal),
                over: over,
                value: center.value,
                caption: center.caption,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stat(
                      icon: 'assets/icons/ic_flame.svg',
                      container: AppColors.primaryContainer,
                      tint: AppColors.primaryDark,
                      label: 'Đã nạp',
                      value: '${formatKcal(c.kcal)} kcal',
                    ),
                    const SizedBox(height: 16),
                    _Stat(
                      icon: 'assets/icons/ic_target.svg',
                      container: AppColors.proteinContainer,
                      tint: AppColors.protein,
                      label: 'Mục tiêu',
                      value: hasTarget ? '${formatKcal(t.kcal)} kcal' : '–',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
          const SizedBox(height: 16),
          MacroBar(
            label: 'Protein',
            color: AppColors.protein,
            track: AppColors.proteinContainer,
            valueColor: AppColors.onProteinContainer,
            consumed: c.proteinG,
            target: t.proteinG,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Carbs',
            color: AppColors.carbs,
            track: AppColors.carbsContainer,
            valueColor: AppColors.onCarbsContainer,
            consumed: c.carbsG,
            target: t.carbsG,
          ),
          const SizedBox(height: 14),
          MacroBar(
            label: 'Fat',
            color: AppColors.fat,
            track: AppColors.fatContainer,
            consumed: c.fatG,
            target: t.fatG,
          ),
        ],
      ),
    );
  }
}

class _OverBadge extends StatelessWidget {
  const _OverBadge({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Vượt $pct %',
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.container,
    required this.tint,
    required this.label,
    required this.value,
  });

  final String icon;
  final Color container;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: container,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgPicture.asset(
            icon,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  color: AppColors.textMuted,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Khối giữa thẻ: icon tròn, tiêu đề, mô tả và nút (mất mạng, chưa có hồ sơ).
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
    return _Card(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: icon,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 26 / 18,
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
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.offline, required this.onRetry});

  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: const Icon(
        Icons.wifi_off,
        color: AppColors.textSecondary,
        size: 28,
      ),
      iconBg: AppColors.background,
      title: offline ? 'Không có kết nối mạng' : 'Không tải được số liệu',
      body: offline
          ? 'Chưa tải được số liệu hôm nay. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.'
          : 'Đã có lỗi khi tải số liệu hôm nay. Thử lại sau ít phút.',
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

class _ProfileMissingBlock extends StatelessWidget {
  const _ProfileMissingBlock();

  @override
  Widget build(BuildContext context) {
    return _MessageCard(
      icon: SvgPicture.asset(
        'assets/icons/ic_target.svg',
        width: 20,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryDark,
          BlendMode.srcIn,
        ),
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

/// Skeleton tĩnh (không shimmer) theo dashboard-04.
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(80, 16),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.outline, width: 14),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < 2; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          Row(
                            children: [
                              _bar(36, 36, r: 10),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _bar(48, 10),
                                    const SizedBox(height: 6),
                                    _bar(80, 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < 3; i++) ...[
                _bar(120, 12),
                const SizedBox(height: 8),
                _bar(double.infinity, 8, r: 4),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: _bar(140, 18)),
        const SizedBox(height: 16),
        for (var i = 0; i < 2; i++) ...[
          _Card(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _bar(40, 40, r: 12),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(90, 12),
                    const SizedBox(height: 8),
                    _bar(160, 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
