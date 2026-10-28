import 'package:elytra/features/onboarding/body_info.dart';

/// Kết quả dinh dưỡng (cùng các trường hàm `calculate_nutrition_targets` trả về).
/// Số giữ 1 chữ số thập phân như cột NUMERIC trong bảng `profiles`.
class NutritionResult {
  final double bmi;
  final double bmr;
  final double tdee;
  final double targetKcal;

  /// Calo mục tiêu − TDEE: −500 (giảm cân), 0, +400 (tăng cân)
  final double calorieDifference;

  /// Calo mục tiêu bị nâng lên mức sàn an toàn (1.200 nữ / 1.500 nam), áp cho mọi mục tiêu
  final bool floorApplied;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;
  final int waterMl;
  final double proteinPct;
  final double fatPct;
  final double carbsPct;

  /// kcal từng bữa: Sáng · Trưa · Tối · Phụ (25 / 35 / 30 / 10%)
  final List<int> mealKcal;

  const NutritionResult({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.targetKcal,
    required this.calorieDifference,
    required this.floorApplied,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.waterMl,
    required this.proteinPct,
    required this.fatPct,
    required this.carbsPct,
    required this.mealKcal,
  });
}

/// Tính BMR/TDEE/macro GIỐNG HỆT hàm `calculate_nutrition_targets` trong database:
/// - BMR Mifflin-St Jeor, làm tròn 1 chữ số thập phân
/// - TDEE = BMR × hệ số vận động (1.2 / 1.375 / 1.55 / 1.725 / 1.9)
/// - Giảm cân −500, Tăng cân +400, Duy trì giữ nguyên; sau đó nâng lên sàn 1.200 nữ / 1.500 nam nếu thấp hơn
/// - Protein 2.0 / 1.6 / 1.8 g/kg (giảm / duy trì / tăng), Fat 25% calo, Carbs phần còn lại
/// - Chất xơ 14 g/1.000 kcal (tối thiểu 25 g), Nước 35 ml/kg
///
/// Database làm tròn kiểu "0,5 lên" trên số thập phân chính xác. Số thực (double)
/// có sai số nhỏ có thể làm tròn lệch 0,1, nên ở đây tính bằng số nguyên theo đơn vị
/// 1/10 (vd. 1592,5 kcal lưu thành 15925).
class NutritionCalculator {
  const NutritionCalculator._();

  static const _activityFactor = {
    // hệ số × 1000
    ActivityLevel.sedentary: 1200,
    ActivityLevel.light: 1375,
    ActivityLevel.moderate: 1550,
    ActivityLevel.active: 1725,
    ActivityLevel.veryActive: 1900,
  };

  static const _proteinPerKg = {
    // g/kg × 10
    Goal.loseWeight: 20,
    Goal.maintain: 16,
    Goal.gainWeight: 18,
  };

  static const mealShares = [25, 35, 30, 10]; // %

  /// a / b làm tròn "0,5 lên" (a ≥ 0, b > 0)
  static int _div(int a, int b) => (2 * a + b) ~/ (2 * b);

  static NutritionResult compute(BodyInfo info) {
    final w10 = (info.weightKg * 10).round(); // cân nặng × 10
    final h10 = (info.heightCm * 10).round(); // chiều cao × 10
    final isFemale = info.gender == Gender.female;

    // BMR = 10W + 6,25H − 5A + s  →  ×40 để thành số nguyên
    final s = isFemale ? -161 : 5;
    final bmr10 = _div(40 * w10 + 25 * h10 - 200 * info.age + 40 * s, 4);
    final tdee10 = _div(bmr10 * _activityFactor[info.activity]!, 1000);

    var target10 = switch (info.goal) {
      Goal.loseWeight => tdee10 - 5000,
      Goal.maintain => tdee10,
      Goal.gainWeight => tdee10 + 4000,
    };
    final floor10 = isFemale ? 12000 : 15000;
    // Sàn áp cho mọi mục tiêu: người nhỏ con/lớn tuổi có TDEE < sàn ngay cả khi duy trì/tăng cân
    final floorApplied = target10 < floor10;
    if (floorApplied) target10 = floor10;

    final protein10 = _div(w10 * _proteinPerKg[info.goal]!, 10);
    final fat10 = _div(target10, 36); // 25% calo / 9 kcal mỗi gram
    // kcal carbs × 40 = 40 × (calo − 4P − 0,25 × calo)
    final rawCarbs40 = 3 * target10 - 16 * protein10;
    final carbsKcal40 = rawCarbs40 < 0 ? 0 : rawCarbs40;
    final carbs10 = _div(carbsKcal40, 16);

    final fiber10 = _div(target10 * 14, 1000);

    return NutritionResult(
      bmi: _div(w10 * 1000000, h10 * h10) / 10,
      bmr: bmr10 / 10,
      tdee: tdee10 / 10,
      targetKcal: target10 / 10,
      calorieDifference: (target10 - tdee10) / 10,
      floorApplied: floorApplied,
      proteinG: protein10 / 10,
      fatG: fat10 / 10,
      carbsG: carbs10 / 10,
      fiberG: (fiber10 < 250 ? 250 : fiber10) / 10,
      waterMl: _div(w10 * 35, 10),
      proteinPct: _div(protein10 * 4000, target10) / 10,
      fatPct: 25,
      carbsPct: _div(carbsKcal40 * 250, target10) / 10,
      mealKcal: [for (final share in mealShares) _div(target10 * share, 1000)],
    );
  }
}
