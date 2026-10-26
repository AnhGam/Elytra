const fs = require('fs');
const path = require('path');

const recipes = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/vietnamese_recipes_crawled.json'), 'utf8'));
const r16 = recipes[15]; // index 15 = #16
console.log("=== RECIPE #16:", r16.title);
console.log("Ingredients:");
r16.ingredients.forEach(i => {
  console.log(`- ${i.raw_text} | name: ${i.ingredient_name_raw} | amount: ${i.amount} ${i.unit} | amount_g: ${i.amount_g}g | matched: [${i.matched_ingredient_code}] ${i.matched_ingredient_name}`);
});
