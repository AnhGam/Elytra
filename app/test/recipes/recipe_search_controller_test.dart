import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:elytra/features/recipes/recipe_search_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
  late FakeRecipeRepository repo;
  late RecipeCatalog catalog;
  late RecipeSearchController ctl;

  setUp(() async {
    repo = FakeRecipeRepository();
    catalog = RecipeCatalog(repo: repo);
    await catalog.ensureLoaded();
    ctl = RecipeSearchController(
        catalog: catalog, now: () => DateTime.utc(2026, 10, 28, 12));
  });
  tearDown(() {
    ctl.dispose();
    catalog.dispose();
  });

  test('lọc dị ứng chỉ khi bật và đã khai báo', () async {
    repo
      ..recipes = [recipe(id: 'a', allergens: {1}), recipe(id: 'b', title: 'B')]
      ..userAllergenIds = {1};
    await catalog.refresh();
    expect(ctl.results.map((r) => r.id), ['b']);
    ctl.toggleExcludeAllergens();
    expect(ctl.results, hasLength(2));
  });
  test('chưa khai báo dị ứng', () => expect(ctl.hasDeclaredAllergens, isFalse));
  test('chip ≤ 500 kcal bật/tắt maxKcal = 500', () {
    ctl.toggleUnder500();
    expect(ctl.filters.maxKcal, 500);
    ctl.toggleUnder500();
    expect(ctl.filters.maxKcal, isNull);
  });
  test('tìm gần đây: tối đa 5, mới nhất trước, bỏ trùng', () {
    for (final q in ['a', 'b', 'c', 'd', 'e', 'f', ' B ']) {
      ctl
        ..setQuery(q)
        ..submitQuery();
    }
    expect(ctl.recentSearches, ['B', 'f', 'e', 'd', 'c']);
    ctl.setQuery('');
    ctl.recordOpened();
    expect(ctl.recentSearches, hasLength(5));
  });
  test('ngân sách bữa trưa từ hồ sơ', () async {
    repo.profile = const UserNutritionProfile(targetKcal: 1968);
    await catalog.refresh();
    expect(ctl.mealBudgetKcal, 689);
  });
  test('nhóm món chỉ hiện nhóm có món, theo thứ tự cố định', () async {
    repo.recipes = [
      recipe(id: 'a', category: 'mon_kho'),
      recipe(id: 'b', category: 'zzz'),
      recipe(id: 'c', category: 'mon_man')
    ];
    await catalog.refresh();
    expect(ctl.categories, ['mon_man', 'mon_kho', 'zzz']);
  });
  test('countFor không đổi filters hiện tại', () async {
    repo.recipes = [recipe(id: 'a', kcal: 100), recipe(id: 'b', kcal: 900)];
    await catalog.refresh();
    expect(ctl.countFor(const RecipeFilters(maxKcal: 500)), 1);
    expect(ctl.results, hasLength(2));
  });
  test('catalog đổi → controller notify', () async {
    var n = 0;
    ctl.addListener(() => n++);
    await catalog.refresh();
    expect(n, greaterThan(0));
  });
  test('fridge không ảnh hưởng kết quả; nhãn nhóm', () async {
    repo.recipes = [recipe(id: 'a'), recipe(id: 'b')];
    await catalog.refresh();
    ctl.toggleFridge();
    expect(ctl.fridge, isTrue);
    expect(ctl.results, hasLength(2));
    expect(categoryLabel('mon_kho'), 'Món kho');
    expect(categoryLabel('zzz'), 'zzz');
  });
}
