import 'dart:async';

import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_recipe_repository.dart';
import '../helpers/recipe_fixtures.dart';

void main() {
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
}
