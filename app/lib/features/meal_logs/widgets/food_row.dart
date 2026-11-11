import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Một dòng kết quả tìm món: icon, tên (tối đa 2 dòng), dòng macro, cột kcal, nút +.
/// Bấm dòng hoặc nút + đều gọi [onTap].
class FoodResultTile extends StatelessWidget {
  const FoodResultTile({
    super.key,
    required this.name,
    required this.macroLine,
    required this.kcalValue,
    required this.kcalUnit,
    required this.onTap,
  });

  final String name;

  /// "P 39 · C 6 · F 7 g".
  final String macroLine;

  /// "240".
  final String kcalValue;

  /// "kcal/phần" hoặc "kcal/100 g".
  final String kcalUnit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      macroLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    kcalValue,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 22 / 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    kcalUnit,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              SizedBox.square(
                dimension: 48,
                child: IconButton(
                  tooltip: 'Thêm $name',
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng skeleton tĩnh cùng kích thước [FoodResultTile].
class FoodTileSkeleton extends StatelessWidget {
  const FoodTileSkeleton({super.key});

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          _bar(44, 44, r: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(140, 12),
                const SizedBox(height: 8),
                _bar(90, 10),
              ],
            ),
          ),
          _bar(40, 24),
        ],
      ),
    );
  }
}
