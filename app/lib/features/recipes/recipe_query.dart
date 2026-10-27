import 'recipe.dart';
import 'recipe_text.dart';

/// Mức khớp tên món với từ khóa; thứ tự = độ ưu tiên (startsWith tốt nhất).
enum MatchLevel { startsWith, wholeWords, wordPrefix }

// Từ khóa có dấu (kể cả đ) thì so với từ tên ở dạng có dấu, ngược lại so không dấu.
bool _eq(String qi, String tj) =>
    removeDiacritics(qi) != qi ? qi == tj : qi == removeDiacritics(tj);

bool _prefix(String qi, String tj) => removeDiacritics(qi) != qi
    ? tj.startsWith(qi)
    : removeDiacritics(tj).startsWith(qi);

/// So khớp tên món với từ khóa; null = không khớp. Không bao giờ dùng slug.
MatchLevel? matchTitle(String title, String query) {
  final q = wordsOf(query);
  if (q.isEmpty) return MatchLevel.wordPrefix;
  final t = wordsOf(title);

  // startsWith: các từ đầu bằng nhau theo vị trí, từ cuối là đầu của từ tương ứng.
  if (q.length <= t.length) {
    final last = q.length - 1;
    var ok = _prefix(q[last], t[last]);
    for (var i = 0; ok && i < last; i++) {
      ok = _eq(q[i], t[i]);
    }
    if (ok) return MatchLevel.startsWith;
  }
  if (q.every((qi) => t.any((tj) => _eq(qi, tj)))) return MatchLevel.wholeWords;
  if (q.every((qi) => t.any((tj) => _prefix(qi, tj)))) {
    return MatchLevel.wordPrefix;
  }
  return null;
}

const Object _unset = Object();

/// Bộ lọc trong bottom sheet.
class RecipeFilters {
  final double? minKcal;
  final double? maxKcal;
  final int? maxTotalMinutes;
  final Set<Difficulty> difficulties;
  final String? category;

  const RecipeFilters({
    this.minKcal,
    this.maxKcal,
    this.maxTotalMinutes,
    this.difficulties = const {},
    this.category,
  });

  RecipeFilters copyWith({
    Object? minKcal = _unset,
    Object? maxKcal = _unset,
    Object? maxTotalMinutes = _unset,
    Set<Difficulty>? difficulties,
    Object? category = _unset,
  }) {
    return RecipeFilters(
      minKcal: identical(minKcal, _unset) ? this.minKcal : minKcal as double?,
      maxKcal: identical(maxKcal, _unset) ? this.maxKcal : maxKcal as double?,
      maxTotalMinutes: identical(maxTotalMinutes, _unset)
          ? this.maxTotalMinutes
          : maxTotalMinutes as int?,
      difficulties: difficulties ?? this.difficulties,
      category: identical(category, _unset) ? this.category : category as String?,
    );
  }

  /// Số nhóm khác mặc định trong sheet: calo, thời gian, độ khó (0–3).
  int get sheetBadgeCount =>
      (minKcal != null || maxKcal != null ? 1 : 0) +
      (maxTotalMinutes != null ? 1 : 0) +
      (difficulties.isNotEmpty ? 1 : 0);
}

enum RecipeSort {
  bestMatch('Phù hợp nhất'),
  kcalAsc('Calo: thấp → cao'),
  kcalDesc('Calo: cao → thấp'),
  proteinPer100Desc('Protein / 100 kcal cao nhất'),
  carbsPer100Asc('Carbs / 100 kcal thấp nhất'),
  fatPer100Asc('Fat / 100 kcal thấp nhất'),
  quickest('Nấu nhanh nhất');

  final String labelVi;
  const RecipeSort(this.labelVi);
}

abstract final class RecipeQuery {
  /// Lọc theo từ khóa, bộ lọc, dị ứng. Tạm thời luôn sắp A–Z theo tên (Task 5 hoàn thiện).
  static List<Recipe> apply(
    List<Recipe> recipes, {
    String query = '',
    RecipeFilters filters = const RecipeFilters(),
    RecipeSort sort = RecipeSort.bestMatch,
    Set<int> excludeAllergenIds = const {},
    int? mealBudgetKcal,
  }) {
    final hasQuery = wordsOf(query).isNotEmpty;
    final out = recipes.where((r) {
      if (hasQuery && matchTitle(r.title, query) == null) return false;
      if (filters.minKcal != null && r.kcal < filters.minKcal!) return false;
      if (filters.maxKcal != null && r.kcal > filters.maxKcal!) return false;
      if (filters.maxTotalMinutes != null &&
          r.totalMinutes > filters.maxTotalMinutes!) {
        return false;
      }
      if (filters.difficulties.isNotEmpty &&
          !filters.difficulties.contains(r.difficulty)) {
        return false;
      }
      if (filters.category != null && r.category != filters.category) {
        return false;
      }
      if (r.allergenIds.any(excludeAllergenIds.contains) ||
          r.condimentAllergenIds.any(excludeAllergenIds.contains)) {
        return false;
      }
      return true;
    }).toList();
    out.sort((a, b) =>
        removeDiacritics(a.title).compareTo(removeDiacritics(b.title)));
    return out;
  }
}
