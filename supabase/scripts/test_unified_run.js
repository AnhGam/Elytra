const { parseRecipeUnified } = require('./unified_recipe_parser');
const { parseIngredientLine } = require('./ingredient_parser');

async function testUnified() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?search=suon+non+rim+sa+ot";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  const p = posts[0];
  const parsed = parseRecipeUnified(p.content.rendered, p.title.rendered);
  console.log("=== Title:", parsed.title);
  console.log("Servings:", parsed.servings);
  console.log(`Ingredients (${parsed.rawIngredients.length}):`);
  for (const raw of parsed.rawIngredients) {
    const item = parseIngredientLine(raw);
    console.log(`  - "${raw}" => Amount: ${item.amount} ${item.unit} (${item.amount_g}g) -> Matched: [${item.matched_ingredient_code}] ${item.matched_ingredient_name}`);
  }
  console.log(`Steps (${parsed.steps.length}):`);
  parsed.steps.slice(0, 3).forEach(s => console.log(`  [${s.step_number}] ${s.title}: ${s.description.substring(0, 70)}...`));
}
testUnified();
