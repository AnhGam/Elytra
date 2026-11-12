// Kiểm thử Edge Function recommend-ai + món yêu thích + RLS trên Supabase thật. Tạo 2 user tạm, chạy xong tự xóa.
// Chạy: SUPABASE_URL=... ANON_KEY=... SERVICE_ROLE_KEY=... node test_recommend_ai_e2e.mjs
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
const ai = (token, body) => call("/functions/v1/recommend-ai", { method: "POST", token, body });

const users = [];
async function makeUser(target) {
  const email = `e2e-${crypto.randomUUID()}@elytra.test`, password = crypto.randomUUID();
  const u = await admin("/auth/v1/admin/users", { method: "POST", body: { email, password, email_confirm: true } });
  assert.equal(u.status, 200, JSON.stringify(u.body));
  users.push(u.body.id);
  await admin(`/rest/v1/profiles?id=eq.${u.body.id}`, {
    method: "PATCH",
    body: { target_calories: target, target_protein_g: 120, target_carbs_g: 200, target_fat_g: 60, goal: "lose_weight" },
  });
  const s = await call("/auth/v1/token?grant_type=password", { method: "POST", body: { email, password } });
  return { token: s.body.access_token, id: u.body.id };
}

try {
  const A = await makeUser(2000), B = await makeUser(1800);

  // 1. Gợi ý bình thường: 10 ứng viên, có lời giải thích, báo rõ mô hình nào đã chọn
  const r1 = await ai(A.token, { meal_type: "lunch", message: "Trưa nay muốn ăn món nước, ít dầu mỡ" });
  assert.equal(r1.status, 200, JSON.stringify(r1.body));
  assert.equal(r1.body.status, "ok");
  assert.equal(r1.body.budget.target_kcal, 700, "trưa = 2000 × 35%");
  assert.equal(r1.body.suggested_recipes.length, 10);
  assert.ok(r1.body.message.length > 20);
  const probs = r1.body.suggested_recipes.map((x) => x.decision_probability);
  console.log("decision_mode:", r1.body.decision_mode, "| fallback (Gemini chat lỗi):", r1.body.fallback);
  console.log("top 3:", r1.body.suggested_recipes.slice(0, 3).map((x) => `${x.title} (${x.decision_probability ?? "-"})`).join(" | "));
  console.log("message:", r1.body.message.slice(0, 300).replace(/\n/g, " "));
  if (r1.body.decision_mode === "model") {
    assert.ok(Math.abs(probs.reduce((a, b) => a + b, 0) - 1) < 0.02, "xác suất cộng lại ≈ 1");
    assert.deepEqual(probs, [...probs].sort((a, b) => b - a), "xếp theo xác suất giảm dần");
  }

  // 2. Từ chối món đầu → không quay lại, cùng phiên chat
  const top = r1.body.suggested_recipes[0];
  const r2 = await ai(A.token, { session_id: r1.body.session_id, meal_type: "lunch", rejected_recipe_ids: [top.id] });
  assert.equal(r2.status, 200);
  assert.equal(r2.body.session_id, r1.body.session_id);
  assert.ok(!r2.body.suggested_recipes.some((x) => x.id === top.id), "món bị từ chối không quay lại");

  // 3. Lịch sử chat lưu xác suất + món từ chối; B không đọc được chat của A
  const msgs = (await call(`/rest/v1/chat_messages?session_id=eq.${r1.body.session_id}&order=created_at`, { token: A.token })).body;
  assert.equal(msgs.length, 4, "2 lượt user + 2 lượt assistant");
  assert.deepEqual(msgs[2].rejected_recipe_ids, [top.id]);
  assert.equal(msgs[1].metadata.decision_mode, r1.body.decision_mode);
  assert.equal((await call(`/rest/v1/chat_messages?session_id=eq.${r1.body.session_id}`, { token: B.token })).body.length, 0);
  // B không chèn được tin nhắn vào phiên của A (kể cả với user_id của chính B)
  const inject = await call("/rest/v1/chat_messages", { method: "POST", token: B.token,
    body: { session_id: r1.body.session_id, user_id: B.id, role: "assistant", content: "rác" } });
  assert.notEqual(inject.status, 201, "không ghi vào phiên người khác");
  // session_id của người khác → server tạo phiên mới, không ghi vào phiên của A
  const rB = await ai(B.token, { session_id: r1.body.session_id, meal_type: "lunch" });
  assert.notEqual(rB.body.session_id, r1.body.session_id);

  // 4. Kiểm tra input. null = không gửi (Dart gửi 'session_id': null ở lượt đầu)
  const nulls = await ai(A.token, { session_id: null, intent: null, recipe_id: null, target_calories: null, meal_type: "lunch" });
  assert.equal(nulls.status, 200, JSON.stringify(nulls.body));
  assert.ok(nulls.body.session_id, "tạo phiên mới");
  assert.equal((await ai(A.token, { accepted_recipe_id: top.id, client_request_id: "abc" })).status, 400);
  assert.equal((await ai(A.token, { meal_type: "brunch" })).status, 400);
  assert.equal((await ai(A.token, { rejected_recipe_ids: ["x"] })).status, 400);
  assert.equal((await ai(A.token, { message: "a".repeat(501) })).status, 400);
  assert.equal((await ai(ANON_KEY, {})).status, 401, "anon key không gọi được");

  // 5. Không gọi RPC bằng uid người khác (SECURITY DEFINER)
  const spoof = await call("/rest/v1/rpc/recommend_dishes_for_user", { method: "POST", token: A.token, body: { p_uid: B.id } });
  assert.notEqual(spoof.status, 200, "gọi bằng uid người khác phải bị chặn");
  assert.equal((await call("/rest/v1/rpc/meal_calorie_budget", { method: "POST", body: {} })).status !== 200, true, "anon không gọi được");

  // 6. "Ăn món này" → ghi nhật ký, chống ghi trùng khi retry
  const reqId = crypto.randomUUID();
  const acc = await ai(A.token, { session_id: r1.body.session_id, meal_type: "lunch", accepted_recipe_id: r2.body.suggested_recipes[0].id, client_request_id: reqId });
  assert.equal(acc.status, 200, JSON.stringify(acc.body));
  assert.equal(acc.body.status, "logged");
  assert.ok(acc.body.budget.consumed.kcal > 0);
  const acc2 = await ai(A.token, { meal_type: "lunch", accepted_recipe_id: r2.body.suggested_recipes[0].id, client_request_id: reqId });
  assert.equal(acc2.body.logged.id, acc.body.logged.id, "retry không ghi trùng");
  assert.equal((await ai(A.token, { accepted_recipe_id: crypto.randomUUID() })).status, 404);

  // 7. Món yêu thích: RLS
  const fav = r1.body.suggested_recipes[5].id;
  assert.equal((await call("/rest/v1/user_favorite_recipes", { method: "POST", token: A.token, body: { recipe_id: fav } })).status, 201);
  assert.equal((await call("/rest/v1/user_favorite_recipes", { method: "POST", token: A.token, body: { recipe_id: fav } })).status, 409, "không nhân bản");
  assert.equal((await call("/rest/v1/user_favorite_recipes", { token: B.token })).body.length, 0, "B không thấy yêu thích của A");
  assert.notEqual((await call("/rest/v1/user_favorite_recipes", { method: "POST", token: B.token, body: { user_id: A.id, recipe_id: fav } })).status, 201,
    "B không thêm hộ A");
  assert.notEqual((await call("/rest/v1/user_favorite_recipes", { method: "POST", body: { recipe_id: fav } })).status, 201, "anon không thêm được");
  await call(`/rest/v1/user_favorite_recipes?recipe_id=eq.${fav}`, { method: "DELETE", token: B.token });
  assert.equal((await call("/rest/v1/user_favorite_recipes", { token: A.token })).body.length, 1, "B không xóa được của A");
  const rFav = await ai(A.token, { meal_type: "lunch" });
  assert.ok(rFav.body.suggested_recipes.some((x) => x.id === fav && x.is_favorite), "món yêu thích được gắn cờ");

  // 8. Ăn quá mục tiêu → goal_reached, không gợi ý món chính
  const big = (await call("/rest/v1/recipes?select=id&is_verified=eq.true&order=calories_per_serving.desc&limit=1", { token: B.token })).body[0];
  await call("/rest/v1/rpc/log_meal", { method: "POST", token: B.token, body: { p_meal_type: "breakfast", p_recipe_id: big.id, p_servings: 3 } });
  const done = await ai(B.token, { meal_type: "dinner" });
  assert.equal(done.status, 200);
  assert.equal(done.body.status, "goal_reached");
  assert.equal(done.body.suggested_recipes.length, 0);

  // 9. Hỏi cách nấu / dinh dưỡng (chip gửi intent + recipe_id): số liệu lấy từ DB
  const dishId = r1.body.suggested_recipes[0].id;
  const db = (await call(`/rest/v1/recipes?select=calories_per_serving,instructions&id=eq.${dishId}`, { token: A.token })).body[0];
  const cook = await ai(A.token, { session_id: r1.body.session_id, intent: "how_to_cook", recipe_id: dishId });
  assert.equal(cook.status, 200, JSON.stringify(cook.body));
  assert.deepEqual([cook.body.intent, cook.body.status], ["how_to_cook", "answered"]);
  assert.equal(cook.body.recipe.id, dishId);
  assert.equal(cook.body.recipe.instructions.length, db.instructions.length);
  assert.ok(cook.body.recipe.ingredients.length > 0);
  console.log("how_to_cook (fallback:", cook.body.fallback + "):", cook.body.message.slice(0, 160).replace(/\n/g, " "));
  const nut = await ai(A.token, { intent: "nutrition", recipe_id: dishId });
  assert.equal(nut.body.recipe.calories_per_serving, db.calories_per_serving, "số liệu đúng DB");
  assert.equal((await ai(A.token, { intent: "how_to_cook" })).status, 400, "chip hỏi món phải có recipe_id");
  assert.equal((await ai(A.token, { intent: "nutrition", recipe_id: crypto.randomUUID() })).status, 404);
  assert.equal((await ai(A.token, { intent: "dance" })).status, 400);

  // 10. Gõ tự do: mô hình quyết định phân loại câu; hỏi "món này" → món đầu của lượt gợi ý gần nhất
  const freeCook = await ai(A.token, { session_id: r1.body.session_id, message: "Món này nấu như thế nào vậy?" });
  console.log("free text: nấu thế nào →", freeCook.body.intent, "| món:", freeCook.body.recipe?.title, "| top lượt đổi món:", r2.body.suggested_recipes[0].title);
  const freeOut = await ai(A.token, { message: "Giá vàng hôm nay bao nhiêu?" });
  console.log("free text 'giá vàng' →", freeOut.body.intent);
  if (r1.body.decision_mode === "model") {
    assert.equal(freeCook.body.intent, "how_to_cook");
    assert.equal(freeCook.body.recipe.id, r2.body.suggested_recipes[0].id, "món đầu của lượt gợi ý gần nhất (sau khi đổi món)");
    assert.equal(freeOut.body.intent, "out_of_scope");
    assert.equal(freeOut.body.suggested_recipes.length, 0);
  }

  console.log("recommend-ai e2e: all checks passed");
} finally {
  for (const id of users) await admin(`/auth/v1/admin/users/${id}`, { method: "DELETE" });
}
