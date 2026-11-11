import 'package:flutter/material.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/home/widgets/meal_card.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/portion_math.dart';

/// "1,5 phần" hoặc "150 g".
String itemAmountLabel(MealLogItem it) {
  if (it.byServings) return formatServings(it.servings ?? 1);
  final g = it.amountG;
  return g == null ? '' : '${formatGram(g)} g';
}

/// Thẻ tóm tắt ngày: "Hôm nay · 10/11", "1.152 / 1.968 kcal", thanh kcal và 3 macro.
class DaySummaryCard extends StatelessWidget {
  const DaySummaryCard({super.key, required this.title, required this.budget});

  final String title;
  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final t = budget.target, c = budget.consumed;
    final over = isOver(c.kcal, t.kcal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Máy hẹp: số thu nhỏ thay vì tràn
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    t.kcal > 0
                        ? '${formatKcal(c.kcal)} / ${formatKcal(t.kcal)} kcal'
                        : '${formatKcal(c.kcal)} kcal',
                    style: TextStyle(
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w700,
                      color: over
                          ? AppColors.onErrorContainer
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(
            ratio: progressRatio(c.kcal, t.kcal),
            color: over ? AppColors.error : AppColors.primary,
            track: AppColors.outline,
            height: 8,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroCol(
                label: 'Protein',
                consumed: c.proteinG,
                target: t.proteinG,
                color: AppColors.protein,
                track: AppColors.proteinContainer,
                valueColor: AppColors.onProteinContainer,
              ),
              const SizedBox(width: 16),
              _MacroCol(
                label: 'Carbs',
                consumed: c.carbsG,
                target: t.carbsG,
                color: AppColors.carbs,
                track: AppColors.carbsContainer,
                valueColor: AppColors.onCarbsContainer,
              ),
              const SizedBox(width: 16),
              _MacroCol(
                label: 'Fat',
                consumed: c.fatG,
                target: t.fatG,
                color: AppColors.fat,
                track: AppColors.fatContainer,
                valueColor: AppColors.onFatContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCol extends StatelessWidget {
  const _MacroCol({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.track,
    required this.valueColor,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;
  final Color track;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final over = isOver(consumed, target);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              height: 18 / 13,
              color: AppColors.textMuted,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatGram(consumed),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: over ? AppColors.onErrorContainer : valueColor,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${formatGram(target)} g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          _Bar(
            ratio: progressRatio(consumed, target),
            color: over ? AppColors.error : color,
            track: track,
            height: 4,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.ratio,
    required this.color,
    required this.track,
    required this.height,
  });

  final double ratio;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: ratio,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhóm một bữa: tiêu đề, kcal của bữa, nút + (ẩn khi ngoài 30 ngày) và các món.
class MealGroup extends StatelessWidget {
  const MealGroup({
    super.key,
    required this.type,
    required this.log,
    required this.editable,
    required this.onAdd,
    required this.onTapItem,
    required this.onDismissItem,
  });

  final MealType type;
  final MealLog log;
  final bool editable;
  final VoidCallback onAdd;
  final ValueChanged<MealLogItem> onTapItem;
  final ValueChanged<MealLogItem> onDismissItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, editable ? 4 : 16, 12),
            child: Row(
              children: [
                MealIcon(type: type),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bữa ${type.labelVi}',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${formatKcal(log.kcal)} kcal',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                if (editable)
                  SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      tooltip: 'Thêm vào bữa ${type.labelVi}',
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, color: AppColors.primaryDark),
                    ),
                  ),
              ],
            ),
          ),
          if (log.items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Chưa ghi món nào',
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final it in log.items) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.outline),
              DiaryItemTile(
                key: ValueKey(it.id),
                item: it,
                editable: editable,
                onTap: () => onTapItem(it),
                onDismissed: () => onDismissItem(it),
              ),
            ],
        ],
      ),
    );
  }
}

/// Một món trong nhật ký: tên, lượng + macro, kcal, mũi tên. Vuốt trái để xoá khi sửa được.
class DiaryItemTile extends StatelessWidget {
  const DiaryItemTile({
    super.key,
    required this.item,
    required this.editable,
    required this.onTap,
    required this.onDismissed,
  });

  final MealLogItem item;
  final bool editable;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final m = item.macros;
    final tile = InkWell(
      onTap: editable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 22 / 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(itemAmountLabel(item), style: _sub),
                      _MacroDot(
                        color: AppColors.protein,
                        text: 'P ${formatGram(m.proteinG)}',
                      ),
                      _MacroDot(
                        color: AppColors.carbs,
                        text: 'C ${formatGram(m.carbsG)}',
                      ),
                      _MacroDot(
                        color: AppColors.fat,
                        text: 'F ${formatGram(m.fatG)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatKcal(m.kcal)} kcal',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (editable)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right, color: AppColors.textSubtle),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
    if (!editable) return tile;
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.onErrorContainer,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: tile,
    );
  }

  static const _sub = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    color: AppColors.textMuted,
  );
}

class _MacroDot extends StatelessWidget {
  const _MacroDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(text, style: DiaryItemTile._sub),
      ],
    );
  }
}
