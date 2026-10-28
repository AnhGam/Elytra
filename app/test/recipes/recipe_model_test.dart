import 'package:elytra/features/recipes/recipe.dart';
import 'package:flutter_test/flutter_test.dart';

// Các cột bắt buộc của bảng recipes.
const Map<String, dynamic> searchRowMinimal = {
  'id': 'a',
  'title': 'Phở bò',
  'slug': 'pho-bo',
  'category': 'mon_man',
  'cuisine': 'vietnamese',
  'servings': 2,
  'prep_time_minutes': 10,
  'cook_time_minutes': 190,
  'difficulty': 'easy',
  'calories_per_serving': 300,
  'protein_g_per_serving': 20,
  'fat_g_per_serving': 5,
  'carbs_g_per_serving': 40,
  'fiber_g_per_serving': 2,
  'sodium_mg_per_serving': 800,
  'image_url': null,
  'description': null,
};

void main() {
  test('fromSearchRow đọc số dạng chuỗi và null', () {
    final r = Recipe.fromSearchRow({
      'id': 'a', 'title': 'Phở bò', 'slug': 'pho-bo', 'image_url': null, 'description': null,
      'category': 'mon_man', 'cuisine': 'vietnamese', 'servings': 2,
      'prep_time_minutes': 10, 'cook_time_minutes': 190, 'difficulty': 'medium',
      'calories_per_serving': '332.50', 'protein_g_per_serving': 31, 'fat_g_per_serving': 5.5,
      'carbs_g_per_serving': 41, 'fiber_g_per_serving': null, 'sodium_mg_per_serving': 900,
      'allergens': [1, 6], 'condiment_allergens': [1],
    });
    expect(r.kcal, 332.5);
    expect(r.fiberG, 0);
    expect(r.totalMinutes, 200);
    expect(r.difficulty, Difficulty.medium);
    expect(r.allergenIds, {1, 6});
    expect(r.condimentAllergenIds, {1});
    expect(r.imageUrl, isNull);
  });

  test('parseSteps: bỏ "Bước N:", gộp dòng trống, chịu được dữ liệu hỏng', () {
    final steps = RecipeStep.parseSteps([
      {'step_number': 2, 'title': 'Bước 2: Giã hành ớt', 'description': 'A\n\n\n\nB'},
      {'step_number': 1, 'title': 'Sơ chế cá', 'description': ' C '},
    ]);
    expect(steps.map((s) => s.number), [1, 2]);
    expect(steps[0].title, 'Sơ chế cá');
    expect(steps[0].description, 'C');
    expect(steps[1].title, 'Giã hành ớt');
    expect(steps[1].description, 'A\n\nB');
    expect(RecipeStep.parseSteps(null), isEmpty);
    expect(RecipeStep.parseSteps({'x': 1}), isEmpty);
    expect(RecipeStep.parseSteps('[]'), isEmpty);
  });

  test('parseSteps: bỏ ":" và khoảng trắng cuối tiêu đề', () {
    final steps = RecipeStep.parseSteps([
      {'step_number': 1, 'title': 'Làm hành ớt: ', 'description': 'A'},
      {'step_number': 2, 'title': 'Bước 2: Ướp cá:', 'description': 'B'},
      {'step_number': 3, 'title': 'Tỉ lệ 1:2 nước mắm', 'description': 'C'},
      {'step_number': 4, 'title': ':', 'description': 'D'},
    ]);
    expect(steps.map((s) => s.title), ['Làm hành ớt', 'Ướp cá', 'Tỉ lệ 1:2 nước mắm', '']);
  });

  test('RecipeDetail.fromRow: dị ứng từ gia vị, nguyên liệu theo order_index', () {
    final d = RecipeDetail.fromRow({
      ...searchRowMinimal,
      'instructions': [],
      'recipe_ingredients': [
        {'order_index': 2, 'raw_text': 'Tỏi: 3 tép', 'ingredient_name_raw': 'Tỏi', 'amount': 3, 'unit': 'tép', 'amount_g': 15},
        {'order_index': 1, 'raw_text': 'Cá: 400g', 'ingredient_name_raw': 'Cá', 'amount': '400', 'unit': 'g', 'amount_g': '400'},
      ],
      'recipe_allergens': [
        {'allergen_id': 1, 'via_condiment': true},
        {'allergen_id': 2, 'via_condiment': false},
      ],
    });
    expect(d.ingredients.map((i) => i.nameRaw), ['Cá', 'Tỏi']);
    expect(d.ingredients.first.amount, 400);
    expect(d.recipe.allergenIds, {1, 2});
    expect(d.recipe.condimentAllergenIds, {1});
    expect(d.steps, isEmpty);
  });

  test('Allergen và UserNutritionProfile fromRow', () {
    final a = Allergen.fromRow({'id': 1, 'name_vi': 'Hải sản', 'description': null});
    expect(a.nameVi, 'Hải sản');
    final p = UserNutritionProfile.fromRow({'target_calories': '1968', 'target_protein_g': null});
    expect(p.targetKcal, 1968);
    expect(p.proteinG, isNull);
  });
}
