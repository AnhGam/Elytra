import 'dart:async';

import 'package:elytra/features/meal_logs/food_search_repository.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/recipes/recipe_text.dart';

/// Bản giả của [FoodSearchRepository] dùng trong test.
class FakeFoodSearchRepository implements FoodSearchRepository {
  List<FoodHit> dishes = [];
  List<FoodHit> ingredients = [];

  /// Id nguyên liệu được coi là nổi bật khi `featured == true`.
  Set<String> featuredIds = {};

  /// Các lời gọi đã nhận: (hàm, từ khoá đã chuẩn hoá, featured, offset).
  final List<(String fn, String? q, bool? featured, int offset)> calls = [];

  /// Nếu đặt, các lời gọi chờ đến khi gate hoàn tất.
  Completer<void>? gate;

  /// Nếu đặt, các lời gọi ném lỗi này.
  FoodSearchException? failWith;

  @override
  Future<List<FoodHit>> searchDishes(String query,
      {int limit = kFoodPageSize, int offset = 0}) async {
    calls.add(('search_dishes', normalizeFoodQuery(query), null, offset));
    return _run(dishes, query, null, limit, offset);
  }

  @override
  Future<List<FoodHit>> searchIngredients(String query,
      {bool? featured, int limit = kFoodPageSize, int offset = 0}) async {
    calls.add(('search_ingredients', normalizeFoodQuery(query), featured, offset));
    return _run(ingredients, query, featured, limit, offset);
  }

  Future<List<FoodHit>> _run(List<FoodHit> src, String query, bool? featured,
      int limit, int offset) async {
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    final q = normalizeFoodQuery(query);
    final key = q == null ? '' : removeDiacritics(q.toLowerCase());
    final list = src.where((h) {
      if (featured == true && !featuredIds.contains(h.id)) return false;
      return removeDiacritics(h.name.toLowerCase()).contains(key);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (offset >= list.length) return [];
    final end = (offset + limit).clamp(0, list.length);
    return list.sublist(offset, end);
  }
}
