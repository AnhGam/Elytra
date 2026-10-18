import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 4 – Mục tiêu: 3 thẻ Giảm cân / Duy trì / Tăng cân.
/// Thẻ được chọn tô màu riêng và mở thêm gợi ý dinh dưỡng.
/// Chọn Giảm hoặc Tăng cân → wizard thành 6 bước (thêm bước 5–6).
class Step4Goal extends StatelessWidget {
  const Step4Goal({super.key, required this.draft});

  final BodyInfoDraft draft;

  static const _options = [
    _GoalOption(
      goal: Goal.loseWeight,
      title: 'Giảm cân',
      subtitle: 'Bớt khoảng 500 kcal mỗi ngày',
      hint: 'Giảm mỡ, giữ cơ · Ưu tiên đạm',
      macro: 'Protein 2,0 g/kg · Chất béo 25%',
      icon: Icons.trending_down,
      theme: _GoalTheme(
        background: Color(0xFFFEF3C7),
        accent: Color(0xFFD97706),
        text: Color(0xFF92400E),
        divider: Color(0xFFFDE68A),
      ),
    ),
    _GoalOption(
      goal: Goal.maintain,
      title: 'Duy trì cân nặng',
      subtitle: 'Ăn bằng đúng TDEE của bạn',
      hint: 'Giữ cân nặng · Ăn uống cân bằng',
      macro: 'Protein 1,6 g/kg · Chất béo 25%',
      icon: Icons.favorite_border,
      theme: _GoalTheme(
        background: Color(0xFFE0F2FE),
        accent: Color(0xFF0284C7),
        text: Color(0xFF075985),
        divider: Color(0xFFBAE6FD),
      ),
    ),
    _GoalOption(
      goal: Goal.gainWeight,
      title: 'Tăng cân',
      subtitle: 'Thêm khoảng 400 kcal mỗi ngày',
      hint: 'Tăng cân, tập luyện · Bổ sung đạm',
      macro: 'Protein 1,8 g/kg · Chất béo 25%',
      icon: Icons.trending_up,
      theme: _GoalTheme(
        background: AppColors.primaryContainer,
        accent: AppColors.primary,
        text: AppColors.primaryDark,
        divider: Color(0xFFBBF7D0),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const StepHeading(
          title: 'Mục tiêu của bạn là gì?',
          description: 'Quyết định lượng calo và tỷ lệ dinh dưỡng mỗi ngày.',
        ),
        const SizedBox(height: 20),
        for (final option in _options) ...[
          _GoalCard(
            option: option,
            selected: draft.goal == option.goal,
            onTap: () => draft.setGoal(option.goal),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Bộ màu của một mục tiêu khi được chọn
class _GoalTheme {
  const _GoalTheme({
    required this.background,
    required this.accent,
    required this.text,
    required this.divider,
  });

  final Color background; // nền thẻ
  final Color accent; // viền thẻ + ô icon
  final Color text; // tên mục tiêu, gợi ý, dấu tích
  final Color divider; // đường kẻ trên phần gợi ý
}

class _GoalOption {
  const _GoalOption({
    required this.goal,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.macro,
    required this.icon,
    required this.theme,
  });

  final Goal goal;
  final String title;
  final String subtitle;
  final String hint;
  final String macro;
  final IconData icon;
  final _GoalTheme theme;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = option.theme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.background : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? t.accent : AppColors.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ô icon 40x40 bo 12
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? t.accent : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option.icon,
                    size: 20,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected ? t.text : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted, // mô tả luôn màu xám
                        ),
                      ),
                      // Phần gợi ý chỉ mở ra khi thẻ được chọn
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: selected
                            ? _hint(t)
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check, size: 20, color: t.text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(_GoalTheme t) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.hint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.egg_outlined, size: 14, color: t.accent),
                const SizedBox(width: 6),
                Text(
                  option.macro,
                  style: TextStyle(fontSize: 11, color: t.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
