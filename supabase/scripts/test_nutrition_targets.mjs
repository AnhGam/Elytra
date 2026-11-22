// Unit test hàm SQL public.calculate_nutrition_targets trên Postgres WASM (PGlite).
// Chạy: node supabase/scripts/test_nutrition_targets.mjs
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
  CREATE TABLE storage.buckets (id text PRIMARY KEY, name text, public bool, file_size_limit bigint, allowed_mime_types text[]);
  CREATE FUNCTION storage.foldername(name text) RETURNS text[] LANGUAGE sql AS $$ SELECT (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1] $$;
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

// Helper gọi hàm SQL và so sánh số theo dung sai
const calc = async (...args) =>
  (await one("SELECT calculate_nutrition_targets($1, $2, $3, $4, $5, $6) AS r", args)).r;

const approx = (actual, exp, field) => {
  const num = Number(actual);
  assert.ok(
    Math.abs(num - exp) <= 0.051,
    `${field}: SQL=${num}, kỳ vọng=${exp}`
  );
};

// Công thức chuẩn viết độc lập bằng JS (+1e-9 bù sai số biểu diễn IEEE 754 tại ranh giới .x5)
const r1 = (x) => Math.round((x + 1e-9) * 10) / 10;
const r0 = (x) => Math.round(x);
const FACTORS = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

const expected = (gender, age, h, w, activity, goal) => {
  const bmi = r1(w / (h / 100) ** 2);
  let bmi_classification;
  if (bmi < 18.5) bmi_classification = "Thiếu cân";
  else if (bmi < 23) bmi_classification = "Bình thường";
  else if (bmi < 25) bmi_classification = "Tiền béo phì (Thừa cân)";
  else bmi_classification = "Béo phì";

  const bmr = r1(10 * w + 6.25 * h - 5 * age + (gender === "female" ? -161 : 5));
  const factor = FACTORS[activity] ?? 1.375;
  const tdee = r1(bmr * factor);

  let target =
    goal === "lose_weight" ? tdee - 500 : goal === "gain_weight" ? tdee + 400 : tdee;
  if (gender === "female" && target < 1200) target = 1200;
  else if (gender !== "female" && target < 1500) target = 1500;

  const pFactor = goal === "lose_weight" ? 2.0 : goal === "gain_weight" ? 1.8 : 1.6;
  const protein_g = r1(w * pFactor);
  const fat_g = r1((target * 0.25) / 9);
  const carbs_g = r1(Math.max(target - protein_g * 4 - target * 0.25, 0) / 4);
  const fiber_g = Math.max(r1((target / 1000) * 14), 25);
  const water_ml = r0(w * 35);
  const calorie_difference = target - tdee;

  return {
    bmi,
    bmi_classification,
    bmr,
    tdee,
    target_calories: target,
    calorie_difference,
    protein_g,
    fat_g,
    carbs_g,
    fiber_g,
    water_ml,
  };
};

// 1. Ca mẫu tính tay (docs/api-contract.md mục 1)
const sample = await calc("male", 22, 170, 65, "moderate", "lose_weight");
const sampleExpected = {
  bmi: 22.5,
  bmr: 1607.5,
  tdee: 2491.6,
  target_calories: 1991.6,
  calorie_difference: -500,
  protein_g: 130,
  fat_g: 55.3,
  carbs_g: 243.4,
  fiber_g: 27.9,
  water_ml: 2275,
};
for (const [k, v] of Object.entries(sampleExpected)) {
  approx(sample[k], v, `ca mẫu.${k}`);
}
assert.equal(sample.bmi_classification, "Bình thường", "ca mẫu.bmi_classification");

// 2. Ma trận 90 ca
const genders = ["male", "female", "other"];
const activities = ["sedentary", "light", "moderate", "active", "very_active"];
const goals = ["lose_weight", "maintain", "gain_weight"];
const bodies = [
  [22, 170, 65],
  [60, 150, 40],
];
const numericFields = [
  "bmi",
  "bmr",
  "tdee",
  "target_calories",
  "calorie_difference",
  "protein_g",
  "fat_g",
  "carbs_g",
  "fiber_g",
  "water_ml",
];

let matrixCount = 0;
for (const gender of genders) {
  for (const activity of activities) {
    for (const goal of goals) {
      for (const [age, h, w] of bodies) {
        matrixCount++;
        const actual = await calc(gender, age, h, w, activity, goal);
        const exp = expected(gender, age, h, w, activity, goal);
        const tag = `[${gender},${age},${h},${w},${activity},${goal}]`;
        for (const f of numericFields) {
          approx(actual[f], exp[f], `${tag}.${f}`);
        }
        assert.equal(
          actual.bmi_classification,
          exp.bmi_classification,
          `${tag}.bmi_classification`
        );
      }
    }
  }
}
assert.equal(matrixCount, 90, "số ca ma trận phải là 90");

// 3. Sàn calo
const floorFemale = await calc("female", 60, 150, 40, "sedentary", "lose_weight");
assert.equal(Number(floorFemale.target_calories), 1200, "sàn calo nữ phải là 1200");
assert.notEqual(Number(floorFemale.calorie_difference), -500, "sàn calo nữ không được giữ chênh lệch -500");

const floorMale = await calc("male", 60, 150, 40, "sedentary", "lose_weight");
assert.equal(Number(floorMale.target_calories), 1500, "sàn calo nam phải là 1500");

const floorOther = await calc("other", 60, 150, 40, "sedentary", "lose_weight");
assert.equal(Number(floorOther.target_calories), 1500, "sàn calo other phải là 1500");

// 4. Ranh giới BMI (cao 200 cm -> bmi = w / 4)
const bmiCases = [
  [73, 18.3, "Thiếu cân"],
  [74, 18.5, "Bình thường"],
  [91.6, 22.9, "Bình thường"],
  [92, 23.0, "Tiền béo phì (Thừa cân)"],
  [100, 25.0, "Béo phì"],
];
for (const [w, expBmi, expClass] of bmiCases) {
  const res = await calc("male", 30, 200, w, "moderate", "maintain");
  approx(res.bmi, expBmi, `ranh giới BMI w=${w}.bmi`);
  assert.equal(res.bmi_classification, expClass, `ranh giới BMI w=${w}.bmi_classification`);
}

// 5. Mức vận động lạ -> hệ số 1.375
const unknownAct = await calc("male", 22, 170, 65, "unknown", "maintain");
approx(unknownAct.tdee, r1(1607.5 * 1.375), "mức vận động lạ.tdee");

// 6. Tỉ lệ macro (ca mẫu bước 1)
const mp = sample.macro_percentages;
const pctSum = Number(mp.protein_pct) + Number(mp.fat_pct) + Number(mp.carbs_pct);
assert.ok(
  pctSum >= 99.8 && pctSum <= 100.2,
  `tổng macro_percentages phải trong [99.8, 100.2], đang là ${pctSum}`
);

console.log("nutrition targets: all checks passed (" + matrixCount + " ca ma trận)");
