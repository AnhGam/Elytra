// Dựng lại DB từ toàn bộ migrations trên Postgres WASM rồi kiểm các lỗi đã sửa (docs/week7-8/AUDIT_REPORT.md).
// Chạy: cd <thư mục tạm> && npm i @electric-sql/pglite@0.2 && node <repo>/supabase/scripts/test_migrations_replay.mjs
import { PGlite } from "@electric-sql/pglite";
import { readFileSync, readdirSync } from "node:fs";
import assert from "node:assert/strict";

const dir = new URL("../migrations/", import.meta.url);
const db = new PGlite();

// Stub phần Supabase mà migrations dùng
await db.exec(`
  CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role;
  CREATE SCHEMA auth; CREATE SCHEMA storage; CREATE SCHEMA extensions;
  CREATE TABLE auth.users (id uuid PRIMARY KEY, email text, raw_user_meta_data jsonb);
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('test.uid', true), '')::uuid $$;
  CREATE TABLE storage.buckets (id text PRIMARY KEY, name text, public bool);
  CREATE TABLE storage.objects (id uuid DEFAULT gen_random_uuid(), bucket_id text, name text);
  ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY; ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
  CREATE FUNCTION f_unaccent(text) RETURNS text LANGUAGE sql AS $$ SELECT $1 $$;
`);
for (const f of readdirSync(dir).filter((f) => f.endsWith(".sql")).sort()) {
  try {
    await db.exec(readFileSync(new URL(f, dir), "utf8"));
  } catch (e) {
    throw new Error(`${f}: ${e.message}`);
  }
}
const rows = async (sql, p = []) => (await db.query(sql, p)).rows;
const one = async (sql, p = []) => (await rows(sql, p))[0];
const allergensOf = async (slugLike) => (await one(`SELECT array_agg(a.code ORDER BY a.code) AS c FROM recipes r
  JOIN recipe_allergens ra ON ra.recipe_id = r.id JOIN allergens a ON a.id = ra.allergen_id WHERE r.slug LIKE $1`, [slugLike])).c ?? [];

// V1: dị ứng và dinh dưỡng sau khi map lại
assert.ok((await allergensOf("ca-bien-kho%")).includes("seafood"), "cá biển kho phải có seafood");
assert.ok((await allergensOf("cach-nau-mam-kho%")).includes("seafood"), "mắm kho phải có seafood");
assert.deepEqual(await allergensOf("ca-bien-kho%"), ["seafood"], "cá biển kho chỉ có seafood (không còn soy do chữ 'tương tự')");
assert.ok((await one(`SELECT 1 AS x FROM ingredient_allergens ia JOIN ingredients i ON i.id = ia.ingredient_id JOIN allergens a ON a.id = ia.allergen_id WHERE i.code = '03020' AND a.code = 'sesame'`))?.x, "Vừng phải có tag sesame");
assert.ok((await allergensOf("cach-nau-bun-bo-hue-chay%")).includes("soy"), "bún bò Huế chay phải có soy");
const pho = await rows(`SELECT r.slug FROM recipes r WHERE EXISTS (SELECT 1 FROM recipe_ingredients x WHERE x.recipe_id = r.id AND x.ingredient_name_raw ~* '(^|[^[:alpha:]])(mè|vừng)([^[:alpha:]]|$)')`);
for (const r of pho) assert.ok((await allergensOf(r.slug)).includes("sesame"), r.slug + " có mè phải có sesame");
const oilOnly = await one(`SELECT count(*)::int AS n FROM recipe_ingredients x JOIN ingredients i ON i.id = x.ingredient_id WHERE i.code = '06002'`);
assert.equal(oilOnly.n, 0, "dầu ăn không còn map vào Dầu thảo mộc (lạc, vừng)");
const lamb = await one(`SELECT count(*)::int AS n FROM recipe_ingredients x JOIN ingredients i ON i.id = x.ingredient_id
  WHERE i.code IN ('07010', '07022', '14002', '01006', '03019')`);
