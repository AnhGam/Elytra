import 'package:intl/intl.dart';

import '../../core/meal_time.dart';
import '../recipes/recipe.dart';
import 'budget_view.dart';
import 'meal_log_models.dart';

const kMinServings = 0.25, kMaxServings = 10.0, kServingStep = 0.25;
const kMinGram = 1, kMaxGram = 2000;
const kServingChips = [0.5, 1.0, 1.5, 2.0];
const kGramChips = [200, 300, 400, 500];

final _servingFmt = NumberFormat('#,##0.##', 'vi');

/// Tăng/giảm một bước, kẹp hai đầu.
double stepServings(double current, int direction) =>
    (current + direction * kServingStep).clamp(kMinServings, kMaxServings);

/// Số nguyên 1–2000; còn lại null.
int? parseGram(String text) {
  final n = int.tryParse(text.trim());
  if (n == null || n < kMinGram || n > kMaxGram) return null;
  return n;
}

/// `1,5 phần`, `0,25 phần`, `1 phần`.
String formatServings(double s) => '${_servingFmt.format(s)} phần';

/// Nhãn chip khẩu phần: `½`, `1`, `1½`, `2`.
String servingChipLabel(double s) {
  final whole = s.truncate();
  final half = (s - whole) >= 0.5;
  if (!half) return '$whole';
  return whole == 0 ? '½' : '$whole½';
}

/// Dinh dưỡng của [servings] phần (số liệu công thức tính theo 1 phần).
Macros previewRecipe(Recipe r, double servings) => Macros(
      kcal: r.kcal,
      proteinG: r.proteinG,
      carbsG: r.carbsG,
      fatG: r.fatG,
    ).scale(servings);

/// Dinh dưỡng của [grams] gam từ số liệu trên 100 g.
Macros previewPer100(FoodHit f, int grams) => f.per100.scale(grams / 100);

String _leftOrOver(String scope, double kcal) => kcal < 0
    ? '$scope vượt ${formatKcal(-kcal)} kcal'
    : '$scope còn ${formatKcal(kcal)} kcal';

/// Dòng `Sau khi thêm: bữa tối còn 230 kcal · cả ngày còn 456 kcal`.
String afterAddLabel({
  required Budget day,
  required MealLog meal,
  required MealType type,
  required Macros add,
}) {
  final parts = <String>[];
  final mealBudget = mealBudgetKcal(day.target.kcal, type);
  if (mealBudget != null) {
    parts.add(_leftOrOver('bữa ${type.labelVi}', mealBudget - meal.kcal - add.kcal));
  }
  parts.add(_leftOrOver('cả ngày', day.remaining.kcal - add.kcal));
  return 'Sau khi thêm: ${parts.join(' · ')}';
}
