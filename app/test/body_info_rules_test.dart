import 'package:flutter_test/flutter_test.dart';

import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';

void main() {
  group('targetWeightRange (người 170 cm, 65 kg)', () {
    test('Giảm cân: 48–64 kg, mặc định 60', () {
      final r = targetWeightRange(Goal.loseWeight, 170, 65);
      expect(r.min, 48);
      expect(r.max, 64);
      expect(r.initial, 60);
    });

    test('Tăng cân: 66–80 kg, mặc định 70', () {
      final r = targetWeightRange(Goal.gainWeight, 170, 65);
      expect(r.min, 66);
      expect(r.max, 80);
      expect(r.initial, 70);
    });
  });

  group('weeksToTarget', () {
    BodyInfo info(Goal goal, double? target) => BodyInfo(
          gender: Gender.male, age: 25, heightCm: 170, weightKg: 65,
          activity: ActivityLevel.moderate, goal: goal, targetWeightKg: target,
        );

    test('Giảm 5 kg → 13 tuần', () => expect(info(Goal.loseWeight, 60).weeksToTarget, 13));
    test('Tăng 5 kg → 17 tuần', () => expect(info(Goal.gainWeight, 70).weeksToTarget, 17));
    test('Duy trì → không có lộ trình', () => expect(info(Goal.maintain, null).weeksToTarget, isNull));
  });

  test('BMI người mẫu = 22,5, Bình thường', () {
    final v = bmi(170, 65);
    expect(v, closeTo(22.5, 0.05));
    expect(bmiCategory(v), 'Bình thường');
  });
}
