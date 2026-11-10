import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lỗi khi gọi nhật ký bữa ăn.
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

/// Món không tồn tại (hoặc của người khác).
class MealLogItemNotFound extends MealLogException {
  const MealLogItemNotFound();
}

/// Món cũ hơn 30 ngày nên không sửa/xóa được.
class MealLogTooOld extends MealLogException {
  const MealLogTooOld();
}

/// Dữ liệu gửi lên không hợp lệ; [field] là trường bị lỗi nếu server báo.
class MealLogInvalid extends MealLogException {
  final String? field;
  const MealLogInvalid([this.field]);
}

/// Lỗi khác, kèm mã/thông điệp từ Edge Function nếu có.
class MealLogFailed extends MealLogException {
  final String? code;
  final String? message;
  const MealLogFailed([this.code, this.message]);
}

/// Thao tác đang gọi, để phân biệt cùng một mã lỗi.
enum MealLogOp { read, add, update, delete }

/// Lấy `error` ({code, message, field}) từ details (Map hoặc chuỗi JSON).
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
MealLogException mapMealLogError(Object e, {MealLogOp op = MealLogOp.add}) {
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
    final field = err?['field'] is String ? err!['field'] as String : null;
    switch (code) {
      case 'PROFILE_NOT_FOUND':
        return const MealLogProfileMissing();
      case 'ITEM_NOT_FOUND':
        return const MealLogItemNotFound();
      case 'VALIDATION_ERROR':
        if (field == 'date' && (op == MealLogOp.update || op == MealLogOp.delete)) {
          return const MealLogTooOld();
        }
        return MealLogInvalid(field);
    }
    return MealLogFailed(code, message);
  }
  return const MealLogFailed();
}

/// Kết quả ghi món: món (kèm bữa/ngày), budget mới, cờ phát lại theo idempotency.
class AddResult {
  const AddResult({required this.item, required this.budget, required this.replayed});
  final MealLogItem item;
  final Budget budget;
  final bool replayed;
}

/// Kết quả sửa món.
class UpdateResult {
  const UpdateResult({required this.item, required this.budget});
  final MealLogItem item;
  final Budget budget;
}

abstract class MealLogRepository {
  Future<DayLog> getDay(String date);
  Future<History> getHistory(String from, String to);
  Future<AddResult> add(LogRequest req, {required String clientRequestId});
  Future<UpdateResult> updateItem(MealLogItem item, {double? servings, int? amountG});
  Future<void> deleteItem(String id);
}

const _timeout = Duration(seconds: 15);

/// Bản gọi Edge Function `meal-logs`. Constructor không chạm `supabase`.
class SupabaseMealLogRepository implements MealLogRepository {
  SupabaseMealLogRepository();

  Future<Map<String, dynamic>> _call(
    MealLogOp op,
    String path, {
    HttpMethod method = HttpMethod.post,
    Map<String, Object>? body,
    Map<String, String>? query,
  }) async {
    try {
      final res = await supabase.functions
          .invoke(path, method: method, body: body, queryParameters: query)
          .timeout(_timeout);
      final data = res.data;
      if (data is! Map) throw const MealLogFailed('BAD_RESPONSE');
      return Map<String, dynamic>.from(data);
    } catch (e) {
      throw mapMealLogError(e, op: op);
    }
  }

  @override
  Future<DayLog> getDay(String date) async => DayLog.fromJson(await _call(
        MealLogOp.read,
        'meal-logs',
        method: HttpMethod.get,
        query: {'date': date},
      ));

  @override
  Future<History> getHistory(String from, String to) async =>
      History.fromJson(await _call(
        MealLogOp.read,
        'meal-logs/history',
        method: HttpMethod.get,
        query: {'from': from, 'to': to},
      ));

  @override
  Future<AddResult> add(LogRequest req, {required String clientRequestId}) async {
    final j = await _call(MealLogOp.add, 'meal-logs', body: req.toBody(clientRequestId));
    return AddResult(
      item: _item(j),
      budget: Budget.fromJson(j['budget']),
      replayed: j['replayed'] == true,
    );
  }

  @override
  Future<UpdateResult> updateItem(MealLogItem item,
      {double? servings, int? amountG}) async {
    final j = await _call(
      MealLogOp.update,
      'meal-logs/items/${item.id}',
      method: HttpMethod.patch,
      body: item.byServings ? {'servings': ?servings} : {'amount_g': ?amountG},
    );
    return UpdateResult(item: _item(j), budget: Budget.fromJson(j['budget']));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _call(MealLogOp.delete, 'meal-logs/items/$id', method: HttpMethod.delete);
  }

  MealLogItem _item(Map<String, dynamic> j) {
    final raw = j['item'];
    if (raw is! Map) throw const MealLogFailed('BAD_RESPONSE');
    return MealLogItem.fromJson(Map<String, dynamic>.from(raw));
  }
}

final mealLogRepo = SupabaseMealLogRepository();
