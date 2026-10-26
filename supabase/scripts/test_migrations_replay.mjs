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
  (SELECT coalesce(sum(amount_g * calories_per_100g / 100), 0) FROM recipe_ingredients WHERE recipe_id = r.id)) > 1`);
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

console.log("migrations replay + audit fixes: all checks passed");
