-- 1. Bảng hồ sơ thể trạng người dùng (User Profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    birth_date DATE,
    age INT,
    height_cm NUMERIC(5,1) CHECK (height_cm >= 50 AND height_cm <= 250),
    weight_kg NUMERIC(5,1) CHECK (weight_kg >= 20 AND weight_kg <= 300),
    activity_level VARCHAR(20) CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
    goal VARCHAR(20) CHECK (goal IN ('lose_weight', 'maintain', 'gain_weight')),
    dietary_preference VARCHAR(30) DEFAULT 'none',
    
    -- Chỉ số năng lượng & Macro chuẩn (tính từ BMR/TDEE Engine)
    bmi NUMERIC(4,1),
    bmr NUMERIC(6,1),
    tdee NUMERIC(6,1),
    target_calories NUMERIC(6,1),
    target_protein_g NUMERIC(5,1),
    target_fat_g NUMERIC(5,1),
    target_carbs_g NUMERIC(5,1),
    target_fiber_g NUMERIC(5,1),
    target_water_ml NUMERIC(6,1),
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Bảng dị ứng người dùng (User Allergens Mapping)
CREATE TABLE IF NOT EXISTS public.user_allergens (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    allergen_id INT REFERENCES public.allergens(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, allergen_id)
);

-- 3. Đánh chỉ mục
CREATE INDEX IF NOT EXISTS idx_user_allergens_user ON public.user_allergens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_allergens_allergen ON public.user_allergens(allergen_id);

-- 4. Kích hoạt Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_allergens ENABLE ROW LEVEL SECURITY;

-- 5. Policies: Người dùng chỉ được xem và cập nhật hồ sơ & dị ứng của chính mình
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own profile') THEN
        CREATE POLICY "Users can view own profile" 
            ON public.profiles FOR SELECT 
            TO authenticated 
            USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile') THEN
        CREATE POLICY "Users can update own profile" 
            ON public.profiles FOR UPDATE 
            TO authenticated 
            USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own profile') THEN
        CREATE POLICY "Users can insert own profile" 
            ON public.profiles FOR INSERT 
            TO authenticated 
            WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own allergens') THEN
        CREATE POLICY "Users can view own allergens" 
            ON public.user_allergens FOR SELECT 
            TO authenticated 
            USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage own allergens') THEN
        CREATE POLICY "Users can manage own allergens" 
            ON public.user_allergens FOR ALL 
            TO authenticated 
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 6. Trigger tự động tạo profile khi đăng ký auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email))
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();;