assert.equal(lamb.n, 0, "không còn map sang thịt cừu/thỏ/cô nhắc/kê/quả đại");
const fish = await one(`SELECT calories_per_serving::float AS k FROM recipes WHERE slug LIKE 'ca-bien-kho%'`);
assert.ok(fish.k > 200, "cá biển kho phải tính cả 700 g cá, đang là " + fish.k);
const consistent = await one(`SELECT count(*)::int AS n FROM recipes r WHERE abs(r.total_calories -
  (SELECT coalesce(sum(amount_g * consumed_pct / 100 * calories_per_100g / 100), 0) FROM recipe_ingredients WHERE recipe_id = r.id)) > 1`);
// Phần ăn vào: nguyên con/có xương thì trừ theo edible_portion_pct, đã sơ chế hoặc đong muỗng thì 100%
const pct = async (slugLike, raw) => Number((await one(`SELECT x.consumed_pct AS p FROM recipe_ingredients x JOIN recipes r ON r.id = x.recipe_id
  WHERE r.slug LIKE $1 AND x.ingredient_name_raw = $2`, [slugLike, raw])).p);
assert.equal(await pct("cach-nau-duoi-heo%", "đuôi heo"), 70);
assert.equal(await pct("ca-bien-kho%", "Cá ngân (hoặc cá biển thịt chắc tương tự)"), 73);
assert.equal(await pct("ca-bien-kho%", "Tỏi băm"), 100);
const duoi = Number((await one(`SELECT calories_per_serving AS k FROM recipes WHERE slug LIKE 'cach-nau-duoi-heo%'`)).k);
assert.ok(duoi < 1100, "đuôi heo hầm phải trừ xương, đang là " + duoi);
assert.equal(consistent.n, 0, "total_calories khớp tổng nguyên liệu");

// Gia vị từ hải sản (nước mắm...) vẫn gây dị ứng nhưng không làm món thành "món hải sản" (via_condiment)
const viaOf = async (slugLike) => (await one(`SELECT ra.via_condiment AS v FROM recipe_allergens ra JOIN recipes r ON r.id = ra.recipe_id
  JOIN allergens a ON a.id = ra.allergen_id WHERE a.code = 'seafood' AND r.slug LIKE $1`, [slugLike]))?.v;
assert.equal(await viaOf("ca-bien-kho%"), false, "cá biển kho: hải sản là nguyên liệu chính");
assert.equal(await viaOf("-cong-thuc-sot-tron-hu-tieu-ga%"), true, "hủ tiếu gà: seafood chỉ đến từ nước mắm");
const ga = await one(`SELECT allergens, condiment_allergens FROM search_recipes(p_query => 'hủ tiếu gà')`);
assert.ok(ga.allergens.includes(1) && ga.condiment_allergens.includes(1), "search_recipes trả cả 2 danh sách");
assert.equal((await rows(`SELECT 1 FROM search_recipes(p_exclude_allergen_ids => ARRAY[1], p_limit => 100) WHERE slug LIKE '-cong-thuc-sot-tron-hu-tieu-ga%'`)).length, 0,
  "người dị ứng hải sản vẫn không thấy món có nước mắm");

// V1 tái phát: recipe mới phải gắn nguyên liệu có thật
const rid = (await one(`SELECT id FROM recipes LIMIT 1`)).id;
await assert.rejects(db.query(`INSERT INTO recipe_ingredients (recipe_id, raw_text, ingredient_name_raw, amount_g) VALUES ($1, 'x', 'x', 10)`, [rid]), /INGREDIENT_NOT_FOUND/);

// V14: món chưa duyệt không xuất hiện trong search_recipes
await db.query(`UPDATE recipes SET is_verified = false WHERE id = $1`, [rid]);
assert.equal((await rows(`SELECT * FROM search_recipes(p_limit => 1000) WHERE id = $1`, [rid])).length, 0);
await db.query(`UPDATE recipes SET is_verified = true WHERE id = $1`, [rid]);

// V12: nguyên liệu vô hiệu không trả chi tiết
const ing = (await one(`SELECT id FROM ingredients LIMIT 1`)).id;
await db.query(`UPDATE ingredients SET is_active = false WHERE id = $1`, [ing]);
assert.equal((await one(`SELECT get_ingredient_details($1) AS d`, [ing])).d, null);
await db.query(`UPDATE ingredients SET is_active = true WHERE id = $1`, [ing]);

