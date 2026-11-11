import 'package:flutter/material.dart';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';

/// Kết quả trả về khi ghi xong (pop kèm giá trị này), để màn trước hiện snackbar.
class LogMealResult {
  const LogMealResult({required this.result, required this.name});
  final AddResult result;
  final String name;
}

/// Màn Ghi bữa ăn. Khung tạm, hoàn thiện ở Task 14.
class LogMealScreen extends StatelessWidget {
  const LogMealScreen({super.key, required this.meal, required this.date});

  final MealType meal;

  /// Ngày ghi, dạng YYYY-MM-DD.
  final String date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi bữa ăn')),
      body: const SizedBox.expand(),
    );
  }
}
