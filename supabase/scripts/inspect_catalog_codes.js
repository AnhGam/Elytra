const fs = require('fs');
const path = require('path');

const catalog = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/ingredients_catalog.json'), 'utf8'));

const testTerms = [
  'lợn', 'bò', 'gà', 'trứng', 'đậu phụ', 'đậu hũ', 'cá', 'tôm', 'mực',
  'cà chua', 'cà rốt', 'bí đỏ', 'mướp đắng', 'rau muống', 'rau ngót',
  'mồng tơi', 'nấm rơm', 'hành', 'tỏi', 'gừng', 'sả', 'ớt',
  'dầu', 'nước mắm', 'xì dầu', 'đường', 'muối', 'tiêu', 'hạt tiêu',
  'gạo', 'bún', 'phở', 'miến'
];

for (const term of testTerms) {
  const matches = catalog.filter(i => i.name_unaccented.includes(term) || i.name_vi.toLowerCase().includes(term));
  console.log(`\n=== SEARCH "${term}" (${matches.length} results) ===`);
  matches.slice(0, 5).forEach(m => console.log(`  [${m.code}] ${m.name_vi} (Cal: ${m.calories_per_100g}, P: ${m.protein_per_100g}, F: ${m.fat_per_100g}, C: ${m.carbs_per_100g})`));
}
