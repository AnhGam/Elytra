import 'dart:async';

import 'package:elytra/core/meal_time.dart';
import 'package:elytra/features/meal_logs/diary_store.dart';
import 'package:elytra/features/meal_logs/food_search_repository.dart';
import 'package:elytra/features/meal_logs/log_meal_controller.dart';
import 'package:elytra/features/meal_logs/meal_log_models.dart';
import 'package:elytra/features/meal_logs/meal_log_repository.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_food_search_repository.dart';
import '../helpers/fake_meal_log_repository.dart';
import '../helpers/fake_recipe_repository.dart';
import '../helpers/meal_log_fixtures.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
  late FakeMealLogRepository repo;
  late FakeRecipeRepository recipeRepo;
  late FakeFoodSearchRepository search;
  late DiaryStore store;
  late RecipeCatalog catalog;
  late LogMealController c;

  const req =
      LogRequest.recipe(refId: 'r1', servings: 1, meal: MealType.lunch, date: '2026-11-11');
  const reqOtherAmount =
      LogRequest.recipe(refId: 'r1', servings: 1.5, meal: MealType.lunch, date: '2026-11-11');

  setUp(() {
    repo = FakeMealLogRepository();
    recipeRepo = FakeRecipeRepository()
      ..recipes = [
        recipe(id: 'r1', title: 'Cá basa kho tộ'),
        recipe(id: 'r2', title: 'Phở gà'),
        recipe(id: 'r3', title: 'Canh chua'),
      ];
    search = FakeFoodSearchRepository();
    store = DiaryStore(
        repo: repo, now: () => DateTime.utc(2026, 11, 11, 12), scheduleMidnight: false);
    catalog = RecipeCatalog(repo: recipeRepo);
    c = LogMealController(
      store: store,
      catalog: catalog,
      search: search,
      meal: MealType.lunch,
      date: '2026-11-11',
      debounce: Duration.zero,
    );
  });
  tearDown(() {
    c.dispose();
    catalog.dispose();
    store.dispose();
  });

  group('submit', () {
    test('bấm Thêm 2 lần khi chưa xong chỉ 1 request', () async {
      repo.gate = Completer();
      final f1 = c.submit(req);
      expect(c.sending, isTrue);
      final f2 = await c.submit(req);
      expect(f2, isA<LogIgnored>());
      repo.gate!.complete();
      expect(await f1, isA<LogAdded>());
      expect(c.sending, isFalse);
      expect(repo.calls.where((x) => x.$1 == 'add'), hasLength(1));
    });

    test('lỗi mạng: retry y nguyên giữ khoá, đổi lượng thì khoá mới; đóng sheet thì refreshDay',
        () async {
      repo.failOnce['add'] = const MealLogOffline();
      expect(await c.submit(req), isA<LogOfflineOutcome>());
      repo.failOnce['add'] = const MealLogOffline();
      await c.submit(req);
      await c.submit(reqOtherAmount);
      final keys = repo.calls
          .where((x) => x.$1 == 'add')
          .map((x) => (x.$2 as (LogRequest, String)).$2)
          .toList();
      expect(keys[0], keys[1]);
      expect(keys[2], isNot(keys[1]));
      repo.calls.clear();
      repo.failOnce['add'] = const MealLogOffline();
      await c.submit(req);
      await c.onSheetClosed();
      expect(repo.calls.any((x) => x.$1 == 'getDay' && x.$2 == c.date), isTrue);
    });

    test('đóng sheet khi không có lỗi mạng thì không refreshDay', () async {
      await c.onSheetClosed();
      expect(repo.calls.where((x) => x.$1 == 'getDay'), isEmpty);
    });

    test('đóng sheet hai lần sau lỗi mạng chỉ refreshDay một lần', () async {
      repo.failOnce['add'] = const MealLogOffline();
      await c.submit(req);
      await c.onSheetClosed();
      await c.onSheetClosed();
      expect(repo.calls.where((x) => x.$1 == 'getDay'), hasLength(1));
    });

    test('lỗi mạng → đóng sheet → mở lại thêm y nguyên thì giữ khoá cũ', () async {
      repo.failOnce['add'] = const MealLogOffline();
      expect(await c.submit(req), isA<LogOfflineOutcome>());
      await c.onSheetClosed();
      expect(c.keys.hadNetworkError, isFalse);
      expect(await c.submit(req), isA<LogAdded>());
      final keys = repo.calls
          .where((x) => x.$1 == 'add')
          .map((x) => (x.$2 as (LogRequest, String)).$2)
          .toList();
      expect(keys, hasLength(2));
      expect(keys[1], keys[0]);
    });

    test('rời màn sau lỗi mạng thì refreshDay', () async {
      repo.failOnce['add'] = const MealLogOffline();
      await c.submit(req);
      repo.calls.clear();
      c.dispose();
      // Hoãn một nhịp: không báo listener của store trong lúc cây widget đang gỡ
      expect(repo.calls.where((x) => x.$1 == 'getDay'), isEmpty);
      await pumpEventQueue();
      expect(repo.calls.where((x) => x.$1 == 'getDay' && x.$2 == '2026-11-11'), hasLength(1));
      // tearDown cần một controller chưa dispose
      c = LogMealController(
          store: store, catalog: catalog, search: search, meal: MealType.lunch, date: '2026-11-11');
    });

    test('rời màn khi đã đóng sheet (đã làm mới) thì không refreshDay lần nữa', () async {
      repo.failOnce['add'] = const MealLogOffline();
      await c.submit(req);
      await c.onSheetClosed();
      repo.calls.clear();
      c.dispose();
      expect(repo.calls.where((x) => x.$1 == 'getDay'), isEmpty);
      c = LogMealController(
          store: store, catalog: catalog, search: search, meal: MealType.lunch, date: '2026-11-11');
    });

    test('IDEMPOTENCY_CONFLICT → LogFailedOutcome', () async {
      repo.failOnce['add'] = const MealLogFailed('IDEMPOTENCY_CONFLICT');
      expect(await c.submit(req), isA<LogFailedOutcome>());
    });

    test('IDEMPOTENCY_CONFLICT rồi bấm lại y nguyên thì gửi khoá mới', () async {
      repo.failOnce['add'] = const MealLogFailed('IDEMPOTENCY_CONFLICT');
      await c.submit(req);
      expect(await c.submit(req), isA<LogAdded>());
      final keys = [
        for (final x in repo.calls)
          if (x.$1 == 'add') (x.$2 as (LogRequest, String)).$2,
      ];
      expect(keys, hasLength(2));
      expect(keys[1], isNot(keys[0]));
    });

    test('lỗi khác (không phải conflict) vẫn giữ khoá', () async {
      repo.failOnce['add'] = const MealLogFailed('X');
      await c.submit(req);
      await c.submit(req);
      final keys = [
        for (final x in repo.calls)
          if (x.$1 == 'add') (x.$2 as (LogRequest, String)).$2,
      ];
      expect(keys[1], keys[0]);
    });

    test('PROFILE_NOT_FOUND → LogProfileMissingOutcome', () async {
      repo.failOnce['add'] = const MealLogProfileMissing();
      expect(await c.submit(req), isA<LogProfileMissingOutcome>());
    });
  });

  group('tìm kiếm', () {
    test('Nguyên liệu: gợi ý rỗng thì chuyển A–Z', () async {
      search.ingredients = [hit('Cà rốt'), hit('Bắp cải')];
      search.featuredIds = {};
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      final st = c.stateOf(FoodTab.ingredients);
      expect(st.status, SearchStatus.ready);
      expect(st.sectionLabel, 'Nguyên liệu (A–Z)');
      expect(st.hits.map((h) => h.name), ['Bắp cải', 'Cà rốt']);
      expect(search.calls.map((x) => x.$3), [true, null]);
    });

    test('Nguyên liệu: có gợi ý thì nhãn Gợi ý; có từ khoá thì featured null', () async {
      search.ingredients = [hit('Cà rốt'), hit('Bắp cải')];
      search.featuredIds = {'Cà rốt'};
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.ingredients).sectionLabel, 'Gợi ý');
      expect(c.stateOf(FoodTab.ingredients).hits.map((h) => h.name), ['Cà rốt']);
      c.setQuery('bap');
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.ingredients).sectionLabel, isNull);
      expect(c.stateOf(FoodTab.ingredients).hits.map((h) => h.name), ['Bắp cải']);
      expect(search.calls.map((x) => x.$3), [true, null]);
    });

    test('Nguyên liệu A–Z: trang sau cũng dùng featured null', () async {
      search.ingredients = [for (var i = 0; i < 25; i++) hit('NL ${i.toString().padLeft(2, '0')}')];
      search.featuredIds = {};
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.ingredients).hasMore, isTrue);
      await c.loadMore();
      expect(c.stateOf(FoodTab.ingredients).hits, hasLength(25));
      expect(c.stateOf(FoodTab.ingredients).hasMore, isFalse);
      expect(search.calls.map((x) => (x.$3, x.$4)), [(true, 0), (null, 0), (null, 20)]);
    });

    test('loadMore lỗi thì bật loadMoreFailed, giữ danh sách; thử lại thành công thì tắt',
        () async {
      search.dishes = [for (var i = 0; i < 25; i++) hit('Món ${i.toString().padLeft(2, '0')}')];
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      search.failWith = const FoodSearchOffline();
      await c.loadMore();
      var st = c.stateOf(FoodTab.dishes);
      expect(st.loadMoreFailed, isTrue);
      expect(st.hits, hasLength(20));
      expect(st.hasMore, isTrue);
      search.failWith = null;
      await c.loadMore();
      st = c.stateOf(FoodTab.dishes);
      expect(st.loadMoreFailed, isFalse);
      expect(st.hits, hasLength(25));
    });

    test('Món ăn sẵn: nhãn A–Z, phân trang 20, gõ không dấu', () async {
      search.dishes = [
        for (var i = 0; i < 25; i++) hit('Món ${i.toString().padLeft(2, '0')}'),
        hit('Phở bò'),
      ];
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.dishes).sectionLabel, 'Món ăn sẵn (A–Z)');
      expect(c.stateOf(FoodTab.dishes).hits, hasLength(20));
      expect(c.stateOf(FoodTab.dishes).hasMore, isTrue);
      c.setQuery('pho');
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
      expect(c.stateOf(FoodTab.dishes).sectionLabel, isNull);
      expect(c.stateOf(FoodTab.dishes).hasMore, isFalse);
    });

    test('debounce: gõ liên tiếp chỉ gọi một lần với từ khoá cuối', () async {
      c.dispose();
      c = LogMealController(
        store: store,
        catalog: catalog,
        search: search,
        meal: MealType.lunch,
        date: '2026-11-11',
        debounce: const Duration(milliseconds: 20),
      );
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      search.calls.clear();
      c.setQuery('p');
      c.setQuery('ph');
      c.setQuery('pho');
      expect(c.query, 'pho');
      expect(search.calls, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await pumpEventQueue();
      expect(search.calls.map((x) => x.$2), ['pho']);
    });

    test('chỉ tab đang mở gọi tìm kiếm; đổi từ khoá thì tab khác tải lại khi mở', () async {
      search.dishes = [hit('Phở bò'), hit('Bún chả')];
      search.ingredients = [hit('Phở khô', kind: FoodKind.ingredient)];
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      expect(search.calls.map((x) => x.$1), ['search_dishes', 'search_ingredients', 'search_ingredients']);
      search.calls.clear();
      c.setQuery('pho');
      await pumpEventQueue();
      expect(search.calls.map((x) => x.$1), ['search_ingredients']);
      expect(c.stateOf(FoodTab.dishes).hits, isEmpty);
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
      // Quay lại tab đã có kết quả cho từ khoá hiện tại thì không gọi lại
      search.calls.clear();
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      expect(search.calls, isEmpty);
    });

    test('kết quả cũ về muộn bị bỏ', () async {
      search.dishes = [hit('Bún chả'), hit('Phở bò')];
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      final bunGate = Completer<void>();
      search.gate = bunGate;
      c.setQuery('bun');
      await pumpEventQueue(); // request 'bun' đang chờ bunGate
      search.gate = null;
      c.setQuery('pho');
      await pumpEventQueue(); // request 'pho' xong trước
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
      bunGate.complete(); // request 'bun' xong sau cùng
      await pumpEventQueue();
      expect(search.calls.map((x) => x.$2), [null, 'bun', 'pho']);
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
    });

    test('kết quả cũ của tab Nguyên liệu không đổi chế độ featured của trang sau', () async {
      search.ingredients = [
        for (var i = 0; i < 25; i++)
          hit('Cà ${i.toString().padLeft(2, '0')}', kind: FoodKind.ingredient),
      ];
      search.featuredIds = {for (final h in search.ingredients) h.id};
      c.setTab(FoodTab.ingredients);
      await pumpEventQueue();
      final caGate = Completer<void>();
      search.gate = caGate;
      c.setQuery('ca');
      await pumpEventQueue(); // request 'ca' (featured null) đang chờ
      search.gate = null;
      c.setQuery('');
      await pumpEventQueue(); // trang gợi ý (featured true) về trước
      caGate.complete(); // 'ca' về muộn, phải bị bỏ
      await pumpEventQueue();
      final st = c.stateOf(FoodTab.ingredients);
      expect(st.sectionLabel, 'Gợi ý');
      expect(st.hasMore, isTrue);
      search.calls.clear();
      await c.loadMore();
      expect(search.calls.map((x) => (x.$3, x.$4)), [(true, 20)]);
    });

    test('trang loadMore về sau khi đổi từ khoá thì bị bỏ', () async {
      search.dishes = [for (var i = 0; i < 25; i++) hit('Món ${i.toString().padLeft(2, '0')}')];
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      final g = Completer<void>();
      search.gate = g;
      final more = c.loadMore();
      await pumpEventQueue();
      search.gate = null;
      c.setQuery('mon 2');
      await pumpEventQueue();
      g.complete();
      await more;
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name),
          ['Món 20', 'Món 21', 'Món 22', 'Món 23', 'Món 24']);
    });

    test('mất mạng thì offline; retry tải lại', () async {
      search.dishes = [hit('Phở bò')];
      search.failWith = const FoodSearchOffline();
      c.setTab(FoodTab.dishes);
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.dishes).status, SearchStatus.offline);
      search.failWith = const FoodSearchFailed();
      await c.retry();
      expect(c.stateOf(FoodTab.dishes).status, SearchStatus.failed);
      search.failWith = null;
      await c.retry();
      expect(c.stateOf(FoodTab.dishes).status, SearchStatus.ready);
      expect(c.stateOf(FoodTab.dishes).hits.map((h) => h.name), ['Phở bò']);
    });

    test('Món nấu: từ khoá rỗng là Gợi ý theo thứ tự catalog', () async {
      expect(c.stateOf(FoodTab.recipes).sectionLabel, 'Gợi ý');
      await pumpEventQueue();
      final st = c.stateOf(FoodTab.recipes);
      expect(st.status, SearchStatus.ready);
      expect(st.recipes.map((r) => r.id), ['r1', 'r2', 'r3']);
      expect(st.hasMore, isFalse);
      c.setQuery('pho');
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.recipes).sectionLabel, isNull);
      expect(c.stateOf(FoodTab.recipes).recipes.map((r) => r.id), ['r2']);
      expect(search.calls, isEmpty);
    });

    test('Món nấu: catalog lỗi thì failed', () async {
      c.dispose();
      catalog.dispose();
      recipeRepo.failCatalogWith = Exception('x');
      catalog = RecipeCatalog(repo: recipeRepo);
      c = LogMealController(
        store: store,
        catalog: catalog,
        search: search,
        meal: MealType.lunch,
        date: '2026-11-11',
        debounce: Duration.zero,
      );
      await pumpEventQueue();
      expect(c.stateOf(FoodTab.recipes).status, SearchStatus.failed);
    });

    test('đổi bữa thì báo listener', () {
      var n = 0;
      c.addListener(() => n++);
      c.meal = MealType.dinner;
      expect(c.meal, MealType.dinner);
      expect(n, 1);
    });
  });
}
