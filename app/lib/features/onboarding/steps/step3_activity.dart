import 'package:flutter/material.dart';

import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 3 – Mức độ vận động: 5 thẻ chọn một (frame DeclarationScreen3).
/// Hệ số bên phải là số nhân BMR → TDEE.
class Step3Activity extends StatelessWidget {
  const Step3Activity({super.key, required this.draft});

  final BodyInfoDraft draft;

  /// (mức, tên, mô tả, hệ số hiển thị)
  static const _options = [
    (
      ActivityLevel.sedentary,
      'Ít vận động',
      'Ngồi nhiều, hầu như không tập',
      '×1,2',
    ),
    (
      ActivityLevel.light,
      'Nhẹ · 1–3 buổi/tuần',
      'Tập nhẹ hoặc đi bộ nhanh',
      '×1,375',
    ),
    (
      ActivityLevel.moderate,
      'Vừa · 3–5 buổi/tuần',
      'Gym, chạy bộ, thể thao đều đặn',
      '×1,55',
    ),
    (
      ActivityLevel.active,
      'Năng động · 6–7 buổi/tuần',
      'Tập cường độ cao gần mỗi ngày',
      '×1,725',
    ),
    (
      ActivityLevel.veryActive,
      'Rất năng động',
      'Lao động nặng, tập 2 lần/ngày',
      '×1,9',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const StepHeading(
          title: 'Mức độ vận động',
          description: 'Chọn mức gần nhất với một tuần bình thường của bạn.',
        ),
        const SizedBox(height: 20),
        for (final (level, title, subtitle, factor) in _options) ...[
          ChoiceCard(
            title: title,
            subtitle: subtitle,
            trailing: factor,
            selected: draft.activity == level,
            onTap: () => draft.setActivity(level),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
