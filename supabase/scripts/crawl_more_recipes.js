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

function parseRecipeFull(html, rawTitle) {
  const title = cleanTitle(rawTitle);

  // Normalize HTML entities first
  const normHtml = html
    .replace(/&nbsp;/g, ' ')
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'");

  // 1. Ingredients extraction
  // Capture all <li> inside <ul> under any heading with "nguyên liệu" or "gia vị"
  let rawIngredients = [];
  const ingrSections = [...normHtml.matchAll(/<h[234][^>]*>[^<]*(?:nguyên liệu|gia vị)[^<]*<\/h[234]>([\s\S]*?)(?=<h[234]|$)/gi)];
  for (const sec of ingrSections) {
    const items = [...sec[1].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1]));
    for (const it of items) {
      if (it.length > 2 && !it.toLowerCase().startsWith('phần ') && !it.toLowerCase().endsWith(':')) {
        rawIngredients.push(it);
      }
    }
  }

  // Fallback: if no <li> found under headings, look for any <ul> between "Nguyên liệu" and "Cách làm"
  if (rawIngredients.length === 0) {
    const broadMatch = normHtml.match(/nguyên liệu[\s\S]*?(?=cách làm|các bước|hướng dẫn|$)/i);
    if (broadMatch) {
      const items = [...broadMatch[0].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1]));
      for (const it of items) {
        if (it.length > 2) rawIngredients.push(it);
      }
    }
  }

  // 2. Steps extraction
  let steps = [];

  // Style A: <h3>Bước X...</h3><p>...</p>
  const h3Steps = [...normHtml.matchAll(/<h[34][^>]*>(Bước \d+[^<]*)<\/h[34]>([\s\S]*?)(?=<h[234]|$)/gi)];
  if (h3Steps.length > 0) {
    for (const m of h3Steps) {
      const st = cleanHtml(m[1]);
      const sb = cleanHtml(m[2]);
      if (sb.length > 5) steps.push({ step_number: steps.length + 1, title: st, description: sb });
    }
  }

  // Style B: <p><strong>Bước X...</strong>...</p>
  if (steps.length === 0) {
    const pSteps = [...normHtml.matchAll(/<p[^>]*><strong>(Bước \d+[^<:]*)[–:](.*?)<\/strong>([\s\S]*?)<\/p>/gi)];
    if (pSteps.length > 0) {
      for (const m of pSteps) {
        const st = cleanHtml(m[1]) + ": " + cleanHtml(m[2]);
        const sb = cleanHtml(m[3]);
        if (sb.length > 5) steps.push({ step_number: steps.length + 1, title: st, description: sb });
      }
    }
  }

  // Style C: Headings like "1. Sơ chế...", "2. Ướp...", "Cách Sơ Chế..."
  if (steps.length === 0) {
    const stepHeadings = [...normHtml.matchAll(/<h[234][^>]*>(\d+\.\s*[^<]+|Cách (?:Sơ Chế|Ướp|Xào|Kho|Nấu|Chiên|Hầm|Làm Sốt|Pha Nước|Hoàn Thành)[^<]*)<\/h[234]>([\s\S]*?)(?=<h[234]|$)/gi)];
    if (stepHeadings.length > 0) {
      for (const m of stepHeadings) {
        const st = cleanHtml(m[1]);
        const sb = cleanHtml(m[2]);
        if (sb.length > 5) steps.push({ step_number: steps.length + 1, title: st, description: sb });
      }
    }
  }

  // Style D: Steps under "Các bước thực hiện" section
  if (steps.length === 0) {
    const buocSection = normHtml.match(/<h[234][^>]*>[^<]*(?:các bước|cách làm|hướng dẫn)[^<]*<\/h[234]>([\s\S]*?)(?=<h[234]>(?:Bí Quyết|Thành Phẩm|Mẹo|Lưu Ý|Lời Kết)|$)/i);
    if (buocSection) {
      // Check for <ol><li> or <p>
      const olItems = [...buocSection[1].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1])).filter(x => x.length > 15);
      if (olItems.length > 0) {
        olItems.forEach((it, idx) => {
          steps.push({ step_number: idx + 1, title: `Bước ${idx + 1}`, description: it });
        });
      } else {
        const pItems = [...buocSection[1].matchAll(/<p[^>]*>(.*?)<\/p>/gi)].map(m => cleanHtml(m[1])).filter(x => x.length > 15);
        pItems.forEach((it, idx) => {
          steps.push({ step_number: idx + 1, title: `Bước ${idx + 1}`, description: it });
        });
      }
    }
  }

  // Servings and cooking times
  let servings = 4;
  const servingsMatch = normHtml.match(/(?:cho|khẩu phần)\s*(\d+)(?:\s*-\s*(\d+))?\s*(?:người|phần)/i);
  if (servingsMatch) servings = parseInt(servingsMatch[1], 10);

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

  let category = 'mon_man';
  const tLower = title.toLowerCase();
  if (tLower.includes('canh ') || tLower.startsWith('canh')) category = 'mon_canh';
  else if (tLower.includes('chay') || tLower.includes('nấm rơm') || tLower.includes('đậu hũ non')) category = 'mon_chay';
  else if (tLower.includes('cơm ') || tLower.includes('mì ') || tLower.includes('bún ') || tLower.includes('phở ') || tLower.includes('miến ') || tLower.includes('cháo ')) category = 'mon_an_sang';
  else if (tLower.includes('kho ') || tLower.includes('rim ')) category = 'mon_kho';
  else if (tLower.includes('xào ')) category = 'mon_xao';
  else if (tLower.includes('nướng ')) category = 'mon_nuong';

  return { title, rawIngredients, steps, servings, prepTime, cookTime, category };
}

