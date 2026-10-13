alter table public.user_profiles
  add column target_weight_kg      numeric(5,1)
    check (target_weight_kg > 20 and target_weight_kg < 300),
  add column workout_hours_per_day smallint
    check (workout_hours_per_day between 0 and 4),
  add column prefer_gym_cutting    boolean not null default false,  -- "Tập gym kết hợp siết calo"
  add column prefer_healthy_eating boolean not null default false;  -- "Ăn uống lành mạnh"

-- Duy trì: không có cân nặng mục tiêu / giờ tập.
-- Giảm cân: mục tiêu < cân nặng hiện tại. Tăng cơ: mục tiêu > cân nặng hiện tại.
alter table public.user_profiles
  add constraint user_profiles_goal_plan_check check (
    (health_goal = 'maintain'
       and target_weight_kg is null and workout_hours_per_day is null)
    or (health_goal = 'lose_weight'
       and target_weight_kg < weight_kg and workout_hours_per_day is not null)
    or (health_goal = 'gain_muscle'
       and target_weight_kg > weight_kg and workout_hours_per_day is not null)
  );