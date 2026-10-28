import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/recipes/ingredient_format.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_detail_controller.dart';
import 'package:elytra/features/recipes/recipe_nutrition.dart';

final _int = NumberFormat('#,##0', 'vi');
final _gram = NumberFormat('#,##0.#', 'vi');

/// Tiêu đề mục: chữ đậm trái, chữ mờ phải
class DetailSectionHeader extends StatelessWidget {
  const DetailSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Chữ mờ nhỏ (đếm bước, "Mỗi khẩu phần", chú thích)
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key, this.size = 13});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: size, color: AppColors.textMuted),
    );
  }
}

/// Banner đỏ: món có chất người dùng đã khai báo dị ứng
class AllergenBanner extends StatelessWidget {
  const AllergenBanner({super.key, required this.warnings});

  final List<AllergenWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final names = [
      for (final w in warnings)
        w.viaCondiment ? '${w.name} (từ gia vị)' : w.name,
    ].join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 22,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Món này có $names',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bạn đã khai báo dị ứng với các chất này. Cân nhắc trước khi thêm vào bữa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onErrorContainer,
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

/// Dòng mờ thay banner khi chưa tải được dị ứng/hồ sơ của người dùng
class AllergenUncheckedLine extends StatelessWidget {
  const AllergenUncheckedLine({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.textSubtle),
        const SizedBox(width: 6),
        const Flexible(
          child: MutedText('Chưa kiểm tra được dị ứng của bạn · '),
        ),
        // Vùng chạm tối thiểu 48×48 cho chữ liên kết nhỏ
        InkWell(
          onTap: onRetry,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: const Center(
              widthFactor: 1,
              child: Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lưới 4 ô Calo / Protein / Carbs / Fat của 1 khẩu phần
class MacroGrid extends StatelessWidget {
  const MacroGrid({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return Row(
      children: [
        _tile(
          _int.format(r.kcal),
          'kcal',
          'Calo',
          AppColors.primarySurface,
          AppColors.primaryOutline,
          AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        _tile(
          _gram.format(r.proteinG),
          'g',
          'Protein',
          AppColors.proteinContainer,
          AppColors.proteinOutline,
          AppColors.onProteinContainer,
        ),
        const SizedBox(width: 8),
        _tile(
          _gram.format(r.carbsG),
          'g',
          'Carbs',
          AppColors.carbsContainer,
          AppColors.carbsOutline,
          AppColors.onCarbsContainer,
        ),
        const SizedBox(width: 8),
        _tile(
          _gram.format(r.fatG),
          'g',
          'Fat',
          AppColors.fatContainer,
          AppColors.fatOutline,
          AppColors.onFatContainer,
        ),
      ],
    );
  }

  Widget _tile(
    String value,
    String unit,
    String label,
    Color bg,
    Color border,
    Color fg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng so với ngân sách calo của bữa hiện tại; không có ngân sách thì ẩn
class MealFitLine extends StatelessWidget {
  const MealFitLine({
    super.key,
    required this.kcal,
    required this.budget,
    required this.meal,
  });

  final double kcal;
  final int? budget;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final fit = mealFit(kcal, budget);
    if (fit == null) return const SizedBox.shrink();
    final (text, bg, fg, icon) = switch (fit) {
      MealFitWithin(:final pct) => (
        '≈ $pct% calo bữa ${meal.labelVi} của bạn (${_int.format(budget)} kcal)',
        AppColors.primarySurface,
        AppColors.primaryDark,
        Icons.local_fire_department_outlined,
      ),
      MealFitOver(:final overKcal) => (
        'Vượt ${_int.format(overKcal)} kcal so với bữa ${meal.labelVi}',
        AppColors.errorContainer,
        AppColors.onErrorContainer,
        Icons.warning_amber_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Chuẩn bị N phút · Nấu N phút · N phần"
class RecipeMetaRow extends StatelessWidget {
  const RecipeMetaRow({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSubtle),
        const SizedBox(width: 4),
        MutedText(text),
      ],
    );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        item(Icons.schedule, 'Chuẩn bị ${recipe.prepMinutes} phút'),
        item(Icons.soup_kitchen_outlined, 'Nấu ${recipe.cookMinutes} phút'),
        item(Icons.restaurant, '${recipe.servings} phần'),
      ],
    );
  }
}

/// Tiêu đề "Nguyên liệu" + stepper "Nấu cho"
class ServingsHeader extends StatelessWidget {
  const ServingsHeader({
    super.key,
    required this.servings,
    required this.onDec,
    required this.onInc,
  });

  final int servings;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    ButtonStyle style() => IconButton.styleFrom(
      fixedSize: const Size(40, 40),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return DetailSectionHeader(
      title: 'Nguyên liệu',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MutedText('Nấu cho'),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('servingsDec'),
            tooltip: 'Bớt 1 phần',
            onPressed: servings > 1 ? onDec : null,
            style: style(),
            icon: const Icon(
              Icons.remove,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '$servings phần',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            key: const Key('servingsInc'),
            tooltip: 'Thêm 1 phần',
            onPressed: servings < 20 ? onInc : null,
            style: style(),
            icon: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi chú khi đổi khẩu phần: chỉ nhân lượng nguyên liệu
class ServingsNote extends StatelessWidget {
  const ServingsNote({super.key, required this.servings});

  final int servings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Đã nhân lượng nguyên liệu cho $servings phần. '
        'Dinh dưỡng và nút “Thêm vào bữa” vẫn tính 1 phần.',
        style: const TextStyle(fontSize: 13, color: AppColors.primaryDark),
      ),
    );
  }
}

/// Thẻ danh sách nguyên liệu, mỗi dòng theo formatIngredient
class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredients,
    required this.factor,
  });

  final List<RecipeIngredient> ingredients;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final lines = [for (final i in ingredients) formatIngredient(i, factor)];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.outline),
            _row(lines[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(IngredientLine l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.name,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (l.amountText != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l.amountText!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (l.gramText != null) MutedText(l.gramText!, size: 12),
              ],
            )
          else
            // Expanded để ghi chú chiếm nửa phải và căn sát mép phải
            Expanded(
              child: Text(
                l.note ?? '',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ một bước nấu; chạm để đánh dấu xong
class StepCard extends StatelessWidget {
  const StepCard({
    super.key,
    required this.step,
    required this.done,
    required this.onTap,
  });

  final RecipeStep step;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deco = done ? TextDecoration.lineThrough : null;
    final titleColor = done ? AppColors.textMuted : AppColors.textPrimary;
    final bodyColor = done ? AppColors.textMuted : AppColors.textSecondary;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          checked: done,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: done ? ValueKey('stepDone${step.number}') : null,
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.primaryContainer
                        : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.primaryDark,
                        )
                      : Text(
                          '${step.number}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.title.isNotEmpty)
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                            decoration: deco,
                          ),
                        ),
                      if (step.title.isNotEmpty && step.description.isNotEmpty)
                        const SizedBox(height: 4),
                      if (step.description.isNotEmpty)
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: bodyColor,
                            decoration: deco,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ "Thông tin dinh dưỡng": tỉ lệ năng lượng + 6 chất so với mục tiêu ngày
class NutritionCard extends StatelessWidget {
  const NutritionCard({
    super.key,
    required this.recipe,
    required this.profile,
    required this.meal,
  });

  final Recipe recipe;
  final UserNutritionProfile? profile;
  final MealType meal;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final p = profile;
    final split = energySplit(r);
    final sodiumHigh = sodiumHighForMeal(r.sodiumMg, meal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (split != null) ...[
            const Text(
              'Tỉ lệ năng lượng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _SplitBar(split: split),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                _legend(AppColors.protein, 'Protein ${split.proteinPct}%'),
                _legend(AppColors.carbs, 'Carbs ${split.carbsPct}%'),
                _legend(AppColors.fat, 'Fat ${split.fatPct}%'),
              ],
            ),
            const SizedBox(height: 20),
          ],
          const Row(
            children: [
              Expanded(child: MutedText('Chất', size: 12)),
              MutedText('% mục tiêu ngày', size: 12),
            ],
          ),
          const SizedBox(height: 4),
          _NutrientRow(
            label: 'Calo',
            value: '${_int.format(r.kcal)} kcal',
            pct: pctOfTarget(r.kcal, p?.targetKcal),
            color: AppColors.primary,
          ),
          _NutrientRow(
            label: 'Protein',
            value: '${_gram.format(r.proteinG)} g',
            pct: pctOfTarget(r.proteinG, p?.proteinG),
            color: AppColors.protein,
          ),
          _NutrientRow(
            label: 'Carbs',
            value: '${_gram.format(r.carbsG)} g',
            pct: pctOfTarget(r.carbsG, p?.carbsG),
            color: AppColors.carbs,
          ),
          _NutrientRow(
            label: 'Fat',
            value: '${_gram.format(r.fatG)} g',
            pct: pctOfTarget(r.fatG, p?.fatG),
            color: AppColors.fat,
          ),
          _NutrientRow(
            label: 'Chất xơ',
            value: '${_gram.format(r.fiberG)} g',
            pct: pctOfTarget(r.fiberG, p?.fiberG),
            color: AppColors.primary,
          ),
          _NutrientRow(
            label: 'Natri',
            value: '${_int.format(r.sodiumMg)} mg',
            pct: pctOfTarget(r.sodiumMg, kSodiumDailyMaxMg),
            color: AppColors.carbs,
            warn: sodiumHigh,
          ),
          if (sodiumHigh)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Natri cao – nên ăn kèm rau và hạn chế nước chấm, gia vị mặn',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.split});

  final EnergySplit split;

  @override
  Widget build(BuildContext context) {
    final parts = [
      (split.proteinPct, AppColors.protein, 'protein'),
      (split.carbsPct, AppColors.carbs, 'carbs'),
      (split.fatPct, AppColors.fat, 'fat'),
    ].where((e) => e.$1 > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          // stretch: đoạn màu (không có con) cao đủ 8 thay vì 0
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                key: ValueKey('split-${parts[i].$3}'),
                flex: parts[i].$1,
                child: ColoredBox(color: parts[i].$2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.pct,
    required this.color,
    this.warn = false,
  });

  final String label;
  final String value;
  final int? pct;
  final Color color;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final pct = this.pct;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (pct != null)
                SizedBox(
                  width: 44,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: warn ? FontWeight.w600 : FontWeight.w400,
                      color: warn
                          ? AppColors.onErrorContainer
                          : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          // Mục tiêu null → chỉ hiện số, không có thanh
          if (pct != null) ...[
            const SizedBox(height: 6),
            // Rãnh xám full ngang, phần màu tính từ mép trái theo %
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                key: ValueKey('track-$label'),
                width: double.infinity,
                height: 4,
                child: ColoredBox(
                  color: AppColors.outline,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      key: ValueKey('fill-$label'),
                      widthFactor: (pct / 100).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
