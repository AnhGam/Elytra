const fs = require('fs');
const path = require('path');

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

function escapeJson(obj) {
  return `'${JSON.stringify(obj).replace(/'/g, "''")}'::jsonb`;
}

function generateCleanSeed() {
  const masterPath = path.join(__dirname, '../data/vietnamese_recipes_master.json');
  const recipes = JSON.parse(fs.readFileSync(masterPath, 'utf8'));

  // 1. Recipes SQL (split into chunks of 15 recipes so queries stay compact)
  const outDir = path.join(__dirname, '../data/seed_sql');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const CHUNK_SIZE = 15;
  for (let c = 0; c < Math.ceil(recipes.length / CHUNK_SIZE); c++) {
    const chunk = recipes.slice(c * CHUNK_SIZE, (c + 1) * CHUNK_SIZE);
    
    // Part A: Recipes Insert
    let recipesSql = `INSERT INTO public.recipes (
  title, slug, description, image_url, source_url, category, cuisine,
  servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
  calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
  total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
) VALUES\n`;

    const rValues = chunk.map(r => {
      return `  (${escapeSql(r.title)}, ${escapeSql(r.slug)}, ${escapeSql(r.description)}, ${escapeSql(r.image_url)}, ${escapeSql(r.source_url)}, ${escapeSql(r.category)}, ${escapeSql(r.cuisine)}, ${r.servings}, ${r.prep_time_minutes}, ${r.cook_time_minutes}, ${escapeSql(r.difficulty)}, ${escapeJson(r.instructions)}, ${r.nutrition.per_serving.calories}, ${r.nutrition.per_serving.protein_g}, ${r.nutrition.per_serving.fat_g}, ${r.nutrition.per_serving.carbs_g}, ${r.nutrition.per_serving.fiber_g}, ${r.nutrition.per_serving.sodium_mg}, ${r.nutrition.total_calories}, ${r.nutrition.total_protein_g}, ${r.nutrition.total_fat_g}, ${r.nutrition.total_carbs_g}, ${r.nutrition.total_fiber_g}, ${r.nutrition.total_sodium_mg}, true)`;
    });

    recipesSql += rValues.join(',\n') + '\n';
    recipesSql += `ON CONFLICT (slug) DO UPDATE SET
  title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
  instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
  protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
  carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
  sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
  total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
  total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
  total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now();`;

    fs.writeFileSync(path.join(outDir, `recipes_chunk_${c + 1}.sql`), recipesSql, 'utf8');

    // Part B: Recipe Ingredients Insert
    let ingrSql = `INSERT INTO public.recipe_ingredients (
  recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
  amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
  carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
) VALUES\n`;

    const ingrValues = [];
    for (const r of chunk) {
      for (const ing of r.ingredients) {
        const ingrIdVal = ing.matched_ingredient_id ? `'${ing.matched_ingredient_id}'::uuid` : 'NULL';
        ingrValues.push(`  ((SELECT id FROM public.recipes WHERE slug = ${escapeSql(r.slug)}), ${ingrIdVal}, ${ing.order_index}, ${escapeSql(ing.raw_text)}, ${escapeSql(ing.ingredient_name_raw)}, ${ing.amount || 'NULL'}, ${escapeSql(ing.unit)}, ${ing.amount_g || 0}, ${ing.calories_per_100g || 0}, ${ing.protein_per_100g || 0}, ${ing.fat_per_100g || 0}, ${ing.carbs_per_100g || 0}, ${ing.fiber_per_100g || 0}, ${ing.sodium_mg_per_100g || 0})`);
      }
    }

    ingrSql += ingrValues.join(',\n') + ';';
    fs.writeFileSync(path.join(outDir, `ingredients_chunk_${c + 1}.sql`), ingrSql, 'utf8');

    // Part C: Recipe Allergens Insert
    let allerSql = `INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES\n`;
    const allerValues = [];
    for (const r of chunk) {
      for (const aid of r.allergens) {
        allerValues.push(`  ((SELECT id FROM public.recipes WHERE slug = ${escapeSql(r.slug)}), ${aid})`);
      }
    }
    if (allerValues.length > 0) {
      allerSql += allerValues.join(',\n') + '\nON CONFLICT DO NOTHING;';
      fs.writeFileSync(path.join(outDir, `allergens_chunk_${c + 1}.sql`), allerSql, 'utf8');
    }
  }

  console.log(`Generated SQL files in ${outDir}`);
}

generateCleanSeed();
