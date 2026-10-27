import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/features/recipes/ingredient_format.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeIngredient ing(String raw, String name, double? amount, String? unit, double g) =>
    RecipeIngredient(orderIndex: 0, rawText: raw, nameRaw: name, amount: amount, unit: unit, amountG: g);

void main() {
  test('formatAmount', () {
    expect(formatAmount(0.5), '½');
    expect(formatAmount(1.5), '1½');
    expect(formatAmount(2.25), '2,3');
    expect(formatAmount(1000), '1.000');
    expect(formatAmount(3), '3');
  });
  test('đơn vị đếm được có dòng gam, nhân hệ số', () {
    final l = formatIngredient(ing('Đậu hũ: 4 miếng (400g)', 'Đậu hũ', 4, 'miếng', 400), 0.5);
    expect([l.name, l.amountText, l.gramText, l.note], ['Đậu hũ', '2 miếng', '200 g', null]);
  });
  test('g/kg không có dòng gam', () {
    expect(formatIngredient(ing('Thịt xay: 200g', 'Thịt xay', 200, 'g', 200), 1.5).amountText, '300 g');
    final kg = formatIngredient(ing('1 kg cá nục, sơ chế sạch', 'cá nục', 1, 'kg', 1000), 2);
    expect([kg.name, kg.amountText, kg.gramText], ['Cá nục', '2 kg', null]);
  });
  test('muỗng: chuẩn hóa tên, không dòng gam, ½', () {
    expect(formatIngredient(ing('Hạt nêm: 1 muỗng cà phê', 'Hạt nêm', 1, 'muỗng cà', 30), 1.5).amountText, '1½ muỗng cà phê');
    final mc = formatIngredient(ing('1/2 muỗng canh hạt nêm', 'hạt nêm', 0.5, 'muỗng canh', 7.5), 1);
    expect([mc.amountText, mc.gramText], ['½ muỗng canh', null]);
    expect(formatIngredient(ing('x', 'Đường', 2, 'gram', 2), 1).amountText, '2 g');
  });
  test('phần / ít / amount null: ghi chú từ raw_text, không nhân', () {
    final p = formatIngredient(ing('Hành lá: để riêng phần gốc và phần lá, xắt nhỏ', 'Hành lá', 1, 'phần', 30), 3);
    expect([p.amountText, p.gramText, p.note], [null, null, 'để riêng phần gốc và phần lá, xắt nhỏ']);
    final y = formatIngredient(ing('3 lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 'lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 3, 'phần', 90), 2);
    expect([y.name, y.note], ['Lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', '3 lòng đỏ trứng gà (lòng trắng để riêng dùng sau)']);
    expect(formatIngredient(ing('Tiêu xay: 1 ít', 'Tiêu xay', 1, 'ít', 2), 2).note, '1 ít');
    expect(formatIngredient(ing('Ớt (lượng tùy thích)', 'Ớt (lượng tùy thích)', 1, 'ít', 2), 1).note, 'Tùy thích');
    expect(formatIngredient(ing('Muối:', 'Muối', null, null, 0), 1).note, 'Tùy thích');
  });
}
