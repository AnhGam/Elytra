import 'package:elytra/core/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealType at(int h, int m) => mealTypeAt(DateTime.utc(2026, 10, 28, h, m));

  test('mốc biên', () {
    expect(at(3, 59), MealType.snack);
    expect(at(4, 0), MealType.breakfast);
    expect(at(10, 29), MealType.breakfast);
    expect(at(10, 30), MealType.lunch);
    expect(at(14, 29), MealType.lunch);
    expect(at(14, 30), MealType.snack);
    expect(at(16, 59), MealType.snack);
    expect(at(17, 0), MealType.dinner);
    expect(at(21, 29), MealType.dinner);
    expect(at(21, 30), MealType.snack);
    expect(at(23, 59), MealType.snack);
    expect(at(0, 0), MealType.snack);
  });

  test('ngân sách bữa', () {
    expect(mealBudgetKcal(1968, MealType.lunch), 689);
    expect(mealBudgetKcal(2000, MealType.snack), 200);
    expect(mealBudgetKcal(null, MealType.lunch), isNull);
    expect(mealBudgetKcal(0, MealType.lunch), isNull);
  });

  test('isoDate đệm 0',
      () => expect(isoDate(DateTime.utc(2026, 3, 5, 23)), '2026-03-05'));

  test('vnNow lệch UTC đúng 7 giờ', () {
    final diff = vnNow().difference(DateTime.now().toUtc());
    expect((diff.inMinutes - 420).abs() <= 1, isTrue);
  });
}
