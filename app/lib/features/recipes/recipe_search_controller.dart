import 'package:flutter/foundation.dart';

import '../../core/meal_time.dart' as mt;
import 'recipe.dart';
import 'recipe_catalog.dart';
import 'recipe_query.dart';

/// Nhãn tiếng Việt của nhóm món; thứ tự khóa = thứ tự hiển thị.
const kCategoryLabels = {
  'mon_man': 'Món mặn',
  'mon_kho': 'Món kho',
  'mon_an_sang': 'Món ăn sáng',
  'mon_chay': 'Món chay',
  'mon_canh': 'Món canh',
  'mon_xao': 'Món xào',
  'mon_nuong': 'Món nướng',
};

/// Nhãn nhóm món; giá trị lạ trả nguyên văn.
String categoryLabel(String v) => kCategoryLabels[v] ?? v;

/// Trạng thái màn tìm kiếm: từ khóa, bộ lọc, sắp xếp, chip nhanh, tìm gần đây.
class RecipeSearchController extends ChangeNotifier {
  RecipeSearchController({
    required this.catalog,
    this.now = mt.vnNow,
  }) {
    catalog.addListener(_onCatalog);
  }

  final RecipeCatalog catalog;
  final DateTime Function() now;

  String query = '';
  final List<String> _recent = [];
  RecipeFilters filters = const RecipeFilters();
  RecipeSort sort = RecipeSort.bestMatch;
  bool fridge = false; // Chỉ là trạng thái UI, không ảnh hưởng kết quả.
  bool excludeAllergens = true;

  void _onCatalog() => notifyListeners();

  @override
  void dispose() {
    catalog.removeListener(_onCatalog);
    super.dispose();
  }

  List<String> get recentSearches => List.unmodifiable(_recent);

  void setQuery(String q) {
    query = q;
    notifyListeners();
  }

  void _addRecent(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return;
    final low = q.toLowerCase();
    _recent.removeWhere((e) => e.toLowerCase() == low);
    _recent.insert(0, q);
    if (_recent.length > 5) _recent.removeRange(5, _recent.length);
  }

  void submitQuery() {
    _addRecent(query);
    notifyListeners();
  }

  void recordOpened() {
    _addRecent(query);
    notifyListeners();
  }

  void removeRecent(String q) {
    _recent.remove(q);
    notifyListeners();
  }

  void clearRecents() {
    _recent.clear();
    notifyListeners();
  }

  void applyFilters(RecipeFilters f) {
    filters = f;
    notifyListeners();
  }

  void setSort(RecipeSort s) {
    sort = s;
    notifyListeners();
  }

  bool get under500 => filters.maxKcal == 500;
  void toggleUnder500() =>
      applyFilters(filters.copyWith(maxKcal: under500 ? null : 500));

  bool get under30Min => filters.maxTotalMinutes == 30;
  void toggleUnder30Min() =>
      applyFilters(filters.copyWith(maxTotalMinutes: under30Min ? null : 30));

  void toggleFridge() {
    fridge = !fridge;
    notifyListeners();
  }

  void toggleExcludeAllergens() {
    excludeAllergens = !excludeAllergens;
    notifyListeners();
  }

  bool get hasDeclaredAllergens => catalog.userAllergenIds.isNotEmpty;

  int? get mealBudgetKcal =>
      mt.mealBudgetKcal(catalog.profile?.targetKcal, mt.mealTypeAt(now()));

  Set<int> get _excluded => excludeAllergens && hasDeclaredAllergens
      ? catalog.userAllergenIds
      : const {};

  List<Recipe> get results => _run(filters);

  List<Recipe> _run(RecipeFilters f) => RecipeQuery.apply(
        catalog.recipes,
        query: query,
        filters: f,
        sort: sort,
        excludeAllergenIds: _excluded,
        mealBudgetKcal: mealBudgetKcal,
      );

  /// Số món khớp với bộ lọc [f] (cho nút "Xem N món"), không đổi bộ lọc hiện tại.
  int countFor(RecipeFilters f) => _run(f).length;

  List<String> get categories {
    final present = {for (final r in catalog.recipes) r.category};
    final known = kCategoryLabels.keys.where(present.contains);
    final unknown = present.difference(kCategoryLabels.keys.toSet()).toList()
      ..sort();
    return [...known, ...unknown];
  }

  List<Recipe> get popular => RecipeQuery.apply(
        catalog.recipes,
        mealBudgetKcal: mealBudgetKcal,
      ).take(3).toList();
}
