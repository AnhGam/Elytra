import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/meal_time.dart';
import '../recipes/recipe.dart';
import '../recipes/recipe_catalog.dart';
import '../recipes/recipe_query.dart';
import 'diary_store.dart';
import 'food_search_repository.dart';
import 'meal_log_models.dart';
import 'meal_log_repository.dart';
import 'request_keys.dart';

enum FoodTab { recipes, dishes, ingredients }

enum SearchStatus { loading, ready, offline, failed }

/// Kết quả hiển thị của một tab.
class FoodTabState {
  const FoodTabState({
    required this.status,
    this.recipes = const [],
    this.hits = const [],
    this.hasMore = false,
    this.sectionLabel,
    this.loadMoreFailed = false,
  });

  final SearchStatus status;
  final List<Recipe> recipes;
  final List<FoodHit> hits;
  final bool hasMore;
  final String? sectionLabel;

  /// Lần tải trang tiếp theo gần nhất bị lỗi (hiện dòng "Thử lại" cuối danh sách).
  final bool loadMoreFailed;

  FoodTabState _withLoadMoreFailed(bool v) => FoodTabState(
    status: status,
    recipes: recipes,
    hits: hits,
    hasMore: hasMore,
    sectionLabel: sectionLabel,
    loadMoreFailed: v,
  );
}

/// Kết quả của một lần bấm "Thêm".
sealed class LogOutcome {
  const LogOutcome();
}

class LogAdded extends LogOutcome {
  const LogAdded(this.result);
  final AddResult result;
}

class LogOfflineOutcome extends LogOutcome {
  const LogOfflineOutcome();
}

class LogProfileMissingOutcome extends LogOutcome {
  const LogProfileMissingOutcome();
}

class LogFailedOutcome extends LogOutcome {
  const LogFailedOutcome();
}

/// Bấm lặp khi lần trước chưa xong: không gửi gì.
class LogIgnored extends LogOutcome {
  const LogIgnored();
}

const _labelSuggest = 'Gợi ý';
const _labelDishesAz = 'Món ăn sẵn (A–Z)';
const _labelIngredientsAz = 'Nguyên liệu (A–Z)';

/// Trạng thái màn Ghi bữa ăn: tìm kiếm 3 tab và gửi món.
class LogMealController extends ChangeNotifier {
  LogMealController({
    required this.store,
    required this.catalog,
    required this.search,
    required this._meal,
    required this.date,
    this.debounce = const Duration(milliseconds: 300),
    RequestKeys? keys,
  }) : keys = keys ?? RequestKeys() {
    catalog.addListener(_notify);
    // Hoãn một nhịp: controller thường được tạo trong lúc build, catalog báo
    // listener ngay khi bắt đầu tải sẽ gây lỗi markNeedsBuild during build.
    scheduleMicrotask(() {
      if (!_disposed) _ensureTab(_tab);
    });
  }

  final DiaryStore store;
  final RecipeCatalog catalog;
  final FoodSearchRepository search;
  final Duration debounce;
  final RequestKeys keys;

  MealType _meal;

  /// Ngày ghi món (`YYYY-MM-DD`).
  final String date;
  FoodTab _tab = FoodTab.recipes;
  String _query = ''; // đang gõ
  String _applied = ''; // đã qua debounce, dùng để tìm
  Timer? _debounceTimer;
  bool _sending = false;
  bool _disposed = false;

  // Số thứ tự request: đổi từ khoá / đổi tab / retry thì tăng, kết quả cũ bị bỏ.
  int _seq = 0;
  final Map<FoodTab, FoodTabState> _states = {};
  bool? _ingredientFeatured; // chế độ featured của các trang tiếp theo tab Nguyên liệu
  final Set<FoodTab> _loadingMore = {};

  MealType get meal => _meal;
  set meal(MealType m) {
    if (m == _meal) return;
    _meal = m;
    _notify();
  }

  FoodTab get tab => _tab;
  String get query => _query;
  bool get sending => _sending;

  void setTab(FoodTab t) {
    if (t == _tab) return;
    _tab = t;
    _invalidateInFlight();
    _ensureTab(t);
    _notify();
  }

