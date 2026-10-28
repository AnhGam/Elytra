import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:elytra/features/recipes/recipe_search_controller.dart';
import 'package:elytra/features/recipes/recipe_text.dart';
import 'package:elytra/features/recipes/widgets/recipe_card.dart';
import 'package:elytra/features/recipes/widgets/recipe_chips.dart';
import 'package:elytra/features/recipes/widgets/skeletons.dart';

final _kcal = NumberFormat('#,##0', 'vi');

/// Tab Món ăn: tìm theo tên, lọc nhanh, nhóm món, sắp xếp
class RecipeSearchScreen extends StatefulWidget {
  const RecipeSearchScreen({super.key});

  @override
  State<RecipeSearchScreen> createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  RecipeSearchController? _controller;
  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  bool _textEmpty = true;

  RecipeSearchController get _c => _controller!;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    // Khung gợi ý theo chữ trong ô (không chờ debounce) để không nháy khi vừa gõ
    _text.addListener(() {
      final empty = _text.text.isEmpty;
      if (empty != _textEmpty) setState(() => _textEmpty = empty);
    });
    // Tải sau frame đầu: catalog báo thay đổi ngay khi bắt đầu tải, không được gọi trong build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.catalog.ensureLoaded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= RecipeSearchController(catalog: RecipeScope.of(context));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller?.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _c.setQuery(v));
  }

  void _setQueryNow(String v) {
    _debounce?.cancel();
    _c.setQuery(v);
  }

  void _onSubmitted(String v) {
    _setQueryNow(v);
    _c.submitQuery();
    _focus.unfocus();
  }

  void _clearQuery() {
    _text.clear();
    _setQueryNow('');
  }

  void _useRecent(String q) {
    _text.text = q;
    _setQueryNow(q);
    _focus.unfocus();
  }

  void _clearFilters() {
    _text.clear();
    _setQueryNow('');
    _c.applyFilters(const RecipeFilters());
  }

  void _open(Recipe r) {
    _focus.unfocus();
    _c.recordOpened();
    context.push('/recipes/${r.id}', extra: r);
  }

  Future<void> _refresh() async {
    try {
      await _c.catalog.refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải lại được. Kiểm tra mạng.')),
      );
    }
  }

  // Task 14 thay bằng sheet Bộ lọc, Sắp xếp, Dị ứng
  void _openSheetPlaceholder() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) =>
          const SizedBox(height: 200, child: Center(child: Text('Sắp có'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final showSuggestions = _focus.hasFocus && _textEmpty;
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Sắp có'))),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tooltip: 'Trợ lý AI',
            child: const Icon(Icons.auto_awesome),
          ),
          body: Column(
            children: [
              _buildHeader(showChips: !showSuggestions),
              Expanded(
                child: showSuggestions
                    // Chạm trong vùng gợi ý không làm ô tìm mất focus
                    ? TextFieldTapRegion(child: _buildSuggestions())
                    : _buildBody(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool showChips}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                'Món ăn',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 8),
                  _buildFilterButton(),
                ],
              ),
            ),
            if (showChips) ...[
              _chipRow(_quickChips()),
              _chipRow(_categoryChips()),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      key: const Key('recipeSearchField'),
      controller: _text,
      focusNode: _focus,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: _onSubmitted,
      onTapOutside: (_) => _focus.unfocus(),
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Tìm tên món…',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: ValueListenableBuilder(
          valueListenable: _text,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Xóa từ khóa',
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: _clearQuery,
                ),
        ),
        enabledBorder: border(AppColors.outline, 1),
        focusedBorder: border(AppColors.primary, 2),
      ),
    );
  }

  Widget _buildFilterButton() {
    final badge = _c.filters.sheetBadgeCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outline),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: _openSheetPlaceholder,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/ic_tune.svg',
                  width: 18,
                  semanticsLabel: 'Bộ lọc',
                ),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chipRow(List<Widget> chips) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  List<Widget> _quickChips() {
    return [
      if (_c.hasDeclaredAllergens)
        QuickFilterChip(
          label: 'Bỏ món dị ứng',
          selected: _c.excludeAllergens,
          onTap: _c.toggleExcludeAllergens,
        )
      else
        QuickFilterChip(
          label: 'Khai báo dị ứng',
          selected: false,
          icon: Icons.add,
          onTap: _openSheetPlaceholder,
        ),
      QuickFilterChip(
        label: 'Từ tủ lạnh',
        selected: _c.fridge,
        onTap: _c.toggleFridge,
      ),
      QuickFilterChip(
        label: '≤ 500 kcal',
        selected: _c.under500,
        onTap: _c.toggleUnder500,
      ),
      QuickFilterChip(
        label: '≤ 30 phút',
        selected: _c.under30Min,
        onTap: _c.toggleUnder30Min,
      ),
    ];
  }

  List<Widget> _categoryChips() {
    final current = _c.filters.category;
    void pick(String? c) => _c.applyFilters(_c.filters.copyWith(category: c));
    return [
      CategoryChip(
        label: 'Tất cả',
        selected: current == null,
        onTap: () => pick(null),
      ),
      for (final c in _c.categories)
        CategoryChip(
          label: categoryLabel(c),
          selected: current == c,
          onTap: () => pick(c),
        ),
    ];
  }

  Widget _buildBody() {
    final catalog = _c.catalog;
    switch (catalog.status) {
      case CatalogStatus.idle:
      case CatalogStatus.loading:
        return _buildLoading();
      case CatalogStatus.error:
        return _buildOffline();
      case CatalogStatus.ready:
        break;
    }
    final results = _c.results;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _countRow('${results.length} món')),
          if (results.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 96),
              sliver: SliverList.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => RecipeCard(
                  recipe: results[i],
                  onTap: () => _open(results[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _countRow(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _openSheetPlaceholder,
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _c.sort.labelVi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // Nút cao 32 nhưng vùng chạm vẫn 48
                  tapTargetSize: MaterialTapTargetSize.padded,
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.outlineStrong),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _countRow('Đang tìm…'),
        for (var i = 0; i < 3; i++)
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: RecipeCardSkeleton(),
          ),
      ],
    );
  }

  Widget _buildOffline() {
    return SingleChildScrollView(
      child: _EmptyState(
        icon: Icons.wifi_off,
        title: 'Không có kết nối mạng',
        message: 'Kiểm tra Wi‑Fi hoặc dữ liệu di động\nrồi thử lại.',
        action: FilledButton(
          onPressed: _c.catalog.ensureLoaded,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: AppColors.surface,
            minimumSize: const Size(104, 48),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('Thử lại'),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final keepsAllergen = _c.excludeAllergens && _c.hasDeclaredAllergens;
    return _EmptyState(
      icon: Icons.search_off,
      title: 'Không tìm thấy món phù hợp',
      message: 'Thử bỏ bớt bộ lọc\nhoặc đổi từ khóa.',
      action: OutlinedButton.icon(
        onPressed: _clearFilters,
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Xóa bộ lọc'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.primaryContainer,
          side: const BorderSide(color: AppColors.primaryOutline),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      footnote: keepsAllergen
          ? 'Lọc dị ứng luôn được giữ để đảm bảo an toàn'
          : null,
    );
  }

  Widget _buildSuggestions() {
    final recent = _c.recentSearches;
    final popular = _c.popular;
    const heading = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
    return Material(
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
        children: [
          if (recent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
              child: Row(
                children: [
                  const Expanded(child: Text('Tìm gần đây', style: heading)),
                  TextButton(
                    onPressed: _c.clearRecents,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                    ),
                    child: const Text('Xóa tất cả'),
                  ),
                ],
              ),
            ),
            for (final q in recent)
              ListTile(
                contentPadding: const EdgeInsets.only(left: 24, right: 12),
                leading: const Icon(Icons.history, color: AppColors.textSubtle),
                title: Text(
                  q,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: IconButton(
                  tooltip: 'Xóa khỏi tìm gần đây',
                  icon: const Icon(Icons.close, color: AppColors.textSubtle),
                  onPressed: () => _c.removeRecent(q),
                ),
                onTap: () => _useRecent(q),
              ),
            const SizedBox(height: 16),
          ],
          if (popular.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Món phổ biến', style: heading),
            ),
            for (final r in popular)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 48,
                    child: RecipeImage(url: r.imageUrl, iconSize: 20),
                  ),
                ),
                title: Text(
                  displayTitle(r.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '${_kcal.format(r.kcal)} kcal · ${categoryLabel(r.category)}'
                  ' · ${formatDuration(r.totalMinutes)}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => _open(r),
              ),
          ],
        ],
      ),
    );
  }
}

/// Khối giữa màn: icon tròn, tiêu đề, lời nhắn, nút hành động
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outline),
              ),
              child: Icon(icon, size: 30, color: AppColors.textSubtle),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            action,
            if (footnote != null) ...[
              const SizedBox(height: 16),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
