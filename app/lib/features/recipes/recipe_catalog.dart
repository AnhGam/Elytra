import 'dart:async';

import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_repository.dart';
import 'package:flutter/widgets.dart';

enum CatalogStatus { idle, loading, ready, error }

/// Bộ nhớ đệm theo phiên cho danh sách món, hồ sơ dinh dưỡng và dị ứng.
class RecipeCatalog extends ChangeNotifier {
  RecipeCatalog({required this.repo, Stream<String?>? userIdChanges}) {
    _sub = userIdChanges?.listen((id) {
      // Lần đầu thấy user (trước đó null) không xóa: tránh hủy lượt tải đang chạy.
      if (id == null || (_lastUserId != null && id != _lastUserId)) clear();
      _lastUserId = id;
    });
  }

  final RecipeRepository repo;
  StreamSubscription<String?>? _sub;
  String? _lastUserId;

  CatalogStatus _status = CatalogStatus.idle;
  List<Recipe> _recipes = const [];
  UserNutritionProfile? _profile;
  List<Allergen> _allergens = const [];
  Set<int> _userAllergenIds = const {};
  Future<void>? _inFlight;
  int _generation = 0; // tăng mỗi lần clear để bỏ kết quả tải cũ
  int _allergenSaves = 0; // tăng mỗi lần lưu dị ứng xong, để lượt tải cũ không ghi đè
  bool _disposed = false;

  CatalogStatus get status => _status;
  List<Recipe> get recipes => _recipes;
  UserNutritionProfile? get profile => _profile;
  List<Allergen> get allergens => _allergens;
  Set<int> get userAllergenIds => _userAllergenIds;

  /// Chỉ tải khi `idle` hoặc `error`; gọi đồng thời chỉ tải một lần.
  Future<void> ensureLoaded() {
    final running = _inFlight;
    if (running != null) return running.catchError((Object _) {});
    if (_status != CatalogStatus.idle && _status != CatalogStatus.error) {
      return Future.value();
    }
    return refresh().catchError((Object _) {});
  }

  /// Tải lại cả 4 nguồn. Lỗi khi đã `ready` → giữ dữ liệu cũ và rethrow.
  Future<void> refresh() {
    final running = _inFlight;
    if (running != null) return running;
    late final Future<void> f;
    f = _load().whenComplete(() {
      if (identical(_inFlight, f)) _inFlight = null;
    });
    _inFlight = f;
    return f;
  }

  Future<void> _load() async {
    final gen = _generation;
    final saves = _allergenSaves;
    final hadData = _status == CatalogStatus.ready;
    if (!hadData) {
      _status = CatalogStatus.loading;
      _notify();
    }
    try {
      final results = await Future.wait<Object?>([
        repo.fetchAll(),
        repo.fetchProfile(),
        repo.fetchAllergens(),
        repo.fetchUserAllergenIds(),
      ]);
      if (gen != _generation) return;
      _recipes = results[0] as List<Recipe>;
      _profile = results[1] as UserNutritionProfile?;
      _allergens = results[2] as List<Allergen>;
      // Người dùng vừa lưu dị ứng sau khi lượt tải này bắt đầu → giữ giá trị vừa lưu
      if (saves == _allergenSaves) _userAllergenIds = results[3] as Set<int>;
      _status = CatalogStatus.ready;
      _notify();
    } catch (_) {
      if (gen != _generation) return;
      if (!hadData) {
        _status = CatalogStatus.error;
        _notify();
      }
      rethrow;
    }
  }

  /// Ghi dị ứng lên server rồi cập nhật bộ nhớ đệm.
  Future<void> saveAllergens(Set<int> ids) async {
    final gen = _generation;
    await repo.saveUserAllergenIds(ids);
    // Đã đăng xuất/đổi tài khoản trong lúc lưu → không ghi vào cache của user mới
    if (gen != _generation) return;
    _allergenSaves++;
    _userAllergenIds = Set.of(ids);
    _notify();
  }

  /// Về trạng thái ban đầu (đăng xuất / đổi user).
  void clear() {
    _generation++;
    _inFlight = null;
    _status = CatalogStatus.idle;
    _recipes = const [];
    _profile = null;
    _allergens = const [];
    _userAllergenIds = const {};
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}

/// Chia sẻ [RecipeCatalog] cho cây widget bên dưới.
class RecipeScope extends InheritedNotifier<RecipeCatalog> {
  const RecipeScope({super.key, required RecipeCatalog catalog, required super.child})
      : super(notifier: catalog);

  /// Như [of] nhưng trả null khi không có RecipeScope phía trên.
  static RecipeCatalog? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecipeScope>()?.notifier;

  static RecipeCatalog of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RecipeScope>();
    if (scope == null) {
      throw FlutterError('RecipeScope.of() được gọi khi không có RecipeScope phía trên.');
    }
    return scope.notifier!;
  }
}