// V7: profiles chặn giá trị vô lý
const uid = "00000000-0000-0000-0000-0000000000aa";
await db.query(`INSERT INTO auth.users VALUES ($1, 'a@x.test', '{}')`, [uid]);
await assert.rejects(db.query(`UPDATE profiles SET target_calories = -5000 WHERE id = $1`, [uid]), /profiles_targets_range/);
await assert.rejects(db.query(`UPDATE profiles SET age = -3 WHERE id = $1`, [uid]), /profiles_age_range/);
await db.query(`UPDATE profiles SET target_calories = 2000, target_protein_g = 100, target_carbs_g = 200, target_fat_g = 60 WHERE id = $1`, [uid]);

await db.query(`SELECT set_config('test.uid', $1, false)`, [uid]);
const egg = (await one(`SELECT id FROM ingredients WHERE code = '09001'`)).id;

// V6: sửa khẩu phần nhiều lần không còn trôi số
const it = (await one(`SELECT log_meal('snack', p_ingredient_id => $1, p_amount_g => 333) AS r`, [egg])).r.item;
for (const g of [7, 1999, 3, 1777, 13, 333]) await db.query(`SELECT update_meal_log_item($1, p_amount_g => $2)`, [it.id, g]);
const after = await one(`SELECT kcal FROM meal_log_items WHERE id = $1`, [it.id]);
assert.ok(Math.abs(Number(after.kcal) - 333 * 1.5) < 0.001, "kcal sau chuỗi PATCH = " + after.kcal);

// V5: không sửa món ngoài 30 ngày
await db.query(`UPDATE meal_logs SET log_date = vn_today() - 40`);
await assert.rejects(db.query(`SELECT update_meal_log_item($1, p_amount_g => 10)`, [it.id]), /VALIDATION_ERROR/);

// V4: ngày đã qua dùng snapshot ở cả Dashboard và lịch sử; hôm nay dùng mục tiêu hiện tại
await db.query(`UPDATE meal_logs SET log_date = vn_today() - 1`);
await db.query(`SELECT log_meal('lunch', p_ingredient_id => $1, p_amount_g => 100)`, [egg]);
await db.query(`UPDATE profiles SET target_calories = 2500 WHERE id = $1`, [uid]);
const h = (await one(`SELECT get_nutrition_history(vn_today() - 1, vn_today()) AS r`)).r;
const yesterday = (await one(`SELECT get_daily_nutrition(vn_today() - 1) AS r`)).r;
const today = (await one(`SELECT get_daily_nutrition() AS r`)).r;
assert.equal(h.days[0].target_kcal, 2000);
assert.equal(yesterday.budget.target.kcal, 2000);
assert.equal(h.days[1].target_kcal, 2500);
assert.equal(today.budget.target.kcal, 2500);

// ===== Review PR #4 =====
// B1: sàn calo cho mọi mục tiêu (nữ 80t, 140 cm, 35 kg, ít vận động: TDEE 796,8)
const tiny = (goal) => one(`SELECT calculate_nutrition_targets('female', 80, 140, 35, 'sedentary', $1) AS r`, [goal]);
assert.equal(Number((await tiny("maintain")).r.target_calories), 1200);
assert.equal(Number((await tiny("gain_weight")).r.target_calories), 1200);
await db.query(`UPDATE profiles SET target_calories = $2 WHERE id = $1`, [uid, (await tiny("maintain")).r.target_calories]);
await db.query(`UPDATE profiles SET target_calories = 2500, target_protein_g = 100 WHERE id = $1`, [uid]);

