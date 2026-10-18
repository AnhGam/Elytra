import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:elytra/core/theme.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';
import 'package:elytra/features/onboarding/widgets/wizard_widgets.dart';

/// Bước 2 – Chiều cao & Cân nặng, kèm thẻ BMI tự cập nhật (frame DeclarationScreen2)
class Step2BodyMetrics extends StatelessWidget {
  const Step2BodyMetrics({super.key, required this.draft});

  final BodyInfoDraft draft;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const StepHeading(
          title: 'Chiều cao & Cân nặng',
          description: 'Dùng để tính chỉ số BMI và BMR của bạn.',
        ),
        const SizedBox(height: 20),
        MeasureCard(
          icon: Icons.straighten,
          title: 'Chiều cao',
          hint: 'Đứng thẳng, không mang giày',
          value: draft.heightCm,
          min: BodyInfoLimits.minHeightCm,
          max: BodyInfoLimits.maxHeightCm,
          unit: 'cm',
          onChanged: draft.setHeight,
        ),
        const SizedBox(height: 16),
        MeasureCard(
          icon: Icons.monitor_weight_outlined,
          title: 'Cân nặng',
          hint: 'Cân vào buổi sáng',
          value: draft.weightKg,
          min: BodyInfoLimits.minWeightKg,
          max: BodyInfoLimits.maxWeightKg,
          unit: 'kg',
          onChanged: draft.setWeight,
        ),
        const SizedBox(height: 16),
        _BmiCard(value: draft.bmiValue),
      ],
    );
  }
}

/// Một mức BMI: tên, khoảng giá trị trên thanh, màu đậm và màu nền nhạt
class _BmiBand {
  const _BmiBand(
    this.label,
    this.from,
    this.to,
    this.color,
    this.tint,
    this.flex,
  );

  final String label;
  final double from;
  final double to;
  final Color color;
  final Color tint;

  /// Độ rộng tương đối của đoạn trên thanh (74 : 95 : 53 : 74)
  final int flex;
}

const _bands = [
  _BmiBand('Gầy', 14, 18.5, Color(0xFF0284C7), Color(0xFFE0F2FE), 74),
  _BmiBand(
    'Bình thường',
    18.5,
    23,
    AppColors.primaryDark,
    AppColors.primaryContainer,
    95,
  ),
  _BmiBand('Thừa cân', 23, 25, Color(0xFFD97706), Color(0xFFFEF3C7), 53),
  _BmiBand('Béo phì', 25, 32, AppColors.error, AppColors.errorContainer, 74),
];

/// Thẻ BMI: số + nhãn mức, thanh 4 màu có chấm tròn chỉ vị trí
class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.value});

  final double value;

  static final _fmt = NumberFormat('0.0', 'vi'); // 22,5

  @override
  Widget build(BuildContext context) {
    final label = bmiCategory(value);
    final band = _bands.firstWhere((b) => b.label == label);
    const gap = 4.0;

    return WizardCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'BMI của bạn',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                _fmt.format(value),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: band.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: band.tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: band.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thanh 4 đoạn màu + chấm chỉ vị trí BMI hiện tại
          LayoutBuilder(
            builder: (context, box) {
              final totalFlex = _bands.fold<int>(0, (s, b) => s + b.flex);
              final usable = box.maxWidth - gap * (_bands.length - 1);
              // Tìm vị trí x của chấm: đầu đoạn chứa BMI + tỉ lệ trong đoạn đó
              var x = 0.0;
              for (final b in _bands) {
                final w = usable * b.flex / totalFlex;
                if (b == band) {
                  final t = ((value - b.from) / (b.to - b.from)).clamp(
                    0.0,
                    1.0,
                  );
                  x += w * t;
                  break;
                }
                x += w + gap;
              }
              const pin = 14.0;
              return SizedBox(
                height: pin,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Row(
                          children: [
                            for (var i = 0; i < _bands.length; i++) ...[
                              if (i > 0) const SizedBox(width: gap),
                              Expanded(
                                flex: _bands[i].flex,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _bands[i].color,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(i == 0 ? 999 : 0),
                                      right: Radius.circular(
                                        i == _bands.length - 1 ? 999 : 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: (x - pin / 2).clamp(0.0, box.maxWidth - pin),
                      child: Container(
                        width: pin,
                        height: pin,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Nhãn 4 mức, canh theo từng đoạn
          Row(
            children: [
              for (var i = 0; i < _bands.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  flex: _bands[i].flex,
                  child: Text(
                    _bands[i].label,
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == _bands.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _bands[i] == band
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _bands[i] == band
                          ? _bands[i].color
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
