const { parseIngredientLine, stripAccents, allergensByIngrId, catalog } = require('./ingredient_parser');

function cleanHtml(s) {
  if (!s) return "";
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&#32;/g, ' ')
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

function parseRecipeUnified(html, rawTitle) {
  const title = cleanTitle(rawTitle);
  const isWprm = html.includes('wprm-recipe-container');

  let rawIngredients = [];
  let steps = [];
  let servings = 4;

  if (isWprm) {
    // 1. WPRM Ingredients
    const ingrMatches = [...html.matchAll(/<li[^>]+class="[^"]*wprm-recipe-ingredient[^"]*"[^>]*>([\s\S]*?)<\/li>/gi)];
    for (const m of ingrMatches) {
      const raw = m[1];
      const amount = cleanHtml(raw.match(/wprm-recipe-ingredient-amount[^>]*>(.*?)<\/span>/i)?.[1] || "");
      const unit = cleanHtml(raw.match(/wprm-recipe-ingredient-unit[^>]*>(.*?)<\/span>/i)?.[1] || "");
      const name = cleanHtml(raw.match(/wprm-recipe-ingredient-name[^>]*>(.*?)<\/(?:span|a)>/i)?.[1] || "");
      const notes = cleanHtml(raw.match(/wprm-recipe-ingredient-notes[^>]*>(.*?)<\/span>/i)?.[1] || "");

      if (name.length > 1) {
        let line = "";
        if (amount && unit) {
          line = `${name}: ${amount} ${unit}`;
        } else if (amount) {
          line = `${name}: ${amount}`;
        } else {
          line = name;
        }
        if (notes) line += ` (${notes})`;
        rawIngredients.push(line);
      }
    }

    // 2. WPRM Instructions
    const stepMatches = [...html.matchAll(/<div[^>]+class="[^"]*wprm-recipe-instruction-text[^"]*"[^>]*>([\s\S]*?)<\/div>/gi)];
    stepMatches.forEach((s, idx) => {
      const desc = cleanHtml(s[1]);
      if (desc.length > 5) {
        steps.push({
          step_number: idx + 1,
          title: `Bước ${idx + 1}`,
          description: desc
        });
      }
    });

    // 3. WPRM Servings
    const srvMatch = html.match(/wprm-recipe-servings[^>]*>(\d+)<\/span>/i) || html.match(/data-servings="(\d+)"/i);
    if (srvMatch) servings = parseInt(srvMatch[1], 10);

  } else {
    // Standard Gutenberg format
    const normHtml = html.replace(/&nbsp;/g, ' ').replace(/&#32;/g, ' ');

    const ingrSectionMatch = normHtml.match(/<h2[^>]*>(?:🛒\s*)?Nguyên Liệu[\s\S]*?<\/h2>([\s\S]*?)(?=<h2[^>]*>(?:👩‍🍳\s*)?Cách Làm|<h2[^>]*>Cách\s+|<h2[^>]*>Hướng Dẫn|$)/i);
    if (ingrSectionMatch) {
      const listItems = [...ingrSectionMatch[1].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1]));
      for (const item of listItems) {
        if (item.length > 2 && !item.toLowerCase().startsWith('phần ') && !item.toLowerCase().endsWith(':')) {
          rawIngredients.push(item);
        }
      }
    }

    // Steps
    const h3Steps = [...normHtml.matchAll(/<h3[^>]*>(Bước \d+[^<]*)<\/h3>([\s\S]*?)(?=<h3|<h2|$)/gi)];
    if (h3Steps.length > 0) {
      for (const m of h3Steps) {
        const st = cleanHtml(m[1]);
        const sb = cleanHtml(m[2]);
        if (sb.length > 5) steps.push({ step_number: steps.length + 1, title: st, description: sb });
      }
    } else {
      const pSteps = [...normHtml.matchAll(/<p[^>]*><strong>(Bước \d+[^<:]*)[–:](.*?)<\/strong>([\s\S]*?)<\/p>/gi)];
      for (const m of pSteps) {
        const st = cleanHtml(m[1]) + ": " + cleanHtml(m[2]);
        const sb = cleanHtml(m[3]);
        if (sb.length > 5) steps.push({ step_number: steps.length + 1, title: st, description: sb });
      }
    }

    const srvMatch = normHtml.match(/(?:cho|khẩu phần)\s*(\d+)(?:\s*-\s*(\d+))?\s*(?:người|phần)/i);
    if (srvMatch) servings = parseInt(srvMatch[1], 10);
  }

  let prepTime = 15;
  let cookTime = 30;
  const tLower = title.toLowerCase();
  if (tLower.includes('kho') || tLower.includes('hầm')) { prepTime = 20; cookTime = 45; }
  else if (tLower.includes('xào') || tLower.includes('canh')) { prepTime = 15; cookTime = 20; }
  else if (tLower.includes('chiên') || tLower.includes('rán')) { prepTime = 15; cookTime = 25; }

  let category = 'mon_man';
  if (tLower.includes('canh ') || tLower.startsWith('canh')) category = 'mon_canh';
  else if (tLower.includes('chay') || tLower.includes('nấm rơm') || tLower.includes('đậu hũ non')) category = 'mon_chay';
  else if (tLower.includes('cơm ') || tLower.includes('mì ') || tLower.includes('bún ') || tLower.includes('phở ') || tLower.includes('miến ') || tLower.includes('cháo ')) category = 'mon_an_sang';
  else if (tLower.includes('kho ') || tLower.includes('rim ')) category = 'mon_kho';
  else if (tLower.includes('xào ')) category = 'mon_xao';
  else if (tLower.includes('nướng ')) category = 'mon_nuong';

  return { title, rawIngredients, steps, servings, prepTime, cookTime, category };
}

module.exports = { parseRecipeUnified, cleanHtml, cleanTitle };
