// Sinh bộ 100 ca kiểm thử offline (tất định) cho AI kiểm duyệt món ăn từ JSON export.
// Chạy: node supabase/scripts/build_moderation_eval_set.mjs <JSON nguồn> <JSON đích>
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const [, , srcPath, outPath] = process.argv;
if (!srcPath || !outPath) {
  console.error(
    "Cách dùng: node supabase/scripts/build_moderation_eval_set.mjs <JSON nguồn> <JSON đích>"
  );
  process.exit(1);
}

const SPAM_CASES = [
  {
    title: "Mua bán iPhone giá rẻ",
    ingredients: [
      { name: "iPhone 15", grams: 200 },
      { name: "ốp lưng", grams: 50 },
    ],
    steps: ["Liên hệ 0909xxxxxx", "Giao hàng toàn quốc"],
  },
  {
    title: "Test test 123",
    ingredients: [
      { name: "test", grams: 100 },
      { name: "abc", grams: 100 },
    ],
    steps: ["test", "test"],
  },
  {
    title: "Cách sửa xe máy bị chết máy",
    ingredients: [
      { name: "bugi", grams: 50 },
      { name: "xăng", grams: 500 },
    ],
    steps: ["Tháo bugi", "Lau sạch rồi lắp lại"],
  },
  {
    title: "Bài thơ mùa thu",
    ingredients: [
      { name: "lá vàng", grams: 10 },
      { name: "gió heo may", grams: 1 },
    ],
    steps: ["Đọc chậm", "Ngắm trời"],
  },
  {
    title: "asdfghjkl",
    ingredients: [
      { name: "qwerty", grams: 100 },
      { name: "zxcv", grams: 100 },
    ],
    steps: ["asdf", "ghjk"],
  },
  {
    title: "Nhận code khuyến mãi miễn phí",
    ingredients: [
      { name: "link", grams: 1 },
      { name: "mã giảm giá", grams: 1 },
    ],
    steps: ["Bấm vào link", "Nhập thông tin thẻ"],
  },
  {
    title: "Hướng dẫn chơi game lên hạng",
    ingredients: [
      { name: "điện thoại", grams: 200 },
      { name: "tai nghe", grams: 100 },
    ],
    steps: ["Mở game", "Chơi 10 trận"],
  },
  {
    title: "Kem chống nắng tự làm",
    ingredients: [
      { name: "kem dưỡng", grams: 50 },
      { name: "tinh dầu", grams: 5 },
    ],
    steps: ["Trộn đều", "Thoa lên da"],
  },
  {
    title: "Làm xà phòng handmade",
    ingredients: [
      { name: "dầu dừa", grams: 300 },
      { name: "xút NaOH", grams: 45 },
    ],
    steps: ["Pha xút với nước", "Trộn với dầu, đổ khuôn"],
  },
  {
    title: "Thuốc diệt chuột",
    ingredients: [
      { name: "thuốc chuột", grams: 20 },
      { name: "mồi", grams: 100 },
    ],
    steps: ["Trộn thuốc vào mồi", "Đặt góc nhà"],
  },
  {
    title: "Món ăn ngon nhất thế giới",
    ingredients: [
      { name: "món ăn", grams: 100 },
      { name: "ngon", grams: 100 },
    ],
    steps: ["Nấu", "Ăn"],
  },
  {
    title: "Bán nhà mặt tiền quận 1",
    ingredients: [
      { name: "nhà", grams: 1 },
      { name: "sổ hồng", grams: 1 },
    ],
    steps: ["Xem nhà", "Đặt cọc"],
  },
  {
    title: "Cách học tiếng Anh nhanh",
    ingredients: [
      { name: "sách", grams: 300 },
      { name: "bút", grams: 10 },
    ],
    steps: ["Học từ vựng", "Luyện nói"],
  },
  {
    title: "Đồ chơi cho mèo",
    ingredients: [
      { name: "len", grams: 50 },
      { name: "bìa carton", grams: 100 },
    ],
    steps: ["Cuộn len", "Dán vào bìa"],
  },
  {
    title: "Sơn tường phòng ngủ",
    ingredients: [
      { name: "sơn nước", grams: 2000 },
      { name: "con lăn", grams: 1 },
    ],
    steps: ["Lau tường", "Lăn 2 lớp sơn"],
  },
];

