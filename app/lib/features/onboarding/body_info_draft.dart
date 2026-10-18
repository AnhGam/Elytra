import 'package:flutter/foundation.dart';

import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/features/onboarding/body_info_rules.dart';

/// "Bản nháp" thể trạng trong lúc người dùng đi qua wizard.
///
/// `BodyInfo` là bản hoàn chỉnh (mọi ô đều đã có giá trị). Trong lúc khai báo,
/// một số ô còn trống (chưa chọn giới tính, chưa chọn mục tiêu…), nên wizard
/// giữ dữ liệu ở đây, rồi đổi sang `BodyInfo` khi bấm "Xem kết quả".
///
/// Là `ChangeNotifier`: mỗi lần dữ liệu đổi, giao diện tự vẽ lại.
class BodyInfoDraft extends ChangeNotifier {
  BodyInfoDraft();

  /// Khôi phục từ bản đã khai báo
  BodyInfoDraft.from(BodyInfo info)
    : _gender = info.gender,
      _age = info.age,
      _heightCm = info.heightCm,
      _weightKg = info.weightKg,
      _activity = info.activity,
      _goal = info.goal,
      _targetWeightKg = info.targetWeightKg,
      _workoutHours =
          info.workoutHoursPerDay ?? BodyInfoLimits.defaultWorkoutHours,
      _preferGymCutting = info.preferGymCutting,
      _preferHealthyEating = info.preferHealthyEating;

  // ----- Dữ liệu (null = chưa chọn) -----
  Gender? _gender;
  int _age = BodyInfoLimits.defaultAge;
  double _heightCm = BodyInfoLimits.defaultHeightCm;
  double _weightKg = BodyInfoLimits.defaultWeightKg;
  ActivityLevel? _activity;
  Goal? _goal;
  double? _targetWeightKg;
  int _workoutHours = BodyInfoLimits.defaultWorkoutHours;
  bool _preferGymCutting = false;
  bool _preferHealthyEating = false;

  Gender? get gender => _gender;
  int get age => _age;
  double get heightCm => _heightCm;
  double get weightKg => _weightKg;
  ActivityLevel? get activity => _activity;
  Goal? get goal => _goal;
  double? get targetWeightKg => _targetWeightKg;
  int get workoutHours => _workoutHours;
  bool get preferGymCutting => _preferGymCutting;
  bool get preferHealthyEating => _preferHealthyEating;

  // ----- Thông tin suy ra -----

  /// Giảm cân / Tăng cân thì có thêm bước 5–6
  bool get hasGoalPlan => _goal != null && _goal != Goal.maintain;

  /// 4 bước khi Duy trì (hoặc chưa chọn mục tiêu), 6 bước khi Giảm / Tăng cân
  int get totalSteps => hasGoalPlan ? 6 : 4;

  int get birthYear => DateTime.now().year - _age;

  double get bmiValue => bmi(_heightCm, _weightKg);

  /// Số tuần ước tính để đạt cân nặng mục tiêu (giảm 0,45 kg/tuần, tăng 0,3 kg/tuần)
  int? get weeksToTarget {
    if (!hasGoalPlan || _targetWeightKg == null) return null;
    return estimateWeeks(_goal!, _weightKg, _targetWeightKg!);
  }

  /// Khoảng cân nặng mục tiêu hiện tại (null khi không có bước 5)
  ({double min, double max, double initial})? get targetRange =>
      hasGoalPlan ? targetWeightRange(_goal!, _heightCm, _weightKg) : null;

  // ----- Thay đổi dữ liệu -----

  void setGender(Gender value) => _update(() => _gender = value);

  void setAge(int value) => _update(
    () => _age = value.clamp(BodyInfoLimits.minAge, BodyInfoLimits.maxAge),
  );

  void setHeight(double value) => _update(() {
    _heightCm = value.clamp(
      BodyInfoLimits.minHeightCm,
      BodyInfoLimits.maxHeightCm,
    );
    _fitTargetIntoRange(); // chiều cao đổi → mục tiêu tính lại
  });

  void setWeight(double value) => _update(() {
    _weightKg = value.clamp(
      BodyInfoLimits.minWeightKg,
      BodyInfoLimits.maxWeightKg,
    );
    _fitTargetIntoRange(); // cân nặng đổi → mục tiêu tính lại
  });

  void setActivity(ActivityLevel value) => _update(() => _activity = value);

  void setGoal(Goal value) => _update(() {
    final changed = value != _goal;
    _goal = value;
    if (value == Goal.maintain) {
      // Duy trì: không có bước 5–6 → xóa dữ liệu lộ trình
      _targetWeightKg = null;
      _workoutHours = BodyInfoLimits.defaultWorkoutHours;
      _preferGymCutting = false;
      _preferHealthyEating = false;
    } else if (changed) {
      // Đổi giữa Giảm ↔ Tăng: đặt lại cân nặng mục tiêu theo mục tiêu mới
      _targetWeightKg = targetRange!.initial;
    }
  });

  void setTargetWeight(double value) => _update(() {
    final r = targetRange;
    if (r != null) _targetWeightKg = value.clamp(r.min, r.max);
  });

  void setWorkoutHours(int value) => _update(
    () => _workoutHours = value.clamp(
      BodyInfoLimits.minWorkoutHours,
      BodyInfoLimits.maxWorkoutHours,
    ),
  );

  void setPreferGymCutting(bool value) =>
      _update(() => _preferGymCutting = value);

  void setPreferHealthyEating(bool value) =>
      _update(() => _preferHealthyEating = value);

  /// Chiều cao / cân nặng đổi → đặt lại cân nặng mục tiêu theo số mới
  /// (giảm: cân nặng − 5 kg, tăng: cân nặng + 5 kg, rồi kẹp vào khoảng hợp lệ).
  /// Áp dụng như nhau cho Giảm cân và Tăng cân.
  void _fitTargetIntoRange() {
    final r = targetRange;
    if (r == null || _targetWeightKg == null) return;
    _targetWeightKg = r.initial;
  }

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }

  // ----- Kiểm tra từng bước (nút "Tiếp tục" chỉ bật khi hợp lệ) -----

  bool isStepValid(int step) => switch (step) {
    1 => _gender != null,
    2 => true, // chiều cao, cân nặng luôn nằm trong khoảng nhờ clamp
    3 => _activity != null,
    4 => _goal != null,
    5 => _targetWeightKg != null,
    6 => true,
    _ => false,
  };

  /// Đã đủ dữ liệu để xem kết quả chưa
  bool get isComplete =>
      List.generate(totalSteps, (i) => i + 1).every(isStepValid);

  /// Đổi bản nháp thành `BodyInfo` hoàn chỉnh (chỉ gọi khi [isComplete])
  BodyInfo toBodyInfo() {
    assert(isComplete, 'Chưa khai báo đủ thông tin');
    return BodyInfo(
      gender: _gender!,
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      activity: _activity!,
      goal: _goal!,
      targetWeightKg: hasGoalPlan ? _targetWeightKg : null,
      workoutHoursPerDay: hasGoalPlan ? _workoutHours : null,
      preferGymCutting: hasGoalPlan && _preferGymCutting,
      preferHealthyEating: hasGoalPlan && _preferHealthyEating,
    );
  }
}
