import 'package:elytra/core/meal_time.dart';
import 'package:elytra/core/uuid.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/foundation.dart';

enum DetailStatus { loading, ready, notFound, error }

/// Kết quả của thao tác "thêm 1 khẩu phần vào bữa hiện tại".
sealed class AddMealResult {
  const AddMealResult();
}

class AddMealSuccess extends AddMealResult {
  const AddMealSuccess();
}

class AddMealOffline extends AddMealResult {
  const AddMealOffline();
}

class AddMealProfileMissing extends AddMealResult {
  const AddMealProfileMissing();
}

class AddMealFailed extends AddMealResult {
  const AddMealFailed();
}

/// Đang gửi thì bỏ qua lần bấm thêm.
class AddMealIgnored extends AddMealResult {
  const AddMealIgnored();
}

class AllergenWarning {
  const AllergenWarning({required this.name, required this.viaCondiment});
  final String name;
  final bool viaCondiment;
}

class RecipeDetailController extends ChangeNotifier {
  RecipeDetailController({
    required this.id,
    Recipe? initial,
    required this.catalog,
    required this.mealLogs,
    DateTime Function() now = vnNow,
    this.newRequestId = uuidV4,
  })  : _initial = initial,
        _cookServings = initial?.servings ?? 1 {
    // Gọi now() đúng một lần: bữa và ngày luôn cùng một thời điểm.
    final t = now();
    mealType = mealTypeAt(t);
    logDate = isoDate(t);
  }

  final String id;
  final Recipe? _initial;
  final RecipeCatalog catalog;
  final MealLogRepository mealLogs;
  final String Function() newRequestId;

  late final MealType mealType;
  late final String logDate;

  RecipeDetail? _detail;
  DetailStatus _status = DetailStatus.loading;
  int _cookServings;
  bool _servingsTouched = false;
  final Set<int> _doneSteps = {};
  bool _sending = false;
  String? _clientRequestId;
  bool _disposed = false;

  RecipeDetail? get detail => _detail;
  DetailStatus get status => _status;
  Recipe? get recipe => _detail?.recipe ?? _initial;
  int get cookServings => _cookServings;
  bool get sending => _sending;
  Set<int> get doneSteps => Set.unmodifiable(_doneSteps);

  double get factor {
    final s = recipe?.servings ?? 0;
    return s <= 0 ? 1 : _cookServings / s;
  }

  int? get mealBudget =>
      mealBudgetKcal(catalog.profile?.targetKcal, mealType);

  Future<void> load() async {
    _status = DetailStatus.loading;
    _notify();
    try {
      // Lỗi catalog (ensureLoaded không ném) không làm hỏng màn chi tiết.
      final results = await Future.wait<Object?>([
        catalog.repo.fetchDetail(id),
        catalog.ensureLoaded(),
      ]);
      final d = results[0] as RecipeDetail?;
      if (d == null) {
        _status = DetailStatus.notFound;
      } else {
        _detail = d;
        if (!_servingsTouched) _cookServings = d.recipe.servings;
        _status = DetailStatus.ready;
      }
    } catch (_) {
      _status = DetailStatus.error;
    }
    _notify();
  }

  void incServings() => _setServings(_cookServings + 1);
  void decServings() => _setServings(_cookServings - 1);

  void _setServings(int v) {
    _servingsTouched = true;
    final n = v.clamp(1, 20);
    if (n == _cookServings) return;
    _cookServings = n;
    _notify();
  }

  void toggleStep(int number) {
    if (!_doneSteps.remove(number)) _doneSteps.add(number);
    _notify();
  }

  List<AllergenWarning> get allergenWarnings {
    final r = recipe;
    if (r == null) return const [];
    final names = {for (final a in catalog.allergens) a.id: a.nameVi};
    final ids = r.allergenIds.intersection(catalog.userAllergenIds).toList()
      ..sort();
    return [
      for (final i in ids)
        if (names[i] != null)
          AllergenWarning(
            name: names[i]!,
            viaCondiment: r.condimentAllergenIds.contains(i),
          ),
    ];
  }

  Future<AddMealResult> addOneServing() async {
    if (_sending) return const AddMealIgnored();
    _sending = true;
    _notify();
    final reqId = _clientRequestId ??= newRequestId();
    try {
      await mealLogs.addRecipe(
        recipeId: id,
        mealType: mealType,
        date: logDate,
        clientRequestId: reqId,
      );
      _clientRequestId = null;
      return const AddMealSuccess();
    } on MealLogOffline {
      return const AddMealOffline();
    } on MealLogProfileMissing {
      return const AddMealProfileMissing();
    } catch (_) {
      return const AddMealFailed();
    } finally {
      _sending = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
