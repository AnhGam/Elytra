import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';

/// Món nhật ký giả; món nấu mặc định có `servings: 1`.
MealLogItem item({
  String id = 'i1',
  String name = 'Món',
  LogSource source = LogSource.recipe,
  double kcal = 100,
  double proteinG = 0,
  double carbsG = 0,
  double fatG = 0,
  double? servings,
  double? amountG,
  String? date,
}) =>
    MealLogItem(
      id: id,
      source: source,
      name: name,
      servings: servings ?? (source == LogSource.recipe ? 1 : null),
      amountG: amountG,
      macros: Macros(kcal: kcal, proteinG: proteinG, carbsG: carbsG, fatG: fatG),
      date: date,
    );

/// Nhật ký ngày giả; budget tính từ [items].
DayLog dayLog({
  String date = '2026-11-11',
  double target = 1968,
  List<(MealType, MealLogItem)> items = const [],
}) {
  final meals = {for (final m in MealType.values) m: MealLog.empty};
  var consumed = Macros.zero;
  for (final (m, i) in items) {
    final cur = meals[m]!;
    final list = [...cur.items, i];
    meals[m] = MealLog(kcal: list.fold(0.0, (s, e) => s + e.macros.kcal), items: list);
    consumed = consumed + i.macros;
  }
  final t = Macros(kcal: target);
  return DayLog(
    date: date,
    budget: Budget(target: t, consumed: consumed, remaining: t - consumed),
    meals: meals,
  );
}

/// Một ngày trong lịch sử; [items] null thì là `kcal > 0 ? 1 : 0`.
HistoryDay hday(String date, double kcal, {double target = 1968, int? items}) =>
    HistoryDay(
      date: date,
      kcal: kcal,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      itemCount: items ?? (kcal > 0 ? 1 : 0),
      targetKcal: target,
    );