  /// Từ khoá chỉ được áp dụng sau [debounce].
  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _applyQuery);
    _notify();
  }

  void _applyQuery() {
    if (_disposed || _query == _applied) return;
    _applied = _query;
    _seq++;
    _states.clear();
    _loadingMore.clear();
    _ensureTab(_tab);
    _notify();
  }

  FoodTabState stateOf(FoodTab t) {
    if (t == FoodTab.recipes) return _recipesState();
    return _states[t] ?? const FoodTabState(status: SearchStatus.loading);
  }

  FoodTabState _recipesState() {
    final empty = normalizeFoodQuery(_applied) == null;
    final status = switch (catalog.status) {
      CatalogStatus.ready => SearchStatus.ready,
      CatalogStatus.error => SearchStatus.failed,
      _ => SearchStatus.loading,
    };
    return FoodTabState(
      status: status,
      recipes: status != SearchStatus.ready
          ? const []
          : empty
          ? catalog.recipes
          : RecipeQuery.apply(catalog.recipes, query: _applied),
      sectionLabel: empty ? _labelSuggest : null,
    );
  }

  // Request đang chạy của tab cũ sẽ bị bỏ, nên tab đó phải tải lại khi mở.
  void _invalidateInFlight() {
    _seq++;
    _states.removeWhere((_, s) => s.status == SearchStatus.loading);
    _loadingMore.clear();
  }

  void _ensureTab(FoodTab t) {
    if (t == FoodTab.recipes) {
      unawaited(catalog.ensureLoaded());
    } else if (_states[t] == null) {
      unawaited(_loadFirst(t));
    }
  }

  Future<void> _loadFirst(FoodTab t) async {
    final seq = _seq;
    final q = _applied;
    final empty = normalizeFoodQuery(q) == null;
    _states[t] = const FoodTabState(status: SearchStatus.loading);
    _notify();
    try {
      List<FoodHit> hits;
      String? label;
      bool? featured; // chỉ ghi vào controller khi kết quả được nhận
      if (t == FoodTab.dishes) {
        hits = await search.searchDishes(q);
        label = empty ? _labelDishesAz : null;
      } else if (empty) {
        hits = await search.searchIngredients(q, featured: true);
        if (seq != _seq) return;
        featured = true;
        label = _labelSuggest;
        if (hits.isEmpty) {
          // Chưa có nguyên liệu gợi ý: chuyển sang danh sách A–Z
          hits = await search.searchIngredients(q);
          featured = null;
          label = _labelIngredientsAz;
        }
      } else {
        hits = await search.searchIngredients(q);
      }
      if (seq != _seq || _disposed) return;
      if (t == FoodTab.ingredients) _ingredientFeatured = featured;
      _states[t] = FoodTabState(
        status: SearchStatus.ready,
        hits: hits,
        hasMore: hits.length >= kFoodPageSize,
        sectionLabel: label,
      );
    } catch (e) {
      if (seq != _seq || _disposed) return;
      _states[t] = FoodTabState(
        status: mapFoodSearchError(e) is FoodSearchOffline
            ? SearchStatus.offline
            : SearchStatus.failed,
      );
    }
    _notify();
  }

  /// Tải trang tiếp theo của tab đang mở (Món ăn sẵn / Nguyên liệu).
  /// Lỗi thì giữ danh sách hiện có, lần cuộn sau thử lại.
  Future<void> loadMore() async {
    final t = _tab;
    final cur = _states[t];
    if (t == FoodTab.recipes ||
        cur == null ||
        cur.status != SearchStatus.ready ||
        !cur.hasMore ||
        _loadingMore.contains(t)) {
      return;
    }
    final seq = _seq;
    _loadingMore.add(t);
    if (cur.loadMoreFailed) {
      _states[t] = cur._withLoadMoreFailed(false);
      _notify();
    }
    try {
      final offset = cur.hits.length;
      final page = t == FoodTab.dishes
          ? await search.searchDishes(_applied, offset: offset)
          : await search.searchIngredients(
              _applied,
              featured: _ingredientFeatured,
              offset: offset,
            );
      if (seq != _seq || _disposed) return;
      _states[t] = FoodTabState(
        status: SearchStatus.ready,
        hits: [...cur.hits, ...page],
        hasMore: page.length >= kFoodPageSize,
        sectionLabel: cur.sectionLabel,
      );
      _notify();
    } catch (_) {
      // Giữ danh sách hiện có, chỉ bật cờ để UI hiện nút "Thử lại"
      if (seq == _seq && !_disposed) {
        _states[t] = cur._withLoadMoreFailed(true);
        _notify();
      }
    } finally {
      if (seq == _seq) _loadingMore.remove(t);
    }
  }

  /// Tải lại tab đang mở từ trang đầu.
  Future<void> retry() async {
    if (_tab == FoodTab.recipes) {
      // Lỗi catalog hiện qua catalog.status (→ SearchStatus.failed)
      await catalog.refresh().catchError((Object _) {});
      return;
    }
    _seq++;
    _loadingMore.clear();
    await _loadFirst(_tab);
  }

  /// Gửi món; khoá idempotency theo [RequestKeys].
  Future<LogOutcome> submit(LogRequest req) async {
    if (_sending) return const LogIgnored();
    _sending = true;
    _notify();
    try {
      final r = await store.add(req, clientRequestId: keys.keyFor(req));
      keys.succeeded();
      return LogAdded(r);
    } on MealLogOffline {
      keys.markNetworkError();
      return const LogOfflineOutcome();
    } on MealLogProfileMissing {
      return const LogProfileMissingOutcome();
    } catch (e) {
      // Khoá đã gắn với nội dung khác trên server: bỏ để lần bấm sau dùng khoá mới
      if (RequestKeys.isConflict(e)) keys.reset();
      return const LogFailedOutcome();
    } finally {
      _sending = false;
      _notify();
    }
  }

  /// Đóng sheet: sau lỗi mạng thì làm mới ngày, vì request đầu có thể đã tới server.
  /// Khoá vẫn giữ tới khi gửi thành công.
  Future<void> onSheetClosed() async {
    if (!keys.hadNetworkError) return;
    final f = store.refreshDay(date);
    keys.clearNetworkError();
    await f;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    // Rời màn sau lỗi mạng (chưa đóng sheet): làm mới ngày để món đã lên server hiện ra
    if (keys.hadNetworkError) {
      keys.clearNetworkError();
      // Hoãn một nhịp: dispose chạy lúc cây widget đang gỡ, store báo listener ngay
      // khi chuyển sang loading sẽ gây lỗi "framework is locked".
      final store = this.store, date = this.date;
      scheduleMicrotask(
        () => unawaited(store.refreshDay(date).catchError((Object _) {})),
      );
    }
    catalog.removeListener(_notify);
    super.dispose();
  }
}
