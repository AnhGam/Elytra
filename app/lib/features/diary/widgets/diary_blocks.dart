import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/theme.dart';

/// Các khối dùng chung của tab Nhật ký (Theo ngày và Thống kê).

/// Khung thẻ thông báo giữa màn (mất mạng, chưa có hồ sơ).
class DiaryMessageCard extends StatelessWidget {
  const DiaryMessageCard({
    super.key,
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

class DiaryErrorBlock extends StatelessWidget {
  const DiaryErrorBlock({
    super.key,
    required this.offline,
    required this.onRetry,
  });

  final bool offline;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DiaryMessageCard(
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

class DiaryProfileMissing extends StatelessWidget {
  const DiaryProfileMissing({super.key});

  @override
  Widget build(BuildContext context) {
    return DiaryMessageCard(
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
class DiarySkeleton extends StatelessWidget {
  const DiarySkeleton({super.key});

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
