import 'package:flutter/material.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 1 – Thông tin cơ bản: giới tính sinh học + tuổi (frame DeclarationScreen1)
class Step1BasicInfo extends StatelessWidget {
  const Step1BasicInfo({super.key, required this.draft});

  final BodyInfoDraft draft;

  /// Nhãn nhóm tuổi trên chip xanh
  static String ageGroup(int age) {
    if (age < 30) return 'Thanh niên (18–29)';
    if (age < 45) return 'Trưởng thành (30–44)';
    if (age < 60) return 'Trung niên (45–59)';
    return 'Cao tuổi (60–80)';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const StepHeading(
          title: 'Thông tin cơ bản',
          description: 'Giới tính và tuổi giúp Elytra tính chính xác chỉ số BMR của bạn.',
        ),
        const SizedBox(height: 20),

        // ----- Giới tính sinh học -----
        const SectionLabel(icon: Icons.wc, text: 'Giới tính sinh học'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: 'Nam',
                icon: Icons.male,
                selected: draft.gender == Gender.male,
                onTap: () => draft.setGender(Gender.male),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderCard(
                label: 'Nữ',
                icon: Icons.female,
                selected: draft.gender == Gender.female,
                onTap: () => draft.setGender(Gender.female),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ----- Tuổi -----
        SectionLabel(
          icon: Icons.calendar_today_outlined,
          text: 'Tuổi của bạn',
          trailing: InfoPill(ageGroup(draft.age), green: true),
        ),
        const SizedBox(height: 8),
        WizardCard(
          child: Column(
            children: [
              // Số tuổi lớn
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${draft.age}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 6),
                  const Text('tuổi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                value: draft.age.toDouble(),
                min: BodyInfoLimits.minAge.toDouble(),
                max: BodyInfoLimits.maxAge.toDouble(),
                minLabel: '${BodyInfoLimits.minAge} tuổi',
                maxLabel: '${BodyInfoLimits.maxAge} tuổi',
                semanticLabel: 'Tuổi',
                onChanged: (v) => draft.setAge(v.round()),
              ),
              const SizedBox(height: 16),
              StepperRow(
                value: draft.age,
                min: BodyInfoLimits.minAge,
                max: BodyInfoLimits.maxAge,
                unit: 'tuổi',
                onChanged: (v) => draft.setAge(v.toInt()),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Năm sinh',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('${draft.birthYear}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thẻ chọn Nam / Nữ: chọn rồi thì nền xanh nhạt + dấu tích
class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFBBF7D0)
                              : AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            size: 20,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Text(label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color: selected
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryDark,
                      child: Icon(Icons.check, size: 12, color: Colors.white),
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
