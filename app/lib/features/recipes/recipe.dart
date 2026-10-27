// Model bất biến cho công thức món ăn, đọc từ RPC search_recipes và bảng recipes.
import 'dart:convert';

enum Difficulty {
  easy,
  medium,
  hard;

  String get labelVi => switch (this) {
        Difficulty.easy => 'Dễ',
        Difficulty.medium => 'Vừa',
        Difficulty.hard => 'Khó',
      };

  // Giá trị lạ hoặc null -> easy.
  static Difficulty fromApi(String? v) => switch (v) {
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => Difficulty.easy,
      };
}

// Đọc số từ num hoặc String (NUMERIC có thể về dạng chuỗi); null/hỏng -> null.
double? _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

// Cột NOT NULL: null -> 0.
double _numOr0(Object? v) => _num(v) ?? 0;

int _int(Object? v) => _num(v)?.toInt() ?? 0;

Set<int> _intSet(Object? v) =>
    v is List ? {for (final e in v) if (_num(e) != null) _num(e)!.toInt()} : <int>{};

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.slug,
    this.imageUrl,
    this.description,
    required this.category,
    required this.cuisine,
    required this.servings,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.difficulty,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sodiumMg,
    this.allergenIds = const {},
    this.condimentAllergenIds = const {},
  });

  final String id;
  final String title;
  final String slug;
  final String? imageUrl;
  final String? description;
  final String category;
  final String cuisine;
  final int servings;
  final int prepMinutes;
  final int cookMinutes;
  final Difficulty difficulty;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sodiumMg;
  final Set<int> allergenIds;
  final Set<int> condimentAllergenIds;

  int get totalMinutes => prepMinutes + cookMinutes;

  // Dòng từ search_recipes (có sẵn allergens, condiment_allergens).
  factory Recipe.fromSearchRow(Map<String, dynamic> row) => Recipe._fromRow(
        row,
        allergenIds: _intSet(row['allergens']),
        condimentAllergenIds: _intSet(row['condiment_allergens']),
      );

  factory Recipe._fromRow(
    Map<String, dynamic> row, {
    required Set<int> allergenIds,
    required Set<int> condimentAllergenIds,
  }) =>
      Recipe(
        id: '${row['id']}',
        title: (row['title'] as String?) ?? '',
        slug: (row['slug'] as String?) ?? '',
        imageUrl: row['image_url'] as String?,
        description: row['description'] as String?,
        category: (row['category'] as String?) ?? '',
        cuisine: (row['cuisine'] as String?) ?? '',
        servings: _int(row['servings']),
        prepMinutes: _int(row['prep_time_minutes']),
        cookMinutes: _int(row['cook_time_minutes']),
        difficulty: Difficulty.fromApi(row['difficulty'] as String?),
        kcal: _numOr0(row['calories_per_serving']),
        proteinG: _numOr0(row['protein_g_per_serving']),
        carbsG: _numOr0(row['carbs_g_per_serving']),
        fatG: _numOr0(row['fat_g_per_serving']),
        fiberG: _numOr0(row['fiber_g_per_serving']),
        sodiumMg: _numOr0(row['sodium_mg_per_serving']),
        allergenIds: allergenIds,
        condimentAllergenIds: condimentAllergenIds,
      );
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.orderIndex,
    required this.rawText,
    required this.nameRaw,
    this.amount,
    this.unit,
    required this.amountG,
  });

  final int orderIndex;
  final String rawText;
  final String nameRaw;
  final double? amount;
  final String? unit;
  final double amountG;

  factory RecipeIngredient.fromRow(Map<String, dynamic> row) => RecipeIngredient(
        orderIndex: _int(row['order_index']),
        rawText: (row['raw_text'] as String?) ?? '',
        nameRaw: (row['ingredient_name_raw'] as String?) ?? '',
        amount: _num(row['amount']),
        unit: row['unit'] as String?,
        amountG: _numOr0(row['amount_g']),
      );
}

// Tiền tố "Bước N:" trong tiêu đề bước.
final RegExp _stepPrefix =
    RegExp(r'^\s*bước\s*\d+\s*[:.\-–]\s*', caseSensitive: false);
final RegExp _blankRuns = RegExp(r'\n{3,}');

class RecipeStep {
  const RecipeStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  // Nhận List hoặc chuỗi JSON của list; dữ liệu khác/hỏng -> [].
  static List<RecipeStep> parseSteps(Object? json) {
    Object? data = json;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return const [];
      }
    }
    if (data is! List) return const [];
    final steps = <RecipeStep>[];
    for (final e in data) {
      if (e is! Map) continue;
      steps.add(RecipeStep(
        number: _int(e['step_number']),
        title: ((e['title'] as String?) ?? '').replaceFirst(_stepPrefix, '').trim(),
        description: ((e['description'] as String?) ?? '')
            .replaceAll(_blankRuns, '\n\n')
            .trim(),
      ));
    }
    steps.sort((a, b) => a.number.compareTo(b.number));
    return steps;
  }
}

class RecipeDetail {
  const RecipeDetail({
    required this.recipe,
    required this.ingredients,
    required this.steps,
  });

  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  // Dòng recipes kèm recipe_ingredients(*) và recipe_allergens(allergen_id, via_condiment).
  factory RecipeDetail.fromRow(Map<String, dynamic> row) {
    final allergenRows = [
      for (final a in (row['recipe_allergens'] as List? ?? const []))
        if (a is Map) a,
    ];
    final ingredients = [
      for (final i in (row['recipe_ingredients'] as List? ?? const []))
        if (i is Map) RecipeIngredient.fromRow(Map<String, dynamic>.from(i)),
    ]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return RecipeDetail(
      recipe: Recipe._fromRow(
        row,
        allergenIds: {for (final a in allergenRows) _int(a['allergen_id'])},
        condimentAllergenIds: {
          for (final a in allergenRows)
            if (a['via_condiment'] == true) _int(a['allergen_id']),
        },
      ),
      ingredients: ingredients,
      steps: RecipeStep.parseSteps(row['instructions']),
    );
  }
}

class Allergen {
  const Allergen({required this.id, required this.nameVi, this.description});

  final int id;
  final String nameVi;
  final String? description;

  factory Allergen.fromRow(Map<String, dynamic> row) => Allergen(
        id: _int(row['id']),
        nameVi: (row['name_vi'] as String?) ?? '',
        description: row['description'] as String?,
      );
}

class UserNutritionProfile {
  const UserNutritionProfile({
    this.targetKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
  });

  final double? targetKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;

  factory UserNutritionProfile.fromRow(Map<String, dynamic> row) =>
      UserNutritionProfile(
        targetKcal: _num(row['target_calories']),
        proteinG: _num(row['target_protein_g']),
        carbsG: _num(row['target_carbs_g']),
        fatG: _num(row['target_fat_g']),
        fiberG: _num(row['target_fiber_g']),
      );
}
