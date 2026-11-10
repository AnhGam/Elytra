import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recipe_fixtures.dart';

List<String> order(List<Recipe> r,
        {String q = '', RecipeSort s = RecipeSort.bestMatch, int? budget}) =>
    RecipeQuery.apply(r, query: q, sort: s, mealBudgetKcal: budget)
        .map((e) => e.id)
        .toList();

void main() {
  test('bestMatch: mức khớp trước, rồi ngân sách', () {
    final x = recipe(id: 'x', title: 'Bò kho', kcal: 300); // startsWith
    final y = recipe(id: 'y', title: 'Phở bò', kcal: 680); // wholeWords
    final z = recipe(id: 'z', title: 'Phở bòn bon', kcal: 689); // wordPrefix
    expect(order([z, y, x], q: 'bo', budget: 689), ['x', 'y', 'z']);
  });
  test('bestMatch: ≤ ngân sách trước, gần ngân sách trước; đúng bằng thuộc nhóm ≤',
      () {
    final a = recipe(id: 'a', title: 'A', kcal: 689);
    final b = recipe(id: 'b', title: 'B', kcal: 600);
    final c = recipe(id: 'c', title: 'C', kcal: 700);
    final d = recipe(id: 'd', title: 'D', kcal: 200);
    expect(order([d, c, b, a], budget: 689), ['a', 'b', 'd', 'c']);
  });
  test('bestMatch: ngân sách null → tên A–Z (bỏ dấu)', () {
    expect(order([recipe(id: 'b', title: 'Đậu'), recipe(id: 'a', title: 'Cá')]),
        ['a', 'b']);
  });
  test('hòa → theo tên', () {
    expect(
        order([
          recipe(id: 'b', title: 'Bún', kcal: 300),
          recipe(id: 'a', title: 'Bánh', kcal: 300)
        ], s: RecipeSort.kcalAsc),
        ['a', 'b']);
  });
  test('calo tăng/giảm', () {
    final l = [
      recipe(id: 'h', title: 'H', kcal: 500),
      recipe(id: 'l', title: 'L', kcal: 100)
    ];
    expect(order(l, s: RecipeSort.kcalAsc), ['l', 'h']);
    expect(order(l, s: RecipeSort.kcalDesc), ['h', 'l']);
  });
  test('/100 kcal, món 0 kcal cuối', () {
    final p = recipe(id: 'p', title: 'P', kcal: 200, protein: 40, carbs: 10, fat: 2);
    final q = recipe(id: 'q', title: 'Q', kcal: 400, protein: 40, carbs: 60, fat: 20);
    final z = recipe(id: 'z', title: 'Z', kcal: 0, protein: 0, carbs: 0, fat: 0);
    expect(order([z, q, p], s: RecipeSort.proteinPer100Desc), ['p', 'q', 'z']);
    expect(order([z, q, p], s: RecipeSort.carbsPer100Asc), ['p', 'q', 'z']);
    expect(order([z, q, p], s: RecipeSort.fatPer100Asc), ['p', 'q', 'z']);
  });
  test('nấu nhanh nhất theo prep + cook', () {
    expect(
        order([
          recipe(id: 's', title: 'S', prep: 30, cook: 30),
          recipe(id: 'f', title: 'F', prep: 5, cook: 40)
        ], s: RecipeSort.quickest),
        ['f', 's']);
  });
}
