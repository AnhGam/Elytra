const fs = require('fs');
const path = require('path');
const { parseIngredientLine, stripAccents, allergensByIngrId } = require('./ingredient_parser');

function cleanHtml(s) {
  if (!s) return "";
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'")
    .replace(/&#8220;/g, '"')
    .replace(/&#8221;/g, '"')
    .replace(/&amp;/g, '&')
    .replace(/&nbsp;/g, ' ')
    .trim();
}

function cleanTitle(raw) {
  return raw
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/[\u{1F300}-\u{1F9FF}]/gu, '')
    .replace(/[\u{2600}-\u{26FF}]/gu, '')
    .replace(/[\u{2700}-\u{27BF}]/gu, '')
    .replace(/–\s*Món Cơm Nhà.*/i, '')
    .replace(/–\s*Ăn Cơm Hay Bánh Mì.*/i, '')
    .replace(/–\s*Công Thức Đơn Giản.*/i, '')
    .replace(/–\s*Đậm Đà Như Ngoài Tiệm.*/i, '')
    .replace(/–\s*Chuẩn Vị.*/i, '')
    .replace(/–\s*Thơm Ngon.*/i, '')
    .replace(/–\s*Ai Ăn Cũng Ghiền.*/i, '')
    .replace(/–\s*Hao Cơm Cực!.*/i, '')
    .replace(/^Cách (?:Làm|Nấu|Kho|Xào|Chiên|Nướng)\s+/i, '')
    .trim();
}

function extractRecipeDetails(html, rawTitle) {
  const title = cleanTitle(rawTitle);

  // 1. Ingredients extraction
  // Matches section under "Nguyên Liệu" until next main section
  const ingrSectionMatch = html.match(/<h2[^>]*>(?:🛒\s*)?Nguyên Liệu[\s\S]*?<\/h2>([\s\S]*?)(?=<h2[^>]*>(?:👩‍🍳\s*)?Cách Làm|<h2[^>]*>Cách\s+|<h2[^>]*>Hướng Dẫn|$)/i);
  let rawIngredients = [];
  if (ingrSectionMatch) {
    const listItems = [...ingrSectionMatch[1].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1]));
    for (const item of listItems) {
      if (item.length > 2 && !item.toLowerCase().startsWith('phần ') && !item.toLowerCase().endsWith(':')) {
        rawIngredients.push(item);
      }
    }
  }

  // 2. Instructions extraction
  let steps = [];
  
  // Format A: <h3>Bước X...</h3><p>...</p>
  const h3Steps = [...html.matchAll(/<h3[^>]*>(Bước \d+[^<]*)<\/h3>([\s\S]*?)(?=<h3|<h2|$)/gi)];
  if (h3Steps.length > 0) {
    for (const m of h3Steps) {
      const stepTitle = cleanHtml(m[1]);
      const stepBody = cleanHtml(m[2]);
      if (stepBody.length > 5) {
        steps.push({ step_number: steps.length + 1, title: stepTitle, description: stepBody });
      }
    }
  }

  // Format B: <p><strong>Bước X...</strong>...</p>
  if (steps.length === 0) {
    const pSteps = [...html.matchAll(/<p[^>]*><strong>(Bước \d+[^<:]*)[–:](.*?)<\/strong>([\s\S]*?)<\/p>/gi)];
    if (pSteps.length > 0) {
      for (const m of pSteps) {
        const stepTitle = cleanHtml(m[1]) + ": " + cleanHtml(m[2]);
        const stepBody = cleanHtml(m[3]);
        if (stepBody.length > 5) {
          steps.push({ step_number: steps.length + 1, title: stepTitle, description: stepBody });
        }
      }
    }
  }

  // Format C: Heading "Cách Sơ Chế...", "Cách Ướp...", "Cách Kho/Nấu/Xào..."
  if (steps.length === 0) {
    const cachHeadings = [...html.matchAll(/<h[23][^>]*>(Cách (?:Sơ Chế|Ướp|Xào|Kho|Nấu|Chiên|Hầm|Làm Sốt|Pha Nước|Hoàn Thành)[^<]*)<\/h[23]>([\s\S]*?)(?=<h[23]|$)/gi)];
    if (cachHeadings.length > 0) {
      for (const m of cachHeadings) {
        const stepTitle = cleanHtml(m[1]);
        const stepBody = cleanHtml(m[2]);
        if (stepBody.length > 5) {
          steps.push({ step_number: steps.length + 1, title: stepTitle, description: stepBody });
        }
      }
    }
  }

  // Fallback Format D: Plain <ol><li> or <p> under Cách Làm
  if (steps.length === 0) {
    const cachLamSection = html.match(/<h2[^>]*>(?:👩‍🍳\s*)?Cách Làm[\s\S]*?<\/h2>([\s\S]*?)(?=<h2[^>]*>(?:Bí Quyết|Thành Phẩm|Mẹo|Lưu Ý|Lời Kết)|$)/i);
    if (cachLamSection) {
      const paragraphs = [...cachLamSection[1].matchAll(/<p[^>]*>(.*?)<\/p>/gi)].map(m => cleanHtml(m[1])).filter(p => p.length > 20);
      paragraphs.forEach((p, idx) => {
        steps.push({ step_number: idx + 1, title: `Bước ${idx + 1}`, description: p });
      });
    }
  }

  // 3. Servings and cooking times
  let servings = 4;
  const servingsMatch = html.match(/(?:cho|khẩu phần)\s*(\d+)(?:\s*-\s*(\d+))?\s*(?:người|phần)/i);
  if (servingsMatch) {
    servings = parseInt(servingsMatch[1], 10);
  }

  let prepTime = 15;
  let cookTime = 30;
  if (title.toLowerCase().includes('kho') || title.toLowerCase().includes('hầm')) {
    prepTime = 20;
    cookTime = 45;
  } else if (title.toLowerCase().includes('xào') || title.toLowerCase().includes('canh')) {
    prepTime = 15;
    cookTime = 20;
  } else if (title.toLowerCase().includes('chiên') || title.toLowerCase().includes('rán')) {
    prepTime = 15;
    cookTime = 25;
  }

  // Determine category
  let category = 'mon_man';
  const tLower = title.toLowerCase();
  if (tLower.includes('canh ') || tLower.startsWith('canh')) category = 'mon_canh';
  else if (tLower.includes('chay') || tLower.includes('nấm rơm') || tLower.includes('đậu hũ non')) category = 'mon_chay';
  else if (tLower.includes('cơm ') || tLower.includes('mì ') || tLower.includes('bún ') || tLower.includes('phở ') || tLower.includes('miến ') || tLower.includes('cháo ')) category = 'mon_an_sang';
  else if (tLower.includes('kho ') || tLower.includes('rim ')) category = 'mon_kho';
  else if (tLower.includes('xào ')) category = 'mon_xao';
  else if (tLower.includes('nướng ')) category = 'mon_nuong';

  return {
    title,
    rawIngredients,
    steps,
    servings,
    prepTime,
    cookTime,
    category
  };
}

