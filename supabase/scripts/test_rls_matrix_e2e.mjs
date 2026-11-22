// Kiểm thử E2E ma trận RLS trên Supabase thật: user B và anon không đọc/ghi được dữ liệu của user A trên mọi bảng, RPC, Edge Function và Storage.
// Tạo 2 user tạm A, B, chạy xong tự xóa.
// Chạy: SUPABASE_URL=... ANON_KEY=... SERVICE_ROLE_KEY=... node test_rls_matrix_e2e.mjs
import assert from "node:assert/strict";

const { SUPABASE_URL: URL_, ANON_KEY, SERVICE_ROLE_KEY } = process.env;
assert.ok(URL_ && ANON_KEY && SERVICE_ROLE_KEY, "thiếu biến môi trường");

const call = async (path, { method = "GET", token = ANON_KEY, key = ANON_KEY, body, headers = {}, raw } = {}) => {
  const res = await fetch(URL_ + path, {
    method,
    headers: { apikey: key, Authorization: `Bearer ${token}`, ...(raw ? {} : { "Content-Type": "application/json" }), ...headers },
    body: raw ?? (body && JSON.stringify(body)),
  });
  const text = await res.text();
  let parsed = null;
  try { parsed = text ? JSON.parse(text) : null; } catch { parsed = text; }
  return { status: res.status, body: parsed };
};
const admin = (path, opts = {}) => call(path, { ...opts, token: SERVICE_ROLE_KEY, key: SERVICE_ROLE_KEY });
const rpc = (name, token, body = {}) => call(`/rest/v1/rpc/${name}`, { method: "POST", token, body });
const errCode = (r) => r.body?.message ?? r.body?.error?.code;

const users = [], recipes = [], files = [];
async function makeUser(name) {
  const email = `e2e-${crypto.randomUUID()}@elytra.test`, password = crypto.randomUUID();
  const u = await admin("/auth/v1/admin/users", { method: "POST", body: { email, password, email_confirm: true } });
  assert.equal(u.status, 200, JSON.stringify(u.body));
  users.push(u.body.id);
  await admin(`/rest/v1/profiles?id=eq.${u.body.id}`, { method: "PATCH", body: { full_name: name, target_calories: 2000, target_protein_g: 100, target_carbs_g: 200, target_fat_g: 60 } });
  const s = await call("/auth/v1/token?grant_type=password", { method: "POST", body: { email, password } });
  return { token: s.body.access_token, id: u.body.id };
}

const results = [];
const check = (target, action, pass) => results.push({ target, action, pass });
const rowsOf = async (path) => (await admin(path)).body;

