import 'dart:async';

import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
  test('lưu dị ứng trong lúc refresh đang chạy → refresh không ghi đè', () async {
    final repo = FakeRecipeRepository()..recipes = [recipe()];
    final c = RecipeCatalog(repo: repo);
    await c.ensureLoaded();
    repo.userAllergenGate = Completer<void>();
    final refreshing = c.refresh(); // đọc dị ứng lúc server còn {}
    await Future<void>.delayed(Duration.zero);
    await c.saveAllergens({2});
    expect(c.userAllergenIds, {2});
    repo.userAllergenGate!.complete();
    await refreshing;
    expect(c.userAllergenIds, {2});
  });
  test('đổi user trong lúc đang lưu dị ứng → không ghi vào cache của user mới', () async {
    final users = StreamController<String?>();
    final repo = FakeRecipeRepository()..recipes = [recipe()];
    final c = RecipeCatalog(repo: repo, userIdChanges: users.stream);
    users.add('u1');
    await c.ensureLoaded();
    repo.saveGate = Completer<void>();
    final saving = c.saveAllergens({2});
    users.add('u2'); // đổi tài khoản → clear()
    await Future<void>.delayed(Duration.zero);
    repo.saveGate!.complete();
    await saving;
    expect(c.userAllergenIds, isEmpty);
    await users.close();
  });
  test('ensureLoaded tải một lần dù gọi song song', () async {
    final repo = FakeRecipeRepository()..recipes = [recipe()];
    final c = RecipeCatalog(repo: repo);
    await Future.wait([c.ensureLoaded(), c.ensureLoaded()]);
    expect(repo.fetchAllCalls, 1);
    expect(c.status, CatalogStatus.ready);
  });
  test('refresh lỗi khi đã có dữ liệu → giữ dữ liệu, rethrow', () async {
    final repo = FakeRecipeRepository()..recipes = [recipe()];
    final c = RecipeCatalog(repo: repo);
    await c.ensureLoaded();
    repo.failWith = Exception('mạng');
    await expectLater(c.refresh(), throwsException);
    expect(c.status, CatalogStatus.ready);
    expect(c.recipes, hasLength(1));
  });
  test('lỗi lần đầu → error, ensureLoaded lại được', () async {
    final repo = FakeRecipeRepository()..failWith = Exception('mạng');
    final c = RecipeCatalog(repo: repo);
    await c.ensureLoaded();
    expect(c.status, CatalogStatus.error);
    repo.failWith = null;
    await c.ensureLoaded();
    expect(c.status, CatalogStatus.ready);
  });
  test('refresh tải lại cả dị ứng và hồ sơ', () async {
    final repo = FakeRecipeRepository();
    final c = RecipeCatalog(repo: repo);
    await c.ensureLoaded();
    repo
      ..userAllergenIds = {1}
      ..profile = const UserNutritionProfile(targetKcal: 1968);
    await c.refresh();
    expect(c.userAllergenIds, {1});
    expect(c.profile?.targetKcal, 1968);
  });
  test('saveAllergens ghi repo và cập nhật', () async {
    final repo = FakeRecipeRepository();
    final c = RecipeCatalog(repo: repo);
    await c.saveAllergens({4, 1});
    expect(repo.userAllergenIds, {1, 4});
    expect(c.userAllergenIds, {1, 4});
  });
  test('đăng xuất hoặc đổi user → clear', () async {
    final users = StreamController<String?>();
    final c = RecipeCatalog(
        repo: FakeRecipeRepository()..userAllergenIds = {1},
        userIdChanges: users.stream);
    users.add('u1');
    await c.ensureLoaded();
    users.add('u1');
    await pumpEventQueue();
    expect(c.status, CatalogStatus.ready);
    users.add('u2');
    await pumpEventQueue();
    expect(c.status, CatalogStatus.idle);
    expect(c.userAllergenIds, isEmpty);
    c.dispose();
  });

  test('ensureLoaded song song khi lỗi lần đầu không ném', () async {
    final repo = FakeRecipeRepository()..failWith = Exception('mạng');
    final c = RecipeCatalog(repo: repo);
    await Future.wait([c.ensureLoaded(), c.ensureLoaded()]);
    expect(c.status, CatalogStatus.error);
  });
  test('ensureLoaded khi refresh lỗi đang chạy không ném, refresh vẫn ném', () async {
    final repo = FakeRecipeRepository()..recipes = [recipe()];
    final c = RecipeCatalog(repo: repo);
    await c.ensureLoaded();
    repo.failWith = Exception('mạng');
    final r = c.refresh();
    final e = c.ensureLoaded();
    await e;
    await expectLater(r, throwsException);
  });
  testWidgets('RecipeScope.maybeOf: có scope → catalog, không có → null', (t) async {
    final c = RecipeCatalog(repo: FakeRecipeRepository());
    RecipeCatalog? found, missing;
    await t.pumpWidget(RecipeScope(
      catalog: c,
      child: Builder(builder: (context) {
        found = RecipeScope.maybeOf(context);
        return const SizedBox();
      }),
    ));
    await t.pumpWidget(Builder(builder: (context) {
      missing = RecipeScope.maybeOf(context);
      return const SizedBox();
    }));
    expect(found, same(c));
    expect(missing, isNull);
  });
}
