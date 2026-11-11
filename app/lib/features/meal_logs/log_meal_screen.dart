import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elytra/core/edit_window.dart';
import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/core/vn_date.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/diary_scope.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/food_search_repository.dart';
import 'package:elytra/features/meal_logs/log_meal_controller.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/meal_logs/widgets/food_row.dart';
import 'package:elytra/features/meal_logs/widgets/portion_sheet.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';

/// Kết quả trả về khi ghi xong (pop kèm giá trị này), để màn trước hiện snackbar.
class LogMealResult {
  const LogMealResult({required this.result, required this.name});
  final AddResult result;
  final String name;
}

/// Snackbar "Đã thêm {tên} vào bữa {bữa}" + "Hoàn tác" (4 giây) sau khi màn Ghi bữa trả về.
void showLogResultSnackBar(
  ScaffoldMessengerState messenger,
  DiaryStore store,
  LogMealResult r,
  MealType fallbackMeal,
) {
  final meal = r.result.item.mealType ?? fallbackMeal;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        // Có action thì Flutter mặc định giữ snackbar tới khi bấm; spec cần tự đóng sau 4 giây
        persist: false,
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

const _tabLabels = {
  FoodTab.recipes: 'Món nấu',
  FoodTab.dishes: 'Món ăn sẵn',
  FoodTab.ingredients: 'Nguyên liệu',
};

/// Màn Ghi bữa ăn: tìm trong 3 nguồn rồi chọn lượng ở [PortionSheet] (§7.2).
class LogMealScreen extends StatefulWidget {
  const LogMealScreen({
    super.key,
    required this.meal,
    required this.date,
    this.search,
  });

  final MealType meal;

  /// Ngày ghi, dạng YYYY-MM-DD.
  final String date;

  /// Mặc định [foodSearchRepo] (tiêm vào để test).
  final FoodSearchRepository? search;

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen>
    with SingleTickerProviderStateMixin {
  LogMealController? _c;
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _text = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final store = DiaryScope.of(context);
    _c = LogMealController(
      store: store,
      catalog: RecipeScope.of(context),
      search: widget.search ?? foodSearchRepo,
      meal: widget.meal,
      date: widget.date,
    )..addListener(_onChanged);
    // Không tải trong build: store báo đổi ngay khi chuyển sang loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(store.ensureDay(widget.date));
    });
  }

  @override
  void dispose() {
    _c?.removeListener(_onChanged);
    _c?.dispose();
    _tabs.dispose();
    _text.dispose();
    super.dispose();
  }

  LogMealController get c => _c!;

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _setTab(FoodTab t) {
    _tabs.index = t.index;
    c.setTab(t);
  }

  Future<void> _open(PortionFood food) async {
    FocusScope.of(context).unfocus();
    final out = await showPortionSheet(context, controller: c, food: food);
    if (!mounted) return;
    // Sau lỗi mạng: làm mới ngày vì request có thể đã tới server
    unawaited(c.onSheetClosed().catchError((Object _) {}));
    switch (out) {
      case LogAdded(:final result):
        Navigator.of(context)
            .pop(LogMealResult(result: result, name: food.name));
      case LogProfileMissingOutcome():
        // Làm mới để màn trước thấy trạng thái "chưa có hồ sơ"
        unawaited(c.store.refreshDay(c.date).catchError((Object _) {}));
        Navigator.of(context).pop();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: _searchField(),
                  ),
                  TabBar(
                    controller: _tabs,
                    onTap: (i) => c.setTab(FoodTab.values[i]),
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3,
                        color: AppColors.primaryDark,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      for (final t in FoodTab.values)
                        Tab(height: 48, text: _tabLabels[t]),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final meal = c.meal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PopupMenuButton<MealType>(
                  tooltip: 'Đổi bữa',
                  initialValue: meal,
                  onSelected: (m) => c.meal = m,
                  itemBuilder: (_) => [
                    for (final m in MealType.values)
                      PopupMenuItem(value: m, child: Text('Bữa ${m.labelVi}')),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Thêm vào bữa ${meal.labelVi}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 28 / 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                Text(
                  _subtitle(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
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

  /// "Hôm nay · bữa tối còn 591 kcal"; ngày khác ghi "T2, 9/11". Chưa có DayLog thì ẩn số.
  String _subtitle() {
    final store = DiaryScope.of(context);
    final date = c.date;
    final d = parseIsoDate(date);
    final dayText = date == store.today || d == null
        ? 'Hôm nay'
        : '${weekdayShort(d)}, ${d.day}/${d.month}';
    final log = store.day(date).log;
    final budget = log == null
        ? null
        : mealBudgetKcal(log.budget.target.kcal, c.meal);
    if (log == null || budget == null) return dayText;
    final left = budget - (log.meals[c.meal]?.kcal ?? 0);
    final meal = 'bữa ${c.meal.labelVi}';
    return left < 0
        ? '$dayText · $meal vượt ${formatKcal(-left)} kcal'
        : '$dayText · $meal còn ${formatKcal(left)} kcal';
  }

  Widget _searchField() {
    OutlineInputBorder border(Color col, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: col, width: w),
    );
    return TextField(
      controller: _text,
      onChanged: c.setQuery,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Tìm món, món ăn sẵn, nguyên liệu',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(Icons.search, size: 22, color: AppColors.textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: _text.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xoá từ khoá',
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () {
                  _text.clear();
                  c.setQuery('');
                },
              ),
        enabledBorder: border(Colors.transparent, 1),
        focusedBorder: border(AppColors.primary, 2),
      ),
    );
  }

  Widget _body() {
    final tab = c.tab;
    final st = c.stateOf(tab);
    switch (st.status) {
      case SearchStatus.loading:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const FoodTileSkeleton(),
        );
      case SearchStatus.offline:
      case SearchStatus.failed:
        return _ErrorBlock(
          offline: st.status == SearchStatus.offline,
          onRetry: c.retry,
        );
      case SearchStatus.ready:
        break;
    }
    final count = tab == FoodTab.recipes ? st.recipes.length : st.hits.length;
    final q = c.query.trim();
    if (count == 0) {
      if (q.isEmpty) {
        return const _Message(
          icon: Icons.search,
          title: 'Chưa có món nào',
          body: null,
        );
      }
      return _NoResult(
        query: q,
        otherTabs: [
          for (final t in FoodTab.values)
            if (t != tab) t,
        ],
        onTab: _setTab,
      );
    }
    final label =
        st.sectionLabel ?? '$count${st.hasMore ? '+' : ''} kết quả cho “$q”';
    final footer = st.loadMoreFailed || st.hasMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Gần cuối danh sách thì tải trang tiếp (controller tự chặn gọi trùng)
        if (st.hasMore && !st.loadMoreFailed && n.metrics.extentAfter < 400) {
          unawaited(c.loadMore());
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: count + 1 + (footer ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            );
          }
          if (i == count + 1) return _footer(st);
          final idx = i - 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: tab == FoodTab.recipes
                ? _recipeTile(st.recipes[idx])
                : _hitTile(st.hits[idx]),
          );
        },
      ),
    );
  }

  Widget _footer(FoodTabState st) {
    if (st.loadMoreFailed) {
      return Center(
        child: TextButton(
          onPressed: c.loadMore,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            minimumSize: const Size(48, 48),
          ),
          child: const Text('Không tải thêm được. Thử lại'),
        ),
      );
    }
    return const SizedBox(
      height: 48,
      child: Center(
        child: Text(
          'Đang tải thêm…',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }

  static String _macroLine(double p, double c, double f) =>
      'P ${formatGram(p)} · C ${formatGram(c)} · F ${formatGram(f)} g';

  Widget _recipeTile(Recipe r) => FoodResultTile(
    name: r.title,
    macroLine: _macroLine(r.proteinG, r.carbsG, r.fatG),
    kcalValue: formatKcal(r.kcal),
    kcalUnit: 'kcal/phần',
    onTap: () => _open(PortionFood.recipe(r)),
  );

  Widget _hitTile(FoodHit h) => FoodResultTile(
    name: h.name,
    macroLine: _macroLine(h.per100.proteinG, h.per100.carbsG, h.per100.fatG),
    kcalValue: formatKcal(h.per100.kcal),
    kcalUnit: 'kcal/100 g',
    onTap: () => _open(PortionFood.hit(h)),
  );
}

/// Khối giữa màn: icon tròn, tiêu đề, mô tả, nội dung thêm.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline),
            ),
            child: Icon(icon, size: 28, color: AppColors.textMuted),
          ),
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
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
        if (extra != null) ...[const SizedBox(height: 16), extra!],
      ],
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({
    required this.query,
    required this.otherTabs,
    required this.onTab,
  });

  final String query;
  final List<FoodTab> otherTabs;
  final void Function(FoodTab) onTab;

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.search,
      title: 'Không tìm thấy “$query”',
      body: 'Thử gõ tên ngắn hơn, hoặc tìm ở tab khác:',
      extra: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final t in otherTabs)
            OutlinedButton(
              onPressed: () => onTab(t),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.outlineStrong),
                shape: const StadiumBorder(),
                minimumSize: const Size(48, 48),
              ),
              child: Text(_tabLabels[t]!),
            ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.offline, required this.onRetry});

  final bool offline;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: offline ? Icons.wifi_off : Icons.error_outline,
      title: offline ? 'Không có kết nối mạng' : 'Không tải được danh sách',
      body: offline
          ? 'Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.'
          : 'Đã có lỗi khi tìm món. Thử lại sau ít phút.',
      extra: Center(
        child: SizedBox(
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
      ),
    );
  }
}
