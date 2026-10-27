import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/recipe_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recipe_fixtures.dart';

void main() {
  group('matchTitle', () {
    test('không dấu khớp có dấu, theo đầu từ', () {
      expect(matchTitle('Cá basa kho tộ', 'ca kho'), MatchLevel.wholeWords);
      expect(matchTitle('Canh gà', 'ca'), MatchLevel.startsWith);
      expect(matchTitle('Phở bò tái', 'pho bo'), MatchLevel.startsWith);
      expect(matchTitle('Bún bò Huế', 'bo hue'), MatchLevel.wholeWords);
      expect(matchTitle('Cá basa kho tộ', 'kho ba'), MatchLevel.wordPrefix);
    });
    test('từ có dấu thì so có dấu, xét theo từng từ', () {
      expect(matchTitle('Canh gà', 'cá'), isNull);
      expect(matchTitle('Phở bò', 'phở bo'), MatchLevel.startsWith);
      expect(matchTitle('Đậu hũ nhồi thịt', 'dau'), MatchLevel.startsWith);
      expect(matchTitle('Đậu hũ nhồi thịt', 'đau'), isNull);
    });
    test('mọi từ phải khớp', () => expect(matchTitle('Phở bò', 'pho ga'), isNull));
    test('tên dạng NFD', () {
      expect(matchTitle('Pho\u031B\u0309 bo\u0300', 'pho bo'), MatchLevel.startsWith);
    });
    test('từ khóa có dấu với tên NFD', () {
      expect(matchTitle('Pho\u031B\u0309 bo\u0300', 'phở'), MatchLevel.startsWith);
    });
    test('từ khóa NFD với tên NFC', () {
      expect(matchTitle('Phở bò', 'pho\u031B\u0309 bo\u0300'), MatchLevel.startsWith);
    });
    test('không khớp giữa từ',
        () => expect(matchTitle('Rau muống xào', 'uong'), isNull));
    test('từ khóa không có từ nào coi như khớp', () {
      expect(matchTitle('Phở bò', ' , '), MatchLevel.wordPrefix);
    });
  });
  group('lọc', () {
    final a = recipe(id: 'a', title: 'Gà luộc', kcal: 500, prep: 10, cook: 20, difficulty: Difficulty.easy, category: 'mon_man', allergens: {2});
    final b = recipe(id: 'b', title: 'Cá kho', kcal: 500.4, prep: 15, cook: 16, difficulty: Difficulty.hard, category: 'mon_kho', allergens: {1});
    final c = recipe(id: 'c', title: 'Canh chua', kcal: 120, prep: 5, cook: 10, difficulty: Difficulty.medium, category: 'mon_canh');
    List<String> ids(List<Recipe> r) => r.map((e) => e.id).toList()..sort();
    test('từ khóa rỗng hoặc chỉ dấu câu → không lọc', () {
      expect(ids(RecipeQuery.apply([a, b, c], query: '  , . ')), ['a', 'b', 'c']);
    });
    test('không khớp qua slug', () {
      final s = recipe(id: 's', title: 'Bò lúc lắc', slug: 'cach-lam-ca-ngon');
      expect(RecipeQuery.apply([s], query: 'ca'), isEmpty);
    });
    test('calo biên đúng bằng min/max, một đầu, min = max', () {
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxKcal: 500))), ['a', 'c']);
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(minKcal: 500))), ['a', 'b']);
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(minKcal: 500, maxKcal: 500))), ['a']);
    });
    test('thời gian = prep + cook, biên tính là thỏa', () {
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxTotalMinutes: 30))), ['a', 'c']);
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(maxTotalMinutes: 15))), ['c']);
    });
    test('độ khó chọn nhiều, rỗng = mọi độ khó', () {
      expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(difficulties: {Difficulty.easy, Difficulty.hard}))), ['a', 'b']);
    });
    test('nhóm món', () => expect(ids(RecipeQuery.apply([a, b, c], filters: const RecipeFilters(category: 'mon_kho'))), ['b']));
    test('dị ứng', () => expect(ids(RecipeQuery.apply([a, b, c], excludeAllergenIds: {1, 9})), ['a', 'c']));
    test('danh sách rỗng', () => expect(RecipeQuery.apply(const []), isEmpty));
    test('sheetBadgeCount', () {
      expect(const RecipeFilters().sheetBadgeCount, 0);
      expect(const RecipeFilters(minKcal: 200, maxKcal: 500, maxTotalMinutes: 30, category: 'mon_kho').sheetBadgeCount, 2);
      expect(const RecipeFilters(difficulties: {Difficulty.easy}).sheetBadgeCount, 1);
    });
    test('copyWith xóa được giá trị về null', () {
      expect(const RecipeFilters(maxKcal: 500).copyWith(maxKcal: null).maxKcal, isNull);
    });
  });
}