async function runExpandedCrawl() {
  console.log("=== EXPANDED RECIPE CRAWLER ===");

  // Load existing recipes to avoid duplicates
  const existingPath = path.join(__dirname, '../data/vietnamese_recipes_crawled.json');
  let allRecipes = [];
  if (fs.existsSync(existingPath)) {
    allRecipes = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
  }
  console.log(`Loaded ${allRecipes.length} existing recipes.`);

  const seenSlugs = new Set(allRecipes.map(r => r.slug));
  const seenTitles = new Set(allRecipes.map(r => stripAccents(r.title)));

  // Target search queries to get 40-50 high-quality diverse dishes
  const searchQueries = [
    'thit kho', 'canh chua', 'suon xao chua ngot', 'ca kho', 'ga kho',
    'bo xao', 'tom rim', 'muc xao', 'dau sot ca', 'chao ga',
    'canh bi do', 'canh rau ngot', 'canh kho qua', 'rau muong xao',
    'cha gio', 'com tam', 'bun cha', 'pho bo', 'bun rieu',
    'nam kho', 'canh cai', 'thit nuong', 'trung chien', 'ca diêu hong'
  ];

  for (const q of searchQueries) {
    if (allRecipes.length >= 45) {
      console.log("Reached target of 45+ recipes!");
      break;
    }
    const url = `https://bepxua.vn/wp-json/wp/v2/posts?search=${encodeURIComponent(q)}&per_page=10&_embed=1`;
    try {
      console.log(`Searching: "${q}"...`);
      const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
      if (!res.ok) continue;
      const posts = await res.json();

      for (const p of posts) {
        if (allRecipes.length >= 45) break;
        if (seenSlugs.has(p.slug)) continue;
        seenSlugs.add(p.slug);

        const details = parseRecipeFull(p.content.rendered, p.title.rendered);
        if (details.rawIngredients.length < 4 || details.steps.length < 2) continue;

        const normTitle = stripAccents(details.title);
        if (seenTitles.has(normTitle)) continue;
        seenTitles.add(normTitle);

        const imageUrl = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || 
                         p.content.rendered.match(/<img[^>]+src="([^">]+)"/i)?.[1] || null;

        const parsedIngredients = [];
        let totalCals = 0, totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0, totalSodium = 0;
        const recipeAllergenIds = new Set();

        for (let i = 0; i < details.rawIngredients.length; i++) {
          const parsed = parseIngredientLine(details.rawIngredients[i]);
          parsed.order_index = i + 1;
          parsedIngredients.push(parsed);

          const factor = parsed.amount_g / 100.0;
          totalCals += parsed.calories_per_100g * factor;
          totalProtein += parsed.protein_per_100g * factor;
          totalFat += parsed.fat_per_100g * factor;
          totalCarbs += parsed.carbs_per_100g * factor;
          totalFiber += parsed.fiber_per_100g * factor;
          totalSodium += parsed.sodium_mg_per_100g * factor;

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

        allRecipes.push(recipeRecord);
        console.log(`Added [#${allRecipes.length}] "${recipeRecord.title}" | Matched: ${recipeRecord.ingredient_match_rate} | Steps: ${recipeRecord.instructions.length}`);
      }
    } catch (e) {
      console.warn(`Query ${q} error:`, e.message);
    }
  }

  console.log(`\n========================================`);
  console.log(`TOTAL RECIPES NOW IN DATASET: ${allRecipes.length}`);
  fs.writeFileSync(existingPath, JSON.stringify(allRecipes, null, 2), 'utf8');
  console.log(`Saved updated dataset to ${existingPath}`);
}

runExpandedCrawl().catch(console.error);
