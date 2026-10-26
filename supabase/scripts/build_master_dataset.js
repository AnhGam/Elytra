const fs = require('fs');
const path = require('path');
const { parseRecipeUnified, cleanHtml, cleanTitle } = require('./unified_recipe_parser');
const { parseIngredientLine, stripAccents, allergensByIngrId } = require('./ingredient_parser');

async function buildMasterDataset() {
  console.log("=== BUILDING MASTER 40-50 VIETNAMESE RECIPES DATASET ===");
  const recipesMap = new Map();

  // Curated targeted queries to cover all iconic Vietnamese dishes
  const queries = [
    'thịt kho', 'canh chua', 'cá kho', 'gà kho', 'sườn kho',
    'bò xào', 'mì xào', 'tôm rim', 'sườn xào chua ngọt', 'bò lúc lắc',
    'gà chiên nước mắm', 'gà rang muối', 'cơm chiên', 'hủ tiếu', 'bún bò',
    'canh khổ qua', 'canh bí đỏ', 'canh rau ngót', 'đậu hũ sốt', 'đậu hũ kho nấm',
    'chả giò', 'bún riêu', 'bún chả', 'cá chiên giòn', 'lẩu thái'
  ];

  for (const q of queries) {
    if (recipesMap.size >= 50) break;
    const url = `https://bepxua.vn/wp-json/wp/v2/posts?search=${encodeURIComponent(q)}&per_page=6&_embed=1`;
    try {
      console.log(`Searching query: "${q}"...`);
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (!res.ok) continue;
      const posts = await res.json();

      for (const p of posts) {
        if (recipesMap.size >= 50) break;
        
        // Skip compilation / roundup articles ("Top 3 cách...", "6 cách làm...")
        if (/^\d+\s*cách|^top\s*\d+|^bí kíp\s*\d+/i.test(p.title.rendered)) {
          continue;
        }

        const parsed = parseRecipeUnified(p.content.rendered, p.title.rendered);
        if (parsed.rawIngredients.length < 4 || parsed.steps.length < 3) continue;

        const cleanT = parsed.title;
        const normKey = stripAccents(cleanT);
        if (recipesMap.has(normKey)) continue;

        // Parse ingredients
        const parsedIngredients = [];
        let totalCals = 0, totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0, totalSodium = 0;
        const recipeAllergenIds = new Set();

        for (let i = 0; i < parsed.rawIngredients.length; i++) {
          const item = parseIngredientLine(parsed.rawIngredients[i]);
          item.order_index = i + 1;
          parsedIngredients.push(item);

          const factor = item.amount_g / 100.0;
          totalCals += item.calories_per_100g * factor;
          totalProtein += item.protein_per_100g * factor;
          totalFat += item.fat_per_100g * factor;
          totalCarbs += item.carbs_per_100g * factor;
          totalFiber += item.fiber_per_100g * factor;
          totalSodium += item.sodium_mg_per_100g * factor;

          if (item.matched_ingredient_id && allergensByIngrId.has(item.matched_ingredient_id)) {
            allergensByIngrId.get(item.matched_ingredient_id).forEach(aid => recipeAllergenIds.add(aid));
          }
        }

        // Quality check: must have at least 150 calories total and good match rate
        if (totalCals < 100) continue;

        const matchedCount = parsedIngredients.filter(pi => pi.matched_ingredient_id !== null).length;
        const matchPct = (matchedCount / parsedIngredients.length) * 100;
        if (matchPct < 60) continue;

        const servings = parsed.servings || 4;
        const imageUrl = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || 
                         p.content.rendered.match(/<img[^>]+src="([^">]+)"/i)?.[1] || null;

        const cleanSlug = p.slug
          .replace(/-%f0%9f%8d%85.*/, '')
          .replace(/%[0-9a-f]{2}/gi, '')
          .replace(/-+$/, '');

        const recipeRecord = {
          title: cleanT,
          slug: cleanSlug,
          description: cleanHtml(p.excerpt?.rendered || "").substring(0, 300) || `Công thức chuẩn vị cho món ${cleanT}`,
          category: parsed.category,
          cuisine: 'vietnamese',
          servings: servings,
          prep_time_minutes: parsed.prepTime,
          cook_time_minutes: parsed.cookTime,
          difficulty: parsed.steps.length > 5 ? 'medium' : 'easy',
          image_url: imageUrl,
          source_url: p.link,
          instructions: parsed.steps,
          ingredients: parsedIngredients,
          allergens: Array.from(recipeAllergenIds),
          nutrition: {
            total_calories: Math.round(totalCals * 10) / 10,
            total_protein_g: Math.round(totalProtein * 10) / 10,
            total_fat_g: Math.round(totalFat * 10) / 10,
            total_carbs_g: Math.round(totalCarbs * 10) / 10,
            total_fiber_g: Math.round(totalFiber * 10) / 10,
            total_sodium_mg: Math.round(totalSodium * 10) / 10,
            per_serving: {
              calories: Math.round((totalCals / servings) * 10) / 10,
              protein_g: Math.round((totalProtein / servings) * 10) / 10,
              fat_g: Math.round((totalFat / servings) * 10) / 10,
              carbs_g: Math.round((totalCarbs / servings) * 10) / 10,
              fiber_g: Math.round((totalFiber / servings) * 10) / 10,
              sodium_mg: Math.round((totalSodium / servings) * 10) / 10
            }
          },
          ingredient_match_rate: `${matchedCount}/${parsedIngredients.length} (${matchPct.toFixed(1)}%)`
        };

        recipesMap.set(normKey, recipeRecord);
        console.log(`[#${recipesMap.size}] "${recipeRecord.title}" (${recipeRecord.category}) | ${parsedIngredients.length} ingr (${recipeRecord.ingredient_match_rate}) | ${parsed.steps.length} steps | ${recipeRecord.nutrition.per_serving.calories} kcal/srv`);
      }
    } catch (err) {
      console.warn(`Query ${q} error:`, err.message);
    }
  }

  // Also query general posts pages if not yet reached 40
  if (recipesMap.size < 40) {
    for (let page = 1; page <= 5; page++) {
      if (recipesMap.size >= 45) break;
      const url = `https://bepxua.vn/wp-json/wp/v2/posts?per_page=50&page=${page}&_embed=1`;
      try {
        console.log(`Fetching general page ${page}...`);
        const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
        if (!res.ok) continue;
        const posts = await res.json();
        for (const p of posts) {
          if (recipesMap.size >= 45) break;
          if (/^\d+\s*cách|^top\s*\d+|^bí kíp\s*\d+/i.test(p.title.rendered)) continue;

          const parsed = parseRecipeUnified(p.content.rendered, p.title.rendered);
          if (parsed.rawIngredients.length < 4 || parsed.steps.length < 3) continue;

          const cleanT = parsed.title;
          const normKey = stripAccents(cleanT);
          if (recipesMap.has(normKey)) continue;

          const parsedIngredients = [];
          let totalCals = 0, totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0, totalSodium = 0;
          const recipeAllergenIds = new Set();

          for (let i = 0; i < parsed.rawIngredients.length; i++) {
            const item = parseIngredientLine(parsed.rawIngredients[i]);
            item.order_index = i + 1;
            parsedIngredients.push(item);

            const factor = item.amount_g / 100.0;
            totalCals += item.calories_per_100g * factor;
            totalProtein += item.protein_per_100g * factor;
            totalFat += item.fat_per_100g * factor;
            totalCarbs += item.carbs_per_100g * factor;
            totalFiber += item.fiber_per_100g * factor;
            totalSodium += item.sodium_mg_per_100g * factor;

            if (item.matched_ingredient_id && allergensByIngrId.has(item.matched_ingredient_id)) {
              allergensByIngrId.get(item.matched_ingredient_id).forEach(aid => recipeAllergenIds.add(aid));
            }
          }

          if (totalCals < 100) continue;
          const matchedCount = parsedIngredients.filter(pi => pi.matched_ingredient_id !== null).length;
          const matchPct = (matchedCount / parsedIngredients.length) * 100;
          if (matchPct < 60) continue;

          const servings = parsed.servings || 4;
          const imageUrl = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || 
                           p.content.rendered.match(/<img[^>]+src="([^">]+)"/i)?.[1] || null;

          const cleanSlug = p.slug
            .replace(/-%f0%9f%8d%85.*/, '')
            .replace(/%[0-9a-f]{2}/gi, '')
            .replace(/-+$/, '');

          const recipeRecord = {
            title: cleanT,
            slug: cleanSlug,
            description: cleanHtml(p.excerpt?.rendered || "").substring(0, 300) || `Công thức chuẩn vị cho món ${cleanT}`,
            category: parsed.category,
            cuisine: 'vietnamese',
            servings: servings,
            prep_time_minutes: parsed.prepTime,
            cook_time_minutes: parsed.cookTime,
            difficulty: parsed.steps.length > 5 ? 'medium' : 'easy',
            image_url: imageUrl,
            source_url: p.link,
            instructions: parsed.steps,
            ingredients: parsedIngredients,
            allergens: Array.from(recipeAllergenIds),
            nutrition: {
              total_calories: Math.round(totalCals * 10) / 10,
              total_protein_g: Math.round(totalProtein * 10) / 10,
              total_fat_g: Math.round(totalFat * 10) / 10,
              total_carbs_g: Math.round(totalCarbs * 10) / 10,
              total_fiber_g: Math.round(totalFiber * 10) / 10,
              total_sodium_mg: Math.round(totalSodium * 10) / 10,
              per_serving: {
                calories: Math.round((totalCals / servings) * 10) / 10,
                protein_g: Math.round((totalProtein / servings) * 10) / 10,
                fat_g: Math.round((totalFat / servings) * 10) / 10,
                carbs_g: Math.round((totalCarbs / servings) * 10) / 10,
                fiber_g: Math.round((totalFiber / servings) * 10) / 10,
                sodium_mg: Math.round((totalSodium / servings) * 10) / 10
              }
            },
            ingredient_match_rate: `${matchedCount}/${parsedIngredients.length} (${matchPct.toFixed(1)}%)`
          };

          recipesMap.set(normKey, recipeRecord);
          console.log(`[#${recipesMap.size}] "${recipeRecord.title}" (${recipeRecord.category}) | ${parsedIngredients.length} ingr (${recipeRecord.ingredient_match_rate}) | ${parsed.steps.length} steps | ${recipeRecord.nutrition.per_serving.calories} kcal/srv`);
        }
      } catch (err) {
        console.warn(`Page ${page} error:`, err.message);
      }
    }
  }

  const finalDataset = Array.from(recipesMap.values());
  console.log(`\n========================================`);
  console.log(`MASTER DATASET COMPLETE: ${finalDataset.length} HIGH-QUALITY VIETNAMESE RECIPES`);

  const outPath = path.join(__dirname, '../data/vietnamese_recipes_master.json');
  fs.writeFileSync(outPath, JSON.stringify(finalDataset, null, 2), 'utf8');
  console.log(`Saved master dataset to ${outPath}`);

  return finalDataset;
}

buildMasterDataset().catch(console.error);
