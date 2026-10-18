import 'package:flutter_test/flutter_test.dart';

import 'package:elytra/features/nutrition/nutrition_calculator.dart';
import 'package:elytra/features/onboarding/body_info.dart';

/// Số kỳ vọng tính theo đúng hàm `calculate_nutrition_targets` trong database
/// (làm tròn 0,5 lên, 1 chữ số thập phân). Hai bên phải ra cùng một số.
void main() {
  BodyInfo person(
    Gender g,
    int age,
    double h,
    double w,
    ActivityLevel a,
    Goal goal,
  ) => BodyInfo(
    gender: g,
    age: age,
    heightCm: h,
    weightKg: w,
    activity: a,
    goal: goal,
  );

  void expectResult(
    NutritionResult r, {
    required double bmi,
    required double bmr,
    required double tdee,
    required double target,
    required double protein,
    required double fat,
    required double carbs,
    required List<double> pct,
    required List<int> meals,
    bool floor = false,
  }) {
    expect(r.bmi, bmi);
    expect(r.bmr, bmr);
    expect(r.tdee, tdee);
    expect(r.targetKcal, target);
    expect(r.proteinG, protein);
    expect(r.fatG, fat);
    expect(r.carbsG, carbs);
    expect([r.proteinPct, r.fatPct, r.carbsPct], pct);
    expect(r.mealKcal, meals);
    expect(r.floorApplied, floor);
  }

  test('Người mẫu: nam 25t, 170 cm, 65 kg, vừa – Giảm cân', () {
    final r = NutritionCalculator.compute(
      person(Gender.male, 25, 170, 65, ActivityLevel.moderate, Goal.loseWeight),
    );
    expectResult(
      r,
      bmi: 22.5,
      bmr: 1592.5,
      tdee: 2468.4,
      target: 1968.4,
      protein: 130.0,
      fat: 54.7,
      carbs: 239.1,
      pct: [26.4, 25.0, 48.6],
      meals: [492, 689, 591, 197],
    );
    expect(r.calorieDifference, -500);
    expect(r.fiberG, 27.6);
    expect(r.waterMl, 2275);
  });

  group('Nam 22t, 170 cm, 65 kg, vừa', () {
    test('Duy trì', () {
      final r = NutritionCalculator.compute(
        person(Gender.male, 22, 170, 65, ActivityLevel.moderate, Goal.maintain),
      );
      expectResult(
        r,
        bmi: 22.5,
        bmr: 1607.5,
        tdee: 2491.6,
        target: 2491.6,
        protein: 104.0,
        fat: 69.2,
        carbs: 363.2,
        pct: [16.7, 25.0, 58.3],
        meals: [623, 872, 747, 249],
      );
      expect(r.calorieDifference, 0);
    });

    test('Tăng cân', () {
      final r = NutritionCalculator.compute(
        person(
          Gender.male,
          22,
          170,
          65,
          ActivityLevel.moderate,
          Goal.gainWeight,
        ),
      );
      expectResult(
        r,
        bmi: 22.5,
        bmr: 1607.5,
        tdee: 2491.6,
        target: 2891.6,
        protein: 117.0,
        fat: 80.3,
        carbs: 425.2,
        pct: [16.2, 25.0, 58.8],
        meals: [723, 1012, 867, 289],
      );
      expect(r.calorieDifference, 400);
    });
  });

  group('Nữ 22t, 158 cm, 50 kg, nhẹ', () {
    test('Giảm cân chạm sàn 1.200', () {
      final r = NutritionCalculator.compute(
        person(
          Gender.female,
          22,
          158,
          50,
          ActivityLevel.light,
          Goal.loseWeight,
        ),
      );
      expectResult(
        r,
        bmi: 20.0,
        bmr: 1216.5,
        tdee: 1672.7,
        target: 1200,
        protein: 100.0,
        fat: 33.3,
        carbs: 125.0,
        pct: [33.3, 25.0, 41.7],
        meals: [300, 420, 360, 120],
        floor: true,
      );
      expect(r.fiberG, 25); // tối thiểu 25 g
    });

    test('Duy trì', () {
      final r = NutritionCalculator.compute(
        person(Gender.female, 22, 158, 50, ActivityLevel.light, Goal.maintain),
      );
      expectResult(
        r,
        bmi: 20.0,
        bmr: 1216.5,
        tdee: 1672.7,
        target: 1672.7,
        protein: 80.0,
        fat: 46.5,
        carbs: 233.6,
        pct: [19.1, 25.0, 55.9],
        meals: [418, 585, 502, 167],
      );
    });

    test('Tăng cân', () {
      final r = NutritionCalculator.compute(
        person(
          Gender.female,
          22,
          158,
          50,
          ActivityLevel.light,
          Goal.gainWeight,
        ),
      );
      expectResult(
        r,
        bmi: 20.0,
        bmr: 1216.5,
        tdee: 1672.7,
        target: 2072.7,
        protein: 90.0,
        fat: 57.6,
        carbs: 298.6,
        pct: [17.4, 25.0, 57.6],
        meals: [518, 725, 622, 207],
      );
    });
  });

  test('Nữ 30t, 150 cm, 40 kg, ít vận động – Giảm cân (chạm sàn, BMI gầy)', () {
    final r = NutritionCalculator.compute(
      person(
        Gender.female,
        30,
        150,
        40,
        ActivityLevel.sedentary,
        Goal.loseWeight,
      ),
    );
    expectResult(
      r,
      bmi: 17.8,
      bmr: 1026.5,
      tdee: 1231.8,
      target: 1200,
      protein: 80.0,
      fat: 33.3,
      carbs: 145.0,
      pct: [26.7, 25.0, 48.3],
      meals: [300, 420, 360, 120],
      floor: true,
    );
    expect(r.waterMl, 1400);
  });
}
