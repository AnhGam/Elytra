// Kiểm thử Sprint 7 (cộng đồng + admin) trên Supabase thật: quyền admin nghiêm ngặt, RLS, Storage, luồng duyệt.
// Tạo 3 user tạm (A, B, admin) + nguyên liệu/món/ảnh tạm; chạy xong tự xóa hết. Không đụng dữ liệu thật.
// Chạy: SUPABASE_URL=... ANON_KEY=... SERVICE_ROLE_KEY=... node test_community_admin_e2e.mjs
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

const users = [], recipes = [], ingredients = [], files = [];
async function makeUser(name) {
  const email = `e2e-${crypto.randomUUID()}@elytra.test`, password = crypto.randomUUID();
  const u = await admin("/auth/v1/admin/users", { method: "POST", body: { email, password, email_confirm: true } });
  assert.equal(u.status, 200, JSON.stringify(u.body));
  users.push(u.body.id);
  await admin(`/rest/v1/profiles?id=eq.${u.body.id}`, { method: "PATCH", body: { full_name: name, target_calories: 2000, target_protein_g: 100, target_carbs_g: 200, target_fat_g: 60 } });
  const s = await call("/auth/v1/token?grant_type=password", { method: "POST", body: { email, password } });
  return { token: s.body.access_token, id: u.body.id };
}

