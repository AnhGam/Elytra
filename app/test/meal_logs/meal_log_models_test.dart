import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/meal_log_fixtures.dart';

void main() {
  test('budget: remaining âm, NUMERIC dạng chuỗi, thiếu remaining', () {
    final b = Budget.fromJson({
      'target': {'kcal': '1968', 'protein_g': 130},
      'consumed': {'kcal': 2118.4, 'protein_g': '140.5'},
    });
    expect(b.remaining.kcal, closeTo(-150.4, 1e-9));
    expect(b.remaining.proteinG, closeTo(-10.5, 1e-9));
  });
  test('item: recipe_id null, source lạ, kiểu lạ không ném', () {
    final i = MealLogItem.fromJson({'id': 'x', 'source': 'recipe', 'recipe_id': null, 'name': 'Phở bò', 'servings': '1.5', 'kcal': 675});
    expect(i.recipeId, isNull);
    expect(i.servings, 1.5);
    expect(MealLogItem.fromJson({'id': 'y', 'source': '??', 'amount_g': 150, 'name': 'A'}).source, LogSource.ingredient);
    expect(() => MealLogItem.fromJson({'id': 'z', 'kcal': [1], 'name': null}), returnsNormally);
  });
  test('item: source lạ không amount_g là recipe; meal_type, date', () {
    final i = MealLogItem.fromJson({'id': 'y', 'source': '??', 'name': 'A', 'meal_type': 'dinner', 'date': '2026-11-11'});
    expect(i.source, LogSource.recipe);
    expect(i.byServings, isTrue);
    expect(i.mealType, MealType.dinner);
    expect(i.date, '2026-11-11');
    expect(MealLogItem.fromJson({'id': 'y', 'name': 'A', 'meal_type': 'zzz'}).mealType, isNull);
  });
  test('DayLog luôn đủ 4 bữa', () {
    final d = DayLog.fromJson({'date': '2026-11-11', 'budget': {}, 'meals': {'lunch': {'kcal': 675, 'items': []}}});
    expect(d.meals.keys, unorderedEquals(MealType.values));
    expect(d.meals[MealType.dinner]!.items, isEmpty);
    expect(d.isEmpty, isTrue);
  });
  test('without trừ budget và kcal bữa; upsert thay theo id', () {
    final a = item(id: 'a', kcal: 300), b = item(id: 'b', kcal: 200);
    final d = dayLog(items: [(MealType.lunch, a), (MealType.lunch, b)]);
    final w = d.without('a');
    expect(w.meals[MealType.lunch]!.kcal, 200);
    expect(w.budget.consumed.kcal, 200);
    expect(w.budget.remaining.kcal, 1768);
    final u = d.upsert(a.copyWith(macros: const Macros(kcal: 450)), MealType.lunch, d.budget);
    expect(u.meals[MealType.lunch]!.items.map((i) => i.id), ['a', 'b']);
    expect(u.meals[MealType.lunch]!.kcal, 650);
    expect(d.find('b'), b);
    expect(d.mealOf('b'), MealType.lunch);
    expect(d.mealOf('nope'), isNull);
  });
  test('LogRequest: == theo nội dung, toBody đúng khoá', () {
    const r = LogRequest.dish(refId: 'd1', amountG: 300, meal: MealType.dinner, date: '2026-11-11');
    expect(r, const LogRequest.dish(refId: 'd1', amountG: 300, meal: MealType.dinner, date: '2026-11-11'));
    expect(r == const LogRequest.dish(refId: 'd1', amountG: 200, meal: MealType.dinner, date: '2026-11-11'), isFalse);
    expect(r.toBody('k'), {'meal_type': 'dinner', 'dish_id': 'd1', 'amount_g': 300, 'date': '2026-11-11', 'client_request_id': 'k'});
  });
  test('LogRequest.recipe toBody có servings', () {
    const r = LogRequest.recipe(refId: 'r1', servings: 1.5, meal: MealType.lunch, date: '2026-11-11');
    expect(r.toBody('k'), {'meal_type': 'lunch', 'recipe_id': 'r1', 'servings': 1.5, 'date': '2026-11-11', 'client_request_id': 'k'});
  });
  test('FoodHit từ dòng RPC có số dạng chuỗi', () {
    final f = FoodHit.fromRow({'id': 'x', 'name_vi': 'Phở bò', 'calories_per_100g': '110.5', 'protein_per_100g': null}, FoodKind.dish);
    expect(f.per100.kcal, 110.5);
    expect(f.per100.proteinG, 0);
  });
  test('History.fromJson', () {
    final h = History.fromJson({
      'from': '2026-11-10', 'to': '2026-11-11', 'target_kcal': 2000,
      'days': [{'date': '2026-11-11', 'kcal': '800', 'item_count': 2, 'target_kcal': 2100}],
    });
    expect(h.targetKcal, 2000);
    expect(h.days.single.kcal, 800);
    expect(h.days.single.itemCount, 2);
    expect(h.days.single.copyWith(kcal: 1).kcal, 1);
  });
}
