import 'dart:math' as math;

import 'package:elytra/features/onboarding/body_info.dart';

/// Bước 5.1: các khoảng hợp lệ và giá trị mặc định của wizard thể trạng.
/// Mọi màn trong wizard đọc số từ đây, không tự gõ số riêng.
class BodyInfoLimits {
  const BodyInfoLimits._();

  // Bước 1: tuổi
  static const minAge = 18;
  static const maxAge = 80;
  static const defaultAge = 25;

  // Bước 2: chiều cao, cân nặng
  static const minHeightCm = 120.0;
  static const maxHeightCm = 220.0;
  static const defaultHeightCm = 170.0;
  static const minWeightKg = 30.0;
  static const maxWeightKg = 200.0;
  static const defaultWeightKg = 65.0;

  // Bước 6: số giờ tập mỗi ngày
  static const minWorkoutHours = 0;
  static const maxWorkoutHours = 4;
  static const defaultWorkoutHours = 1;
}

/// Khoảng cân nặng mục tiêu ở bước 5 (chỉ dùng khi Giảm cân / Tăng cân).
/// Ví dụ người 170 cm, 65 kg: giảm 48–64 kg (mặc định 60), tăng 66–80 kg (mặc định 70).
({double min, double max, double initial}) targetWeightRange(
    Goal goal, double heightCm, double weightKg) {
  final h = heightCm / 100;
  if (goal == Goal.loseWeight) {
    // Thấp nhất: ứng với BMI 16,5 (không thấp hơn 30 kg); cao nhất: nhẹ hơn hiện tại 1 kg
    final min = math.max(BodyInfoLimits.minWeightKg, (16.5 * h * h).ceilToDouble());
    final max = weightKg - 1;
    return (min: min, max: max, initial: (weightKg - 5).clamp(min, max).toDouble());
  }
  // Tăng cân: từ nặng hơn 1 kg tới tối đa +15 kg (không quá 200 kg)
  final min = weightKg + 1;
  final max = math.min(BodyInfoLimits.maxWeightKg, weightKg + 15);
  return (min: min, max: max, initial: (weightKg + 5).clamp(min, max).toDouble());
}

/// BMI = cân nặng (kg) / chiều cao (m)²
double bmi(double heightCm, double weightKg) {
  final h = heightCm / 100;
  return weightKg / (h * h);
}

/// Phân loại BMI theo ngưỡng cho người châu Á (giống hàm tính trong database)
String bmiCategory(double value) {
  if (value < 18.5) return 'Gầy';
  if (value < 23) return 'Bình thường';
  if (value < 25) return 'Thừa cân';
  return 'Béo phì';
}
