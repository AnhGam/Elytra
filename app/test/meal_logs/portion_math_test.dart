import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/portion_math.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recipe_fixtures.dart';

void main() {
  test('stepper dừng ở 0,25 và 10', () {
    expect(stepServings(0.25, -1), 0.25);
    expect(stepServings(10, 1), 10);
    expect(stepServings(1.5, 1), 1.75);
  });

  test('parseGram giới hạn 1–2000', () {
    for (final s in ['', '0', '2001', 'abc', '-5', '1.5']) {
      expect(parseGram(s), isNull, reason: s);
    }
    expect(parseGram('2000'), 2000);
    expect(parseGram(' 1 '), 1);
  });

  test('nhãn khẩu phần', () {
    expect(formatServings(1.5), '1,5 phần');
    expect(formatServings(0.25), '0,25 phần');
    expect(formatServings(1), '1 phần');
    expect([for (final s in kServingChips) servingChipLabel(s)],
        ['½', '1', '1½', '2']);
  });

  test('xem trước 1,5 phần và dòng sau khi thêm', () {
    final r = recipe(kcal: 240, proteinG: 39, carbsG: 6, fatG: 7);
    final m = previewRecipe(r, 1.5);
    expect(m.kcal, 360);
    expect(m.proteinG, 58.5);
    final day = Budget.fromJson({
      'target': {'kcal': 1968},
      'consumed': {'kcal': 1152},
    });
    expect(
        afterAddLabel(
            day: day, meal: MealLog.empty, type: MealType.dinner, add: m),
        'Sau khi thêm: bữa tối còn 230 kcal · cả ngày còn 456 kcal');
  });

  test('afterAddLabel: vượt và thiếu mục tiêu', () {
    final day = Budget.fromJson({
      'target': {'kcal': 1968},
      'consumed': {'kcal': 1900},
    });
    expect(
        afterAddLabel(
            day: day,
            meal: MealLog.empty,
            type: MealType.dinner,
            add: const Macros(kcal: 600)),
        'Sau khi thêm: bữa tối vượt 10 kcal · cả ngày vượt 532 kcal');
    final none = Budget.fromJson({
      'target': {'kcal': 0},
      'consumed': {'kcal': 0},
    });
    expect(
        afterAddLabel(
            day: none,
            meal: MealLog.empty,
            type: MealType.dinner,
            add: const Macros(kcal: 100)),
        'Sau khi thêm: cả ngày vượt 100 kcal');
  });

  test('xem trước theo gam', () {
    final f = FoodHit.fromRow(
        {'id': 'x', 'name_vi': 'Cơm', 'calories_per_100g': 130},
        FoodKind.ingredient);
    expect(previewPer100(f, 200).kcal, 260);
  });
}