const SPAM_CATEGORIES = ["mon_man", "mon_xao", "mon_canh"];

const WRONG_CATEGORY_MAP = {
  mon_canh: "mon_nuong",
  mon_xao: "mon_canh",
  mon_kho: "mon_an_sang",
  mon_nuong: "mon_canh",
  mon_an_sang: "mon_kho",
  mon_man: "gia_vi_an_kem",
  mon_chay: "mon_nuong",
};

const EXPECTED_COUNTS = {
  real: 45,
  spam: 15,
  wrong_servings: 15,
  wrong_category: 10,
  missing_allergen: 15,
};

const round1 = (n) => Math.round(n * 10) / 10;

// So sánh chuỗi theo mã ASCII để kết quả tất định trên mọi locale
const cmpAscii = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

const kcalOk = (kcal, category) =>
  category === "gia_vi_an_kem" ? true : kcal >= 150 && kcal <= 1000;

const caseId = (group, idx) => `${group}-${String(idx + 1).padStart(2, "0")}`;

function toInput(recipe) {
  const rawIngredients = Array.isArray(recipe.recipe_ingredients)
    ? [...recipe.recipe_ingredients]
    : [];
  rawIngredients.sort(
    (a, b) => (Number(a.order_index) || 0) - (Number(b.order_index) || 0)
  );
  const ingredients = rawIngredients.map((ing) => ({
    name: ing.ingredient_name_raw,
    grams: round1((Number(ing.amount_g) * Number(ing.consumed_pct)) / 100),
  }));

  const rawSteps = Array.isArray(recipe.instructions)
    ? [...recipe.instructions]
    : [];
  rawSteps.sort(
    (a, b) => (Number(a.step_number) || 0) - (Number(b.step_number) || 0)
  );
  const steps = rawSteps.map((s) =>
    [s.title, s.description].filter(Boolean).join(": ")
  );

  const codes = new Set();
  for (const item of recipe.recipe_allergens || []) {
    const code = item?.allergens?.code ?? item?.code;
    if (code) codes.add(code);
  }
  const allergen_codes = [...codes].sort(cmpAscii);

  return {
    title: recipe.title,
    category: recipe.category,
    servings: Number(recipe.servings),
    ingredients,
    steps,
    calories_per_serving: Number(recipe.calories_per_serving),
    protein_g_per_serving: Number(recipe.protein_g_per_serving),
    fat_g_per_serving: Number(recipe.fat_g_per_serving),
    carbs_g_per_serving: Number(recipe.carbs_g_per_serving),
    allergen_codes,
  };
}

const raw = readFileSync(srcPath, "utf8");
const recipes = JSON.parse(raw);
if (!Array.isArray(recipes)) {
  console.error("Dữ liệu JSON nguồn phải là mảng món ăn.");
  process.exit(1);
}

const R = [...recipes].sort((a, b) => cmpAscii(a.slug, b.slug));
if (R.length !== EXPECTED_COUNTS.real) {
  console.error(
    `Cần đúng ${EXPECTED_COUNTS.real} món trong nguồn, hiện có ${R.length}.`
  );
  process.exit(1);
}
const nonCond = R.filter((m) => m.category !== "gia_vi_an_kem");
if (nonCond.length < 25) {
  console.error(`Không đủ 25 món khác gia_vi_an_kem (hiện có ${nonCond.length}).`);
  process.exit(1);
}

const withAllergen = R.filter((m) => toInput(m).allergen_codes.length >= 1);
if (withAllergen.length < EXPECTED_COUNTS.missing_allergen) {
  console.error(
    `QUESTIONS: Chỉ có ${withAllergen.length} món có >= 1 mã dị ứng (cần ${EXPECTED_COUNTS.missing_allergen}).`
  );
  process.exit(1);
}

const cases = [];

// 1. real (45)
R.forEach((m, i) => {
  const input = toInput(m);
  cases.push({
    id: caseId("real", i),
    group: "real",
    flaw: null,
    input,
    expected: {
      is_dish: true,
      category: m.category,
      kcal_ok: kcalOk(input.calories_per_serving, m.category),
      allergens: [...input.allergen_codes],
    },
    note: "Món thật đã duyệt",
  });
});

