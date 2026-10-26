const fs = require('fs');
const path = require('path');

const recipes = JSON.parse(fs.readFileSync(path.join(__dirname, '../data/vietnamese_recipes_crawled.json'), 'utf8'));

console.log(`=== CURRENT 45 RECIPES ===`);
recipes.forEach((r, idx) => {
  console.log(`[${idx + 1}] "${r.title}" | Category: ${r.category} | Ingr: ${r.ingredients.length} | Match: ${r.ingredient_match_rate} | Steps: ${r.instructions.length} | Cal/srv: ${r.nutrition.per_serving.calories}`);
});
