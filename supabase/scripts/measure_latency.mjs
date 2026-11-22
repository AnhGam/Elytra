// Đo thời gian phản hồi API thật trên Supabase (tìm món, nhật ký, ngân sách calo, gợi ý AI) và in bảng Markdown.
// Tạo 1 user tạm, chạy xong tự xóa. Không sửa dữ liệu mẫu.
// Chạy: SUPABASE_URL=... ANON_KEY=... SERVICE_ROLE_KEY=... node measure_latency.mjs
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

const users = [];
async function makeUser(name) {
  const email = `e2e-${crypto.randomUUID()}@elytra.test`, password = crypto.randomUUID();
  const u = await admin("/auth/v1/admin/users", { method: "POST", body: { email, password, email_confirm: true } });
  assert.equal(u.status, 200, JSON.stringify(u.body));
  users.push(u.body.id);
  await admin(`/rest/v1/profiles?id=eq.${u.body.id}`, { method: "PATCH", body: { full_name: name, target_calories: 2000, target_protein_g: 100, target_carbs_g: 200, target_fat_g: 60 } });
  const s = await call("/auth/v1/token?grant_type=password", { method: "POST", body: { email, password } });
  return { token: s.body.access_token, id: u.body.id };
}

const percentile = (sorted, q) => sorted[Math.ceil(q * sorted.length) - 1];

// Chạy tuần tự n lần: bỏ lần đầu (khởi động) khỏi p50/p95/max nhưng vẫn ghi nhận riêng
async function timeIt(label, n, fn, summarize) {
  let firstMs = 0;
  const times = [];
  const bodies = [];
  for (let i = 0; i < n; i++) {
    const t0 = performance.now();
    const res = await fn();
    const ms = Math.round(performance.now() - t0);
    if (res.status < 200 || res.status >= 300) {
      throw new Error(`${label} (lần ${i + 1}): HTTP ${res.status} ${JSON.stringify(res.body)}`);
    }
    bodies.push(res.body);
    if (i === 0) firstMs = ms;
    else times.push(ms);
  }
  times.sort((a, b) => a - b);
  return {
    label,
    n: n - 1,
    first_ms: firstMs,
    p50_ms: percentile(times, 0.5),
    p95_ms: percentile(times, 0.95),
    max_ms: times[times.length - 1],
    note: summarize ? summarize(bodies) : "",
  };
}

const aiNote = (bodies) => {
  const fb = bodies.filter((b) => b?.fallback === true).length;
  const mode = bodies.at(-1)?.decision_mode;
  return `fallback ${fb}/${bodies.length}${mode ? `; decision_mode=${mode}` : ""}`;
};

try {
  const { token } = await makeUser("Đo tốc độ");
  const rec = await call("/rest/v1/recipes?select=id&is_verified=eq.true&limit=1");
  assert.equal(rec.status, 200, JSON.stringify(rec.body));
  const recipeId = rec.body?.[0]?.id;
  assert.ok(recipeId, "không tìm thấy món đã duyệt");

  const rows = [
    await timeIt("search_recipes (20 món/trang)", 21, () => rpc("search_recipes", ANON_KEY, { p_page: 1, p_page_size: 20 })),
    await timeIt('search_recipes (từ khóa "ga")', 21, () => rpc("search_recipes", ANON_KEY, { p_query: "ga", p_page_size: 20 })),
    await timeIt("GET /meal-logs (Dashboard)", 21, () => call("/functions/v1/meal-logs", { token })),
    await timeIt("POST /meal-logs (ghi 1 món)", 11, () => call("/functions/v1/meal-logs", { method: "POST", token, body: { meal_type: "snack", recipe_id: recipeId, servings: 1 } })),
    await timeIt("meal_calorie_budget", 21, () => rpc("meal_calorie_budget", token, { p_meal_type: "dinner" })),
    await timeIt("recommend-ai (gợi ý món, có AI)", 6, () => call("/functions/v1/recommend-ai", { method: "POST", token, body: { meal_type: "dinner", target_calories: 600 } }), aiNote),
    await timeIt("recommend-ai (hỏi cách nấu)", 6, () => call("/functions/v1/recommend-ai", { method: "POST", token, body: { intent: "how_to_cook", recipe_id: recipeId } }), aiNote),
  ];

  console.log(`Đo lúc: ${new Date().toISOString()}, từ máy chạy script, Supabase project ${new URL(URL_).host}`);
  console.log("| API | số lần đo | lần đầu (ms) | p50 (ms) | p95 (ms) | max (ms) | ghi chú |");
  console.log("| --- | --- | --- | --- | --- | --- | --- |");
  for (const r of rows) {
    console.log(`| ${r.label} | ${r.n} | ${r.first_ms} | ${r.p50_ms} | ${r.p95_ms} | ${r.max_ms} | ${r.note} |`);
  }
  console.log("measure latency: done");
} finally {
  for (const id of users) {
    await admin(`/auth/v1/admin/users/${id}`, { method: "DELETE" });
  }
}
