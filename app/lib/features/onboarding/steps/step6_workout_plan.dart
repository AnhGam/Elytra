import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 6 – Kế hoạch tập luyện (chỉ có khi Giảm cân / Tăng cân).
/// Các giá trị ở đây KHÔNG đổi lượng calo (mức vận động ở bước 3 đã tính
/// phần tập luyện); chúng được lưu để sau này gợi ý món ăn hợp giờ tập.
class Step6WorkoutPlan extends StatelessWidget {
  const Step6WorkoutPlan({super.key, required this.draft});

  final BodyInfoDraft draft;

  @override
  Widget build(BuildContext context) {
    final losing = draft.goal == Goal.loseWeight;
    final hours = draft.workoutHours;
    const min = BodyInfoLimits.minWorkoutHours;
    const max = BodyInfoLimits.maxWorkoutHours;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const StepHeading(
          title: 'Kế hoạch tập luyện của bạn',
          description: 'Giúp Elytra gợi ý món ăn phù hợp với giờ tập của bạn.',
        ),
        const SizedBox(height: 20),

        // ----- Thẻ 1: số giờ tập mỗi ngày -----
        WizardCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SỐ GIỜ TẬP MỖI NGÀY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gồm cả cardio và tập tạ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // [−]  1 giờ  [+]
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TouchTarget(
                    onTap: hours - 1 >= min
                        ? () => draft.setWorkoutHours(hours - 1)
                        : null,
                    child: CircleStepButton(
                      size: 40,
                      outlined: true, // nền trắng viền xám theo Figma
                      icon: Icons.remove,
                      tooltip: 'Giảm 1 giờ',
                      onPressed: hours - 1 >= min
                          ? () => draft.setWorkoutHours(hours - 1)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$hours',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'giờ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  TouchTarget(
                    onTap: hours + 1 <= max
                        ? () => draft.setWorkoutHours(hours + 1)
                        : null,
                    child: CircleStepButton(
                      size: 40,
                      outlined: true, // nền trắng viền xám theo Figma
                      icon: Icons.add,
                      tooltip: 'Tăng 1 giờ',
                      onPressed: hours + 1 <= max
                          ? () => draft.setWorkoutHours(hours + 1)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                value: hours.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                minLabel: '$min giờ',
                maxLabel: '$max giờ',
                semanticLabel: 'Số giờ tập mỗi ngày',
                onChanged: (v) => draft.setWorkoutHours(v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ----- Thẻ 2–3: hai công tắc -----
        _ToggleCard(
          icon: Icons.local_fire_department_outlined,
          title: losing
              ? 'Tập gym kết hợp siết calo'
              : 'Tập gym kết hợp tăng cân',
          subtitle: losing
              ? 'Ưu tiên món giàu đạm, ít calo sau buổi tập'
              : 'Ưu tiên món giàu đạm, đủ năng lượng sau buổi tập',
          value: draft.preferGymCutting,
          onChanged: draft.setPreferGymCutting,
        ),
        const SizedBox(height: 12),
        _ToggleCard(
          icon: Icons.eco_outlined,
          title: 'Ăn uống lành mạnh',
          subtitle: 'Ưu tiên thực phẩm tươi, ít chế biến',
          value: draft.preferHealthyEating,
          onChanged: draft.setPreferHealthyEating,
        ),
      ],
    );
  }
}

/// Thẻ có công tắc bật/tắt; bấm vào bất kỳ đâu trên thẻ cũng đổi được
class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: MergeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.textMuted),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  thumbColor: const WidgetStatePropertyAll(Colors.white),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: const Color(0xFFD1DCE8),
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
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
