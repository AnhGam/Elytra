// Kiểm thử Edge Function meal-logs + RLS trên Supabase thật. Tạo 2 user tạm, chạy xong tự xóa.
// Chạy: SUPABASE_URL=... ANON_KEY=... SERVICE_ROLE_KEY=... node test_meal_logs_e2e.mjs
import assert from "node:assert/strict";

const { SUPABASE_URL: URL_, ANON_KEY, SERVICE_ROLE_KEY } = process.env;
assert.ok(URL_ && ANON_KEY && SERVICE_ROLE_KEY, "thiếu biến môi trường");

const call = async (path, { method = "GET", token = ANON_KEY, key = ANON_KEY, body, headers = {} } = {}) => {
  const res = await fetch(URL_ + path, {
    method,
    headers: { apikey: key, Authorization: `Bearer ${token}`, "Content-Type": "application/json", ...headers },
    body: body && JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
};
const admin = (path, opts = {}) => call(path, { ...opts, token: SERVICE_ROLE_KEY, key: SERVICE_ROLE_KEY });
const fn = (path, token, opts = {}) => call("/functions/v1/meal-logs" + path, { ...opts, token });

const users = [];
async function makeUser(target) {
  const email = `e2e-${crypto.randomUUID()}@elytra.test`, password = crypto.randomUUID();
  const u = await admin("/auth/v1/admin/users", { method: "POST", body: { email, password, email_confirm: true } });
  assert.equal(u.status, 200, JSON.stringify(u.body));
  users.push(u.body.id);
  await admin(`/rest/v1/profiles?id=eq.${u.body.id}`, {
    method: "PATCH",
    body: { target_calories: target, target_protein_g: 120, target_carbs_g: 200, target_fat_g: 60 },
  });
  const s = await call("/auth/v1/token?grant_type=password", { method: "POST", body: { email, password } });
  return s.body.access_token;
}

try {
  const A = await makeUser(2000), B = await makeUser(1800);
  const recipe = (await call("/rest/v1/recipes?select=id,calories_per_serving&is_verified=eq.true&limit=1")).body[0];
  const ing = (await call("/rest/v1/ingredients?select=id,calories_per_100g&is_active=eq.true&limit=1")).body[0];
  const key = crypto.randomUUID();

  // POST: ghi món + chống ghi trùng
  let r = await fn("", A, { method: "POST", body: { meal_type: "lunch", recipe_id: recipe.id, servings: 2, client_request_id: key } });
  assert.equal(r.status, 201, JSON.stringify(r.body));
  assert.equal(r.body.item.kcal, Math.round(recipe.calories_per_serving * 2));
  const itemId = r.body.item.id;
  r = await fn("", A, { method: "POST", body: { meal_type: "lunch", recipe_id: recipe.id, servings: 2, client_request_id: key } });
  assert.equal(r.status, 200);
  assert.equal(r.body.replayed, true);
  r = await fn("", A, { method: "POST", body: { meal_type: "lunch", recipe_id: recipe.id, servings: 3, client_request_id: key } });
  assert.equal(r.status, 422);
  assert.equal(r.body.error.code, "IDEMPOTENCY_CONFLICT");
  r = await fn("", A, { method: "POST", body: { meal_type: "breakfast", ingredient_id: ing.id, amount_g: 150 } });
  assert.equal(r.status, 201);

  // Lỗi theo format contract
  r = await fn("", A, { method: "POST", body: { meal_type: "brunch", recipe_id: recipe.id } });
  assert.deepEqual([r.status, r.body.error.code, r.body.error.field], [400, "VALIDATION_ERROR", "meal_type"]);
  r = await fn("", A, { method: "POST", body: { meal_type: "lunch", recipe_id: "not-a-uuid" } });
  assert.deepEqual([r.status, r.body.error.code], [400, "VALIDATION_ERROR"]);
  r = await fn("", A, { method: "POST", body: { meal_type: "lunch", recipe_id: crypto.randomUUID() } });
  assert.deepEqual([r.status, r.body.error.code], [404, "RECIPE_NOT_FOUND"]);
  r = await fn("", "invalid-token");
  assert.equal(r.status, 401);

  // GET ngày + lịch sử
  r = await fn("", A);
  assert.equal(r.status, 200);
  const consumed = Math.round(recipe.calories_per_serving * 2) + Math.round(ing.calories_per_100g * 1.5);
  assert.ok(Math.abs(r.body.budget.consumed.kcal - consumed) <= 1);
  assert.equal(r.body.budget.remaining.kcal, 2000 - r.body.budget.consumed.kcal);
  assert.equal(r.body.meals.lunch.items.length, 1);
  r = await fn(`/history?from=${r.body.date}&to=${r.body.date}`, A);
  assert.equal(r.status, 200);
  assert.equal(r.body.days[0].target_kcal, 2000);

  // PATCH
  r = await fn(`/items/${itemId}`, A, { method: "PATCH", body: { servings: 1 } });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.item.kcal, Math.round(recipe.calories_per_serving));
  r = await fn(`/items/${itemId}`, B, { method: "PATCH", body: { servings: 5 } });
  assert.deepEqual([r.status, r.body.error.code], [404, "ITEM_NOT_FOUND"]);

  // RLS: B không thấy / không xóa được món của A; không ai ghi thẳng vào bảng được
  assert.deepEqual((await call("/rest/v1/meal_log_items?select=id", { token: B })).body, []);
  assert.equal((await call("/rest/v1/meal_log_items?select=id", { token: A })).body.length, 2);
  assert.equal((await fn(`/items/${itemId}`, B, { method: "DELETE" })).status, 204);
  assert.equal((await call(`/rest/v1/meal_log_items?select=id&id=eq.${itemId}`, { token: A })).body.length, 1);
  r = await call("/rest/v1/meal_log_items", { method: "POST", token: A, body: { meal_log_id: crypto.randomUUID(), user_id: users[0], name: "x", servings: 1, kcal: 0, protein_g: 0, carbs_g: 0, fat_g: 0, fiber_g: 0 } });
  assert.ok([401, 403].includes(r.status), "insert thẳng phải bị chặn: " + r.status);
  await call(`/rest/v1/meal_log_items?id=eq.${itemId}`, { method: "PATCH", token: A, body: { kcal: 0 } });
  assert.notEqual((await fn("", A)).body.meals.lunch.kcal, 0, "update thẳng phải bị chặn");

  // DELETE của chủ
  assert.equal((await fn(`/items/${itemId}`, A, { method: "DELETE" })).status, 204);
  assert.equal((await fn("", A)).body.meals.lunch.items.length, 0);

  console.log("meal-logs e2e: all checks passed");
} finally {
  for (const id of users) await admin(`/auth/v1/admin/users/${id}`, { method: "DELETE" });
}