await db.query(`DELETE FROM meal_logs WHERE user_id = $1`, [uid]);
const logEgg = (args) => one(`SELECT log_meal('lunch', p_ingredient_id => $1, p_amount_g => 100${args}) AS r`, [egg]);
// R1a: gửi lại request gốc sau khi món đã bị PATCH -> trả món đã ghi, không 422
const key1 = "11111111-2222-3333-4444-555555555555";
const k1 = (await one(`SELECT log_meal('lunch', p_ingredient_id => $1, p_amount_g => 100, p_client_request_id => $2) AS r`, [egg, key1])).r;
await db.query(`SELECT update_meal_log_item($1, p_amount_g => 150)`, [k1.item.id]);
const re1 = (await one(`SELECT log_meal('lunch', p_ingredient_id => $1, p_amount_g => 100, p_client_request_id => $2) AS r`, [egg, key1])).r;
assert.equal(re1.replayed, true);
assert.equal(re1.item.amount_g, 150, "trả trạng thái hiện tại của món");
await assert.rejects(db.query(`SELECT log_meal('lunch', p_ingredient_id => $1, p_amount_g => 999, p_client_request_id => $2)`, [egg, key1]), /IDEMPOTENCY_CONFLICT/);
// R1b: không gửi date, gửi lại sau 0h -> vẫn là request cũ, không tạo bữa rỗng hôm nay
const key2 = "11111111-2222-3333-4444-666666666666";
const k2 = (await one(`SELECT log_meal('dinner', p_ingredient_id => $1, p_amount_g => 50, p_client_request_id => $2) AS r`, [egg, key2])).r;
await db.query(`UPDATE meal_logs SET log_date = vn_today() - 1 WHERE id = (SELECT meal_log_id FROM meal_log_items WHERE id = $1)`, [k2.item.id]);
const re2 = (await one(`SELECT log_meal('dinner', p_ingredient_id => $1, p_amount_g => 50, p_client_request_id => $2) AS r`, [egg, key2])).r;
assert.equal(re2.replayed, true);
assert.equal(re2.item.date, (await one(`SELECT (vn_today() - 1)::text AS d`)).d);
assert.equal((await one(`SELECT count(*)::int AS n FROM meal_logs WHERE user_id = $1 AND log_date = vn_today() AND meal_type = 'dinner'`, [uid])).n, 0);

// R2: ngày đã qua dùng snapshot cả kcal lẫn macro
await db.query(`UPDATE meal_logs SET target_kcal = 2000, target_protein_g = 90 WHERE log_date = vn_today() - 1`);
const yd = (await one(`SELECT get_daily_nutrition(vn_today() - 1) AS r`)).r.budget.target;
assert.equal(yd.kcal, 2000);
assert.equal(Number(yd.protein_g), 90, "macro ngày cũ theo snapshot");
assert.equal(Number((await one(`SELECT get_daily_nutrition() AS r`)).r.budget.target.protein_g), 100, "hôm nay theo hồ sơ");

// R3: xóa qua RPC: chặn món > 30 ngày, dọn bữa rỗng, idempotent
await db.query(`UPDATE meal_logs SET log_date = vn_today() - 40 WHERE id = (SELECT meal_log_id FROM meal_log_items WHERE id = $1)`, [k2.item.id]);
await assert.rejects(db.query(`SELECT delete_meal_log_item($1)`, [k2.item.id]), /VALIDATION_ERROR/);
const lunchLog = (await one(`SELECT meal_log_id AS id FROM meal_log_items WHERE id = $1`, [k1.item.id])).id;
await db.query(`SELECT delete_meal_log_item($1)`, [k1.item.id]);
assert.equal((await one(`SELECT count(*)::int AS n FROM meal_logs WHERE id = $1`, [lunchLog])).n, 0, "bữa rỗng bị dọn");
await db.query(`SELECT delete_meal_log_item($1)`, [k1.item.id]); // gọi lại không lỗi

// R4: % và _ là ký tự thường
assert.equal((await rows(`SELECT * FROM search_recipes(p_query => '%', p_limit => 100)`)).length, 0);
assert.equal((await rows(`SELECT * FROM search_recipes(p_query => '_', p_limit => 100)`)).length, 0);
// '%' giờ là ký tự thường: chỉ khớp 8 tên tiếng Anh có '%' thật (vd 'Cognac (32% alcohol)'), trước đây ra toàn bộ
const pctIng = await rows(`SELECT name_en FROM search_ingredients(p_query => '%', p_limit => 100)`);
assert.ok(pctIng.length === 8 && pctIng.every((x) => x.name_en.includes('%')), 'tìm % ra ' + pctIng.length);
assert.equal((await rows(`SELECT * FROM search_ingredients(p_query => '_', p_limit => 100)`)).length, 0);
// Tìm không dấu
for (const [plain, accented] of [["bo luc lac", "bò lúc lắc"], ["dau hu", "đậu hũ"], ["DAU HU", "Đậu Hũ"]]) {
  const a = (await rows(`SELECT id FROM search_recipes(p_query => $1)`, [accented])).map((x) => x.id).sort();
  const b = (await rows(`SELECT id FROM search_recipes(p_query => $1)`, [plain])).map((x) => x.id).sort();
  assert.ok(a.length > 0 && JSON.stringify(a) === JSON.stringify(b), `'${plain}' phải ra giống '${accented}'`);
}
const phoIng = (await rows(`SELECT name_vi FROM search_ingredients(p_query => 'pho')`)).map((x) => x.name_vi);
assert.ok(phoIng.indexOf("Bánh phở") >= 0 && phoIng.indexOf("Bánh phở") < phoIng.findIndex((n) => /phồng/.test(n)), "khớp nguyên từ 'phở' xếp trước 'phồng'");
// f_unaccent có thật -> create_custom_ingredient (admin) chạy được
await db.query(`SELECT create_custom_ingredient('Rau thử nghiệm', 4, 10, 1, 0, 2)`);
assert.equal((await one(`SELECT name_unaccented AS n FROM ingredients WHERE name_vi = 'Rau thử nghiệm'`)).n, "rau thu nghiem");

