import 'package:flutter_test/flutter_test.dart';

import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_draft.dart';

void main() {
  test('Mở wizard: giá trị mặc định 25 tuổi, 170 cm, 65 kg, 4 bước', () {
    final d = BodyInfoDraft();
    expect(d.age, 25);
    expect(d.heightCm, 170);
    expect(d.weightKg, 65);
    expect(d.totalSteps, 4);
    expect(d.isStepValid(1), isFalse); // chưa chọn giới tính
  });

  test('Nhập quá giới hạn bị kéo về biên', () {
    final d = BodyInfoDraft()
      ..setAge(10)
      ..setHeight(300);
    expect(d.age, 18);
    expect(d.heightCm, 220);
  });

  test('Chọn Giảm cân → 6 bước, mục tiêu mặc định 60 kg', () {
    final d = BodyInfoDraft()..setGoal(Goal.loseWeight);
    expect(d.totalSteps, 6);
    expect(d.targetWeightKg, 60);
  });

  test('Đổi Giảm → Tăng cân → mục tiêu thành 70 kg', () {
    final d = BodyInfoDraft()
      ..setGoal(Goal.loseWeight)
      ..setGoal(Goal.gainWeight);
    expect(d.targetWeightKg, 70);
  });

  test('Đổi sang Duy trì → xóa dữ liệu lộ trình, còn 4 bước', () {
    final d = BodyInfoDraft()
      ..setGoal(Goal.loseWeight)
      ..setPreferGymCutting(true)
      ..setGoal(Goal.maintain);
    expect(d.totalSteps, 4);
    expect(d.targetWeightKg, isNull);
    expect(d.preferGymCutting, isFalse);
  });

  test('Sửa cân nặng làm mục tiêu cũ ra ngoài khoảng → lấy mặc định mới', () {
    final d = BodyInfoDraft()
      ..setGoal(Goal.loseWeight) // mục tiêu 60
      ..setWeight(58); // giờ phải nhẹ hơn 58 → 60 không còn hợp lệ
    expect(d.targetWeightKg, 53); // 58 − 5
  });

  test('Khai báo đủ → toBodyInfo', () {
    final d = BodyInfoDraft()
      ..setGender(Gender.male)
      ..setActivity(ActivityLevel.moderate)
      ..setGoal(Goal.loseWeight);
    expect(d.isComplete, isTrue);
    final info = d.toBodyInfo();
    expect(info.targetWeightKg, 60);
    expect(info.workoutHoursPerDay, 1);
    expect(info.weeksToTarget, 13);
  });

  test('Tăng cân: sửa cân nặng → mục tiêu luôn = cân nặng mới + 5', () {
    final d = BodyInfoDraft()
      ..setGoal(Goal.gainWeight)
      ..setWeight(58);
    expect(d.targetWeightKg, 63);
  });

  test('Giảm cân: tăng cân nặng → mục tiêu = cân nặng mới − 5', () {
    final d = BodyInfoDraft()
      ..setGoal(Goal.loseWeight)
      ..setWeight(80);
    expect(d.targetWeightKg, 75);
  });
}
