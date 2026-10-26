// Sinh SQL map lại recipe_ingredients bằng ingredient_parser đã sửa, rồi tính lại dinh dưỡng + dị ứng của món.
// Input: JSON xuất từ DB
//   supabase db query --linked "select r.slug, x.order_index, x.ingredient_name_raw from recipe_ingredients x
//     join recipes r on r.id = x.recipe_id" -o json > rows.json
// Chạy: node remap_recipe_ingredients.js rows.json > ../migrations/<timestamp>_remap_recipe_ingredients.sql
const fs = require('fs');
const { lookupIngredient, keywordAllergenCodes, condimentAllergenCodes, catalog } = require('./ingredient_parser');

const raw = fs.readFileSync(process.argv[2], 'utf8');
const rows = JSON.parse(raw.slice(raw.indexOf('{'))).rows;
const q = (s) => "'" + String(s).replace(/'/g, "''") + "'";

const rice = catalog.find((i) => i.code === 'X01004');
const mapRows = [];
const allergenRows = new Set();
for (const r of rows) {
  const ing = lookupIngredient(r.ingredient_name_raw);
  mapRows.push(`(${q(r.slug)}, ${r.order_index}, ${ing ? q(ing.code) : 'NULL'})`);
  for (const code of keywordAllergenCodes(r.ingredient_name_raw)) allergenRows.add(`(${q(r.slug)}, ${q(code)}, false)`);
  for (const code of condimentAllergenCodes(r.ingredient_name_raw)) allergenRows.add(`(${q(r.slug)}, ${q(code)}, true)`);
}

process.stdout.write(`-- Sinh bởi supabase/scripts/remap_recipe_ingredients.js. KHÔNG sửa tay: sửa từ điển trong ingredient_parser.js rồi sinh lại.
-- Lý do: từ điển cũ trỏ sai mã FCT (vd 'gà' -> Thịt cừu, 'lạc' -> Quả đại, 'mè' -> Bột đậu xanh, 'dầu ăn' -> Dầu lạc+vừng)
-- và bỏ sót nhiều nguyên liệu (cá, mắm, tàu hủ ky) -> sai calo và thiếu/thừa tag dị ứng.

-- Nguyên liệu quy đổi: FCT chỉ có gạo sống, công thức ghi khối lượng cơm chín (gạo tẻ máy ÷ 2,6)
INSERT INTO public.ingredients (id, code, name_vi, name_unaccented, category_id, calories_per_100g, protein_per_100g,
    fat_per_100g, carbs_per_100g, fiber_per_100g, sodium_mg, edible_portion_pct, density_g_per_ml)
VALUES (${q(rice.id)}, ${q(rice.code)}, ${q(rice.name_vi)}, ${q(rice.name_unaccented)}, ${rice.category_id}, ${rice.calories_per_100g},
    ${rice.protein_per_100g}, ${rice.fat_per_100g}, ${rice.carbs_per_100g}, ${rice.fiber_per_100g}, ${rice.sodium_mg}, 100, 1)
ON CONFLICT (code) DO NOTHING;

CREATE TEMP TABLE remap (slug TEXT, order_index INT, code TEXT) ON COMMIT DROP;
INSERT INTO remap VALUES
${mapRows.join(',\n')};

UPDATE public.recipe_ingredients x
   SET ingredient_id = i.id,
       calories_per_100g = COALESCE(i.calories_per_100g, 0), protein_per_100g = COALESCE(i.protein_per_100g, 0),
       fat_per_100g = COALESCE(i.fat_per_100g, 0), carbs_per_100g = COALESCE(i.carbs_per_100g, 0),
       fiber_per_100g = COALESCE(i.fiber_per_100g, 0), sodium_mg_per_100g = COALESCE(i.sodium_mg, 0)
  FROM remap m
  JOIN public.recipes r ON r.slug = m.slug
  LEFT JOIN public.ingredients i ON i.code = m.code
 WHERE x.recipe_id = r.id AND x.order_index = m.order_index;

-- Tính lại dinh dưỡng món giống create_recipe_with_nutrition
UPDATE public.recipes r
   SET total_calories = t.cal, total_protein_g = t.prot, total_fat_g = t.fat, total_carbs_g = t.carbs,
       total_fiber_g = t.fiber, total_sodium_mg = t.sod,
       calories_per_serving = round(t.cal / r.servings, 1), protein_g_per_serving = round(t.prot / r.servings, 1),
       fat_g_per_serving = round(t.fat / r.servings, 1), carbs_g_per_serving = round(t.carbs / r.servings, 1),
       fiber_g_per_serving = round(t.fiber / r.servings, 1), sodium_mg_per_serving = round(t.sod / r.servings, 1),
       updated_at = now()
  FROM (SELECT recipe_id,
               round(sum(amount_g * calories_per_100g / 100), 1) AS cal, round(sum(amount_g * protein_per_100g / 100), 1) AS prot,
               round(sum(amount_g * fat_per_100g / 100), 1) AS fat, round(sum(amount_g * carbs_per_100g / 100), 1) AS carbs,
               round(sum(amount_g * fiber_per_100g / 100), 1) AS fiber, round(sum(amount_g * sodium_mg_per_100g / 100), 1) AS sod
          FROM public.recipe_ingredients GROUP BY recipe_id) t
 WHERE t.recipe_id = r.id;

-- Dị ứng = kế thừa từ nguyên liệu đã map ∪ từ khóa trên tên nguyên liệu (bắt cả dòng không map được).
-- via_condiment = true khi chất dị ứng CHỈ đến từ gia vị chế biến sẵn (nhóm FCT 13: nước mắm, mắm tôm, xì dầu...; hoặc từ khóa gia vị):
-- vẫn lọc khi người dùng dị ứng, nhưng món không bị coi là "món hải sản".
CREATE TEMP TABLE keyword_allergens (slug TEXT, code TEXT, via_condiment BOOLEAN) ON COMMIT DROP;
INSERT INTO keyword_allergens VALUES
${[...allergenRows].join(',\n')};

DELETE FROM public.recipe_allergens WHERE recipe_id IN (SELECT r.id FROM public.recipes r JOIN remap m ON m.slug = r.slug);
INSERT INTO public.recipe_allergens (recipe_id, allergen_id, via_condiment)
SELECT recipe_id, allergen_id, bool_and(via_condiment)
  FROM (SELECT x.recipe_id, ia.allergen_id, i.code LIKE '13%' AS via_condiment
          FROM public.recipe_ingredients x
          JOIN public.ingredients i ON i.id = x.ingredient_id
          JOIN public.ingredient_allergens ia ON ia.ingredient_id = x.ingredient_id
        UNION ALL
        SELECT r.id, a.id, k.via_condiment
          FROM keyword_allergens k JOIN public.recipes r ON r.slug = k.slug JOIN public.allergens a ON a.code = k.code) src
 GROUP BY recipe_id, allergen_id
ON CONFLICT DO NOTHING;
`);
