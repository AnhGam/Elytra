// Kiểm từ điển map nguyên liệu (các ca từng sai trong AUDIT_REPORT V1). Chạy: node test_ingredient_parser.js
const assert = require('assert/strict');
const { lookupIngredient, keywordAllergenCodes } = require('./ingredient_parser');

const name = (raw) => lookupIngredient(raw)?.name_vi ?? null;
const cases = [
  ['gà (cắt miếng vừa ăn', 'Thịt gà ta'], ['nước dừa tươi', 'Nước dừa non tươi'], ['mè rang', 'Vừng(đen, trắng)'],
  ['đậu phộng rang', 'Lạc hạt'], ['dầu ăn', 'Dầu cọ'], ['cơm nguội', 'Cơm tẻ (gạo tẻ máy nấu chín)'],
  ['Cá ngân (hoặc cá biển thịt chắc tương tự)', 'Cá nục'], ['tàu hủ ky lá', 'Đậu phụ chúc'], ['cua đồng', 'Cua đồng'],
  ['cá diêu hồng', 'Cá rô phi'], ['thịt thăn bò', 'Thịt bò loại I'], ['bắp chuối', 'Hoa chuối'], ['bạc hà', 'Dọc mùng'],
  // theo từ, không theo chuỗi con
  ['bớt muối', 'Muối'], ['nấm đùi gà', 'Nấm thường tươi'], ['Nấm mèo', 'Mộc nhĩ'],
  // cố ý không map
  ['cá bống chay', null], ['sườn non chay', null], ['đậu bắp', null], ['hạt điều đỏ DH Foods', null], ['lá dứa', null],
  ['gói gia vị mì (có sẵn trong gói mì)', null], ['nước mắm chay', null]
];
for (const [raw, want] of cases) assert.equal(name(raw), want, raw);

const allergens = [
  // gia vị chế biến từ hải sản: không tính là nguyên liệu chính (đi qua condimentAllergenCodes)
  ['mắm cá linh', []], ['mắm tôm', []], ['nước mắm cá', []], ['dầu hào', []], ['nước mắm, tôm khô', ['seafood']],
  ['tàu hủ ky non', ['soy']], ['Cá ngân (hoặc cá biển thịt chắc tương tự)', ['seafood']], ['tương xí muội', []], ['chao', ['soy']], ['nui', ['gluten']], ['hạt điều rang', ['tree_nut']],
  ['hạt điều đỏ DH Foods', []], ['dầu điều', []], ['cá bống chay', []], ['mì chính', []], ['tương ớt', []], ['Nấm mèo', []]
];
for (const [raw, want] of allergens) assert.deepEqual(keywordAllergenCodes(raw), want, raw);
const { condimentAllergenCodes } = require('./ingredient_parser');
for (const [raw, want] of [['nước mắm', ['seafood']], ['mắm tôm', ['seafood']], ['dầu hào', ['seafood']], ['nước mắm chay', []], ['tôm khô', []]]) {
  assert.deepEqual(condimentAllergenCodes(raw), want, 'condiment ' + raw);
}
console.log('ingredient_parser: all checks passed');
