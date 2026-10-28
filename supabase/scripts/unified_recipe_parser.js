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

// Tên bài viết = tên món + lời quảng cáo ở trước/giữa/sau ("Cách làm ... thơm ngon ăn là ghiền").
// Bóc lấy tên món. Tên đã duyệt tay cho dữ liệu hiện có nằm ở data/recipe_names.json (ưu tiên hơn hàm này).
const COOK_VERBS = ['xào', 'kho', 'chiên', 'nướng', 'rim', 'hầm', 'om', 'luộc', 'hấp', 'nấu', 'rang', 'trộn', 'ngâm'];
// Cụm khen dài trước, cụm ngắn sau. KHÔNG có 'thơm' đứng một mình (kho thơm = kho dứa)
const PRAISE = [
  'chuẩn nhà hàng', 'như nhà hàng', 'ngon ngất ngây', 'ngất ngây', 'gây nghiện', 'hút hồn', 'mê mẩn', 'tuyệt hảo', 'thần thánh',
  'đúng điệu', 'đúng vị', 'bao ngon', 'xuất sắc',
  'cả nhà ai cũng mê', 'ai ăn cũng ghiền', 'ăn là ghiền', 'đậm chất đồng quê', 'như ngoài tiệm', 'như ngoài hàng',
  'ngon vô đối', 'ngon bá cháy', 'ngon hết ý', 'ngon khó cưỡng', 'ngon lạ miệng', 'ngon số dách', 'ngon mê ly', 'ngon miệng', 'ngon lành',
  'siêu thơm ngon', 'thơm ngon', 'thơm lừng', 'thơm nức', 'thơm mềm', 'dẻo thơm', 'siêu ngon', 'cực ngon', 'tơi ngon', 'béo ngon', 'mềm ngon',
  'vô đối', 'bá cháy', 'hết ý', 'khó cưỡng', 'lạ miệng', 'số dách', 'mê ly', 'quên sầu', 'bất bại', 'hao cơm',
  'đậm đà', 'đậm vị', 'chuẩn vị', 'ngọt thanh', 'ngọt ngào', 'giòn rụm', 'giòn giòn', 'trắng giòn', 'mềm mọng', 'màu đẹp',
  'hấp dẫn', 'bổ dưỡng', 'dinh dưỡng', 'trứ danh', 'đơn giản', 'tại nhà', 'nhanh gọn', 'đặc biệt', 'độc đáo', 'tuyệt vời', 'nước sệt',
  'công thức', 'ngon', 'giòn', 'mềm', 'béo', 'dẻo', 'siêu', 'cực'
];
// Vị là một phần tên món khi có động từ nấu trong 2 từ đứng trước ("rim mặn ngọt", "ngâm giấm chua ngọt"); ở chỗ khác là lời khen
const TASTES = ['mặn ngọt', 'chua ngọt', 'chua cay'];
const PROPER = ['Huế', 'Dương Châu', 'Mông Cổ', 'Campuchia', 'Thái', 'Hà Nội', 'Sài Gòn', 'Hàn Quốc', 'Nhật', 'Nam Bộ', 'Singapore'];

const wordRe = (p) => new RegExp('(?<![\\p{L}])' + p.replace(/\s+/g, '\\s+') + '(?![\\p{L}])', 'giu');

function normalizeDishName(title) {
  // Tách tiền tố 'Cách <động từ>' TRƯỚC cleanTitle, vì cleanTitle xóa luôn động từ ('Cách Xào Miến' -> 'Miến')
  let t = title.replace(/\s+/g, ' ').trim();
  let verb = null;
  t = t.replace(/^(?:cách\s+(?:mới\s+)?|công\s+thức\s+|bí\s+quyết\s+|mẹo\s+|hướng\s+dẫn\s+(?:cách\s+)?|mách\s+bạn\s+(?:cách\s+)?)(?:(làm|nấu|\p{L}+)\s+)?/iu, (m, v) => {
    // 'nấu' quá chung ('Cách nấu phở' -> 'Phở'), chỉ giữ động từ mang nghĩa món ('Cách xào miến' -> 'Miến xào')
    if (v && COOK_VERBS.includes(v.toLowerCase()) && v.toLowerCase() !== 'nấu') verb = v.toLowerCase();
    else if (v && v.toLowerCase() === 'nấu') return '';
    else if (v && !['làm', 'nấu'].includes(v.toLowerCase())) return v + ' '; // 'Công thức sốt trộn' -> giữ 'sốt'
    return '';
  });
  t = cleanTitle(t).split(/\s[–—-]\s|[,:|!]/)[0];
  for (const taste of TASTES) {
    t = t.replace(wordRe(taste), (m, off, s) => {
      const before = s.slice(0, off).trim().toLowerCase().split(/\s+/).slice(-2);
      return before.some((w) => COOK_VERBS.includes(w)) ? m : ' ';
    });
  }
  for (const p of PRAISE) t = t.replace(wordRe(p), ' ');
  t = t.replace(/\s+/g, ' ').trim();
  if (verb && !COOK_VERBS.some((v) => wordRe(v).test(t))) t = `${t} ${verb}`;
  t = t.toLowerCase();
  for (const p of PROPER) t = t.replace(wordRe(p.toLowerCase()), p);
  return t.charAt(0).toUpperCase() + t.slice(1);
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

  return { title, name: normalizeDishName(rawTitle), rawIngredients, steps, servings, prepTime, cookTime, category };
}

module.exports = { parseRecipeUnified, cleanHtml, cleanTitle, normalizeDishName };