async function crawlBatch() {
  console.log("Starting recipe crawl from bepxua.vn...");
  const candidateRecipes = [];
  const seenSlugs = new Set();
  const seenTitles = new Set();

  // Fetch from multiple pages and categories
  const endpoints = [
    "https://bepxua.vn/wp-json/wp/v2/posts?per_page=100&page=1&_embed=1",
    "https://bepxua.vn/wp-json/wp/v2/posts?per_page=100&page=2&_embed=1",
    "https://bepxua.vn/wp-json/wp/v2/posts?categories=149&per_page=30&_embed=1" // Món chay
  ];

  for (const ep of endpoints) {
    try {
      console.log(`Fetching endpoint: ${ep}...`);
      const res = await fetch(ep, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });
      if (!res.ok) {
        console.warn(`Failed ${ep}: status ${res.status}`);
        continue;
      }
      const posts = await res.json();
      console.log(`Received ${posts.length} posts.`);

      for (const p of posts) {
        if (seenSlugs.has(p.slug)) continue;
        seenSlugs.add(p.slug);

        const details = extractRecipeDetails(p.content.rendered, p.title.rendered);
        
        // Quality check: must have title, >= 4 ingredients, >= 3 steps
        if (details.rawIngredients.length < 4 || details.steps.length < 3) {
          continue;
        }

        // Avoid duplicate titles
        const normTitle = stripAccents(details.title);
        if (seenTitles.has(normTitle)) continue;
        seenTitles.add(normTitle);

        const imageUrl = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || 
                         p.content.rendered.match(/<img[^>]+src="([^">]+)"/i)?.[1] || null;

        // Parse ingredients and calculate nutrition
        const parsedIngredients = [];
        let totalCals = 0;
        let totalProtein = 0;
        let totalFat = 0;
        let totalCarbs = 0;
        let totalFiber = 0;
        let totalSodium = 0;
        const recipeAllergenIds = new Set();

        for (let i = 0; i < details.rawIngredients.length; i++) {
          const rawLine = details.rawIngredients[i];
          const parsed = parseIngredientLine(rawLine);
          parsed.order_index = i + 1;
          parsedIngredients.push(parsed);

          // Nutrition accumulation
          const factor = parsed.amount_g / 100.0;
          totalCals += parsed.calories_per_100g * factor;
          totalProtein += parsed.protein_per_100g * factor;
          totalFat += parsed.fat_per_100g * factor;
          totalCarbs += parsed.carbs_per_100g * factor;
          totalFiber += parsed.fiber_per_100g * factor;
          totalSodium += parsed.sodium_mg_per_100g * factor;

          // Allergen accumulation
          if (parsed.matched_ingredient_id && allergensByIngrId.has(parsed.matched_ingredient_id)) {
            allergensByIngrId.get(parsed.matched_ingredient_id).forEach(aid => recipeAllergenIds.add(aid));
          }
        }

        const servings = details.servings || 4;
        const matchedCount = parsedIngredients.filter(pi => pi.matched_ingredient_id !== null).length;
        const matchPct = (matchedCount / parsedIngredients.length) * 100;

        const recipeRecord = {
          title: details.title,
          slug: p.slug.replace(/-%f0%9f%8d%85.*/, '').replace(/%[0-9a-f]{2}/gi, '').replace(/-+$/, ''),
          description: cleanHtml(p.excerpt?.rendered || "").substring(0, 300) || `Công thức chuẩn vị cho món ${details.title}`,
          category: details.category,
          cuisine: 'vietnamese',
          servings: servings,
          prep_time_minutes: details.prepTime,
          cook_time_minutes: details.cookTime,
          difficulty: details.steps.length > 5 ? 'medium' : 'easy',
          image_url: imageUrl,
          source_url: p.link,
          instructions: details.steps,
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

        candidateRecipes.push(recipeRecord);
        console.log(`[#${candidateRecipes.length}] "${recipeRecord.title}" (${recipeRecord.category}) | Ingredients: ${parsedIngredients.length} (${recipeRecord.ingredient_match_rate}) | Steps: ${details.steps.length} | Cals/srv: ${recipeRecord.nutrition.per_serving.calories}`);
      }
    } catch (err) {
      console.error(`Error crawling ${ep}:`, err.message);
    }
  }

  console.log(`\n========================================`);
  console.log(`TOTAL VALID CRAWLED RECIPES: ${candidateRecipes.length}`);
  
  // Save dataset
  const outPath = path.join(__dirname, '../data/vietnamese_recipes_crawled.json');
  fs.writeFileSync(outPath, JSON.stringify(candidateRecipes, null, 2), 'utf8');
  console.log(`Saved dataset to ${outPath}`);

  return candidateRecipes;
}

crawlBatch().catch(console.error);
