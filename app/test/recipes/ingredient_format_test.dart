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
  test('đơn vị: muỗng cafe và không phân biệt hoa thường', () {
    final c = formatIngredient(ing('x', 'Đường', 2, 'muỗng cafe', 10), 1);
    expect([c.amountText, c.gramText], ['2 muỗng cà phê', null]);
    expect(formatIngredient(ing('x', 'Đường', 2, 'Gram', 2), 1).amountText, '2 g');
    expect(formatIngredient(ing('x', 'Hạt nêm', 1, 'Muỗng cà', 5), 1).amountText, '1 muỗng cà phê');
    final cu = formatIngredient(ing('x', 'Hành', 1, ' Củ ', 60), 1);
    expect([cu.amountText, cu.gramText], ['1 củ', '60 g']);
    final ph = formatIngredient(ing('Hành lá: xắt nhỏ', 'Hành lá', 1, 'PHẦN', 30), 3);
    expect([ph.amountText, ph.gramText, ph.note], [null, null, 'xắt nhỏ']);
  });

  test('g/kg/ml/lít: số lẻ hiện thập phân VN, không dùng ½', () {
    expect(formatIngredient(ing('Hành tím: 10g', 'Hành tím', 10, 'g', 10), 1.25).amountText, '12,5 g');
    expect(formatIngredient(ing('Cá: 1 kg', 'Cá', 1, 'kg', 1000), 0.5).amountText, '0,5 kg');
    expect(formatIngredient(ing('Nước: 5 ml', 'Nước', 5, 'ml', 5), 0.5).amountText, '2,5 ml');
    expect(formatIngredient(ing('Nước: 1 lít', 'Nước', 1, 'lít', 1000), 1.5).amountText, '1,5 lít');
    // Đơn vị đếm và muỗng vẫn dùng ½
    expect(formatIngredient(ing('Hành tây: 1 củ', 'Hành tây', 1, 'củ', 60), 1.5).amountText, '1½ củ');
    expect(formatIngredient(ing('Đường: 1 muỗng canh', 'Đường', 1, 'muỗng canh', 12), 0.5).amountText,
        '½ muỗng canh');
  });

  test('dòng gam mờ làm tròn số nguyên', () {
    final l = formatIngredient(ing('Tỏi: 3 tép', 'Tỏi', 3, 'tép', 15), 1.25);
    expect([l.amountText, l.gramText], ['3,8 tép', '19 g']);
  });
  test('đơn vị rỗng không để khoảng trắng thừa; tên được cắt khoảng trắng', () {
    final l = formatIngredient(ing('Trứng: 2', '  trứng gà ', 2, '  ', 100), 1);
    expect([l.name, l.amountText], ['Trứng gà', '2']);
  });
}
