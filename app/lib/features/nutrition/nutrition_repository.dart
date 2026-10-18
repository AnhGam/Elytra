import 'package:elytra/features/nutrition/nutrition_calculator.dart';
import 'package:elytra/features/onboarding/body_info.dart';
import 'package:elytra/main.dart';

/// Lưu hồ sơ thể trạng + mục tiêu dinh dưỡng vào dòng `profiles` của người đang
/// đăng nhập (RLS chỉ cho sửa dòng của chính mình).
///
/// Tạm thời app tự tính rồi ghi thẳng vào bảng. Khi có Edge Function
/// `calc-nutrition`, chỉ cần đổi phần thân hàm [save] sang gọi function đó.
/// 4 trường lộ trình (cân nặng mục tiêu, giờ tập, 2 lựa chọn) chưa lưu vì
/// bảng `profiles` chưa có cột.
class NutritionRepository {
  Future<NutritionResult> save(BodyInfo info) async {
    final r = NutritionCalculator.compute(info);
    final json = info.toJson();
    await supabase.from('profiles').upsert({
      'id': supabase.auth.currentUser!.id,
      'gender': json['gender'],
      'age': info.age,
      'height_cm': info.heightCm,
      'weight_kg': info.weightKg,
      'activity_level': json['activity_level'],
      'goal': json['goal'],
      'bmi': r.bmi,
      'bmr': r.bmr,
      'tdee': r.tdee,
      'target_calories': r.targetKcal,
      'target_protein_g': r.proteinG,
      'target_fat_g': r.fatG,
      'target_carbs_g': r.carbsG,
      'target_fiber_g': r.fiberG,
      'target_water_ml': r.waterMl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return r;
  }
}

final nutritionRepo = NutritionRepository();
