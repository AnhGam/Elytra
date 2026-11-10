import 'dart:async';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
  late FakeRecipeRepository repo;
  late RecipeCatalog catalog;
  late FakeMealLogRepository meal;
  late RecipeDetailController c;

  RecipeDetailController make({Recipe? initial, DateTime Function()? now}) {
    var n = 0;
    return RecipeDetailController(
      id: 'r1',
      initial: initial,
      catalog: catalog,
      mealLogs: meal,
      now: now ?? () => DateTime.utc(2026, 10, 28, 12),
      newRequestId: () => 'id-${++n}',
    );
  }

  setUp(() {
    repo = FakeRecipeRepository();
    repo.details['r1'] = RecipeDetail(
      recipe: recipe(id: 'r1', servings: 2, allergens: {1, 2}, condiment: {1}),
      ingredients: const [],
      steps: const [],
    );
    catalog = RecipeCatalog(repo: repo);
    meal = FakeMealLogRepository();
    c = make();
  });

  test('load: có detail → ready; không thấy → notFound; lỗi → error', () async {
    await c.load();
    expect(c.status, DetailStatus.ready);
    expect(c.detail, isNotNull);

    repo.details.clear();
    final c2 = make();
    await c2.load();
    expect(c2.status, DetailStatus.notFound);

    repo.failWith = Exception('boom');
    final c3 = make();
    await c3.load();
    expect(c3.status, DetailStatus.error);
  });

  test('mở bằng extra hiện ngay recipe trước khi load', () {
    final c = make(initial: recipe(id: 'r1', title: 'Cá kho'));
    expect(c.recipe!.title, 'Cá kho');
    expect(c.status, DetailStatus.loading);
  });

  test('khẩu phần 1–20, factor', () async {
    await c.load();
    c.incServings();
    expect(c.factor, 1.5);
    for (var i = 0; i < 30; i++) {
      c.decServings();
    }
    expect(c.cookServings, 1);
    for (var i = 0; i < 30; i++) {
      c.incServings();
    }
    expect(c.cookServings, 20);
  });

  test('bữa và ngày từ cùng một now()', () {
    final c = make(now: () => DateTime.utc(2026, 10, 28, 23, 50));
    expect(c.mealType, MealType.snack);
    expect(c.logDate, '2026-10-28');
  });

  test('gửi đúng body, thành công thì lần sau id mới', () async {
    expect(await c.addOneServing(), isA<AddMealSuccess>());
    await c.addOneServing();
    expect(meal.calls.map((x) => x['clientRequestId']), ['id-1', 'id-2']);
    expect(meal.calls.first['mealType'], MealType.lunch);
    expect(meal.calls.first['date'], '2026-10-28');
    expect(meal.calls.first['recipeId'], 'r1');
  });

  test('mất mạng thì thử lại dùng lại id cũ', () async {
    meal.failWith = MealLogOffline();
    expect(await c.addOneServing(), isA<AddMealOffline>());
    meal.failWith = null;
    await c.addOneServing();
    expect(meal.calls.map((x) => x['clientRequestId']), ['id-1', 'id-1']);
  });

  test('PROFILE_NOT_FOUND', () async {
    meal.failWith = MealLogProfileMissing();
    expect(await c.addOneServing(), isA<AddMealProfileMissing>());
  });

  test('lỗi khác → AddMealFailed, giữ id', () async {
    meal.failWith = MealLogFailed('X', 'm');
    expect(await c.addOneServing(), isA<AddMealFailed>());
    meal.failWith = null;
    await c.addOneServing();
    expect(meal.calls.map((x) => x['clientRequestId']), ['id-1', 'id-1']);
  });

  test('bấm hai lần khi đang gửi → một request', () async {
    meal.gate = Completer<void>();
    final first = c.addOneServing();
    expect(c.sending, isTrue);
    expect(await c.addOneServing(), isA<AddMealIgnored>());
    meal.gate!.complete();
    await first;
    expect(c.sending, isFalse);
    expect(meal.calls, hasLength(1));
  });

  test('cảnh báo dị ứng có cờ gia vị, kể cả khi chip lọc tắt', () async {
    repo
      ..userAllergenIds = {1, 2}
      ..allergens = const [
        Allergen(id: 1, nameVi: 'Hải sản'),
        Allergen(id: 2, nameVi: 'Trứng'),
      ];
    await c.load();
    expect(c.allergenWarnings.map((w) => (w.name, w.viaCondiment)),
        [('Hải sản', true), ('Trứng', false)]);
  });

  test('toggleStep đánh dấu và bỏ đánh dấu', () {
    c.toggleStep(2);
    expect(c.doneSteps, {2});
    c.toggleStep(2);
    expect(c.doneSteps, isEmpty);
  });
}