try {
  const A = await makeUser("Bếp Nhà Lan"), B = await makeUser(""), AD = await makeUser("Quản trị");
  assert.equal((await admin("/rest/v1/admins", { method: "POST", body: { user_id: AD.id, note: "e2e" } })).status, 201);

  // 1. Không tự cấp quyền admin, không đọc được bảng admins / nhật ký
  assert.notEqual((await call("/rest/v1/admins", { method: "POST", token: A.token, body: { user_id: A.id } })).status, 201, "user không tự thêm mình làm admin");
  const seeAdmins = await call("/rest/v1/admins", { token: A.token });
  assert.ok(seeAdmins.status !== 200 || seeAdmins.body.length === 0, "user không xem được danh sách admin");
  assert.equal((await rpc("is_admin", A.token)).body, false);
  assert.equal((await rpc("is_admin", AD.token)).body, true);
  assert.equal((await rpc("is_admin", ANON_KEY)).body, false, "anon gọi được is_admin (dùng trong RLS) và nhận false");

  // 2. User thường gọi mọi thao tác admin → FORBIDDEN
  const egg = (await call("/rest/v1/ingredients?select=id&code=eq.09001")).body[0].id;
  for (const [name, body] of [["admin_list_pending_recipes", {}], ["admin_review_recipe", { p_recipe_id: crypto.randomUUID(), p_approve: true, p_submitted_at: new Date().toISOString() }],
    ["admin_save_ingredient", { p_name_vi: "Thử", p_category_id: 1, p_calories_per_100g: 10, p_protein_per_100g: 1, p_fat_per_100g: 1, p_carbs_per_100g: 1 }],
    ["admin_set_ingredient_active", { p_id: egg, p_active: false }], ["admin_delete_ingredient", { p_id: egg }]]) {
    const r = await rpc(name, A.token, body);
    assert.notEqual(r.status, 200, name);
    assert.equal(errCode(r), "FORBIDDEN", name);
    assert.notEqual((await rpc(name, ANON_KEY, body)).status, 200, "anon: " + name);
  }
  assert.equal((await call(`/rest/v1/ingredients?select=is_active&id=eq.${egg}`)).body[0].is_active, true, "trứng vẫn hoạt động");

  // 3. Admin thêm nguyên liệu (để test không đụng nguyên liệu thật)
  const ing = await rpc("admin_save_ingredient", AD.token, { p_name_vi: "Nguyên liệu e2e " + Date.now(), p_category_id: 1,
    p_calories_per_100g: 350, p_protein_per_100g: 10, p_fat_per_100g: 2, p_carbs_per_100g: 70, p_allergen_ids: [7] });
  assert.equal(ing.status, 200, JSON.stringify(ing.body));
  ingredients.push(ing.body.id);

  // 4. User không ghi thẳng bảng recipes; gửi qua RPC → pending
  assert.notEqual((await call("/rest/v1/recipes", { method: "POST", token: A.token, body: { title: "Hack", slug: "hack-" + Date.now(), status: "approved" } })).status, 201);
  const steps = [{ title: "Sơ chế", description: "Rửa sạch" }, { description: "Nấu chín" }];
  const ingr = [{ ingredient_id: ing.body.id, amount: 300 }, { ingredient_id: egg, amount: 100 }];
  const sub = await rpc("submit_recipe", A.token, { p_title: "Bánh e2e", p_category: "mon_man", p_servings: 2, p_ingredients: ingr, p_instructions: steps });
  assert.equal(sub.status, 200, JSON.stringify(sub.body));
  recipes.push(sub.body.id);
  assert.equal(sub.body.status, "pending");
  assert.deepEqual(sub.body.allergens, [2, 7], "dị ứng kế thừa: trứng + gluten");
  assert.ok(Math.abs(sub.body.calories_per_serving - (300 * 3.5 + 150) / 2) < 1);
  const patch = await call(`/rest/v1/recipes?id=eq.${sub.body.id}`, { method: "PATCH", token: A.token, body: { status: "approved" }, headers: { Prefer: "return=representation" } });
  assert.ok(patch.status >= 400 || patch.body.length === 0, "user không tự duyệt bằng PATCH");

  // 5. Ai thấy món pending: tác giả + admin; B và anon không
  assert.equal((await call(`/rest/v1/recipes?select=id,status&id=eq.${sub.body.id}`, { token: A.token })).body[0]?.status, "pending");
  assert.equal((await call(`/rest/v1/recipes?select=id&id=eq.${sub.body.id}`, { token: B.token })).body.length, 0);
  assert.equal((await call(`/rest/v1/recipes?select=id&id=eq.${sub.body.id}`)).body.length, 0);
  assert.equal((await call(`/rest/v1/recipe_ingredients?select=id&recipe_id=eq.${sub.body.id}`, { token: B.token })).body.length, 0);
  assert.equal((await call(`/rest/v1/recipe_ingredients?select=id&recipe_id=eq.${sub.body.id}`, { token: A.token })).body.length, 2);
  assert.equal(errCode(await rpc("submit_recipe", B.token, { p_title: "Sửa hộ", p_category: "mon_man", p_servings: 2, p_ingredients: ingr, p_instructions: steps, p_recipe_id: sub.body.id })), "RECIPE_NOT_FOUND");
  assert.equal(errCode(await rpc("delete_my_recipe", B.token, { p_recipe_id: sub.body.id })), "RECIPE_NOT_FOUND");

  // 6. Ảnh: chỉ thư mục của mình, chỉ ảnh
  const png = Uint8Array.from(atob("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="), (c) => c.charCodeAt(0));
  const up = (who, path, type = "image/png", data = png) =>
    call(`/storage/v1/object/user-recipe-images/${path}`, { method: "POST", token: who.token, raw: data, headers: { "Content-Type": type } });
  const own = `${A.id}/e2e-${Date.now()}.png`;
  assert.equal((await up(A, own)).status, 200, "upload vào thư mục của mình");
  files.push(own);
  assert.notEqual((await up(A, `${B.id}/hack.png`)).status, 200, "không upload vào thư mục người khác");
  assert.notEqual((await up(A, `${A.id}/x.txt`, "text/plain", new TextEncoder().encode("hi"))).status, 200, "chỉ nhận ảnh");
  assert.notEqual((await up({ token: ANON_KEY }, `${A.id}/anon.png`)).status, 200, "anon không upload");
  const imgUrl = `${URL_}/storage/v1/object/public/user-recipe-images/${own}`;
  assert.equal((await fetch(imgUrl)).status, 200, "ảnh xem công khai được");
  const otherImg = await rpc("submit_recipe", A.token, { p_title: "Ảnh lạ", p_category: "mon_man", p_servings: 1, p_ingredients: ingr, p_instructions: steps,
    p_image_url: `${URL_}/storage/v1/object/public/user-recipe-images/${B.id}/x.png` });
  assert.equal(errCode(otherImg), "VALIDATION_ERROR", "không dùng ảnh trong thư mục người khác");
  for (const url of [`https://evil.com/x.jpg?/storage/v1/object/public/user-recipe-images/${own}`, imgUrl + "?x=1", `${URL_}/storage/v1/object/public/user-recipe-images/${A.id}/chua-upload.png`]) {
    assert.equal(errCode(await rpc("submit_recipe", A.token, { p_title: "Ảnh lạ", p_category: "mon_man", p_servings: 1, p_ingredients: ingr, p_instructions: steps, p_image_url: url })), "VALIDATION_ERROR", url);
  }
  const list = await call("/storage/v1/object/list/user-recipe-images", { method: "POST", token: B.token, body: { prefix: A.id + "/", limit: 10 } });
  assert.ok(list.status !== 200 || list.body.length === 0, "người khác không liệt kê được ảnh của A");
  const listAnon = await call("/storage/v1/object/list/user-recipe-images", { method: "POST", body: { prefix: A.id + "/", limit: 10 } });
  assert.ok(listAnon.status !== 200 || listAnon.body.length === 0, "anon không liệt kê được");

  // 7. AI chấm sẵn: chỉ admin
  assert.equal((await call("/functions/v1/recipe-review-assist", { method: "POST", token: A.token, body: { recipe_id: sub.body.id } })).status, 403);
  const assist = await call("/functions/v1/recipe-review-assist", { method: "POST", token: AD.token, body: { recipe_id: sub.body.id } });
  assert.equal(assist.status, 200, JSON.stringify(assist.body));
  console.log("AI chấm sẵn:", assist.body.ai_review ? JSON.stringify({ is_dish: assist.body.ai_review.is_dish, cat: assist.body.ai_review.category, warnings: assist.body.ai_review.warnings }) : assist.body.message);

  // 8. Admin: hàng chờ → từ chối (bắt buộc lý do) → tác giả sửa gửi lại → duyệt
  const queue = await rpc("admin_list_pending_recipes", AD.token);
  const mine = queue.body.find((x) => x.id === sub.body.id);
  assert.equal(mine.author_name, "Bếp Nhà Lan");
  const seen1 = mine.submitted_at;
  assert.equal(errCode(await rpc("admin_review_recipe", AD.token, { p_recipe_id: sub.body.id, p_approve: false, p_submitted_at: seen1 })), "VALIDATION_ERROR");
  assert.equal((await rpc("admin_review_recipe", AD.token, { p_recipe_id: sub.body.id, p_approve: false, p_submitted_at: seen1, p_reason: "Thiếu bước ướp" })).status, 200);
  const rej = (await call(`/rest/v1/recipes?select=status,reject_reason&id=eq.${sub.body.id}`, { token: A.token })).body[0];
  assert.deepEqual([rej.status, rej.reject_reason], ["rejected", "Thiếu bước ướp"], "tác giả thấy lý do từ chối");
  const re = await rpc("submit_recipe", A.token, { p_title: "Bánh e2e", p_category: "mon_man", p_servings: 2, p_ingredients: ingr,
    p_instructions: [...steps, { description: "Ướp 15 phút" }], p_image_url: imgUrl, p_recipe_id: sub.body.id });
  assert.equal(re.body.status, "pending");
  assert.equal(errCode(await rpc("admin_review_recipe", AD.token, { p_recipe_id: sub.body.id, p_approve: true, p_submitted_at: seen1 })), "RECIPE_CHANGED", "duyệt bằng bản cũ bị chặn");
  const seen2 = (await rpc("admin_list_pending_recipes", AD.token, { p_page_size: 100 })).body.find((x) => x.id === sub.body.id).submitted_at;
  assert.equal((await rpc("admin_review_recipe", AD.token, { p_recipe_id: sub.body.id, p_approve: true, p_submitted_at: seen2 })).status, 200);
  assert.equal((await call(`/rest/v1/recipes?select=id&id=eq.${sub.body.id}`)).body.length, 1, "đã duyệt: anon xem được");
  const comm = await rpc("list_community_recipes", ANON_KEY, { p_page_size: 100 });
  assert.equal(comm.body.find((x) => x.id === sub.body.id)?.author_name, "Bếp Nhà Lan");
  assert.ok(!JSON.stringify(comm.body).includes("@elytra.test"), "không lộ email");
  assert.equal(errCode(await rpc("submit_recipe", A.token, { p_title: "Đổi", p_category: "mon_man", p_servings: 2, p_ingredients: ingr, p_instructions: steps, p_recipe_id: sub.body.id })), "RECIPE_LOCKED");

  // 9. Món của B (tên trống) hiện "Người dùng Elytra"
  const subB = await rpc("submit_recipe", B.token, { p_title: "Món của B", p_category: "mon_canh", p_servings: 1, p_ingredients: ingr, p_instructions: steps });
  recipes.push(subB.body.id);
  await rpc("admin_review_recipe", AD.token, { p_recipe_id: subB.body.id, p_approve: true, p_submitted_at: (await rpc("admin_list_pending_recipes", AD.token, { p_page_size: 100 })).body.find((x) => x.id === subB.body.id).submitted_at });
  assert.equal((await rpc("list_community_recipes", ANON_KEY, { p_page_size: 100 })).body.find((x) => x.id === subB.body.id)?.author_name, "Người dùng Elytra");

  // 10. Nguyên liệu đã có công thức dùng → xóa thành vô hiệu hóa; nhật ký: admin đọc được, user không
  assert.equal((await rpc("admin_delete_ingredient", AD.token, { p_id: ing.body.id })).body.action, "deactivated");
  assert.equal((await call(`/rest/v1/ingredients?select=id&id=eq.${ing.body.id}`)).body.length, 0, "anon không thấy nguyên liệu đã tắt");
  assert.equal((await call(`/rest/v1/ingredients?select=is_active&id=eq.${ing.body.id}`, { token: AD.token })).body[0]?.is_active, false, "admin vẫn thấy");
  assert.ok((await call(`/rest/v1/admin_audit_log?select=action&admin_id=eq.${AD.id}`, { token: AD.token })).body.length >= 4);
  assert.equal((await call(`/rest/v1/admin_audit_log?select=action`, { token: A.token })).body.length, 0, "user không đọc nhật ký admin");

  console.log("community + admin e2e: all checks passed");
} finally {
  for (const id of recipes) await admin(`/rest/v1/recipes?id=eq.${id}`, { method: "DELETE" });
  for (const id of ingredients) await admin(`/rest/v1/ingredients?id=eq.${id}`, { method: "DELETE" });
  if (files.length) await admin("/storage/v1/object/user-recipe-images", { method: "DELETE", body: { prefixes: files } });
  for (const id of users) {
    await admin(`/rest/v1/admin_audit_log?admin_id=eq.${id}`, { method: "DELETE" });
    await admin(`/rest/v1/recipes?created_by=eq.${id}`, { method: "DELETE" });
    await admin(`/auth/v1/admin/users/${id}`, { method: "DELETE" });
  }
}
