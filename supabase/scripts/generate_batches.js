const fs = require('fs');
const path = require('path');

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

function escapeJson(obj) {
  return `'${JSON.stringify(obj).replace(/'/g, "''")}'::jsonb`;
}

function buildBatchSql(recipes, startIdx, count) {
  const batch = recipes.slice(startIdx, startIdx + count);
  let sql = `DO $$\nDECLARE\n  v_recipe_id UUID;\nBEGIN\n\n`;

  for (let i = 0; i < batch.length; i++) {
    const r = batch[i];
    sql += `  -- [${startIdx + i + 1}] Recipe: ${r.title}\n`;
    sql += `  INSERT INTO public.recipes (\n`;
    sql += `    title, slug, description, image_url, source_url, category, cuisine,\n`;
    sql += `    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,\n`;
    sql += `    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,\n`;
    sql += `    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified\n`;
    sql += `  ) VALUES (\n`;
    sql += `    ${escapeSql(r.title)}, ${escapeSql(r.slug)}, ${escapeSql(r.description)}, ${escapeSql(r.image_url)}, ${escapeSql(r.source_url)}, ${escapeSql(r.category)}, ${escapeSql(r.cuisine)},\n`;
    sql += `    ${r.servings}, ${r.prep_time_minutes}, ${r.cook_time_minutes}, ${escapeSql(r.difficulty)}, ${escapeJson(r.instructions)},\n`;
    sql += `    ${r.nutrition.per_serving.calories}, ${r.nutrition.per_serving.protein_g}, ${r.nutrition.per_serving.fat_g}, ${r.nutrition.per_serving.carbs_g}, ${r.nutrition.per_serving.fiber_g}, ${r.nutrition.per_serving.sodium_mg},\n`;
    sql += `    ${r.nutrition.total_calories}, ${r.nutrition.total_protein_g}, ${r.nutrition.total_fat_g}, ${r.nutrition.total_carbs_g}, ${r.nutrition.total_fiber_g}, ${r.nutrition.total_sodium_mg}, true\n`;
    sql += `  )\n`;
    sql += `  ON CONFLICT (slug) DO UPDATE SET\n`;
    sql += `    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,\n`;
    sql += `    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,\n`;
    sql += `    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,\n`;
    sql += `    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,\n`;
    sql += `    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,\n`;
    sql += `    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,\n`;
    sql += `    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,\n`;
    sql += `    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()\n`;
    sql += `  RETURNING id INTO v_recipe_id;\n\n`;

    sql += `  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;\n`;
    sql += `  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;\n\n`;

    if (r.ingredients && r.ingredients.length > 0) {
      sql += `  INSERT INTO public.recipe_ingredients (\n`;
      sql += `    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,\n`;
      sql += `    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,\n`;
      sql += `    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g\n`;
      sql += `  ) VALUES\n`;

      const ingrRows = r.ingredients.map(ing => {
        const ingrIdVal = ing.matched_ingredient_id ? `'${ing.matched_ingredient_id}'::uuid` : 'NULL';
        return `    (v_recipe_id, ${ingrIdVal}, ${ing.order_index}, ${escapeSql(ing.raw_text)}, ${escapeSql(ing.ingredient_name_raw)}, ${ing.amount || 'NULL'}, ${escapeSql(ing.unit)}, ${ing.amount_g || 0}, ${ing.calories_per_100g || 0}, ${ing.protein_per_100g || 0}, ${ing.fat_per_100g || 0}, ${ing.carbs_per_100g || 0}, ${ing.fiber_per_100g || 0}, ${ing.sodium_mg_per_100g || 0})`;
      });
      sql += ingrRows.join(',\n') + ';\n\n';
    }

    if (r.allergens && r.allergens.length > 0) {
      sql += `  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES\n`;
      const allRows = r.allergens.map(aid => `    (v_recipe_id, ${aid})`);
      sql += allRows.join(',\n') + '\n  ON CONFLICT DO NOTHING;\n\n';
    }
  }

  sql += `END $$;\n`;
  return sql;
}

const masterPath = path.join(__dirname, '../data/vietnamese_recipes_master.json');
const recipes = JSON.parse(fs.readFileSync(masterPath, 'utf8'));

// Generate 5 batches of 9 recipes
const batchDir = path.join(__dirname, '../data/batches');
if (!fs.existsSync(batchDir)) fs.mkdirSync(batchDir, { recursive: true });

for (let b = 0; b < 5; b++) {
  const sql = buildBatchSql(recipes, b * 9, 9);
  const file = path.join(batchDir, `seed_batch_${b + 1}.sql`);
  fs.writeFileSync(file, sql, 'utf8');
  console.log(`Wrote ${file} (${(sql.length / 1024).toFixed(1)} KB)`);
}
