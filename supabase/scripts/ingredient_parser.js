const fs = require('fs');
const path = require('path');

// 1. Load database catalogs
const catalogPath = path.join(__dirname, '../data/ingredients_catalog.json');
const allergensPath = path.join(__dirname, '../data/allergens.json');
const ingrAllergensPath = path.join(__dirname, '../data/ingredient_allergens.json');

const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
const allergens = JSON.parse(fs.readFileSync(allergensPath, 'utf8'));
const ingrAllergens = JSON.parse(fs.readFileSync(ingrAllergensPath, 'utf8'));

// Build lookup maps
const ingredientByCode = new Map(catalog.map(i => [i.code, i]));
const ingredientById = new Map(catalog.map(i => [i.id, i]));
const allergensByIngrId = new Map();
for (const link of ingrAllergens) {
  if (!allergensByIngrId.has(link.ingredient_id)) {
    allergensByIngrId.set(link.ingredient_id, []);
  }
  allergensByIngrId.get(link.ingredient_id).push(link.allergen_id);
}

// 2. Comprehensive Vietnamese culinary synonym dictionary mapped to ingredient codes
const RAW_SYNONYMS = [
  // Eggs (Priority over chicken)
  ['lòng đỏ trứng gà', '09002'],
  ['lòng đỏ trứng vịt', '09005'],
  ['lòng đỏ trứng', '09002'],
  ['lòng đỏ', '09002'],
  ['lòng trắng trứng gà', '09003'],
  ['lòng trắng trứng', '09003'],
  ['lòng trắng', '09003'],
  ['trứng gà ta', '09001'],
  ['trứng gà công nghiệp', '09012'],
  ['trứng gà', '09001'],
  ['hột gà', '09001'],
  ['trứng vịt', '09004'],
  ['hột vịt', '09004'],
  ['trứng cút', '09009'],
  ['trứng', '09001'],

  // Pork
  ['thịt ba rọi rút sườn', '07018'],
  ['thịt ba chỉ', '07018'],
  ['thịt ba rọi', '07018'],
  ['thịt lợn ba chỉ', '07018'],
  ['ba rọi heo', '07018'],
  ['ba chỉ heo', '07018'],
  ['ba rọi', '07018'],
  ['ba chỉ', '07018'],
  ['thịt nạc dăm', '07083'],
  ['thịt nạc vai', '07083'],
  ['nạc dăm', '07083'],
  ['nạc vai', '07083'],
  ['thịt nạc đùi', '07084'],
  ['thịt nạc thăn', '07085'],
  ['thịt thăn heo', '07085'],
  ['thịt thăn', '07085'],
  ['sườn cốt lết', '07083'],
  ['sườn non', '07053'],
  ['sườn que', '07053'],
  ['sườn heo', '07053'],
  ['sườn lợn', '07053'],
  ['sườn cọng', '07053'],
  ['sườn', '07053'],
  ['thịt heo xay', '07017'],
  ['thịt heo bằm', '07017'],
  ['thịt lợn nạc', '07017'],
  ['thịt nạc heo', '07017'],
  ['thịt xay', '07017'],
  ['thịt bằm', '07017'],
  ['thịt nạc', '07017'],
  ['thịt heo', '07017'],
  ['thịt lợn', '07017'],
  ['chân giò heo', '07032'],
  ['chân giò', '07032'],
  ['móng giò', '07032'],
  ['da heo', '07031'],
  ['bì heo', '07031'],
  ['mỡ heo', '06003'],
  ['mỡ lợn', '06003'],
  ['tai heo', '07054'],
  ['tai lợn', '07054'],
  ['dạ dày heo', '07034'],
  ['gan heo', '07041'],
  ['gan lợn', '07041'],
  ['lòng non', '07047'],
  ['chả lụa', '07064'],
  ['giò lụa', '07064'],

  // Beef
  ['thịt bò phi lê', '07003'],
  ['thịt bò xay', '07003'],
  ['thịt bò bằm', '07003'],
  ['thịt bò nạc', '07003'],
  ['thịt bò', '07003'],
  ['thăn bò', '07003'],
  ['bắp bò', '07002'],
  ['gân bò', '07002'],
  ['nạm bò', '07002'],
  ['dẻ sườn bò', '07002'],
  ['bò phi lê', '07003'],
  ['thịt bò', '07003'],
  ['bò', '07003'],

  // Chicken & Poultry
  ['thịt gà ta', '07010'],
  ['lòng gà', '07082'],
  ['mề gà', '07082'],
  ['ức gà', '07010'],
  ['đùi gà', '07010'],
  ['cánh gà', '07010'],
  ['chân gà', '07010'],
  ['thịt gà', '07010'],
  ['gà ta', '07010'],
  ['gà', '07010'],
  ['thịt vịt', '07022'],
  ['vịt', '07022'],

  // Seafood & Fish
  ['tôm sú tươi', '08051'],
  ['tôm sú', '08051'],
  ['tôm thẻ', '08051'],
  ['tôm đồng', '08052'],
  ['tôm tươi', '08052'],
  ['tôm khô', '08053'],
  ['tôm', '08052'],
  ['tép', '08052'],
  ['mực ống', '08040'],
  ['mực lá', '08040'],
  ['mực tươi', '08040'],
  ['mực khô', '08039'],
  ['mực', '08040'],
  ['cua đồng', '08013'],
  ['thịt cua', '08011'],
  ['cua biển', '08011'],
  ['cua', '08011'],
  ['ghẹ', '08014'],
  ['cá nục', '08020'],
  ['cá lóc', '08030'],
  ['cá quả', '08030'],
  ['cá diêu hồng', '08037'],
  ['cá điêu hồng', '08037'],
  ['cá rô phi', '08037'],
  ['cá bớp', '08001'],
  ['cá basa', '08003'],
  ['cá ba sa', '08003'],
  ['cá hú', '08003'],
  ['cá thu', '08044'],
  ['cá trắm', '08029'],
  ['cá chép', '08003'],
  ['cá trê', '08030'],
  ['cá bống', '08001'],
  ['cá chốt', '08001'],
  ['cá chim', '08001'],
  ['cá kìm', '08001'],
  ['lươn', '08026'],
  ['nghêu', '08033'],
  ['ngao', '08033'],
  ['sò huyết', '08041'],
  ['ốc', '08035'],

  // Tofu & Soy
  ['đậu hũ non', '03025'],
  ['đậu hũ chiên', '03027'],
  ['đậu hũ trắng', '03025'],
  ['đậu hũ', '03025'],
  ['đậu phụ', '03025'],
  ['tàu hũ ky', '03026'],
  ['tàu hũ', '03025'],
  ['váng đậu', '03026'],

  // Vegetables & Roots
  ['cà chua', '04005'],
  ['cà rốt', '04007'],
  ['khoai tây', '02008'],
  ['khoai lang', '02007'],
  ['khoai môn', '02005'],
  ['khoai sọ', '02006'],
  ['bí đỏ', '04005'],
  ['bí xanh', '04004'],
  ['bí đao', '04004'],
  ['khổ qua', '04055'],
  ['mướp đắng', '04055'],
  ['mướp', '04054'],
  ['bầu', '04003'],
  ['rau muống', '04083'],
  ['rau ngót', '04086'],
  ['rau mồng tơi', '04080'],
  ['mồng tơi', '04080'],
  ['rau dền', '04070'],
  ['cải ngọt', '04018'],
  ['cải thìa', '04018'],
  ['cải bẹ xanh', '04018'],
  ['cải xanh', '04018'],
  ['cải thảo', '04019'],
  ['bắp cải', '04001'],
  ['giá đỗ', '04040'],
  ['giá', '04040'],
  ['dưa leo', '04036'],
  ['dưa chuột', '04036'],
  ['cà tím', '04014'],
  ['đậu cô ve', '04029'],
  ['đậu que', '04029'],
  ['đậu hà lan', '04031'],
  ['bông cải xanh', '04009'],
  ['súp lơ', '04009'],
  ['cần tây', '04021'],
  ['cần nước', '04020'],
  ['nấm rơm', '04129'],
  ['nấm đông cô', '04057'],
  ['nấm hương', '04057'],
  ['nấm mèo', '04056'],
  ['mộc nhĩ', '04056'],
  ['nấm kim châm', '04129'],
  ['nấm bào ngư', '04129'],
  ['nấm đùi gà', '04129'],
  ['nấm', '04129'],
  ['hành tây', '04039'],
  ['hành hoa', '04038'],
  ['hành lá', '04038'],
  ['hành tím', '04037'],
  ['hành khô', '04037'],
  ['hành củ', '04037'],
  ['tỏi tây', '04104'],
  ['tỏi băm', '04103'],
  ['tỏi', '04103'],
  ['gừng tươi', '13003'],
  ['gừng', '13003'],
  ['sả băm', '04038'],
  ['sả cây', '04038'],
  ['sả', '04038'],
  ['ớt chuông', '04061'],
  ['ớt hiểm', '04061'],
  ['ớt sừng', '04061'],
  ['ớt đỏ', '04061'],
  ['ớt bột', '13008'],
  ['ớt', '04061'],
  ['ngò gai', '04071'],
  ['ngò rí', '04071'],
  ['rau mùi', '04071'],
  ['rau ngổ', '04071'],
  ['thì là', '04071'],
  ['nước cốt chanh', '05004'],
  ['chanh', '05004'],
  ['quất', '05004'],
  ['tắc', '05004'],
  ['dứa', '05014'],
  ['thơm', '05014'],
  ['khóm', '05014'],
  ['nước cốt me', '05028'],
  ['me chua', '05028'],
  ['me', '05028'],
  ['chuối', '05007'],
  ['bắp ngọt', '01011'],
  ['bắp', '01011'],
  ['ngô', '01011'],
  ['măng chua', '04050'],
  ['măng tươi', '04050'],
  ['măng', '04050'],

  // Condiments & Seasonings
  ['dầu thực vật', '06002'],
  ['dầu đậu phộng', '06002'],
  ['dầu mè', '06002'],
  ['dầu ăn', '06002'],
  ['dầu hào', '13022'],
  ['nước mắm cốt', '13014'],
  ['nước mắm cá', '13014'],
  ['nước mắm loại i', '13015'],
  ['nước mắm', '13015'],
  ['nước tương', '13022'],
  ['xì dầu', '13022'],
  ['đường thốt nốt', '12014'],
  ['đường phèn', '12014'],
  ['đường cát', '12013'],
  ['đường kính', '12014'],
  ['đường', '12014'],
  ['muối ăn', '13005'],
  ['muối', '13005'],
  ['hạt tiêu', '13004'],
  ['tiêu xay', '13004'],
  ['tiêu đen', '13004'],
  ['tiêu', '13004'],
  ['hạt nêm', '13005'],
  ['bột nêm', '13005'],
  ['bột ngọt', '13005'],
  ['mì chính', '13005'],
  ['tương ớt', '13021'],
  ['tương cà', '04005'],
  ['nước màu thốt nốt', '12014'],
  ['nước màu', '12014'],
  ['mắm tôm đặc', '13011'],
  ['mắm tôm', '13011'],
  ['mắm tép', '13013'],
  ['nước dừa tươi', '14002'],
  ['nước dừa', '14002'],
  ['nước mía', '12014'],
  ['nước cốt dừa', '03004'],
  ['hạt mè', '03023'],
  ['mè rang', '03023'],
  ['mè', '03023'],
  ['vừng', '03023'],
  ['đậu phộng', '03019'],
  ['lạc', '03019'],
  ['bột chiên giòn', '01010'],
  ['bột bắp', '01010'],
  ['bột năng', '01010'],

  // Carbs / Staples
  ['cơm nguội', '01003'],
  ['cơm', '01003'],
  ['gạo tẻ', '01003'],
  ['gạo nếp', '01002'],
  ['gạo', '01003'],
  ['bún tươi', '01020'],
  ['bún', '01020'],
  ['bánh phở', '01013'],
  ['phở', '01013'],
  ['miến dong', '02015'],
  ['miến', '02015'],
  ['mì trứng', '01014'],
  ['mì sợi', '01014'],
  ['mì gói', '01014'],
  ['mì', '01014'],
  ['bánh mì', '01006']
];

