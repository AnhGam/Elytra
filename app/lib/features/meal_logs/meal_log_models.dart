import '../../core/meal_time.dart';

// Đọc số khoan dung: num -> double, chuỗi số -> double, còn lại -> 0.
// NaN / Infinity (kể cả chuỗi "NaN") cũng là 0, để `.toInt()` không ném.
double _num(Object? v) => _numOrNull(v) ?? 0;

// Như _num nhưng giữ null khi thiếu/hỏng/không hữu hạn (cột nullable).
double? _numOrNull(Object? v) {
  final d = v is num
      ? v.toDouble()
      : v is String
          ? double.tryParse(v.trim())
          : null;
  return d != null && d.isFinite ? d : null;
}

String? _str(Object? v) => v is String ? v : null;

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

/// Bốn chỉ số dinh dưỡng chính.
class Macros {
  const Macros({this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});

  static const zero = Macros();

  factory Macros.fromJson(Object? j) {
    final m = _map(j);
    return Macros(
      kcal: _num(m['kcal']),
      proteinG: _num(m['protein_g']),
      carbsG: _num(m['carbs_g']),
      fatG: _num(m['fat_g']),
    );
  }

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Macros operator +(Macros o) => Macros(
        kcal: kcal + o.kcal,
        proteinG: proteinG + o.proteinG,
        carbsG: carbsG + o.carbsG,
        fatG: fatG + o.fatG,
      );

  Macros operator -(Macros o) => Macros(
        kcal: kcal - o.kcal,
        proteinG: proteinG - o.proteinG,
        carbsG: carbsG - o.carbsG,
        fatG: fatG - o.fatG,
      );

  Macros scale(double k) => Macros(
        kcal: kcal * k,
        proteinG: proteinG * k,
        carbsG: carbsG * k,
        fatG: fatG * k,
      );
}

/// Mục tiêu / đã nạp / còn lại của một ngày (còn lại có thể âm).
class Budget {
  const Budget({required this.target, required this.consumed, required this.remaining});

  factory Budget.fromJson(Object? j) {
    final m = _map(j);
    final target = Macros.fromJson(m['target']);
    final consumed = Macros.fromJson(m['consumed']);
    final remaining =
        m['remaining'] is Map ? Macros.fromJson(m['remaining']) : target - consumed;
    return Budget(target: target, consumed: consumed, remaining: remaining);
  }

  final Macros target;
  final Macros consumed;
  final Macros remaining;

  /// Tính lại `remaining` theo lượng đã nạp mới.
  Budget withConsumed(Macros c) =>
      Budget(target: target, consumed: c, remaining: target - c);
}

enum LogSource { recipe, dish, ingredient }

LogSource _source(Object? v, bool hasAmount) => switch (v) {
      'recipe' => LogSource.recipe,
      'dish' => LogSource.dish,
      'ingredient' => LogSource.ingredient,
      _ => hasAmount ? LogSource.ingredient : LogSource.recipe,
    };

MealType? _mealType(Object? v) {
  for (final m in MealType.values) {
    if (m.apiValue == v) return m;
  }
  return null;
}

/// Một món đã ghi trong nhật ký (số liệu là snapshot lúc ghi).
class MealLogItem {
  const MealLogItem({
    required this.id,
    required this.source,
    this.recipeId,
    this.dishId,
    this.ingredientId,
    required this.name,
    this.imageUrl,
    this.servings,
    this.amountG,
    required this.macros,
    this.createdAt,
    this.mealType,
    this.date,
  });

  factory MealLogItem.fromJson(Map<String, dynamic> j) {
    final amount = _numOrNull(j['amount_g']);
    return MealLogItem(
      id: _str(j['id']) ?? '',
      source: _source(j['source'], amount != null),
      recipeId: _str(j['recipe_id']),
      dishId: _str(j['dish_id']),
      ingredientId: _str(j['ingredient_id']),
      name: _str(j['name']) ?? '',
      imageUrl: _str(j['image_url']),
      servings: _numOrNull(j['servings']),
      amountG: amount,
      macros: Macros.fromJson(j),
      createdAt: DateTime.tryParse(_str(j['created_at']) ?? ''),
      mealType: _mealType(j['meal_type']),
      date: _str(j['date']),
    );
  }

