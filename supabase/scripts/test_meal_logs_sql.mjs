// Kiểm thử migration vá quyền RPC + meal_logs trên Postgres WASM (không cần Supabase/Docker).
// Chạy: cd <thư mục tạm> && npm i @electric-sql/pglite@0.2 && node <đường dẫn>/test_meal_logs_sql.mjs
import { PGlite } from "@electric-sql/pglite";
import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const read = (name) => readFileSync(new URL("../migrations/" + name, import.meta.url), "utf8");
const db = new PGlite();

// Stub tối thiểu các phần của Supabase mà migration dùng
await db.exec(`
  CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role;
  CREATE SCHEMA auth;
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('test.uid', true), '')::uuid $$;
  CREATE TABLE profiles (id uuid PRIMARY KEY, target_calories numeric, target_protein_g numeric, target_fat_g numeric, target_carbs_g numeric);
  CREATE TABLE recipes (id uuid PRIMARY KEY, title text, image_url text, is_verified bool,
    calories_per_serving numeric, protein_g_per_serving numeric, fat_g_per_serving numeric, carbs_g_per_serving numeric, fiber_g_per_serving numeric);
  CREATE TABLE ingredients (id uuid PRIMARY KEY, name_vi text, is_active bool,
    calories_per_100g numeric, protein_per_100g numeric, fat_per_100g numeric, carbs_per_100g numeric, fiber_per_100g numeric);
  INSERT INTO profiles VALUES ('00000000-0000-0000-0000-00000000000a', 2000, 150, 60, 200),
                              ('00000000-0000-0000-0000-00000000000b', 1800, 120, 50, 180),
                              ('00000000-0000-0000-0000-00000000000c', NULL, NULL, NULL, NULL);
  INSERT INTO recipes VALUES ('00000000-0000-0000-0000-000000000001', 'Phở bò', 'pho.jpg', true, 450, 25, 10, 60, 2),
                             ('00000000-0000-0000-0000-000000000002', 'Chờ duyệt', null, false, 100, 1, 1, 1, 1);
  INSERT INTO ingredients VALUES ('00000000-0000-0000-0000-000000000011', 'Trứng gà', true, 166, 14.8, 11.6, 0.5, NULL);
`);
// Giả lập các hàm nguy hiểm đang có trên DB thật
await db.exec(`
  CREATE FUNCTION exec_seed_sql(query text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$ BEGIN EXECUTE query; END $$;
  CREATE FUNCTION create_custom_ingredient(p_name_vi varchar) RETURNS void LANGUAGE sql SECURITY DEFINER AS $$ SELECT $$;
  GRANT EXECUTE ON FUNCTION create_custom_ingredient(varchar) TO anon, authenticated;
  CREATE FUNCTION rls_auto_enable() RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = pg_catalog AS $$ SELECT $$;
`);
await db.exec(read("20261026085000_harden_rpc_permissions.sql"));
const priv = async (role, fn) => (await db.query(`SELECT has_function_privilege($1, $2, 'EXECUTE') AS ok`, [role, fn])).rows[0].ok;
assert.equal((await db.query(`SELECT count(*)::int AS n FROM pg_proc WHERE proname = 'exec_seed_sql'`)).rows[0].n, 0);
assert.equal(await priv("anon", "create_custom_ingredient(varchar)"), false);
assert.equal(await priv("authenticated", "create_custom_ingredient(varchar)"), false);
assert.equal(await priv("service_role", "create_custom_ingredient(varchar)"), true);
assert.deepEqual((await db.query(`SELECT proconfig FROM pg_proc WHERE proname = 'create_custom_ingredient'`)).rows[0].proconfig,
  ["search_path=public, extensions"]);
assert.deepEqual((await db.query(`SELECT proconfig FROM pg_proc WHERE proname = 'rls_auto_enable'`)).rows[0].proconfig,
  ["search_path=pg_catalog"]);

await db.exec(read("20261026090000_create_meal_logs.sql"));
assert.equal(await priv("anon", "log_meal(text, uuid, numeric, uuid, numeric, date, uuid)"), false);

const A = "00000000-0000-0000-0000-00000000000a", B = "00000000-0000-0000-0000-00000000000b";
const PHO = "00000000-0000-0000-0000-000000000001", DRAFT = "00000000-0000-0000-0000-000000000002";
const EGG = "00000000-0000-0000-0000-000000000011";
const KEY = "11111111-1111-1111-1111-111111111111";

const as = async (uid, sql, params = []) => {
  await db.query(`SELECT set_config('test.uid', $1, false)`, [uid ?? ""]);
  return (await db.query(sql, params)).rows[0];
};
const err = async (uid, sql, params) => {
  try { await as(uid, sql, params); } catch (e) { return [e.message, e.hint]; }
  assert.fail("expected error: " + sql);
};
const log = (args) => `SELECT log_meal(${args}) AS r`;

// Ghi recipe 1.5 khẩu phần
let r = (await as(A, log(`'lunch', $1, 1.5`), [PHO])).r;
assert.equal(r.item.kcal, 675);
assert.equal(r.item.source, "recipe");
assert.equal(r.budget.consumed.kcal, 675);
assert.equal(r.budget.remaining.kcal, 1325);