// Sort synonyms strictly by phrase length descending (longest, most specific first)
const SYNONYMS = RAW_SYNONYMS.sort((a, b) => b[0].length - a[0].length);

function stripAccents(str) {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .trim();
}

function parseIngredientLine(raw) {
  let line = raw.trim();
  let name = "";
  let qty = 1;
  let unit = "phần";
  let grams = 0;
  let notes = "";

  if (line.includes(':')) {
    const parts = line.split(':');
    name = parts[0].trim();
    const rest = parts.slice(1).join(':').trim();
    
    const parenGrams = rest.match(/\((\d+(?:\.\d+)?)\s*(?:g|gram|gam)\)/i);
    if (parenGrams) {
      grams = parseFloat(parenGrams[1]);
    }

    const qtyMatch = rest.match(/^(\d+(?:\/\d+|\.\d+)?)\s*([a-zA-Z\u00C0-\u1EF9]+(?:\s+[a-zA-Z\u00C0-\u1EF9]+)?)?/);
    if (qtyMatch) {
      let numStr = qtyMatch[1];
      if (numStr.includes('/')) {
        const [num, den] = numStr.split('/').map(Number);
        qty = num / den;
      } else {
        qty = parseFloat(numStr);
      }
      if (qtyMatch[2]) {
        unit = qtyMatch[2].toLowerCase().trim();
      }
    }
    notes = rest;
  } else {
    const numUnitRegex = /^(\d+(?:\/\d+|\.\d+)?)\s*(kg|kí|ký|g|gram|gam|ml|l|lít|muỗng canh|thìa canh|muỗng cà phê|thìa cà phê|muỗng súp|muỗng cafe|tbsp|tsp|chén|bát|tép|củ|trái|quả|cây|nhánh|miếng|bó|lát)\s+(.*)$/i;
    const match = line.match(numUnitRegex);
    if (match) {
      let numStr = match[1];
      if (numStr.includes('/')) {
        const [num, den] = numStr.split('/').map(Number);
        qty = num / den;
      } else {
        qty = parseFloat(numStr);
      }
      unit = match[2].trim().toLowerCase();
      name = match[3].split(',')[0].trim();
      notes = line;
    } else {
      const attachedMatch = line.match(/^(\d+(?:\.\d+)?)(kg|kí|ký|g|gram|gam|ml|l)\s+(.*)$/i);
      if (attachedMatch) {
        qty = parseFloat(attachedMatch[1]);
        unit = attachedMatch[2].trim().toLowerCase();
        name = attachedMatch[3].split(',')[0].trim();
        notes = line;
      } else {
        const numOnlyMatch = line.match(/^(\d+(?:\/\d+|\.\d+)?)\s+(.*)$/);
        if (numOnlyMatch) {
          qty = parseFloat(numOnlyMatch[1]);
          unit = "phần";
          name = numOnlyMatch[2].split(',')[0].trim();
          notes = line;
        } else {
          name = line.split(',')[0].trim();
          qty = 1;
          unit = "ít";
          notes = line;
        }
      }
    }
  }

  // Grams conversion
  if (grams === 0) {
    const u = unit.toLowerCase();
    const n = name.toLowerCase();

    if (u === 'g' || u === 'gram' || u === 'gam') {
      grams = qty;
    } else if (u === 'kg' || u === 'kí' || u === 'ký') {
      grams = qty * 1000;
    } else if (u === 'ml' || u === 'mililit') {
      grams = qty;
    } else if (u === 'l' || u === 'lít') {
      grams = qty * 1000;
    } else if (u.includes('muỗng canh') || u.includes('thìa canh') || u.includes('súp') || u.includes('tbsp')) {
      grams = qty * 15;
    } else if (u.includes('muỗng cà phê') || u.includes('thìa cà phê') || u.includes('tsp') || u.includes('cafe')) {
      grams = qty * 5;
    } else if (u.includes('chén') || u.includes('bát')) {
      grams = qty * 200;
    } else if (u.includes('tép')) {
      grams = qty * 5;
    } else if (u.includes('củ')) {
      if (n.includes('hành tím') || n.includes('hành khô')) grams = qty * 15;
      else if (n.includes('hành tây')) grams = qty * 120;
      else if (n.includes('gừng')) grams = qty * 20;
      else if (n.includes('cà rốt')) grams = qty * 100;
      else if (n.includes('khoai tây')) grams = qty * 150;
      else grams = qty * 50;
    } else if (u.includes('trái') || u.includes('quả')) {
      if (n.includes('trứng gà')) grams = qty * 50;
      else if (n.includes('trứng vịt')) grams = qty * 65;
      else if (n.includes('cà chua')) grams = qty * 75;
      else if (n.includes('ớt')) grams = qty * 5;
      else if (n.includes('chanh') || n.includes('tắc')) grams = qty * 30;
      else if (n.includes('khổ qua')) grams = qty * 150;
      else if (n.includes('dưa leo')) grams = qty * 100;
      else grams = qty * 60;
    } else if (u.includes('cây') || u.includes('nhánh')) {
      if (n.includes('sả')) grams = qty * 25;
      else if (n.includes('hành lá')) grams = qty * 15;
      else if (n.includes('cần')) grams = qty * 30;
      else grams = qty * 20;
    } else if (u.includes('miếng')) {
      if (n.includes('đậu hũ') || n.includes('đậu phụ')) grams = qty * 100;
      else grams = qty * 50;
    } else if (u.includes('bó')) {
      grams = qty * 300;
    } else if (u.includes('lát')) {
      grams = qty * 5;
    } else if (u.includes('ít') || u.includes('chút') || u.includes('nhúm')) {
      grams = 2;
    } else {
      grams = qty > 20 ? qty : qty * 30;
    }
  }

  // Lookup matching ingredient
  let matchedIngredient = null;
  const cleanNameLower = name.toLowerCase().trim();

  // 1. Direct synonym lookup: match if cleanNameLower includes synonym (checked from longest to shortest)
  for (const [synonym, code] of SYNONYMS) {
    if (cleanNameLower.includes(synonym)) {
      matchedIngredient = ingredientByCode.get(code);
      if (matchedIngredient) break;
    }
  }

  // 2. Unaccented match against catalog
  if (!matchedIngredient) {
    const unaccented = stripAccents(name);
    if (unaccented.length > 2 && !['nuoc loc', 'nuoc soi', 'gia vi'].includes(unaccented)) {
      matchedIngredient = catalog.find(i => i.name_unaccented === unaccented) ||
                          catalog.find(i => i.name_unaccented.startsWith(unaccented)) ||
                          catalog.find(i => i.name_unaccented.includes(unaccented));
    }
  }

  return {
    raw_text: raw,
    ingredient_name_raw: name || raw,
    amount: Math.round(qty * 100) / 100,
    unit: unit,
    amount_g: Math.round(grams * 10) / 10,
    matched_ingredient_id: matchedIngredient ? matchedIngredient.id : null,
    matched_ingredient_code: matchedIngredient ? matchedIngredient.code : null,
    matched_ingredient_name: matchedIngredient ? matchedIngredient.name_vi : null,
    calories_per_100g: matchedIngredient ? Number(matchedIngredient.calories_per_100g) : 0,
    protein_per_100g: matchedIngredient ? Number(matchedIngredient.protein_per_100g) : 0,
    fat_per_100g: matchedIngredient ? Number(matchedIngredient.fat_per_100g) : 0,
    carbs_per_100g: matchedIngredient ? Number(matchedIngredient.carbs_per_100g) : 0,
    fiber_per_100g: matchedIngredient ? Number(matchedIngredient.fiber_per_100g) : 0,
    sodium_mg_per_100g: matchedIngredient ? Number(matchedIngredient.sodium_mg) : 0
  };
}

module.exports = {
  parseIngredientLine,
  stripAccents,
  catalog,
  allergensByIngrId
};