  final String id;
  final LogSource source;
  final String? recipeId;
  final String? dishId;
  final String? ingredientId;
  final String name;
  final String? imageUrl;
  final double? servings;
  final double? amountG;
  final Macros macros;
  final DateTime? createdAt;
  final MealType? mealType;
  final String? date;

  /// Món nấu tính theo khẩu phần; còn lại tính theo gam.
  bool get byServings => source == LogSource.recipe;

  MealLogItem copyWith({double? servings, double? amountG, Macros? macros}) =>
      MealLogItem(
        id: id,
        source: source,
        recipeId: recipeId,
        dishId: dishId,
        ingredientId: ingredientId,
        name: name,
        imageUrl: imageUrl,
        servings: servings ?? this.servings,
        amountG: amountG ?? this.amountG,
        macros: macros ?? this.macros,
        createdAt: createdAt,
        mealType: mealType,
        date: date,
      );
}

/// Một bữa: tổng kcal và danh sách món.
class MealLog {
  const MealLog({required this.kcal, required this.items});

  static const empty = MealLog(kcal: 0, items: []);

  final double kcal;
  final List<MealLogItem> items;
}

double _sumKcal(List<MealLogItem> items) =>
    items.fold(0.0, (s, i) => s + i.macros.kcal);

/// Nhật ký một ngày; `meals` luôn đủ 4 bữa.
class DayLog {
  const DayLog({required this.date, required this.budget, required this.meals});

  factory DayLog.fromJson(Map<String, dynamic> j) {
    final raw = _map(j['meals']);
    final meals = <MealType, MealLog>{};
    for (final m in MealType.values) {
      final mj = _map(raw[m.apiValue]);
      final items = mj['items'] is List
          ? [
              for (final e in mj['items'] as List)
                if (e is Map) MealLogItem.fromJson(Map<String, dynamic>.from(e)),
            ]
          : <MealLogItem>[];
      meals[m] = MealLog(kcal: _num(mj['kcal']), items: items);
    }
    return DayLog(
      date: _str(j['date']) ?? '',
      budget: Budget.fromJson(j['budget']),
      meals: meals,
    );
  }

  final String date;
  final Budget budget;
  final Map<MealType, MealLog> meals;

  /// Thay món cùng `id` (giữ vị trí) hoặc thêm vào cuối bữa; budget lấy theo tham số.
  DayLog upsert(MealLogItem item, MealType meal, Budget budget) {
    final cur = meals[meal] ?? MealLog.empty;
    final idx = cur.items.indexWhere((i) => i.id == item.id);
    final items = [...cur.items];
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
    return DayLog(
      date: date,
      budget: budget,
      meals: {...meals, meal: MealLog(kcal: _sumKcal(items), items: items)},
    );
  }

  /// Bỏ món theo `id`, cộng lại kcal bữa và tính lại budget.
  DayLog without(String itemId) {
    final removed = find(itemId);
    if (removed == null) return this;
    final next = <MealType, MealLog>{};
    meals.forEach((m, log) {
      if (log.items.any((i) => i.id == itemId)) {
        final items = log.items.where((i) => i.id != itemId).toList();
        next[m] = MealLog(kcal: _sumKcal(items), items: items);
      } else {
        next[m] = log;
      }
    });
    return DayLog(
      date: date,
      budget: budget.withConsumed(budget.consumed - removed.macros),
      meals: next,
    );
  }

  MealLogItem? find(String itemId) {
    for (final log in meals.values) {
      for (final i in log.items) {
        if (i.id == itemId) return i;
      }
    }
    return null;
  }

  MealType? mealOf(String itemId) {
    for (final e in meals.entries) {
      if (e.value.items.any((i) => i.id == itemId)) return e.key;
    }
    return null;
  }

