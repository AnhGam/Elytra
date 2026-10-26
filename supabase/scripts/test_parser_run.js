const { parseIngredientLine } = require('./ingredient_parser');

const testLines = [
  'Đậu hũ: 4 miếng (400g)',
  'Thịt xay: 200g',
  'Hành tím: 10g (xắt lát, băm sơ)',
  'Hành lá: để riêng phần gốc và phần lá, xắt nhỏ',
  'Ngò rí: xắt nhỏ',
  'Hạt nêm: 1 muỗng cà phê',
  'Đường: 1 muỗng cà phê',
  'Nước mắm: 1 muỗng canh',
  'Tiêu xay: 1 ít',
  'Cà chua: 4 trái, xắt nhỏ, băm sơ',
  'Dầu ăn: 2 muỗng canh',
  '1 kg cá nục, sơ chế sạch',
  '5 muỗng canh nước mắm',
  '3 lòng đỏ trứng gà',
  '300g thịt ba rọi',
  '200g tôm sú tươi',
  '1 bó rau muống',
  '2 củ cà rốt'
];

let matched = 0;
for (const line of testLines) {
  const res = parseIngredientLine(line);
  const ok = res.matched_ingredient_id !== null;
  if (ok) matched++;
  console.log(`${ok ? '✅' : '❌'} "${line}" => Name: "${res.ingredient_name_raw}", Grams: ${res.amount_g}g, Matched: [${res.matched_ingredient_code}] ${res.matched_ingredient_name}`);
}
console.log(`\nMatch Rate: ${matched}/${testLines.length} (${((matched/testLines.length)*100).toFixed(1)}%)`);
