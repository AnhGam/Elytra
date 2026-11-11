import 'dart:async';
import 'dart:io';

import 'package:elytra/features/meal_logs/food_search_repository.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_food_search_repository.dart';

void main() {
  test('từ khoá rỗng hoặc chỉ dấu câu → null', () {
    expect(normalizeFoodQuery(''), isNull);
    expect(normalizeFoodQuery('  , . '), isNull);
    expect(normalizeFoodQuery('  phở bò '), 'phở bò');
  });

  test('lỗi mạng và lỗi khác', () {
    expect(mapFoodSearchError(const SocketException('x')),
        isA<FoodSearchOffline>());
    expect(mapFoodSearchError(TimeoutException('x')), isA<FoodSearchOffline>());
    expect(mapFoodSearchError(StateError('x')), isA<FoodSearchFailed>());
  });

  FoodHit hit(String n, FoodKind k) =>
      FoodHit.fromRow({'id': n, 'name_vi': n}, k);

  test('bản giả: không dấu vẫn khớp, phân trang', () async {
    final f = FakeFoodSearchRepository()
      ..dishes = [
        for (final n in ['Phở bò', 'Bún chả', 'Phở gà']) hit(n, FoodKind.dish)
      ];
    expect((await f.searchDishes('pho')).map((h) => h.name),
        ['Phở bò', 'Phở gà']);
    expect((await f.searchDishes('', limit: 2, offset: 2)).map((h) => h.name),
        ['Phở gà']);
  });

  test('bản giả: lọc nguyên liệu nổi bật và ghi lại lời gọi', () async {
    final f = FakeFoodSearchRepository()
      ..ingredients = [
        for (final n in ['Gạo', 'Cà rốt']) hit(n, FoodKind.ingredient)
      ]
      ..featuredIds = {'Gạo'};
    expect((await f.searchIngredients('', featured: true)).map((h) => h.name),
        ['Gạo']);
    expect((await f.searchIngredients('')).map((h) => h.name),
        ['Cà rốt', 'Gạo']);
    expect(f.calls.first, ('search_ingredients', null, true, 0));
  });

  test('bản giả: failWith ném lỗi', () async {
    final f = FakeFoodSearchRepository()..failWith = const FoodSearchOffline();
    expect(f.searchDishes('a'), throwsA(isA<FoodSearchOffline>()));
  });
}
