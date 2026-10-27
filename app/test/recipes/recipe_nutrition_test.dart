import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/recipes/recipe_nutrition.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recipe_fixtures.dart';

void main() {
  test('tỉ lệ năng lượng như Figma (P39 C6 F7)', () {
    final s = energySplit(recipe(protein: 39, carbs: 6, fat: 7))!;
    expect([s.proteinPct, s.carbsPct, s.fatPct], [64, 10, 26]);
    expect(energySplit(recipe(protein: 0, carbs: 0, fat: 0)), isNull);
  });
  test('% mục tiêu', () {
    expect(pctOfTarget(240, 1968), 12);
    expect(pctOfTarget(39, null), isNull);
    expect(pctOfTarget(39, 0), isNull);
  });
  test('mealFit', () {
    expect((mealFit(240, 689) as MealFitWithin).pct, 35);
    expect((mealFit(689, 689) as MealFitWithin).pct, 100);
    expect((mealFit(800.4, 689) as MealFitOver).overKcal, 111);
    expect(mealFit(240, null), isNull);
    expect(mealFit(240, 0), isNull);
  });
  test('natri theo phần của bữa', () {
    expect(sodiumHighForMeal(700, MealType.lunch), isFalse); // ngưỡng 700
    expect(sodiumHighForMeal(701, MealType.lunch), isTrue);
    expect(sodiumHighForMeal(201, MealType.snack), isTrue); // ngưỡng 200
  });
}