  bool get isEmpty => meals.values.every((m) => m.items.isEmpty);
}

/// Tổng một ngày trong lịch sử.
class HistoryDay {
  const HistoryDay({
    required this.date,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.itemCount,
    required this.targetKcal,
  });

  factory HistoryDay.fromJson(Map<String, dynamic> j) => HistoryDay(
        date: _str(j['date']) ?? '',
        kcal: _num(j['kcal']),
        proteinG: _num(j['protein_g']),
        carbsG: _num(j['carbs_g']),
        fatG: _num(j['fat_g']),
        itemCount: _num(j['item_count']).toInt(),
        targetKcal: _num(j['target_kcal']),
      );

  final String date;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int itemCount;
  final double targetKcal;

  HistoryDay copyWith({
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    int? itemCount,
  }) =>
      HistoryDay(
        date: date,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        itemCount: itemCount ?? this.itemCount,
        targetKcal: targetKcal,
      );
}

/// Lịch sử nhiều ngày cho biểu đồ.
class History {
  const History({
    required this.from,
    required this.to,
    required this.targetKcal,
    required this.days,
  });

  factory History.fromJson(Map<String, dynamic> j) => History(
        from: _str(j['from']) ?? '',
        to: _str(j['to']) ?? '',
        targetKcal: _num(j['target_kcal']),
        days: j['days'] is List
            ? [
                for (final e in j['days'] as List)
                  if (e is Map) HistoryDay.fromJson(Map<String, dynamic>.from(e)),
              ]
            : const [],
      );

  final String from;
  final String to;
  final double targetKcal;
  final List<HistoryDay> days;
}

enum FoodKind { dish, ingredient }

/// Kết quả tìm món ăn sẵn / nguyên liệu, dinh dưỡng trên 100 g.
class FoodHit {
  const FoodHit({
    required this.id,
    required this.kind,
    required this.name,
    required this.per100,
  });

  factory FoodHit.fromRow(Map<String, dynamic> r, FoodKind kind) => FoodHit(
        id: _str(r['id']) ?? '',
        kind: kind,
        name: _str(r['name_vi']) ?? '',
        per100: Macros(
          kcal: _num(r['calories_per_100g']),
          proteinG: _num(r['protein_per_100g']),
          carbsG: _num(r['carbs_per_100g']),
          fatG: _num(r['fat_per_100g']),
        ),
      );

  final String id;
  final FoodKind kind;
  final String name;
  final Macros per100;
}

/// Yêu cầu ghi một món; so sánh theo nội dung.
class LogRequest {
  const LogRequest.recipe({
    required this.refId,
    this.servings = 1,
    required this.meal,
    required this.date,
  })  : source = LogSource.recipe,
        amountG = null;

  const LogRequest.dish({
    required this.refId,
    required int this.amountG,
    required this.meal,
    required this.date,
  })  : source = LogSource.dish,
        servings = null;

  const LogRequest.ingredient({
    required this.refId,
    required int this.amountG,
    required this.meal,
    required this.date,
  })  : source = LogSource.ingredient,
        servings = null;

  final LogSource source;
  final String refId;
  final double? servings;
  final int? amountG;
  final MealType meal;
  final String date;

  Map<String, Object> toBody(String clientRequestId) => {
        'meal_type': meal.apiValue,
        switch (source) {
          LogSource.recipe => 'recipe_id',
          LogSource.dish => 'dish_id',
          LogSource.ingredient => 'ingredient_id',
        }: refId,
        'servings': ?servings,
        'amount_g': ?amountG,
        'date': date,
        'client_request_id': clientRequestId,
      };

  @override
  bool operator ==(Object other) =>
      other is LogRequest &&
      other.source == source &&
      other.refId == refId &&
      other.servings == servings &&
      other.amountG == amountG &&
      other.meal == meal &&
      other.date == date;

  @override
  int get hashCode => Object.hash(source, refId, servings, amountG, meal, date);
}
