import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';

/// Khối xám tĩnh thay cho nội dung đang tải
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.outline,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Khung thẻ món lúc đang tải: ảnh 144 + 2 dòng
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 144, radius: 0),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 200, height: 12),
                SizedBox(height: 10),
                SkeletonBox(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
