const fs = require('fs');
const path = require('path');

const catalog = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/ingredients_catalog.json'), 'utf8'));

console.log("--- PORK (category 7) ---");
catalog.filter(i => i.category_id === 7 && i.name_unaccented.includes('lon')).forEach(i => {
  console.log(`[${i.code}] ${i.name_vi} (Cal: ${i.calories_per_100g})`);
});

console.log("--- FISH (category 8) ---");
catalog.filter(i => i.category_id === 8 && i.name_unaccented.includes('ca ')).slice(0, 15).forEach(i => {
  console.log(`[${i.code}] ${i.name_vi}`);
});

console.log("--- SEASONING / SUGAR / SALT (category 11, 13) ---");
catalog.filter(i => i.category_id === 11 || i.category_id === 13).forEach(i => {
  console.log(`[${i.code}] ${i.name_vi} (Cal: ${i.calories_per_100g})`);
});
