import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/auth/widgets/auth_widgets.dart';

/// Màn Chào (Figma: WelcomeScreen 2:45) — 2 lối vào: Bắt đầu / Đăng nhập
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Phần nội dung: cuộn được nếu màn hình thấp
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHeader(),
                    _HeroCard(),
                    SizedBox(height: 24),
                    _ValueProposition(),
                    SizedBox(height: 25),
                    _FeatureTiles(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Nút hành động: luôn ghim ở đáy màn hình
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Bắt đầu',
                    onPressed: () => context.push('/onboarding'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size.fromHeight(40),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.12,
                      ),
                    ),
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo lá trong vòng tròn xanh nhạt + chữ "Elytra"
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/elytra_leaf_logo.png',
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Elytra',
            style: TextStyle(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.55,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ ảnh món ăn + 3 nhãn nổi ở đáy ảnh
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 288,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.outline),
              Image.asset(
                'assets/images/welcome_food_bowl.png',
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MacroBadge(
                      leading: SvgPicture.asset('assets/icons/ic_kcal.svg'),
                      label: '420 kcal',
                      color: const Color(0xFF92400E),
                      weight: FontWeight.w700,
                    ),
                    const _MacroBadge(
                      leading: _Dot(),
                      label: 'Tăng cân',
                      color: AppColors.primaryDark,
                      weight: FontWeight.w600,
                    ),
                    _MacroBadge(
                      leading: SvgPicture.asset('assets/icons/ic_protein.svg'),
                      label: '32g Protein',
                      color: const Color(0xFF075985),
                      weight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: AppColors.primary,
      shape: BoxShape.circle,
    ),
  );
}

/// Nhãn bo tròn nền trắng 90%: icon + chữ 11px
class _MacroBadge extends StatelessWidget {
  const _MacroBadge({
    required this.leading,
    required this.label,
    required this.color,
    required this.weight,
  });

  final Widget leading;
  final String label;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              height: 16.5 / 11,
              fontWeight: weight,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề lớn + mô tả ngắn
class _ValueProposition extends StatelessWidget {
  const _ValueProposition();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Ăn đúng chuẩn,\ndáng khoa học',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            height: 38 / 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tính nhu cầu calo và macro theo thể trạng của bạn trong 1 phút',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 22.75 / 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 3 ô tính năng nằm ngang, cao bằng nhau.
/// Theo Figma: cả hàng rộng cố định 342, mỗi ô ~107 x 121, cách nhau 10.
class _FeatureTiles extends StatelessWidget {
  const _FeatureTiles();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 342,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureTile(
                  icon: 'assets/icons/ic_portion.svg',
                  title: 'Đo khẩu\nphần',
                  subtitle: 'Chuẩn món Việt',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FeatureTile(
                  icon: 'assets/icons/ic_macro.svg',
                  title: 'Cân bằng\nMacro',
                  subtitle: 'Đạm · Đường ·\nBéo',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FeatureTile(
                  icon: 'assets/icons/ic_target.svg',
                  title: 'Theo sát\nđích',
                  subtitle: 'Không áp lực',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: false,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            softWrap: false,
            style: const TextStyle(
              fontSize: 10,
              height: 2,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
