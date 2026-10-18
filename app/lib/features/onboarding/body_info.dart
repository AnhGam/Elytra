enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

/// Giảm cân · Duy trì · Tăng cân (khớp cột `goal` của bảng `profiles`:
/// lose_weight / maintain / gain_weight)
enum Goal { loseWeight, maintain, gainWeight }

class BodyInfo {
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;
  final double? targetWeightKg;
  final int? workoutHoursPerDay;
  final bool preferGymCutting;
  final bool preferHealthyEating;

  const BodyInfo({
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.targetWeightKg,
    this.workoutHoursPerDay,
    this.preferGymCutting = false,
    this.preferHealthyEating = false,
  });

  bool get hasGoalPlan => goal != Goal.maintain;
  int get totalSteps => hasGoalPlan ? 6 : 4;
  int get birthYear => DateTime.now().year - age;

  int? get weeksToTarget {
    if (!hasGoalPlan || targetWeightKg == null) return null;
    final rate = goal == Goal.loseWeight ? 0.4 : 0.3; // kg/tuần
    return ((targetWeightKg! - weightKg).abs() / rate).ceil();
  }

  Map<String, dynamic> toJson({bool save = false}) => {
    'gender': gender.name,
    'age': age,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': const {
      ActivityLevel.sedentary: 'sedentary',
      ActivityLevel.light: 'light',
      ActivityLevel.moderate: 'moderate',
      ActivityLevel.active: 'active',
      ActivityLevel.veryActive: 'very_active',
    }[activity],
    'goal': const {
      Goal.loseWeight: 'lose_weight',
      Goal.maintain: 'maintain',
      Goal.gainWeight: 'gain_weight',
    }[goal],
    'target_weight_kg': hasGoalPlan ? targetWeightKg : null,
    'workout_hours_per_day': hasGoalPlan ? workoutHoursPerDay : null,
    'prefer_gym_cutting': hasGoalPlan && preferGymCutting,
    'prefer_healthy_eating': hasGoalPlan && preferHealthyEating,
    'save': save,
  };
}
