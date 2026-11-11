import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/theme.dart';
import 'package:elytra/features/meal_logs/budget_view.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';

/// Icon, màu nền và màu icon của từng bữa (theo README Sprint 5).
({String icon, Color container, Color tint}) mealVisual(MealType t) =>
    switch (t) {
      MealType.breakfast => (
        icon: 'assets/icons/ic_sunrise.svg',
        container: AppColors.primaryContainer,
        tint: AppColors.primaryDark,
      ),
      MealType.lunch => (
        icon: 'assets/icons/ic_sun.svg',
        container: AppColors.carbsContainer,
        tint: AppColors.carbs,
      ),
      MealType.dinner => (
        icon: 'assets/icons/ic_moon.svg',
        container: AppColors.proteinContainer,
        tint: AppColors.protein,
      ),
      MealType.snack => (
        icon: 'assets/icons/ic_snack.svg',
        container: AppColors.fatContainer,
        tint: AppColors.fat,
      ),
    };

/// Ô icon bữa (vuông bo góc, nền theo bữa).
class MealIcon extends StatelessWidget {
  const MealIcon({super.key, required this.type, this.size = 40});

  final MealType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = mealVisual(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: v.container,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        v.icon,
        width: size * 0.45,
        height: size * 0.45,
        colorFilter: ColorFilter.mode(v.tint, BlendMode.srcIn),
      ),
    );
  }
}

/// Thẻ một bữa trên Dashboard: tên món, "487 / 492 kcal", thanh tiến độ, nút +.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.type,
    required this.log,
    required this.budgetKcal,
    required this.current,
    required this.onAdd,
  });

  final MealType type;
  final MealLog log;

  /// Ngân sách kcal của bữa; null khi chưa có mục tiêu.
  final int? budgetKcal;

  /// Bữa trùng giờ hiện tại: viền `primary` và chữ "· đến giờ".
  final bool current;
  final VoidCallback onAdd;

  String get _names {
    if (log.items.isEmpty) return 'Chưa ghi món nào';
    // Nối mọi tên, dòng quá dài thì Text tự cắt bằng "…"
    return log.items.map((e) => e.name).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final budget = budgetKcal?.toDouble();
    final over = isOver(log.kcal, budget);
    final title = 'Bữa ${type.labelVi}${current ? ' · đến giờ' : ''}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current ? AppColors.primary : AppColors.outline,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MealIcon(type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Số lớn trên máy hẹp thì thu nhỏ thay vì tràn
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKcal(log.kcal),
                        style: TextStyle(
                          fontSize: 17,
                          height: 24 / 17,
                          fontWeight: FontWeight.w700,
                          color: over
                              ? AppColors.onErrorContainer
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        budgetKcal == null
                            ? 'kcal'
                            : '/ ${formatKcal(budgetKcal!)} kcal',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox.square(
                dimension: 48,
                child: IconButton(
                  tooltip: 'Thêm vào bữa ${type.labelVi}',
                  onPressed: onAdd,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _Progress(
              ratio: progressRatio(log.kcal, budget),
              over: over,
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.ratio, required this.over});

  final double ratio;
  final bool over;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.outline)),
            FractionallySizedBox(
              widthFactor: ratio,
              heightFactor: 1,
              child: ColoredBox(
                color: over ? AppColors.error : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
