CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    source_url TEXT,
    category VARCHAR(50) NOT NULL DEFAULT 'mon_man',
    cuisine VARCHAR(50) NOT NULL DEFAULT 'vietnamese',
    servings INTEGER NOT NULL DEFAULT 4 CHECK (servings > 0),
    prep_time_minutes INTEGER NOT NULL DEFAULT 15 CHECK (prep_time_minutes >= 0),
    cook_time_minutes INTEGER NOT NULL DEFAULT 30 CHECK (cook_time_minutes >= 0),
    difficulty VARCHAR(20) NOT NULL DEFAULT 'easy' CHECK (difficulty IN ('easy', 'medium', 'hard')),
    instructions JSONB NOT NULL DEFAULT '[]'::jsonb,
    calories_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    protein_g_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    fat_g_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    carbs_g_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    fiber_g_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    sodium_mg_per_serving NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_calories NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_protein_g NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_fat_g NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_carbs_g NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_fiber_g NUMERIC(8,2) NOT NULL DEFAULT 0,
    total_sodium_mg NUMERIC(8,2) NOT NULL DEFAULT 0,
    is_verified BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES public.ingredients(id) ON DELETE SET NULL,
    order_index INTEGER NOT NULL DEFAULT 0,
    raw_text TEXT NOT NULL,
    ingredient_name_raw VARCHAR(255) NOT NULL,
    amount NUMERIC(10,2),
    unit VARCHAR(50),
    amount_g NUMERIC(10,2) NOT NULL DEFAULT 0,
    calories_per_100g NUMERIC(8,2) DEFAULT 0,
    protein_per_100g NUMERIC(8,2) DEFAULT 0,
    fat_per_100g NUMERIC(8,2) DEFAULT 0,
    carbs_per_100g NUMERIC(8,2) DEFAULT 0,
    fiber_per_100g NUMERIC(8,2) DEFAULT 0,
    sodium_mg_per_100g NUMERIC(8,2) DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.recipe_allergens (
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
    allergen_id INTEGER NOT NULL REFERENCES public.allergens(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (recipe_id, allergen_id)
);

CREATE INDEX IF NOT EXISTS idx_recipes_category ON public.recipes(category);
CREATE INDEX IF NOT EXISTS idx_recipes_cuisine ON public.recipes(cuisine);
CREATE INDEX IF NOT EXISTS idx_recipes_slug ON public.recipes(slug);
CREATE INDEX IF NOT EXISTS idx_recipes_calories ON public.recipes(calories_per_serving);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON public.recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_ingredient_id ON public.recipe_ingredients(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_recipe_allergens_recipe_id ON public.recipe_allergens(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_allergens_allergen_id ON public.recipe_allergens(allergen_id);

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_allergens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read-only access on recipes" ON public.recipes FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access on recipe_ingredients" ON public.recipe_ingredients FOR SELECT USING (true);
CREATE POLICY "Allow public read-only access on recipe_allergens" ON public.recipe_allergens FOR SELECT USING (true);

CREATE POLICY "Allow service role full access on recipes" ON public.recipes FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Allow service role full access on recipe_ingredients" ON public.recipe_ingredients FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Allow service role full access on recipe_allergens" ON public.recipe_allergens FOR ALL TO service_role USING (true) WITH CHECK (true);
;
