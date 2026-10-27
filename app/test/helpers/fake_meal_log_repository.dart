import 'dart:async';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';

/// Bản giả: ghi lại lời gọi, có thể chặn bằng [gate] hoặc ném [failWith].
class FakeMealLogRepository implements MealLogRepository {
  final List<Map<String, Object>> calls = [];
  Completer<void>? gate;
  MealLogException? failWith;

  @override
  Future<void> addRecipe({
    required String recipeId,
    required MealType mealType,
    required String date,
    required String clientRequestId,
  }) async {
    calls.add({
      'recipeId': recipeId,
      'mealType': mealType,
      'date': date,
      'clientRequestId': clientRequestId,
    });
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
  }
}
