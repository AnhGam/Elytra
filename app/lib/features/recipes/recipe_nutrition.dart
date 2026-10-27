import '../../core/meal_time.dart';
import 'recipe.dart';

/// Ngưỡng natri tối đa mỗi ngày (mg).
const double kSodiumDailyMaxMg = 2000;

/// Tỉ lệ % năng lượng từ đạm / tinh bột / béo.
class EnergySplit {
  final int proteinPct, carbsPct, fatPct;
  const EnergySplit(this.proteinPct, this.carbsPct, this.fatPct);
}

/// P×4, C×4, F×9; tổng năng lượng 0 thì trả null.
EnergySplit? energySplit(Recipe r) {
  final p = r.proteinG * 4, c = r.carbsG * 4, f = r.fatG * 9;
  final total = p + c + f;
  if (total <= 0) return null;
  return EnergySplit(
    (p / total * 100).round(),
    (c / total * 100).round(),
    (f / total * 100).round(),
  );
}

/// % so với mục tiêu ngày; target null hoặc ≤ 0 thì null (tránh chia cho 0).
int? pctOfTarget(double value, double? target) {
  if (target == null || target <= 0) return null;
  return (value / target * 100).round();
}

sealed class MealFit {
  const MealFit();
}

/// Nằm trong ngân sách calo của bữa, chiếm [pct]%.
class MealFitWithin extends MealFit {
  final int pct;
  const MealFitWithin(this.pct);
}

/// Vượt ngân sách [overKcal] kcal.
class MealFitOver extends MealFit {
  final int overKcal;
  const MealFitOver(this.overKcal);
}

/// So khớp kcal với ngân sách bữa; budget null hoặc ≤ 0 thì null.
MealFit? mealFit(double kcal, int? budget) {
  if (budget == null || budget <= 0) return null;
  if (kcal <= budget) return MealFitWithin((kcal / budget * 100).round());
  return MealFitOver((kcal - budget).round());
}

/// Natri vượt phần cho phép của bữa này.
bool sodiumHighForMeal(double sodiumMg, MealType m) =>
    sodiumMg > kSodiumDailyMaxMg * m.sharePct / 100;
