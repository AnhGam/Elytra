import 'dart:async';
import 'dart:io';

import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/recipes/recipe_text.dart';
import 'package:elytra/main.dart';

/// Số dòng mỗi trang kết quả tìm kiếm.
const kFoodPageSize = 20;

/// Từ khoá rỗng hoặc chỉ gồm dấu câu → null (RPC trả danh sách mặc định).
String? normalizeFoodQuery(String q) => wordsOf(q).isEmpty ? null : q.trim();

/// Lỗi khi tìm món/nguyên liệu.
sealed class FoodSearchException implements Exception {
  const FoodSearchException();
}

/// Mất mạng / quá thời gian chờ.
class FoodSearchOffline extends FoodSearchException {
  const FoodSearchOffline();
}

/// Lỗi khác.
class FoodSearchFailed extends FoodSearchException {
  const FoodSearchFailed();
}

/// Quy lỗi bất kỳ về [FoodSearchException].
FoodSearchException mapFoodSearchError(Object e) {
  if (e is FoodSearchException) return e;
  if (e is SocketException || e is TimeoutException) {
    return const FoodSearchOffline();
  }
  // ClientException (http/postgrest) nhận diện qua tên để khỏi import thêm gói.
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('ClientException')) {
    return const FoodSearchOffline();
  }
  return const FoodSearchFailed();
}

abstract class FoodSearchRepository {
  Future<List<FoodHit>> searchDishes(String query,
      {int limit = kFoodPageSize, int offset = 0});

  Future<List<FoodHit>> searchIngredients(String query,
      {bool? featured, int limit = kFoodPageSize, int offset = 0});
}

class SupabaseFoodSearchRepository implements FoodSearchRepository {
  @override
  Future<List<FoodHit>> searchDishes(String query,
      {int limit = kFoodPageSize, int offset = 0}) {
    return _call('search_dishes', FoodKind.dish, {
      'p_query': normalizeFoodQuery(query),
      'p_limit': limit,
      'p_offset': offset,
    });
  }

  @override
  Future<List<FoodHit>> searchIngredients(String query,
      {bool? featured, int limit = kFoodPageSize, int offset = 0}) {
    return _call('search_ingredients', FoodKind.ingredient, {
      'p_query': normalizeFoodQuery(query),
      'p_is_featured': featured,
      'p_limit': limit,
      'p_offset': offset,
    });
  }

  Future<List<FoodHit>> _call(
      String fn, FoodKind kind, Map<String, dynamic> params) async {
    try {
      final res = await supabase
          .rpc(fn, params: params)
          .timeout(const Duration(seconds: 15)) as List;
      return [
        for (final r in res)
          if (r is Map) FoodHit.fromRow(Map<String, dynamic>.from(r), kind),
      ];
    } catch (e) {
      throw mapFoodSearchError(e);
    }
  }
}

final FoodSearchRepository foodSearchRepo = SupabaseFoodSearchRepository();
