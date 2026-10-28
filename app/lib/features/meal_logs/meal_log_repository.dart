import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lỗi khi thêm món vào nhật ký bữa ăn.
sealed class MealLogException implements Exception {
  const MealLogException();
}

/// Mất mạng / quá thời gian chờ.
class MealLogOffline extends MealLogException {
  const MealLogOffline();
}

/// Người dùng chưa có hồ sơ mục tiêu dinh dưỡng.
class MealLogProfileMissing extends MealLogException {
  const MealLogProfileMissing();
}

/// Lỗi khác, kèm mã/thông điệp từ Edge Function nếu có.
class MealLogFailed extends MealLogException {
  final String? code;
  final String? message;
  const MealLogFailed([this.code, this.message]);
}

/// Lấy `error` ({code, message}) từ details (Map hoặc chuỗi JSON).
Map<String, dynamic>? _errorBody(dynamic details) {
  try {
    final d = details is String ? jsonDecode(details) : details;
    if (d is Map && d['error'] is Map) {
      return Map<String, dynamic>.from(d['error'] as Map);
    }
  } catch (_) {}
  return null;
}

// Không xử lý http.ClientException riêng (http không phải dependency trực tiếp);
// functions_client đã bọc lỗi transport thành FunctionsFetchException.
MealLogException mapMealLogError(Object e) {
  if (e is MealLogException) return e;
  if (e is FunctionsFetchException ||
      e is SocketException ||
      e is TimeoutException) {
    return const MealLogOffline();
  }
  if (e is FunctionException) {
    final err = _errorBody(e.details);
    // Kiểm tra kiểu thay vì ép kiểu: body lỗi lạ không được làm văng TypeError
    final code = err?['code'] is String ? err!['code'] as String : null;
    final message = err?['message'] is String ? err!['message'] as String : null;
    if (code == 'PROFILE_NOT_FOUND') return const MealLogProfileMissing();
    return MealLogFailed(code, message);
  }
  return const MealLogFailed();
}

abstract class MealLogRepository {
  Future<void> addRecipe({
    required String recipeId,
    required MealType mealType,
    required String date,
    required String clientRequestId,
  });
}

/// Bản gọi Edge Function `meal-logs`. Constructor không chạm `supabase`.
class SupabaseMealLogRepository implements MealLogRepository {
  SupabaseMealLogRepository();

  @override
  Future<void> addRecipe({
    required String recipeId,
    required MealType mealType,
    required String date,
    required String clientRequestId,
  }) async {
    try {
      await supabase.functions.invoke('meal-logs', body: {
        'meal_type': mealType.apiValue,
        'recipe_id': recipeId,
        'servings': 1,
        'date': date,
        'client_request_id': clientRequestId,
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw mapMealLogError(e);
    }
  }
}

final mealLogRepo = SupabaseMealLogRepository();
