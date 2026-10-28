import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_detail_controller.dart';
import 'package:elytra/features/recipes/recipe_search_controller.dart';
import 'package:elytra/features/recipes/recipe_text.dart';
import 'package:elytra/features/recipes/widgets/detail_sections.dart';
import 'package:elytra/features/recipes/widgets/recipe_card.dart';
import 'package:elytra/features/recipes/widgets/sheet_frame.dart';
import 'package:elytra/features/recipes/widgets/skeletons.dart';

const _heroHeight = 240.0;
final _kcal = NumberFormat('#,##0', 'vi');

/// Màn Chi tiết món: nguyên liệu, cách nấu, dinh dưỡng, thêm 1 phần vào bữa hiện tại
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.id,
    this.initial,
    this.mealLogs,
  });

  final String id;

  /// Món truyền từ danh sách (extra) để hiện ngay phần đầu trong lúc tải
  final Recipe? initial;

  /// Tiêm bản giả trong test; mặc định gọi Edge Function thật
  final MealLogRepository? mealLogs;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  RecipeDetailController? _controller;

  RecipeDetailController get _c => _controller!;

  @override
  void initState() {
    super.initState();
    // Tải sau frame đầu: controller/catalog báo thay đổi ngay khi bắt đầu tải
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= RecipeDetailController(
      id: widget.id,
      initial: widget.initial,
      catalog: RecipeScope.of(context),
      mealLogs: widget.mealLogs ?? mealLogRepo,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _back() => Navigator.of(context).maybePop();

  Future<void> _retryCatalog() async {
    try {
      await _c.catalog.refresh();
    } catch (_) {
      // Vẫn lỗi: dòng "Chưa kiểm tra được dị ứng" tiếp tục hiện
    }
  }

  Future<void> _add() async {
    final result = await _c.addOneServing();
    if (!mounted) return;
    final meal = 'bữa ${_c.mealType.labelVi}';
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    void show(String text, [SnackBarAction? action]) =>
        messenger.showSnackBar(SnackBar(content: Text(text), action: action));
    switch (result) {
      case AddMealSuccess():
        show('Đã thêm 1 phần vào $meal');
      case AddMealOffline():
        // Thử lại gửi lại đúng client_request_id cũ (controller giữ)
        show(
          'Không có kết nối',
          SnackBarAction(label: 'Thử lại', onPressed: _add),
        );
      case AddMealProfileMissing():
        show(
          'Bạn cần hoàn tất hồ sơ trước',
          SnackBarAction(
            label: 'Khai báo',
            onPressed: () => context.go('/gate'),
          ),
        );
      case AddMealFailed():
        show('Không thêm được. Thử lại sau.');
      case AddMealIgnored():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phụ thuộc catalog: dị ứng/hồ sơ tải xong thì banner, dòng bữa cập nhật
    RecipeScope.of(context);
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        switch (_c.status) {
          case DetailStatus.notFound:
            return _message(
              icon: Icons.search_off,
              title: 'Không tìm thấy món',
              body: 'Món này không còn hoặc chưa được duyệt.',
              action: 'Quay lại',
              onAction: _back,
            );
          case DetailStatus.error when _c.detail == null:
            return _message(
              icon: Icons.wifi_off,
              title: 'Không tải được món',
              body: 'Kiểm tra kết nối mạng rồi thử lại.',
              action: 'Thử lại',
              onAction: _c.load,
            );
          default:
            return _buildContent();
        }
      },
    );
  }

  Widget _buildContent() {
    final recipe = _c.recipe;
    final detail = _c.detail;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(recipe: recipe, onBack: _back),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            sliver: SliverList.list(
              children: recipe == null
                  ? const [_BodySkeleton(full: true)]
                  : [
                      ..._buildTop(recipe),
                      if (detail == null)
                        const _BodySkeleton(full: false)
                      else
                        ..._buildDetail(detail),
                    ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAddBar(recipe),
    );
  }

  // Phần hiện được ngay từ extra: cảnh báo dị ứng, lưới 4 ô, dòng bữa, meta
  List<Widget> _buildTop(Recipe recipe) {
    final warnings = _c.allergenWarnings;
    final catalogFailed = _c.catalog.status == CatalogStatus.error;
    return [
      if (warnings.isNotEmpty) ...[
        AllergenBanner(warnings: warnings),
        const SizedBox(height: 16),
      ] else if (catalogFailed) ...[
        AllergenUncheckedLine(onRetry: _retryCatalog),
        const SizedBox(height: 4),
      ],
      MacroGrid(recipe: recipe),
      const SizedBox(height: 12),
      MealFitLine(kcal: recipe.kcal, budget: _c.mealBudget, meal: _c.mealType),
      const SizedBox(height: 12),
      RecipeMetaRow(recipe: recipe),
    ];
  }

  List<Widget> _buildDetail(RecipeDetail d) {
    final r = d.recipe;
    final profile = _c.catalog.profile;
    final target = profile?.targetKcal;
    return [
      const SizedBox(height: 24),
      ServingsHeader(
        servings: _c.cookServings,
        onDec: _c.decServings,
        onInc: _c.incServings,
      ),
      const SizedBox(height: 12),
      if (_c.cookServings != r.servings) ...[
        ServingsNote(servings: _c.cookServings),
        const SizedBox(height: 12),
      ],
      if (d.ingredients.isEmpty)
        const MutedText('Chưa có danh sách nguyên liệu')
      else
        IngredientCard(ingredients: d.ingredients, factor: _c.factor),
      const SizedBox(height: 32),
      DetailSectionHeader(
        title: 'Cách nấu',
        trailing: MutedText('${d.steps.length} bước'),
      ),
      const SizedBox(height: 12),
      for (final s in d.steps) ...[
        StepCard(
          step: s,
          done: _c.doneSteps.contains(s.number),
          onTap: () => _c.toggleStep(s.number),
        ),
        const SizedBox(height: 12),
      ],
      if (d.steps.isNotEmpty)
        const MutedText('Chạm vào bước để đánh dấu đã làm xong', size: 12),
      const SizedBox(height: 32),
      const DetailSectionHeader(
        title: 'Thông tin dinh dưỡng',
        trailing: MutedText('Mỗi khẩu phần'),
      ),
      const SizedBox(height: 12),
      NutritionCard(recipe: r, profile: profile, meal: _c.mealType),
      const SizedBox(height: 12),
      MutedText(
        target != null && target > 0
            ? 'Số liệu ước tính từ nguyên liệu · mục tiêu ngày '
                  '${_kcal.format(target)} kcal, natri tối đa 2.000 mg'
            : 'Số liệu ước tính từ nguyên liệu · natri tối đa 2.000 mg',
        size: 12,
      ),
    ];
  }

  Widget _buildAddBar(Recipe? recipe) {
    final sending = _c.sending;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: FilledButton.icon(
            onPressed: sending || recipe == null ? null : _add,
            style: sheetPrimaryButtonStyle(),
            icon: sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.add, size: 22),
            label: Text('Thêm 1 phần vào bữa ${_c.mealType.labelVi}'),
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    required String action,
    required VoidCallback onAction,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _back,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              MutedText(body, size: 15),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(120, 48),
                ),
                child: Text(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ảnh đầu trang 240; cuộn lên thì thu về thanh trắng có nút quay lại + tên món
class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.recipe, required this.onBack});

  final Recipe? recipe;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final r = recipe;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: _heroHeight - top,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (context, box) {
          final collapsed = box.maxHeight <= kToolbarHeight + top + 24;
          if (collapsed) {
            return Container(
              padding: EdgeInsets.only(top: top),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.outline)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r == null ? '' : displayTitle(r.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              if (r == null)
                const SkeletonBox(height: _heroHeight, radius: 0)
              else ...[
                RecipeImage(url: r.imageUrl, iconSize: 48),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1],
                      colors: [
                        AppColors.textPrimary.withValues(alpha: 0),
                        AppColors.textPrimary.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: _HeroTitle(recipe: r),
                ),
              ],
              Positioned(
                left: 12,
                top: top + 4,
                child: _CircleBackButton(onPressed: onBack),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final cuisine = r.cuisine == 'vietnamese' ? 'Việt Nam' : r.cuisine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            categoryLabel(r.category),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayTitle(r.title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$cuisine · ${r.difficulty.labelVi}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.surface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

/// Nút quay lại tròn trắng 40, vùng chạm 48
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Quay lại',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        fixedSize: const Size(40, 40),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: const Icon(
        Icons.arrow_back,
        size: 22,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Khối xám cho phần đang tải (detail-04); full = chưa có cả lưới 4 ô
class _BodySkeleton extends StatelessWidget {
  const _BodySkeleton({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (full) ...[
          const SkeletonBox(width: 220, height: 24, radius: 8),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                const Expanded(child: SkeletonBox(height: 64, radius: 16)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(height: 40, radius: 12),
        ],
        const SizedBox(height: 24),
        const SkeletonBox(width: 160, height: 20, radius: 8),
        const SizedBox(height: 16),
        const SkeletonBox(height: 180, radius: 16),
      ],
    );
  }
}