// Ghi ingredient 120g
r = (await as(A, log(`'breakfast', p_ingredient_id => $1, p_amount_g => 120, p_client_request_id => $2`), [EGG, KEY])).r;
assert.equal(r.item.kcal, 199);
assert.equal(r.replayed, false);
assert.equal(r.budget.consumed.kcal, 874);

// Retry cùng key -> không ghi trùng
r = (await as(A, log(`'breakfast', p_ingredient_id => $1, p_amount_g => 120, p_client_request_id => $2`), [EGG, KEY])).r;
assert.equal(r.replayed, true);
assert.equal(r.budget.consumed.kcal, 874);

// Cùng key khác nội dung -> lỗi
assert.deepEqual(await err(A, log(`'breakfast', p_ingredient_id => $1, p_amount_g => 200, p_client_request_id => $2`), [EGG, KEY]),
  ["IDEMPOTENCY_CONFLICT", "client_request_id"]);

// Validation + not found
assert.deepEqual(await err(A, log(`'brunch', $1`), [PHO]), ["VALIDATION_ERROR", "meal_type"]);
assert.deepEqual(await err(A, log(`'lunch', $1, p_ingredient_id => $2, p_amount_g => 1`), [PHO, EGG]), ["VALIDATION_ERROR", "recipe_id"]);
assert.deepEqual(await err(A, log(`'lunch', $1, 20`), [PHO]), ["VALIDATION_ERROR", "servings"]);
assert.deepEqual(await err(A, log(`'lunch', p_ingredient_id => $1`), [EGG]), ["VALIDATION_ERROR", "amount_g"]);
assert.deepEqual(await err(A, log(`'lunch', $1, p_date => vn_today() + 1`), [PHO]), ["VALIDATION_ERROR", "date"]);
assert.deepEqual(await err(A, log(`'lunch', $1`), [DRAFT]), ["RECIPE_NOT_FOUND", "recipe_id"]);
assert.equal((await err("00000000-0000-0000-0000-00000000000c", log(`'lunch', $1`), [PHO]))[0], "PROFILE_NOT_FOUND");
assert.equal((await err(null, log(`'lunch', $1`), [PHO]))[0], "UNAUTHORIZED");

// Tổng hợp ngày: chia theo bữa
const day = (await as(A, `SELECT get_daily_nutrition() AS r`)).r;
assert.equal(day.meals.lunch.kcal, 675);
assert.equal(day.meals.breakfast.items.length, 1);
assert.equal(day.meals.dinner.items.length, 0);

// User B không thấy dữ liệu của A, và có thể dùng cùng client_request_id
assert.equal((await as(B, `SELECT get_daily_nutrition() AS r`)).r.budget.consumed.kcal, 0);
assert.equal((await as(B, log(`'lunch', $1, p_client_request_id => $2`), [PHO, KEY])).r.replayed, false);

// Sửa khẩu phần: nhân theo tỉ lệ trên snapshot, giữ snapshot khi recipe gốc đổi
const lunchId = day.meals.lunch.items[0].id;
await db.exec(`UPDATE recipes SET calories_per_serving = 9999`);
r = (await as(A, `SELECT update_meal_log_item($1, 3) AS r`, [lunchId])).r;
assert.equal(r.item.kcal, 1350);
assert.equal(r.item.meal_type, "lunch");
assert.equal(r.budget.consumed.kcal, 1549);
assert.deepEqual(await err(A, `SELECT update_meal_log_item($1, p_amount_g => 100)`, [lunchId]), ["VALIDATION_ERROR", "servings"]);
assert.deepEqual(await err(B, `SELECT update_meal_log_item($1, 1)`, [lunchId]), ["ITEM_NOT_FOUND", "id"]);
r = (await as(A, `SELECT update_meal_log_item($1, 1.5) AS r`, [lunchId])).r;
assert.equal(r.item.kcal, 675);

// Lịch sử: đủ ngày, ngày trống = 0, giới hạn 31 ngày
const h = (await as(A, `SELECT get_nutrition_history(vn_today() - 6, vn_today()) AS r`)).r;
assert.equal(h.days.length, 7);
assert.equal(h.days[6].kcal, 874);
assert.equal(h.days[0].kcal, 0);

// Đổi mục tiêu: ngày đã ghi giữ mục tiêu cũ, ngày chưa ghi dùng mục tiêu mới
await db.exec(`UPDATE profiles SET target_calories = 1500 WHERE id = '${A}'`);
const h2 = (await as(A, `SELECT get_nutrition_history(vn_today() - 6, vn_today()) AS r`)).r;
assert.equal(h2.days[6].target_kcal, 2000);
assert.equal(h2.days[0].target_kcal, 1500);
assert.equal(h2.target_kcal, 1500);
assert.deepEqual(await err(A, `SELECT get_nutrition_history(vn_today() - 31, vn_today())`), ["VALIDATION_ERROR", "from"]);

console.log("harden + meal_logs: all checks passed");