// Tên món đã chuẩn hóa, tiêu đề gốc còn giữ
assert.equal((await one(`SELECT count(*)::int AS n FROM recipes WHERE title ~* '(^|[^[:alpha:]])(ngon|ghiền|đậm đà|thơm lừng)([^[:alpha:]]|$)'`)).n, 0, "tên món không còn lời quảng cáo");
assert.equal((await one(`SELECT count(*)::int AS n FROM recipes WHERE source_title IS NULL`)).n, 0, "tiêu đề gốc được giữ");
assert.equal((await one(`SELECT title FROM recipes WHERE slug = 'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc'`)).title, "Cá chim kho thơm");
assert.ok((await rows(`SELECT 1 FROM search_recipes(p_query => 'bo luc lac')`)).length === 1);

// Món ăn sẵn (FCT chương XV) không còn là nguyên liệu, nhưng vẫn ghi bữa được
assert.equal((await one(`SELECT count(*)::int AS n FROM ingredients WHERE category_id = 15`)).n, 0);
assert.equal((await one(`SELECT count(*)::int AS n FROM prepared_dishes`)).n, 73);
assert.equal((await rows(`SELECT 1 FROM search_ingredients(p_query => 'phở bò')`)).length, 0, "phở bò không còn là nguyên liệu");
const phoDish = (await rows(`SELECT id, name_vi FROM search_dishes(p_query => 'pho')`));
assert.equal(phoDish[0].name_vi.startsWith("Phở"), true, "search_dishes 'pho' ra món phở trước");
await assert.rejects(db.query(`INSERT INTO ingredients (code, name_vi, category_id, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g)
  VALUES ('X99', 'Bún chả mới', 15, 1, 1, 1, 1)`), /ingredients_not_prepared_dish/);
const dishLog = (await one(`SELECT log_meal('lunch', p_dish_id => $1, p_amount_g => 500) AS r`, [phoDish[0].id])).r;
assert.equal(dishLog.item.source, "dish");
assert.equal(dishLog.item.dish_id, phoDish[0].id);
await assert.rejects(db.query(`SELECT log_meal('lunch', p_dish_id => $1, p_ingredient_id => $2, p_amount_g => 100)`, [phoDish[0].id, egg]), /VALIDATION_ERROR/);
const glutenDish = (await one(`SELECT count(*)::int AS n FROM prepared_dish_allergens`)).n;
assert.equal(glutenDish, 10, "10 liên kết dị ứng chuyển theo món");

// Calo/khẩu phần hợp lý sau khi đọc lại khối lượng (trước: lẩu gà 81, cá chim kho 85, cá bống chay 9)
const kcal = Object.fromEntries((await rows(`SELECT title, calories_per_serving::float AS k FROM recipes`)).map((x) => [x.title, x.k]));
assert.ok(Object.values(kcal).every((k) => k >= 80 && k <= 1300), "mọi món 80–1300 kcal/khẩu");
assert.ok(kcal["Lẩu gà lá giang"] > 400 && kcal["Cá chim kho thơm"] > 200 && kcal["Hủ tiếu gà trộn"] > 400);
const macroOff = await one(`SELECT count(*)::int AS n FROM recipes WHERE abs(4*protein_g_per_serving + 4*carbs_g_per_serving + 9*fat_g_per_serving - calories_per_serving) > calories_per_serving * 0.2`);
assert.equal(macroOff.n, 0, "kcal khớp macro");

console.log("migrations replay + audit fixes: all checks passed");
