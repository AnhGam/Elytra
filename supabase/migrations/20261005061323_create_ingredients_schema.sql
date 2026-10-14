-- 1. Bảng danh mục phân loại nguyên liệu
CREATE TABLE IF NOT EXISTS ingredient_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    roman VARCHAR(10),
    name_vi VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    display_order INT DEFAULT 0
);

-- 2. Bảng danh mục dị ứng chuẩn
CREATE TABLE IF NOT EXISTS allergens (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name_vi VARCHAR(100) NOT NULL,
    description TEXT
);

-- 3. Bảng nguyên liệu chính (Master Ingredients)
CREATE TABLE IF NOT EXISTS ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name_vi VARCHAR(150) NOT NULL,
    name_en VARCHAR(150),
    name_unaccented VARCHAR(150),
    category_id INT NOT NULL REFERENCES ingredient_categories(id) ON DELETE RESTRICT,
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    edible_portion_pct NUMERIC(5,1) DEFAULT 100.0 CHECK (edible_portion_pct >= 0 AND edible_portion_pct <= 100),
    density_g_per_ml NUMERIC(4,2) DEFAULT 1.00 CHECK (density_g_per_ml > 0),
    
    calories_per_100g NUMERIC(6,1) NOT NULL CHECK (calories_per_100g >= 0),
    protein_per_100g NUMERIC(5,1) NOT NULL CHECK (protein_per_100g >= 0),
    fat_per_100g NUMERIC(5,1) NOT NULL CHECK (fat_per_100g >= 0),
    carbs_per_100g NUMERIC(5,1) NOT NULL CHECK (carbs_per_100g >= 0),
    fiber_per_100g NUMERIC(5,1) DEFAULT 0 CHECK (fiber_per_100g >= 0),
    water_g NUMERIC(5,1) DEFAULT 0 CHECK (water_g >= 0),
    ash_g NUMERIC(5,1) DEFAULT 0 CHECK (ash_g >= 0),
    
    calcium_mg NUMERIC(6,1),
    phosphorus_mg NUMERIC(6,1),
    iron_mg NUMERIC(6,2),
    zinc_mg NUMERIC(6,2),
    sodium_mg NUMERIC(6,1),
    potassium_mg NUMERIC(6,1),
    magnesium_mg NUMERIC(6,1),
    manganese_mg NUMERIC(6,3),
    copper_mcg NUMERIC(6,1),
    selenium_mcg NUMERIC(6,1),
    
    vit_c_mg NUMERIC(6,1),
    thiamine_b1_mg NUMERIC(6,2),
    riboflavin_b2_mg NUMERIC(6,2),
    niacin_b3_mg NUMERIC(6,2),
    pantothenic_b5_mg NUMERIC(6,3),
    vit_b6_mg NUMERIC(6,3),
    folate_b9_mcg NUMERIC(6,1),
    vit_b12_mcg NUMERIC(6,2),
    retinol_mcg NUMERIC(6,1),
    vit_a_rae_mcg NUMERIC(6,1),
    vit_d_mcg NUMERIC(6,2),
    vit_e_mg NUMERIC(6,2),
    vit_k_mcg NUMERIC(6,1),
    beta_carotene_mcg NUMERIC(6,1),
    
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Bảng liên kết nguyên liệu & dị ứng
CREATE TABLE IF NOT EXISTS ingredient_allergens (
    ingredient_id UUID REFERENCES ingredients(id) ON DELETE CASCADE,
    allergen_id INT REFERENCES allergens(id) ON DELETE CASCADE,
    PRIMARY KEY (ingredient_id, allergen_id)
);

-- 5. Đánh chỉ mục tối ưu hóa
CREATE INDEX IF NOT EXISTS idx_ingredients_category ON ingredients(category_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_active ON ingredients(id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_ingredients_featured ON ingredients(id) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_ingredients_name_vi ON ingredients(name_vi);
CREATE INDEX IF NOT EXISTS idx_ingredients_unaccented ON ingredients(name_unaccented);
CREATE INDEX IF NOT EXISTS idx_ingredient_allergens_allergen ON ingredient_allergens(allergen_id);

-- RLS
ALTER TABLE ingredient_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredient_allergens ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public read on ingredient_categories') THEN
        CREATE POLICY "Allow public read on ingredient_categories" ON ingredient_categories FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public read on allergens') THEN
        CREATE POLICY "Allow public read on allergens" ON allergens FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public read on ingredients') THEN
        CREATE POLICY "Allow public read on ingredients" ON ingredients FOR SELECT USING (is_active = true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public read on ingredient_allergens') THEN
        CREATE POLICY "Allow public read on ingredient_allergens" ON ingredient_allergens FOR SELECT USING (true);
    END IF;
END $$;;
