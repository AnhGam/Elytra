import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_text.dart';

// Tạo nhanh một Recipe cho test.
Recipe recipe({
  String id = 'r1',
  String title = 'Cá basa kho tộ',
  String? slug,
  double kcal = 240,
  double protein = 39,
  double carbs = 6,
  double fat = 7,
  double fiber = 0.7,
  double sodium = 1540,
  int prep = 10,
  int cook = 30,
  int servings = 2,
  Difficulty difficulty = Difficulty.easy,
  String category = 'mon_kho',
  Set<int> allergens = const {},
  Set<int> condiment = const {},
}) =>
    Recipe(
      id: id,
      title: title,
      slug: slug ?? slugify(title),
      category: category,
      cuisine: 'vietnamese',
      servings: servings,
      prepMinutes: prep,
      cookMinutes: cook,
      difficulty: difficulty,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      fiberG: fiber,
      sodiumMg: sodium,
      allergenIds: allergens,
      condimentAllergenIds: condiment,
    );
