import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_repository.dart';

// Repository giả cho test: dữ liệu nằm trong các trường công khai.
class FakeRecipeRepository implements RecipeRepository {
  List<Recipe> recipes = [];
  Map<String, RecipeDetail> details = {};
  UserNutritionProfile? profile;
  List<Allergen> allergens = [];
  Set<int> userAllergenIds = {};
  // Khác null thì mọi hàm đều ném lỗi này.
  Object? failWith;
  int fetchAllCalls = 0;

  Future<T> _run<T>(T Function() body) {
    final e = failWith;
    if (e != null) return Future.error(e);
    return Future.value(body());
  }

  @override
  Future<List<Recipe>> fetchAll() {
    fetchAllCalls++;
    return _run(() => List.of(recipes));
  }

  @override
  Future<RecipeDetail?> fetchDetail(String id) => _run(() => details[id]);

  @override
  Future<UserNutritionProfile?> fetchProfile() => _run(() => profile);

  @override
  Future<List<Allergen>> fetchAllergens() => _run(() => List.of(allergens));

  @override
  Future<Set<int>> fetchUserAllergenIds() => _run(() => Set.of(userAllergenIds));

  @override
  Future<void> saveUserAllergenIds(Set<int> ids) =>
      _run(() => userAllergenIds = Set.of(ids));
}