try {
  const A = await makeUser("Người A"), B = await makeUser("Người B");

  // Tạo dữ liệu riêng của A trên các bảng, chat và công thức chờ duyệt
  const verified = (await call("/rest/v1/recipes?select=id&is_verified=eq.true&limit=2")).body;
  assert.ok(Array.isArray(verified) && verified.length >= 1, "thiếu món đã duyệt trong DB");
  const recipeId = verified[0].id;
  const otherRecipeId = verified[1]?.id ?? recipeId;
  const egg = (await call("/rest/v1/ingredients?select=id&code=eq.09001")).body[0].id;

  const logRes = await call("/functions/v1/meal-logs", { method: "POST", token: A.token, body: { meal_type: "lunch", recipe_id: recipeId, servings: 1 } });
  assert.equal(logRes.status, 201, JSON.stringify(logRes.body));
  const itemA = logRes.body.item.id;

  assert.equal((await call("/rest/v1/user_allergens", { method: "POST", token: A.token, body: { user_id: A.id, allergen_id: 2 } })).status, 201);
  assert.equal((await call("/rest/v1/user_favorite_recipes", { method: "POST", token: A.token, body: { recipe_id: recipeId } })).status, 201);

  const chatRes = await call("/functions/v1/recommend-ai", { method: "POST", token: A.token, body: { meal_type: "lunch" } });
  assert.equal(chatRes.status, 200, JSON.stringify(chatRes.body));
  const sessionA = chatRes.body.session_id;
  assert.ok(sessionA, "recommend-ai không trả session_id");

  const submitArgs = {
    p_title: "Món RLS test",
    p_category: "mon_man",
    p_servings: 1,
    p_ingredients: [{ ingredient_id: egg, amount: 100 }, { ingredient_id: egg, amount: 50 }],
    p_instructions: [{ description: "Nấu" }],
  };
  const subRes = await rpc("submit_recipe", A.token, submitArgs);
  assert.equal(subRes.status, 200, JSON.stringify(subRes.body));
  const recipeA = subRes.body.id;
  recipes.push(recipeA);

  // 4.1 Bảng có dữ liệu riêng của A: B không đọc / thêm hộ / sửa / xóa được
  const owned = [
    { table: "profiles", filter: `id=eq.${A.id}`, patch: { target_calories: 999 } },
    { table: "user_allergens", filter: `user_id=eq.${A.id}`, insert: { user_id: A.id, allergen_id: 3 }, patch: { allergen_id: 4 } },
    { table: "user_favorite_recipes", filter: `user_id=eq.${A.id}`, insert: { user_id: A.id, recipe_id: otherRecipeId } },
    { table: "meal_logs", filter: `user_id=eq.${A.id}`, insert: { user_id: A.id, log_date: "2026-01-01", meal_type: "dinner", target_kcal: 2000 }, patch: { target_kcal: 1 } },
    { table: "meal_log_items", filter: `user_id=eq.${A.id}`, patch: { kcal: 1 } },
    { table: "chat_sessions", filter: `user_id=eq.${A.id}`, insert: { user_id: A.id, meal_type: "lunch" }, patch: { meal_type: "dinner" } },
    { table: "chat_messages", filter: `user_id=eq.${A.id}`, insert: { session_id: sessionA, user_id: A.id, role: "user", content: "x" }, patch: { content: "sửa" } },
    { table: "recipes", filter: `id=eq.${recipeA}`, patch: { status: "approved" } },
    { table: "recipe_ingredients", filter: `recipe_id=eq.${recipeA}`, patch: { amount_g: 1 } },
    { table: "recipe_allergens", filter: `recipe_id=eq.${recipeA}`, optionalSetup: true },
  ];

  for (const t of owned) {
    const setupRows = await rowsOf(`/rest/v1/${t.table}?select=*&${t.filter}`);
    if (!t.optionalSetup && (!Array.isArray(setupRows) || setupRows.length === 0)) check(t.table, "setup", false);

    const sel = await call(`/rest/v1/${t.table}?select=*&${t.filter}`, { token: B.token });
    check(t.table, "select", sel.status !== 200 || (Array.isArray(sel.body) && sel.body.length === 0));

    if (t.insert) {
      const ins = await call(`/rest/v1/${t.table}`, { method: "POST", token: B.token, body: t.insert });
      check(t.table, "insert", ins.status !== 201);
    }

    if (t.patch) {
      const [col, val] = Object.entries(t.patch)[0];
      const up = await call(`/rest/v1/${t.table}?${t.filter}`, {
        method: "PATCH", token: B.token, body: t.patch, headers: { Prefer: "return=representation" },
      });
      const afterUp = await rowsOf(`/rest/v1/${t.table}?select=*&${t.filter}`);
      const patched = Array.isArray(afterUp) && afterUp.some((r) => r[col] === val || (typeof val === "number" && Number(r[col]) === val));
      check(t.table, "update", (up.status >= 400 || (Array.isArray(up.body) && up.body.length === 0)) && !patched);
    }

    const beforeDel = await rowsOf(`/rest/v1/${t.table}?select=*&${t.filter}`);
    await call(`/rest/v1/${t.table}?${t.filter}`, { method: "DELETE", token: B.token });
    const afterDel = await rowsOf(`/rest/v1/${t.table}?select=*&${t.filter}`);
    check(t.table, "delete", Array.isArray(beforeDel) && Array.isArray(afterDel) && afterDel.length === beforeDel.length);
  }

  // 4.2 Bảng nội bộ: app (đăng nhập lẫn anon) không đọc/ghi được
  for (const table of ["ai_usage", "recipe_submissions", "admins", "app_config", "admin_audit_log"]) {
    for (const [label, token] of [["B", B.token], ["anon", ANON_KEY]]) {
      const sel = await call(`/rest/v1/${table}?select=*`, { token });
      check(table, `select (${label})`, sel.status !== 200 || (Array.isArray(sel.body) && sel.body.length === 0));
      const ins = await call(`/rest/v1/${table}`, { method: "POST", token, body: {} });
      check(table, `insert (${label})`, ins.status !== 201);
    }
  }

  // 4.3 Anon không đọc được dữ liệu cá nhân của A
  for (const [table, filter] of [
    ["profiles", `id=eq.${A.id}`],
    ["user_allergens", `user_id=eq.${A.id}`],
    ["user_favorite_recipes", `user_id=eq.${A.id}`],
    ["meal_logs", `user_id=eq.${A.id}`],
    ["meal_log_items", `user_id=eq.${A.id}`],
    ["chat_messages", `user_id=eq.${A.id}`],
  ]) {
    const sel = await call(`/rest/v1/${table}?select=*&${filter}`);
    check(table, "select (anon)", sel.status !== 200 || (Array.isArray(sel.body) && sel.body.length === 0));
  }

  // 4.4 RPC / Edge Function nhận id của người khác
  const rec = await rpc("recommend_dishes_for_user", B.token, { p_uid: A.id });
  check("recommend_dishes_for_user", "rpc (uid A)", rec.status !== 200);

  const upItem = await rpc("update_meal_log_item", B.token, { p_item_id: itemA, p_servings: 3 });
  const itemServings = (await rowsOf(`/rest/v1/meal_log_items?select=servings&id=eq.${itemA}`))[0]?.servings;
  check("update_meal_log_item", "rpc (item A)", upItem.status !== 200 && Number(itemServings) === 1);

  await rpc("delete_meal_log_item", B.token, { p_item_id: itemA });
  check("delete_meal_log_item", "rpc (item A)", (await rowsOf(`/rest/v1/meal_log_items?select=id&id=eq.${itemA}`)).length === 1);

  const editRec = await rpc("submit_recipe", B.token, { ...submitArgs, p_title: "Chiếm", p_recipe_id: recipeA });
  check("submit_recipe", "rpc (sửa món A)", errCode(editRec) === "RECIPE_NOT_FOUND");

  const delRec = await rpc("delete_my_recipe", B.token, { p_recipe_id: recipeA });
  check("delete_my_recipe", "rpc (xóa món A)", errCode(delRec) === "RECIPE_NOT_FOUND");

  const dailyB = await rpc("get_daily_nutrition", B.token, {});
  check("get_daily_nutrition", "rpc (chỉ thấy của B)", dailyB.status === 200 && dailyB.body?.budget?.consumed?.kcal === 0);

  const patchEdge = await call(`/functions/v1/meal-logs/items/${itemA}`, { method: "PATCH", token: B.token, body: { servings: 3 } });
  check("meal-logs PATCH", "edge (item A)", patchEdge.status === 404);

  await call(`/functions/v1/meal-logs/items/${itemA}`, { method: "DELETE", token: B.token });
  check("meal-logs DELETE", "edge (item A)", (await rowsOf(`/rest/v1/meal_log_items?select=id&id=eq.${itemA}`)).length === 1);

  const chatB = await call("/functions/v1/recommend-ai", { method: "POST", token: B.token, body: { session_id: sessionA, meal_type: "lunch" } });
  check("recommend-ai session A", "edge (session A)", chatB.status === 200 && Boolean(chatB.body?.session_id) && chatB.body.session_id !== sessionA);

  const histA = await call(`/rest/v1/chat_messages?select=id&session_id=eq.${sessionA}`, { token: B.token });
  check("chat history A", "select (session A)", Array.isArray(histA.body) && histA.body.length === 0);

  // 4.5 Storage: B không ghi đè, xóa, hay liệt kê ảnh trong thư mục của A
  const png = Uint8Array.from(atob("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="), (c) => c.charCodeAt(0));
  const up = (who, path, type = "image/png", data = png, headers = {}) =>
    call(`/storage/v1/object/user-recipe-images/${path}`, { method: "POST", token: who.token, raw: data, headers: { "Content-Type": type, ...headers } });
  const own = `${A.id}/rls.png`;
  const upA = await up(A, own);
  assert.equal(upA.status, 200, JSON.stringify(upA.body));
  files.push(own);

  const overwrite = await up(B, own, "image/png", png, { "x-upsert": "true" });
  check("storage:user-recipe-images", "overwrite", overwrite.status !== 200);

  await call(`/storage/v1/object/user-recipe-images/${own}`, { method: "DELETE", token: B.token });
  check("storage:user-recipe-images", "delete", (await fetch(`${URL_}/storage/v1/object/public/user-recipe-images/${own}`)).status === 200);

  const list = await call("/storage/v1/object/list/user-recipe-images", { method: "POST", token: B.token, body: { prefix: A.id + "/", limit: 10 } });
  check("storage:user-recipe-images", "list", list.status !== 200 || (Array.isArray(list.body) && list.body.length === 0));

  console.table(results);
  assert.ok(results.every((r) => r.pass), "có lỗ hổng RLS: " + JSON.stringify(results.filter((r) => !r.pass)));
  console.log("rls matrix e2e: all checks passed (" + results.length + " kiểm tra)");
} finally {
  for (const id of recipes) await admin(`/rest/v1/recipes?id=eq.${id}`, { method: "DELETE" });
  if (files.length) await admin("/storage/v1/object/user-recipe-images", { method: "DELETE", body: { prefixes: files } });
  for (const id of users) {
    await admin(`/rest/v1/admin_audit_log?admin_id=eq.${id}`, { method: "DELETE" });
    await admin(`/rest/v1/recipes?created_by=eq.${id}`, { method: "DELETE" });
    await admin(`/auth/v1/admin/users/${id}`, { method: "DELETE" });
  }
}
