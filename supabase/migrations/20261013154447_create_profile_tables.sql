-- ---------------------------------------------------------------------
-- 1. user_profiles – Hồ sơ cá nhân & mục tiêu macro (quan hệ 1:1 với auth.users)
-- ---------------------------------------------------------------------
create table public.user_profiles (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null unique
                      references auth.users (id) on delete cascade,

  -- ERD ghi NOT NULL, nhưng luồng onboarding không hỏi tên → tạm cho phép NULL
  full_name         varchar(100),

  gender            varchar(10) not null
                      check (gender in ('male', 'female')),

  -- App/api-contract gửi "age"; Edge Function quy đổi: current_date - age năm
  birth_date        date not null
                      check (birth_date <= current_date),

  height_cm         numeric(5,1) not null
                      check (height_cm > 50 and height_cm < 250),
  weight_kg         numeric(5,1) not null
                      check (weight_kg > 20 and weight_kg < 300),

  activity_level    varchar(20) not null
                      check (activity_level in
                        ('sedentary', 'light', 'moderate', 'active', 'very_active')),

  -- api-contract gọi là "goal"; cột trong ERD là health_goal
  health_goal       varchar(20) not null
                      check (health_goal in ('lose_weight', 'maintain', 'gain_muscle')),

  bmr               numeric(6,1),          -- Mifflin-St Jeor
  tdee              numeric(6,1),          -- BMR × hệ số vận động
  target_calories   numeric(6,1) not null check (target_calories > 500),
  target_protein_g  numeric(5,1) not null check (target_protein_g >= 0),
  target_carbs_g    numeric(5,1) not null check (target_carbs_g  >= 0),
  target_fat_g      numeric(5,1) not null check (target_fat_g    >= 0),

  diet_preference   varchar(30) not null default 'standard'
);

-- user_id đã UNIQUE nên tự có B-Tree index; thêm index cho diet_preference theo ERD
create index idx_user_profiles_diet_preference
  on public.user_profiles (diet_preference);

alter table public.user_profiles enable row level security;

-- Người dùng chỉ ĐỌC được hồ sơ của chính mình.
-- Không có policy insert/update: việc ghi do Edge Function calc-nutrition
-- (dùng service_role key, bỏ qua RLS) thực hiện khi save: true.
create policy "user_profiles: read own"
  on public.user_profiles
  for select
  to authenticated
  using (user_id = (select auth.uid()));


-- ---------------------------------------------------------------------
-- 2. allergens – Danh mục dị ứng chuẩn (master, ~10–20 dòng)
-- ---------------------------------------------------------------------
create table public.allergens (
  id           serial primary key,
  code         varchar(50)  not null unique,   -- vd: 'seafood', 'peanut', 'egg'
  name_vi      varchar(100) not null,          -- vd: 'Hải sản', 'Đậu phộng', 'Trứng'
  description  text
);

alter table public.allergens enable row level security;

-- Ai cũng đọc được (kể cả khi chưa đăng nhập, để hiện danh sách ở onboarding).
-- Không có policy ghi: chỉ Admin/service_role thêm sửa.
create policy "allergens: public read"
  on public.allergens
  for select
  to anon, authenticated
  using (true);


-- ---------------------------------------------------------------------
-- 3. user_allergens – Dị ứng của từng người dùng (N:N)
-- ---------------------------------------------------------------------
create table public.user_allergens (
  user_id      uuid not null references auth.users (id)       on delete cascade,
  allergen_id  int  not null references public.allergens (id) on delete restrict,
  created_at   timestamptz not null default now(),
  primary key (user_id, allergen_id)
);

-- PK (user_id, allergen_id) đã phục vụ tra cứu theo user_id.
-- Thêm index cho allergen_id (cột FK thứ hai) theo quy tắc "mọi FK đều có index".
create index idx_user_allergens_allergen_id
  on public.user_allergens (allergen_id);

alter table public.user_allergens enable row level security;

create policy "user_allergens: read own"
  on public.user_allergens
  for select
  to authenticated
  using (user_id = (select auth.uid()));
