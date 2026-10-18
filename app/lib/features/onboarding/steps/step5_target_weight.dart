import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 5 – Cân nặng mục tiêu (chỉ có khi Giảm cân / Tăng cân).
/// Thẻ 1: chọn cân nặng muốn đạt. Thẻ 2: lộ trình ước tính (số tuần).
class Step5TargetWeight extends StatelessWidget {
  const Step5TargetWeight({super.key, required this.draft});

  final BodyInfoDraft draft;

  static final _kg = NumberFormat('#,##0.#', 'vi');

  @override
  Widget build(BuildContext context) {
    final range = draft.targetRange;
    final target = draft.targetWeightKg;

    if (range == null || target == null) return const SizedBox.shrink();

    final losing = draft.goal == Goal.loseWeight;
    final diff = target - draft.weightKg; // âm khi giảm, dương khi tăng
    final weeks = draft.weeksToTarget; // cùng công thức với BodyInfo

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        StepHeading(
          title: losing ? 'Giảm xuống bao nhiêu kg?' : 'Tăng lên bao nhiêu kg?',
          description: losing
              ? 'Chọn cân nặng bạn muốn đạt. Giảm từ từ giúp giữ cơ và dễ duy trì.'
              : 'Chọn cân nặng bạn muốn đạt. Tăng từ từ giúp lên cơ và hạn chế tích mỡ.',
        ),
        const SizedBox(height: 20),

        // ----- Thẻ 1: cân nặng mục tiêu -----
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
                      Icons.track_changes,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CÂN NẶNG MỤC TIÊU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cùng bố cục với bước 2: [−5][−]  số lớn  [+][+5]
              StepperRow(
                value: target,
                min: range.min,
                max: range.max,
                unit: 'kg',
                smallSize: 36,
                largeSize: 36,
                gap: 6,
                onChanged: (v) => draft.setTargetWeight(v.toDouble()),
                center: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _kg.format(target),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LabeledSlider(
                value: target,
                min: range.min,
                max: range.max,
                minLabel: '${_kg.format(range.min)} kg',
                maxLabel: '${_kg.format(range.max)} kg',
                semanticLabel: 'Cân nặng mục tiêu',
                onChanged: (v) => draft.setTargetWeight(v.roundToDouble()),
              ),
              // Cảnh báo (không chặn) khi BMI ở cân nặng mục tiêu < 18,5
              if (bmi(draft.heightCm, target) < healthyBmiMin) ...[
                const SizedBox(height: 12),
                _LowBmiWarning(
                  targetKg: target,
                  targetBmi: bmi(draft.heightCm, target),
                  suggestedKg: minHealthyWeightKg(draft.heightCm),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ----- Thẻ 2: lộ trình ước tính -----
        _PlanCard(
          losing: losing,
          current: '${_kg.format(draft.weightKg)} kg',
          change: '${losing ? '−' : '+'}${_kg.format(diff.abs())} kg',
          weeks: '~$weeks tuần',
        ),
      ],
    );
  }
}

/// Thẻ "Lộ trình ước tính": vàng cam khi giảm, xanh lá khi tăng
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.losing,
    required this.current,
    required this.change,
    required this.weeks,
  });

  final bool losing;
  final String current;
  final String change;
  final String weeks;

  @override
  Widget build(BuildContext context) {
    final bg = losing ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4);
    final line = losing ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0);
    final fg = losing ? const Color(0xFF92400E) : AppColors.primaryDark;

    Widget column(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
    Widget divider() => Container(width: 1, height: 36, color: line);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                'Lộ trình ước tính',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: line),
                  bottom: BorderSide(color: line),
                ),
              ),
              child: Row(
                children: [
                  column(current, 'Hiện tại'),
                  divider(),
                  column(change, losing ? 'Cần giảm' : 'Cần tăng'),
                  divider(),
                  column(weeks, 'Thời gian'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            losing
                ? 'Dựa trên mức thâm hụt khoảng 500 kcal mỗi ngày.'
                : 'Dựa trên tốc độ tăng khoảng 0,3 kg mỗi tuần.',
            style: TextStyle(fontSize: 12, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Hộp cảnh báo đỏ nhạt: cân nặng mục tiêu làm BMI thấp hơn mức bình thường
class _LowBmiWarning extends StatelessWidget {
  const _LowBmiWarning({
    required this.targetKg,
    required this.targetBmi,
    required this.suggestedKg,
  });

  final double targetKg;
  final double targetBmi;
  final double suggestedKg;

  static final _kg = NumberFormat('#,##0.#', 'vi');
  static final _bmi = NumberFormat('0.0', 'vi');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_kg.format(targetKg)} kg ứng với BMI ${_bmi.format(targetBmi)} – '
              'thấp hơn mức bình thường (18,5). '
              'Nên chọn từ ${_kg.format(suggestedKg)} kg trở lên.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