// 2. spam (15)
SPAM_CASES.forEach((s, i) => {
  const category = SPAM_CATEGORIES[i % SPAM_CATEGORIES.length];
  cases.push({
    id: caseId("spam", i),
    group: "spam",
    flaw: "spam",
    input: {
      title: s.title,
      category,
      servings: 1,
      ingredients: s.ingredients.map((ing) => ({ ...ing })),
      steps: [...s.steps],
      calories_per_serving: 300,
      protein_g_per_serving: 10,
      fat_g_per_serving: 10,
      carbs_g_per_serving: 40,
      allergen_codes: [],
    },
    expected: {
      is_dish: false,
      category,
      kcal_ok: true,
      allergens: [],
    },
    note: "Không phải công thức món ăn",
  });
});

// 3. wrong_servings (15)
nonCond.slice(0, 15).forEach((m, i) => {
  const input = toInput(m);
  const k = Math.ceil(1300 / Math.max(input.calories_per_serving, 50));
  input.calories_per_serving = round1(input.calories_per_serving * k);
  input.protein_g_per_serving = round1(input.protein_g_per_serving * k);
  input.fat_g_per_serving = round1(input.fat_g_per_serving * k);
  input.carbs_g_per_serving = round1(input.carbs_g_per_serving * k);
  input.servings = Math.max(1, Math.round(input.servings / k));
  cases.push({
    id: caseId("wrong_servings", i),
    group: "wrong_servings",
    flaw: "wrong_servings",
    input,
    expected: {
      is_dish: true,
      category: m.category,
      kcal_ok: false,
      allergens: [...input.allergen_codes],
    },
    note: `Số khẩu phần sai: kcal/khẩu phần bị nhân ${k}`,
  });
});

// 4. wrong_category (10)
nonCond.slice(15, 25).forEach((m, i) => {
  const input = toInput(m);
  const fakeCat = WRONG_CATEGORY_MAP[m.category];
  if (!fakeCat) {
    console.error(`Thiếu ánh xạ wrong_category cho "${m.category}".`);
    process.exit(1);
  }
  input.category = fakeCat;
  cases.push({
    id: caseId("wrong_category", i),
    group: "wrong_category",
    flaw: "wrong_category",
    input,
    expected: {
      is_dish: true,
      category: m.category,
      kcal_ok: kcalOk(input.calories_per_serving, m.category),
      allergens: [...input.allergen_codes],
    },
    note: `Khai sai danh mục ${m.category} → ${fakeCat}`,
  });
});

// 5. missing_allergen (15)
withAllergen.slice(0, 15).forEach((m, i) => {
  const input = toInput(m);
  const origAllergens = [...input.allergen_codes];
  const removed = origAllergens[0];
  input.allergen_codes = origAllergens.slice(1);
  cases.push({
    id: caseId("missing_allergen", i),
    group: "missing_allergen",
    flaw: "missing_allergen",
    input,
    expected: {
      is_dish: true,
      category: m.category,
      kcal_ok: kcalOk(input.calories_per_serving, m.category),
      allergens: origAllergens,
    },
    note: `Thiếu tag dị ứng ${removed}`,
  });
});

// Kiểm tra chéo trước khi ghi file
if (cases.length !== 100) {
  throw new Error(`Tổng số ca phải là 100, nhận được ${cases.length}`);
}
const ids = new Set();
const groupCounts = {};
for (const c of cases) {
  if (ids.has(c.id)) throw new Error(`Trùng id: ${c.id}`);
  ids.add(c.id);
  groupCounts[c.group] = (groupCounts[c.group] || 0) + 1;
}
for (const [g, expectedCount] of Object.entries(EXPECTED_COUNTS)) {
  if (groupCounts[g] !== expectedCount) {
    throw new Error(
      `Nhóm ${g} phải có ${expectedCount} ca, nhận được ${groupCounts[g] || 0}`
    );
  }
}

const payload = {
  version: 1,
  source: srcPath,
  built_by: "supabase/scripts/build_moderation_eval_set.mjs",
  cases,
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
console.log(`moderation eval set: ${cases.length} ca → ${outPath}`);
