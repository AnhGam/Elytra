-- Migration: 20261005000008_seed_recipes.sql
-- Description: Seed 45 authentic Vietnamese recipes, ingredients, and inherited allergens

DO $$
DECLARE
  v_recipe_id UUID;
BEGIN

  -- [1] Recipe: Đậu Hũ Nhồi Thịt Sốt Cà Chua
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Đậu Hũ Nhồi Thịt Sốt Cà Chua', 'dau-hu-nhoi-thit-sot-ca-chua', 'Chào mọi người, lại là Bếp đây! 👋 Hôm nay Bếp muốn chia sẻ với các bạn một món ăn tuy quen mà lạ – đậu hũ nhồi thịt sốt cà chua. Quen vì đậu hũ với thịt xay thì nhà nào cũng hay có sẵn, mà lạ vì cách kết hợp này ăn hao [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/dauhudonthit.jpg', 'https://bepxua.vn/dau-hu-nhoi-thit-sot-ca-chua-%f0%9f%8d%85-mon-com-nha-ai-an-cung-ghien/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1: Sơ Chế Đậu Hũ Và Làm Nhân Thịt","description":"Đậu hũ mua về cắt đôi, dùng muỗng nạo bỏ bớt phần ruột ở giữa để tạo khoảng trống nhồi nhân (nhớ nạo nhẹ tay kẻo bể đậu nha mọi người).\n\n\n\nThịt xay cho vào tô, thêm 1/2 phần hành tím, hành lá, ngò rí đã chuẩn bị, nêm 1 muỗng cà phê hạt nêm, 1 muỗng cà phê đường, 1 muỗng cà phê nước mắm, 1 ít tiêu xay rồi trộn đều tay cho thịt thấm gia vị."},{"step_number":2,"title":"Bước 2: Nhồi Thịt Vào Đậu Hũ","description":"Múc nhân thịt dồn vào từng miếng đậu hũ đã khoét ruột, dùng muỗng ém chặt tay để nhân không bị rớt ra khi chiên."},{"step_number":3,"title":"Bước 3: Chiên Đậu Hũ","description":"Bắc chảo lên bếp, làm nóng dầu rồi cho đậu hũ vào chiên với lửa vừa. Chiên đến khi mặt đậu vàng đều thì lật mặt còn lại, chiên tiếp cho vàng giòn cả hai mặt. Vớt đậu ra để riêng, để ráo bớt dầu.\n\n\n\n💡 Mẹo nhỏ từ Bếp: để lửa vừa thôi mọi người nhé, lửa lớn quá đậu dễ cháy vỏ mà nhân thịt bên trong chưa kịp chín đâu."},{"step_number":4,"title":"Bước 4: Nấu Sốt Cà Chua","description":"Cho 2 muỗng canh dầu ăn vào chảo, phi thơm phần gốc hành lá và hành tím còn lại. Sau đó cho cà chua vào xào khoảng 2 phút cho cà mềm nhũn ra.\n\n\n\nNêm vào 1 muỗng canh đường (gia giảm tùy độ chua của trái cà), 1 muỗng canh nước mắm, 1 muỗng canh nước tương, 1 muỗng canh tương ớt, 1 muỗng canh tương cà. Đảo đều tay khoảng 1-2 phút cho hỗn hợp sốt hòa quyện."},{"step_number":5,"title":"Bước 5: Om Đậu Hũ Với Sốt","description":"Đổ 150ml nước lọc vào chảo sốt, cho đậu hũ đã chiên vào. Lật đều các mặt đậu, om với lửa nhỏ khoảng 2-3 phút cho đậu thấm đều sốt cà chua sóng sánh."},{"step_number":6,"title":"Bước 6: Hoàn Thành","description":"Rắc thêm hành lá, ngò rí, tiêu xay lên trên cho dậy mùi thơm là xong! Múc ra dĩa, ăn nóng với cơm trắng thì khỏi phải bàn, đảm bảo nồi cơm hết sạch veo. 😋"}]'::jsonb,
    310.8, 22.3, 16.6, 17.8, 1.5, 3180.9,
    1243.4, 89.2, 66.4, 71.4, 5.9, 12723.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'd9ce50a4-4865-4c7e-9a1c-20a8146f3c33'::uuid, 1, 'Đậu hũ: 4 miếng (400g)', 'Đậu hũ', 4, 'miếng', 400, 97, 10.9, 5.4, 1.1, 0.4, 7),
    (v_recipe_id, '053ccf2e-c2ce-4ec7-a3e0-1acac583971d'::uuid, 2, 'Thịt xay: 200g', 'Thịt xay', 200, 'g', 200, 139, 19, 7, 0, 0, 76),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'Hành tím: 10g (xắt lát, băm sơ – dùng 1/2 cho nhân, 1/2 để phi thơm sốt)', 'Hành tím', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 4, 'Hành lá: để riêng phần gốc và phần lá, xắt nhỏ (dùng 1/2 cho nhân, 1/2 rắc lên trên)', 'Hành lá', 1, 'phần', 30, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 5, 'Ngò rí: xắt nhỏ (dùng 1/2 cho nhân, 1/2 rắc lên trên)', 'Ngò rí', 1, 'phần', 30, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'Hạt nêm: 1 muỗng cà phê', 'Hạt nêm', 1, 'muỗng cà', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 7, 'Đường: 1 muỗng cà phê', 'Đường', 1, 'muỗng cà', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 8, 'Nước mắm: 1 muỗng cà phê', 'Nước mắm', 1, 'muỗng cà', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 9, 'Tiêu xay: 1 ít', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 10, 'Cà chua: 4 trái, xắt nhỏ, băm sơ', 'Cà chua', 4, 'trái', 300, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 11, 'Dầu ăn: 2 muỗng canh', 'Dầu ăn', 2, 'muỗng canh', 30, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 12, 'Đường: 1 muỗng canh (gia giảm tùy độ chua của cà)', 'Đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 13, 'Nước mắm: 1 muỗng canh', 'Nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 14, 'Nước tương: 1 muỗng canh', 'Nước tương', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 15, 'Tương ớt: 1 muỗng canh', 'Tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 16, 'Tương cà: 1 muỗng canh', 'Tương cà', 1, 'muỗng canh', 15, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, NULL, 17, 'Nước lọc: 150ml', 'Nước lọc', 150, 'ml', 150, 0, 0, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6),
    (v_recipe_id, 8),
    (v_recipe_id, 4)
  ON CONFLICT DO NOTHING;

  -- [2] Recipe: Cá Nục Kho Nước Mía Đậm Đà, Ngọt Thanh
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cá Nục Kho Nước Mía Đậm Đà, Ngọt Thanh', 'ca-nuc-kho-nuoc-mia-dam-da-ngot-thanh-an-com-hay-banh-mi-deu-cuon', 'Meta description: Cách làm cá nục kho nước mía đậm đà, thịt cá săn chắc, nước kho sánh keo ngọt thanh tự nhiên. Công thức chi tiết, dễ làm tại nhà, ăn với cơm hay bánh mì đều ngon. Từ khóa mục tiêu: cá nục kho nước mía, cách kho cá nục, cá nục kho, [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/ca-nuc-kho-rucs.jpg', 'https://bepxua.vn/ca-nuc-kho-nuoc-mia-dam-da-ngot-thanh-an-com-hay-banh-mi-deu-cuon/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1: Sơ chế cá","description":"Cá nục mua về Bếp làm sạch, đánh vảy, bỏ ruột, rửa lại cho hết nhớt và mùi tanh, để ráo."},{"step_number":2,"title":"Bước 2: Giã hành ớt","description":"Hành tím và ớt giã nát để khi ướp gia vị thấm đều và dậy mùi thơm hơn."},{"step_number":3,"title":"Bước 3: Ướp cá","description":"Cho tất cả gia vị gồm nước mắm, nước tương, nước màu thốt nốt, đường thốt nốt, muối, bột ngọt, mỡ heo và phần hành ớt giã vào tô cá. Trộn đều tay để cá thấm gia vị từ trong ra ngoài. Bọc kín tô, ướp cá khoảng 1-2 tiếng cho thấm."},{"step_number":4,"title":"Bước 4: Kho sơ cho cá săn","description":"Cho cá vào nồi, kho lửa vừa khoảng 2-3 phút đến khi thấy cá săn lại là được, chưa cần đổ nước vội."},{"step_number":5,"title":"Bước 5: Thêm nước mía, kho liu riu","description":"Đổ 300ml nước mía vào nồi, đậy nắp, để lửa nhỏ liu riu kho khoảng 45-60 phút. Đây là bước quan trọng nhất, mọi người nhớ để lửa nhỏ thôi để cá chín từ từ, thấm gia vị đều mà không bị nát."},{"step_number":6,"title":"Bước 6: Hoàn thiện","description":"Kho gần được 1 tiếng, nước kho sẽ sánh keo lại, bám đều quanh miếng cá. Bếp thường cho thêm vài lát ớt lên trên cho món ăn bắt mắt hơn trước khi tắt bếp."}]'::jsonb,
    746.2, 53.4, 21.9, 83.6, 0.2, 2286.7,
    2985, 213.5, 87.7, 334.5, 0.8, 9147, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'e4f5f6ab-2f28-467b-b2ec-16f889e30e67'::uuid, 1, '1 kg cá nục, sơ chế sạch', 'cá nục', 1, 'kg', 1000, 111, 20.2, 3.3, 0, 0, 104),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 2, '5 muỗng canh nước mắm', 'nước mắm', 5, 'muỗng canh', 75, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 3, '5 muỗng canh nước tương', 'nước tương', 5, 'muỗng canh', 75, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 4, '1 muỗng canh nước màu thốt nốt', 'nước màu thốt nốt', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 5, '1 muỗng canh đường thốt nốt', 'đường thốt nốt', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, '1 muỗng cà phê muối', 'muối', 1, 'muỗng cà phê', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, '1 muỗng cà phê bột ngọt', 'bột ngọt', 1, 'muỗng cà phê', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 8, '4 muỗng canh mỡ heo', 'mỡ heo', 4, 'muỗng canh', 60, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 9, '20g hành tím', 'hành tím', 20, 'g', 20, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 10, 'Ớt (lượng tùy thích)', 'Ớt (lượng tùy thích)', 1, 'ít', 2, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 11, '300 ml nước mía', 'nước mía', 300, 'ml', 300, 397, 0, 0, 99.3, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [3] Recipe: Mì Xào Bò Đậm Đà, Sợi Mì Dai, Thịt Bò Giòn Béo
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Mì Xào Bò Đậm Đà, Sợi Mì Dai, Thịt Bò Giòn Béo', 'cach-lam-mi-xao-bo-dam-da-soi-mi-dai-thit-bo-gion-beo', 'Hôm nay mình muốn chia sẻ với cả nhà một món ăn "cứu đói" cực kỳ hợp lý những hôm bận rộn mà vẫn muốn có bữa cơm tươm tất: mì xào bò. Chỉ với vài nguyên liệu quen thuộc trong bếp, chưa đến 20 phút là đã có ngay một dĩa mì xào nóng [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/mi-xao-bo.jpg', 'https://bepxua.vn/cach-lam-mi-xao-bo-dam-da-soi-mi-dai-thit-bo-gion-beo/', 'mon_an_sang', 'vietnamese',
    4, 15, 20, 'medium', '[{"step_number":1,"title":"Bước 1 – Ướp thịt bò: ","description":"Thịt bò xắt lát mỏng, trộn đều với hạt nêm, dầu hào, dầu ăn và tiêu xay. Để khoảng 10-15 phút cho thấm."},{"step_number":2,"title":"Bước 2 – Pha sốt xào: ","description":"Trộn đều gói gia vị mì, nước tương, dầu hào, đường, tương cà và tương ớt trong một chén nhỏ, khuấy đều cho tan hết."},{"step_number":3,"title":"Bước 3 – Luộc mì: ","description":"Đun sôi nước, cho mì vào luộc khoảng 2 phút cho mì vừa mềm tới, vớt ra để ráo. Không luộc quá lâu kẻo mì bị nhũn, mất độ dai khi xào."},{"step_number":4,"title":"Bước 4 – Xào thịt bò: ","description":"Bắc chảo nóng, cho 1 muỗng canh mỡ vào, phi thơm 1/2 phần tỏi xay. Cho thịt bò vào xào lửa lớn khoảng 1 phút cho thịt vừa chín tới, giòn béo. Xào lửa lớn là bí quyết để thịt bò không bị dai và ra nước nhiều đó cả nhà. Xào xong gắp thịt ra dĩa để riêng."},{"step_number":5,"title":"Bước 5 – Xào cải: ","description":"Cùng chảo đó, cho thêm 2 muỗng canh mỡ, phi thơm phần tỏi xay còn lại. Cho cải ngọt vào đảo đến khi vừa xìu, thêm 1 muỗng canh sốt xào vào đảo đều cho cải thấm và chín tới."},{"step_number":6,"title":"Bước 6 – Trộn mì: ","description":"Cho mì đã luộc vào chảo, dùng đũa xốc nhẹ cho mì tơi ra, không bị vón cục. Rưới hết phần sốt xào còn lại vào, xốc đều tay cho mì thấm sốt và quyện với cải."},{"step_number":7,"title":"Bước 7 – Hoàn thiện: ","description":"Cho thịt bò và hành tây vào, xốc thêm khoảng 30 giây cho tất cả nguyên liệu hòa quyện rồi tắt bếp. Gắp ra dĩa, rắc thêm ngò rí và chút tiêu xay lên trên là xong."}]'::jsonb,
    214.2, 17, 8.3, 18, 1.3, 1116.2,
    856.7, 68.1, 33.1, 71.9, 5.2, 4464.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'c893db6c-a1b2-4e27-bbb0-92724957e044'::uuid, 1, 'Thịt bò: 250g (xắt lát mỏng)', 'Thịt bò', 250, 'g', 250, 118, 21, 3.8, 0, 0, 83),
    (v_recipe_id, '5b441af9-af33-48c9-b6b2-127992c9884a'::uuid, 2, 'Mì gói: 2 gói (dùng luôn gói gia vị mì đi kèm)', 'Mì gói', 2, 'gói', 60, 200, 3.7, 6.8, 31.1, 0.2, 0),
    (v_recipe_id, '7ef588d9-36cf-4438-8ed3-d5d4706bd73b'::uuid, 3, 'Cải ngọt: 200g (cắt khúc)', 'Cải ngọt', 200, 'g', 200, 54, 3.7, 0.2, 9.4, 1.5, 96),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 4, 'Củ hành tây: 50g (xắt lát)', 'Củ hành tây', 50, 'g', 50, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 5, 'Tỏi: 20g (xay nhuyễn)', 'Tỏi', 20, 'g', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 6, 'Mỡ heo hoặc dầu ăn', 'Mỡ heo hoặc dầu ăn', 1, 'ít', 2, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 7, 'Ngò rí, tiêu xay', 'Ngò rí', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, '1 muỗng cà phê hạt nêm', 'hạt nêm', 1, 'muỗng cà phê', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 9, '1 muỗng canh dầu hào', 'dầu hào', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 10, '1 muỗng canh dầu ăn', 'dầu ăn', 1, 'muỗng canh', 15, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 11, 'Chút tiêu xay', 'Chút tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '5b441af9-af33-48c9-b6b2-127992c9884a'::uuid, 12, '1 gói gia vị mì (có sẵn trong gói mì)', 'gói gia vị mì (có sẵn trong gói mì)', 1, 'phần', 30, 200, 3.7, 6.8, 31.1, 0.2, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 13, '1 muỗng canh nước tương', 'nước tương', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 14, '1/2 muỗng canh dầu hào', 'dầu hào', 0.5, 'muỗng canh', 7.5, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 15, '2 muỗng cà phê đường', 'đường', 2, 'muỗng cà phê', 10, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 16, '1 muỗng canh tương cà', 'tương cà', 1, 'muỗng canh', 15, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 17, '1/2 muỗng canh tương ớt', 'tương ớt', 0.5, 'muỗng canh', 7.5, 41, 0.5, 0.5, 8.5, 0.9, 25);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 7),
    (v_recipe_id, 6),
    (v_recipe_id, 8),
    (v_recipe_id, 4)
  ON CONFLICT DO NOTHING;

  -- [4] Recipe: Cơm Chiên Thập Cẩm Tơi Ngon Như Ngoài Tiệm
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cơm Chiên Thập Cẩm Tơi Ngon Như Ngoài Tiệm', 'com-chien-thap-cam-toi-ngon-nhu-ngoai-tiem-cong-thuc-don-gian-ai-lam-cung-duoc', 'Nhà mình sáng nào cũng có nồi cơm nguội để dành, mà cứ để không thì phí lắm phải không mọi người? Vậy nên món cơm chiên thập cẩm luôn là "cứu tinh" của mình mỗi khi tủ lạnh có sẵn ít chả lụa, lạp xưởng, cà rốt, đậu que&#8230; Chỉ cần đảo vài phút [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/com-chien-thap-cam3.jpg', 'https://bepxua.vn/com-chien-thap-cam-toi-ngon-nhu-ngoai-tiem-cong-thuc-don-gian-ai-lam-cung-duoc/', 'mon_an_sang', 'vietnamese',
    2, 15, 25, 'easy', '[{"step_number":1,"title":"Bước 1: Trộn cơm với trứng","description":"Cho cơm nguội vào tô, đập 3 lòng đỏ trứng vào, thêm hạt nêm, nước tương, bột ngọt. Trộn đều tay cho cơm thấm gia vị và áo đều lòng đỏ trứng."},{"step_number":2,"title":"Bước 2: Xào rau củ và thịt","description":"Bắc chảo, cho 1 muỗng canh mỡ heo phi thơm tỏi băm. Cho cà rốt, đậu que vào đảo khoảng 2 phút cho chín tới, tiếp tục cho chả lụa vào đảo thêm 30 giây, nêm 1 muỗng cafe hạt nêm rồi trút ra dĩa để riêng."},{"step_number":3,"title":"Bước 3: Chiên cơm","description":"Cho thêm 3 muỗng canh mỡ heo vào chảo, phi tỏi băm vàng thơm rồi cho phần cơm đã trộn trứng vào chiên. Đảo đều tay trên lửa lớn đến khi hạt cơm khô ráo, tơi và nảy tưng lên là đạt."},{"step_number":4,"title":"Bước 4: Hoàn thiện món ăn","description":"Cho lòng trắng trứng vào đảo khoảng 1 phút cho chín, sau đó trút phần rau củ thịt đã xào ở bước 2 vào, đảo thêm 1 phút cho hòa quyện. Cuối cùng cho hành lá vào, trộn đều rồi tắt bếp."}]'::jsonb,
    1260.5, 35.1, 50.9, 165.3, 2.4, 2607.2,
    2520.9, 70.1, 101.9, 330.7, 4.8, 5214.3, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '893efa61-7553-48ce-b9f8-0489b6990882'::uuid, 1, '2 chén đầy cơm (nên dùng cơm nguội, để tủ lạnh qua đêm sẽ cho hạt cơm tơi hơn hẳn)', 'đầy cơm (nên dùng cơm nguội', 2, 'chén', 400, 347, 8.1, 1.3, 75.7, 0.7, 5),
    (v_recipe_id, '336ae6ec-56b0-43f2-bf6f-851916419ff2'::uuid, 2, '3 lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 'lòng đỏ trứng gà (lòng trắng để riêng dùng sau)', 3, 'phần', 90, 327, 13.6, 29.8, 1, 0, 108),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 3, '1/2 muỗng canh hạt nêm', 'hạt nêm', 0.5, 'muỗng canh', 7.5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 4, '1 muỗng canh nước tương', 'nước tương', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, '1/2 muỗng cafe bột ngọt', 'bột ngọt', 0.5, 'muỗng cafe', 2.5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 6, '80g cà rốt, xắt hạt lựu', 'cà rốt', 80, 'g', 80, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, '1288989f-9473-4381-a22a-20b317ea4259'::uuid, 7, '60g đậu que, xắt hạt lựu', 'đậu que', 60, 'g', 60, 77, 5, 0, 14.3, 1, 96),
    (v_recipe_id, '964b93b9-05d8-4dd1-b896-d2c149bdf5fc'::uuid, 8, '80g chả lụa, xắt hạt lựu', 'chả lụa', 80, 'g', 80, 517, 10.8, 50.4, 5.1, 0, 339),
    (v_recipe_id, '6fc43974-62d6-44e6-93b4-11a24d79b939'::uuid, 9, '50g lạp xưởng, xắt hạt lựu', 'lạp xưởng', 50, 'g', 50, 585, 20.8, 55, 1.7, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 10, 'Hành lá xắt nhỏ', 'Hành lá xắt nhỏ', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 11, '20g tỏi, đập dập băm sơ', 'tỏi', 20, 'g', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 12, 'Mỡ heo (hoặc dầu ăn)', 'Mỡ heo (hoặc dầu ăn)', 1, 'ít', 2, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 13, 'Ngò rí, tiêu xay để trang trí', 'Ngò rí', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 2),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [5] Recipe: Gà Kho Sả Đậm Đà Thơm Lừng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Gà Kho Sả Đậm Đà Thơm Lừng', 'ga-kho-sa-dam-da-thom-lung-mon-com-nha-ai-cung-ghien', 'Những ngày trời se lạnh hay mưa lâm thâm, chẳng gì bằng một nồi gà kho sả nóng hổi, đậm đà ăn cùng cơm trắng. Thịt gà thấm gia vị vừa ăn, nước kho sánh có màu vàng nâu đẹp mắt, thơm mùi sả với nước dừa tươi beo béo. Mình nấu món này hoài mà lần nào cả nhà cũng húp sạch nước kho luôn. Chị em cùng vào', 'https://bepxua.vn/wp-content/uploads/2026/09/ga-kho-sa.jpg', 'https://bepxua.vn/ga-kho-sa-dam-da-thom-lung-mon-com-nha-ai-cung-ghien/', 'mon_kho', 'vietnamese',
    3, 20, 45, 'easy', '[{"step_number":1,"title":"Bước 1: Phi thơm gia vị","description":"Bắc chảo lên bếp, cho 2 muỗng canh dầu ăn vào đun nóng, sau đó cho hành tỏi ớt xay vào phi thơm cùng 1/2 phần sả đã chuẩn bị. Đảo đều tay đến khi dậy mùi thơm nức."},{"step_number":2,"title":"Bước 2: Xào săn thịt gà","description":"Cho thịt gà vào chảo, đảo đều cho thịt săn lại và thấm đều phần dầu hành tỏi ớt vừa phi."},{"step_number":3,"title":"Bước 3: Nêm gia vị và kho sơ","description":"Thêm vào 1 muỗng canh đường, 1 muỗng cà phê muối, 1 muỗng cà phê bột ngọt, 1 muỗng canh tương ớt và 1 muỗng cà phê nước màu dừa. Đảo đều rồi kho khoảng 3 phút cho gà thấm gia vị và lên màu đẹp."},{"step_number":4,"title":"Bước 4: Kho với nước dừa","description":"Đổ 300ml nước dừa tươi vào, kho tiếp 5-7 phút cho thịt gà mềm và nước kho sánh lại."},{"step_number":5,"title":"Bước 5: Hoàn thiện","description":"Cho 3 muỗng canh nước mắm cùng phần sả còn lại vào, đảo đều rồi kho thêm 2 phút cho dậy mùi. Cuối cùng thêm ớt tươi vào là xong."}]'::jsonb,
    1480, 3.4, 10.3, 287.4, 5.3, 1297.3,
    4440, 10.3, 31, 862.3, 15.9, 3891.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '7a02b320-d9d5-4dbc-b7b6-4d30d4412b04'::uuid, 1, '1kg gà (cắt miếng vừa ăn, rửa sạch)', 'gà (cắt miếng vừa ăn', 1, 'kg', 1000, 338, 0.6, 0.1, 83.7, 1.5, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 2, '3 cây sả (đập dập, xắt nhỏ, chia làm 2 phần)', 'sả (đập dập', 3, 'cây', 75, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'Hành tím, tỏi, ớt (mỗi loại 10g, xay nhuyễn)', 'Hành tím', 1, 'ít', 2, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 4, '2 muỗng canh dầu ăn', 'dầu ăn', 2, 'muỗng canh', 30, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 5, '1 muỗng canh đường', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, '1 muỗng cà phê muối', 'muối', 1, 'muỗng cà phê', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, '1 muỗng cà phê bột ngọt', 'bột ngọt', 1, 'muỗng cà phê', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 8, '1 muỗng canh tương ớt', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 9, '1 muỗng cà phê nước màu dừa', 'nước màu dừa', 1, 'muỗng cà phê', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '6bc90d7d-c381-471d-91c7-01a99c85fb89'::uuid, 10, '300ml nước dừa tươi', 'nước dừa tươi', 300, 'ml', 300, 224, 0, 0, 0, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 11, '3 muỗng canh nước mắm', 'nước mắm', 3, 'muỗng canh', 45, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 12, 'Ớt tươi (tùy khẩu vị)', 'Ớt tươi (tùy khẩu vị)', 1, 'ít', 2, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, NULL, 13, 'Rau ăn kèm', 'Rau ăn kèm', 1, 'ít', 2, 0, 0, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 8),
    (v_recipe_id, 4)
  ON CONFLICT DO NOTHING;

  -- [6] Recipe: chè đậu trắng dẻo thơm ngọt ngào
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'chè đậu trắng dẻo thơm ngọt ngào', 'cach-nau-che-dau-trang-deo-thom-ngot-ngao', 'Chè đậu trắng, món ăn dân dã có nguồn gốc từ vùng Nam Bộ từ lâu đã trở thành thức quà quen thuộc trong lòng người Việt. Không chỉ đơn thuần là một món ăn giải nhiệt, chè đậu trắng còn là một phần ký ức tuổi thơ của bao người. Đây cũng là món [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/x_LzyFhT47U-HD.jpg', 'https://bepxua.vn/cach-nau-che-dau-trang-deo-thom-ngot-ngao/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Đậu trắng lựa bỏ hạt hư, ngâm nước qua đêm rồi rửa sạch, để ráo. Cho vào nồi 1,5l nước lọc và cho đậu vào nấu 40-45 phút cho đậu mềm."},{"step_number":2,"title":"Bước 2","description":"Nếp vo sạch, ngâm 30 phút. Dừa nạo vắt lấy 300ml nước cốt dừa nhất và 400ml nước cốt dừa dão."},{"step_number":3,"title":"Bước 3","description":"Đậu trắng luộc xong trút ra. Xếp lá dứa vào đáy 1 nồi khác rồi cho đậu đã luộc, nếp đã ngâm, đường vào nồi dàn đều, thêm 1 muỗng cafe muối rắc đều lên và cho nước cốt dừa dão, 900ml nước lọc vào nồi. Xong đậy nắp nấu chè với lửa vừa đến khi sôi thì hạ lửa nhỏ."},{"step_number":4,"title":"Bước 4","description":"Nấu chè khoảng 20 phút thì vớt lá dứa ra, đảo nhẹ. Cho 1 muỗng canh bột năng vào chén, thêm chút nước khuấy đều rồi cho vani vào khuấy sau đó rưới đều vào nồi chè, tiếp tục đảo nhẹ để chè có độ sệt. Nấu đến khi chè sệt lại thì tắt bếp."},{"step_number":5,"title":"Bước 5","description":"Làm nước cốt dừa ăn kèm: Cho vào chảo nước cốt dừa nhất, 1 muỗng canh đường, 1 muỗng canh bột năng, 1 ít muối rồi khuấy tan, nấu đến khi vừa sôi thì tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Múc chè ra chén, chan nước cốt dừa lên và thưởng thức."}]'::jsonb,
    791.5, 22.6, 2.3, 170.2, 3.6, 504,
    3166.1, 90.4, 9.4, 680.9, 14.6, 2015.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '7053bdfe-f950-4522-99c3-30013c0c74ee'::uuid, 1, 'nếp: 200 gram', 'nếp', 200, 'gram', 200, 348, 8.6, 1.5, 75.1, 0.6, 3),
    (v_recipe_id, '50f51502-f3d8-4fe3-b8f2-3ce0f37030a5'::uuid, 2, 'đậu trắng: 300 gram', 'đậu trắng', 300, 'gram', 300, 341, 23.2, 2.1, 57.4, 3.6, 0),
    (v_recipe_id, NULL, 3, 'dừa nạo: 500 gram', 'dừa nạo', 500, 'gram', 500, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '55e5e96b-c33f-4dfe-99a6-03ad1bab890b'::uuid, 4, 'lá dứa: 1 bó', 'lá dứa', 1, 'bó', 300, 32, 0.8, 0, 7.3, 0.8, 24),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 5, 'đường: 300 gram', 'đường', 300, 'gram', 300, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, NULL, 6, 'vani: 1 ống', 'vani', 1, 'ống', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'muối: 1 muỗng cafe + ít', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 9, 'bột năng: 2 muỗng canh', 'bột năng', 2, 'muỗng canh', 30, 335, 4, 0.2, 79.4, 0.5, 0);

  -- [7] Recipe: sườn non rim sả ớt mặn ngọt mềm mọng ngon lành
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn non rim sả ớt mặn ngọt mềm mọng ngon lành', 'cach-lam-suon-non-rim-sa-ot-man-ngot-mem-mong-ngon-lanh', 'Sườn non heo, với phần thịt mềm, mỡ ít và xương sụn giòn tan là một trong những nguyên liệu được ưa chuộng trong ẩm thực Việt Nam và nhiều quốc gia khác. Bạn có thể chế biến sườn non heo thành rất nhiều món ăn hấp dẫn, từ truyền thống đến mới lạ theo [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/LK_MvTOpsTM-HD.jpg', 'https://bepxua.vn/cach-lam-suon-non-rim-sa-ot-man-ngot-mem-mong-ngon-lanh/', 'mon_kho', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cho vào thau sườn non cùng 1 muỗng cafe muối và cho nước nóng vào trụng sơ thịt khoảng 2-3 phút cho sạch mùi tanh rồi vớt thịt ra rửa sạch, để ráo nước."},{"step_number":2,"title":"Bước 2","description":"Sả bào cho vào cối giã sơ cho sả mềm, ăn không bị xảm rồi trút sả ra. Cho tiếp tỏi, ớt, hành tím vào giã nát rồi cho 1 muỗng canh nước lọc vào trộn đều."},{"step_number":3,"title":"Bước 3","description":"Cho vào tô thịt, 1 muỗng cafe muối, nước hành tỏi ớt giã rồi trộn đều. Cho tiếp 2 muỗng canh bột bắp vào trộn đều với sườn để giúp sườn mềm, không bị khô khi chiên."},{"step_number":4,"title":"Bước 4","description":"Cho dầu ăn vào chảo đun nóng, dầu nóng cho sườn vào chiên lửa vừa đến khi vàng đều rồi vớt ra dĩa."},{"step_number":5,"title":"Bước 5","description":"Cho vào chén 1 muỗng canh đường, 1,5 muỗng canh nước mắm, 2 muỗng canh tương ớt, 100ml nước nóng vào khuấy đều làm sốt rim sườn."},{"step_number":6,"title":"Bước 6","description":"Cho 3 muỗng canh dầu ăn vào chảo đã rửa sạch đun nóng, dầu nóng cho xác hành tỏi ớt vào phi thơm rồi cho sả vào phi vừa vàng và vớt ra."},{"step_number":7,"title":"Bước 7","description":"Cho sườn chiên và nước sốt vào chảo đảo đều với lửa nhỏ cho sốt ngấm vào sườn, đến khi sốt sệt lại thì cho sả phi vào đảo đều cho sả bám đều sườn thì tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Cho sườn non rim sả ớt ra dĩa, ăn với cơm nóng và thưởng thức."}]'::jsonb,
    522.5, 46.1, 32.1, 12.3, 0.4, 1125,
    2090.2, 184.3, 128.3, 49, 1.6, 4499.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non heo: 1 kg', 'sườn non heo', 1, 'kg', 1000, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 2, 'ớt: 10 gram', 'ớt', 10, 'gram', 10, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 4, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 5, 'sả bào: 80 gram', 'sả bào', 80, 'gram', 80, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 6, 'bột bắp: 2 muỗng canh', 'bột bắp', 2, 'muỗng canh', 30, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'muối: 2 muỗng cafe', 'muối', 2, 'muỗng cafe', 10, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 9, 'nước mắm: 1,5 muỗng canh', 'nước mắm', 1, 'phần', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 10, 'tương ớt: 2 muỗng canh', 'tương ớt', 2, 'muỗng canh', 30, 41, 0.5, 0.5, 8.5, 0.9, 25);

  -- [8] Recipe: sườn non chay rim nước mía xá xíu mặn ngọt ăn là ghiền
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn non chay rim nước mía xá xíu mặn ngọt ăn là ghiền', 'cach-lam-suon-non-chay-rim-nuoc-mia-xa-xiu-man-ngot-an-la-ghien', 'Nếu như sườn non là một nguyên liệu rất được ưa thích trong ẩm thực mặn thì sườn non chay cũng rất được “bồ kết” trong ẩm thực chay. Được làm từ đậu nành, lúa mì hoặc các loại thực phẩm giàu protein thực vật khác; sườn non chay không chỉ đáp ứng nhu cầu [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/08/youthumb_eX921P2SQhI_maxres.jpg', 'https://bepxua.vn/cach-lam-suon-non-chay-rim-nuoc-mia-xa-xiu-man-ngot-an-la-ghien/', 'mon_chay', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Sườn non chay ngâm nước khoảng 3-4h cho mềm rồi vắt sả 2-3 lần nước sau đó khứa caro."},{"step_number":2,"title":"Bước 2","description":"Cho sườn non chay vào chảo dầu nóng chiên đến khi vàng đều sau đó tăng lửa lớn chiên thêm 2 phút rồi gắp ra."},{"step_number":3,"title":"Bước 3","description":"Tỏi cho vào máy xay gia vị xay nhuyễn. Cho tỏi vào chảo vừa chiên, đã chắt dầu để lại một ít phi thơm rồi cho nước mía vào, thêm 3 muỗng canh sốt ướp xá xíu, 1 muỗng canh nước tương, 1 muỗng cafe hạt nêm chay, 2 muỗng cafe đường nấu sôi."},{"step_number":4,"title":"Bước 4","description":"Cho sườn non chiên vào chảo sốt vừa sôi lật cho sốt thấm đều sườn, chú ý hạ lửa nhỏ. Lật đến khi sườn thấm sốt rồi thì rắc mè rang lên và tắt bếp."},{"step_number":5,"title":"Bước 5","description":"Cho sườn non chay rim nước mía xá xíu ra dĩa,  ăn cùng cơm nóng, bún, bánh hỏi… và thưởng thức."}]'::jsonb,
    268.5, 5.3, 3.2, 54.6, 0.2, 712.2,
    1074, 21.1, 13, 218.3, 0.6, 2849, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non chay: 100 gram', 'sườn non chay', 100, 'gram', 100, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 30 gram', 'tỏi', 30, 'gram', 30, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 3, 'nước mía: 200 ml', 'nước mía', 200, 'ml', 200, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 4, 'hạt nêm chay: 1 muỗng cafe', 'hạt nêm chay', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 5, 'đường: 2 muỗng cafe', 'đường', 2, 'muỗng cafe', 10, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 6, 'nước tương: 1 muỗng canh', 'nước tương', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, NULL, 7, 'sốt ướp xá xíu: 3 muỗng canh', 'sốt ướp xá xíu', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'fb9792c5-423c-451c-ad0a-e6422a2a1592'::uuid, 8, 'Mè rang', 'Mè rang', 1, 'ít', 2, 363, 24.6, 2.5, 60.4, 3.9, 6);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [9] Recipe: sườn non kho tiêu mềm ngon mặn ngọt hao cơm
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn non kho tiêu mềm ngon mặn ngọt hao cơm', 'cach-lam-suon-non-kho-tieu-mem-ngon-man-ngot-hao-com', 'Nếu đang “đau đầu” chọn lựa món cho các bữa ăn hàng ngày của gia đình, bạn đừng quên cân nhắc đến các món từ sườn non heo nhé. Đây là phần thịt heo rất được yêu thích vì nhiều thịt ít xương, ít mỡ, sụn mềm giòn; dễ chế biến thành nhiều món ăn [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/07/maxresdefault-3.jpg', 'https://bepxua.vn/cach-lam-suon-non-kho-tieu-mem-ngon-man-ngot-hao-com/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Tỏi, hành tím cho vào máy xay gia vị xay nhuyễn. Sườn non rửa sạch, cho vào tô sườn non,  ½ phần hành tỏi xay, 1 muỗng cafe muối, 1 muỗng cafe hạt nêm, 3 muỗng canh đường, 2 muỗng canh nước mắm,1 muỗng cafe bột ngọt, tiêu xay trộn đều, ướp 15 phút."},{"step_number":2,"title":"Bước 2","description":"Cho 1 muỗng canh nước màu (gia giảm tùy theo độ đậm nhạt màu) vào tô thịt trộn đều. Cho 2 muỗng canh dầu ăn vào chảo và đun nóng, dầu nóng cho phần hành tỏi xay còn lại vào phi thơm rồi cho sườn non vào đảo đều, kho lửa vừa từ 7-10 phút."},{"step_number":3,"title":"Bước 3","description":"Cho 500ml nước nóng vào chảo thịt rồi đậy nắp kho khoảng 25-30 phút, thỉnh thoảng mở nắp đảo đều trong lúc kho. Kho thịt đến khi cạn nước vừa ý thì tắt bếp."},{"step_number":4,"title":"Bước 4","description":"Cho sườn non kho tiêu ra dĩa, thêm hành lá, ớt, tiêu xay tùy ý. Ăn cùng cơm nóng và thưởng thức."}]'::jsonb,
    538.9, 45.7, 32.1, 16.8, 0.3, 1605.5,
    2155.4, 182.8, 128.3, 67, 1.1, 6421.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non: 1 kg', 'sườn non', 1, 'kg', 1000, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'hành tím: 20 gram', 'hành tím', 20, 'gram', 20, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 4, 'Hành lá, ớt', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'bột ngọt: 1 muỗng cafe', 'bột ngọt', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'nước màu: 1 muỗng canh', 'nước màu', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 9, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: 3 muỗng canh', 'đường', 3, 'muỗng canh', 45, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 11, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  -- [10] Recipe: cá bống chay chiên sả giòn giòn cực ngon
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'cá bống chay chiên sả giòn giòn cực ngon', 'cach-lam-ca-bong-chay-chien-sa-gion-gion-cuc-ngon', 'Với việc mô phỏng theo những món ăn mặn, ẩm thực chay ngày càng trở nên đa dạng và hấp dẫn hơn với những món ăn thỏa mãn cả hương vị lẫn hình thức. Đều là những nguyên liệu thiên nhiên nhưng qua sự khéo tay và sáng tạo của các đầu bếp, những món [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/06/maxresdefault-2-1.jpg', 'https://bepxua.vn/cach-lam-ca-bong-chay-chien-sa-gion-gion-cuc-ngon/', 'mon_chay', 'vietnamese',
    4, 15, 25, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cá bống chay đem ngâm nước cho mềm trong 10 phút rồi rửa lại 2-3 lần nước, vắt thật khô. Cho cá bống chay vào tô, nêm ½ muỗng cafe muối xốc đều."},{"step_number":2,"title":"Bước 2","description":"Cho sả bào vào máy xay xay nhuyễn vừa. Cho 1 chén dầu ăn vào chảo và đun nóng, dầu nóng cho sả xay vào phi thơm đến khi sả vàng thì trút ra rây lấy riêng sả phi."},{"step_number":3,"title":"Bước 3","description":"Cho lại dầu phi sả vào chảo cho xăm xắp, đun nóng dầu rồi cho cá bống chay vào chiên lửa vừa đến khi vàng đều thì vớt cá bống chay ra dĩa có lót giấy thấm dầu."},{"step_number":4,"title":"Bước 4","description":"Trút dầu trong chảo, cho lại vào chảo 1 muỗng cafe hạt nêm chay, ½ muỗng canh đường, 2 muỗng canh nước tương, 2 muỗng canh nước lọc, 1 muỗng cafe ớt rim rồi đảo đều nấu sôi."},{"step_number":5,"title":"Bước 5","description":"Cho cá bống chay chiên vào chảo sốt, xốc đều cá bống chay chiên cho thấm sốt với lửa nhỏ sau đó cho sả phi vào trộn đều và tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Cho cá bống chay chiên sả ra dĩa, ăn cùng cơm nóng và thưởng thức."}]'::jsonb,
    58.3, 4.8, 0.2, 9.4, 0.3, 3818.1,
    233.2, 19, 0.8, 37.5, 1.2, 15272.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '8686ff4c-79de-4f30-9164-810747de4e30'::uuid, 1, 'cá bống chay: 100 gram', 'cá bống chay', 100, 'gram', 100, 70, 15.8, 0.8, 0, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 2, 'sả bào: 100 gram', 'sả bào', 100, 'gram', 100, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 3, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 4, 'hạt nêm chay: 1 muỗng cafe', 'hạt nêm chay', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 5, 'ớt rim: 1 muỗng cafe', 'ớt rim', 1, 'muỗng cafe', 5, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'đường: ½ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 7, 'nước tương: ½ muỗng canh', 'nước tương', 1, 'phần', 30, 55, 6.3, 0, 7.5, 0.8, 5637);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [11] Recipe: sườn chay rim mặn ngọt ngon lạ miệng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn chay rim mặn ngọt ngon lạ miệng', 'cach-lam-suon-chay-rim-man-ngot-ngon-la-mieng', 'Giống như sườn non được ưa chuộng trong các món mặn, đối với các tín đồ ăn chay, sườn non chay cũng là một nguyên liệu thường xuyên được lựa chọn trong việc chuẩn bị món ăn. Được làm hoàn toàn từ các thành phần thiên nhiên như đậu nành, lúa mì, gia vị chay, [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/06/maxresdefault-2.jpg', 'https://bepxua.vn/cach-lam-suon-chay-rim-man-ngot-ngon-la-mieng/', 'mon_chay', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Sườn non chay đem ngâm nước khoảng 4-5h cho nở mềm. Sau khi ngâm đem sườn non chay vắt rửa 2-3 lần nước sau đó vắt thật khô. Cắt sườn non chay thành 4 phần."},{"step_number":2,"title":"Bước 2","description":"Khoai lang gọt vỏ, rửa sạch, xắt miếng dài. Dùng đũa xắn miếng sườn chay ra rồi nhét khoai vào sườn. Cho vào tô sườn nhồi khoai 2 muỗng canh bột chiên giòn xóc đều."},{"step_number":3,"title":"Bước 3","description":"Bắc chảo lên bếp, cho dầu ăn vào xăm xắp nấu sôi dầu sau đó hạ lửa nhỏ vừa và cho sườn chay nhồi khoai vào chiên vàng đều. Sườn vàng rồi thì gắp ra dĩa lót giấy thấm dầu."},{"step_number":4,"title":"Bước 4","description":"Chắt hết dầu trong chảo, chỉ chừa lại một ít. Cho 1 muỗng canh đường, 6 muỗng canh nước tương, 1 muỗng canh tương ớt, 1 muỗng canh dầu hào chay, ⅓ muỗng cafe ngũ vị hương, ½ muỗng cafe tỏi bột, tiêu xay, 5 muỗng canh nước lọc vào chảo nấu sôi."},{"step_number":5,"title":"Bước 5","description":"Cho lại sườn chiên vào chảo sốt, đảo cho sốt bám đều sườn rồi tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Cho sườn chay rim mặn ngọt ra dĩa, ăn với cơm nóng và thưởng thức."}]'::jsonb,
    126.1, 7.1, 3.3, 17, 0.7, 1506.1,
    504.6, 28.5, 13.2, 68, 2.8, 6024.4, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non chay: 100 gram', 'sườn non chay', 100, 'gram', 100, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, '42f6e199-c4ea-4b60-a16a-332a2e9ebb65'::uuid, 2, 'khoai lang: 1 củ ((chọn củ to))', 'khoai lang', 1, 'củ', 50, 97, 1.5, 0, 22.7, 1.2, 71),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 3, 'bột chiên giòn: 2 muỗng canh', 'bột chiên giòn', 2, 'muỗng canh', 30, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, NULL, 4, 'ngũ vị hương: ⅓ muỗng cafe', 'ngũ vị hương', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 5, 'tỏi bột: ½ muỗng cafe', 'tỏi bột', 1, 'phần', 30, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 7, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 8, 'dầu hào chay: 1 muỗng canh', 'dầu hào chay', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 9, 'nước tương: 6 muỗng canh', 'nước tương', 6, 'muỗng canh', 90, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 10, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [12] Recipe: tôm rim mặn ngọt và salad trộn dầu giấm ngon khó cưỡng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'tôm rim mặn ngọt và salad trộn dầu giấm ngon khó cưỡng', 'cach-lam-tom-rim-man-ngot-va-salad-tron-dau-giam-ngon-kho-cuong', 'Con tôm với vị ngọt tự nhiên, thịt chắc và giàu dinh dưỡng, từ lâu đã trở thành một trong những nguyên liệu hải sản được yêu thích hàng đầu trong ẩm thực trên khắp thế giới. Từ những món ăn dân dã hàng ngày đến những món ăn cao cấp, tôm đều xuất hiện [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/youthumb_b3kotHG8Hgg_maxres.jpg', 'https://bepxua.vn/cach-lam-tom-rim-man-ngot-va-salad-tron-dau-giam-ngon-kho-cuong/', 'mon_kho', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Tôm lột vỏ, bỏ chỉ lưng, rửa qua nước muối rồi rửa sạch lại, để ráo. Cho tỏi vào máy xay gia vị xay nhuyễn. Rau củ rửa sạch, thái sợi nhỏ củ."},{"step_number":2,"title":"Bước 2","description":"Cho 100ml dầu ăn vào chảo đun nóng, dầu nóng cho tỏi xay vào phi vừa vàng thì trút ra chén, để lại một ít tỏi phi trong chảo."},{"step_number":3,"title":"Bước 3","description":"Cho 4 muỗng canh giấm ăn, 1,5 muỗng canh đường, ½ muỗng cafe muối, tiêu xay, 1 muỗng canh dầu ăn vào chảo rồi khuấy đều nấu sôi 1 phút làm sốt dầu giấm."},{"step_number":4,"title":"Bước 4","description":"Cho vào chén 3 muỗng canh nước lọc, 2 muỗng canh nước mắm, 1 muỗng canh dầu hào, 1 muỗng canh tương ớt, 1,5 muỗng canh đường, tiêu xay khuấy tan."},{"step_number":5,"title":"Bước 5","description":"Cho vào thố rau xà lách, ớt chuông, cà rốt, dưa leo, hành tây tím rồi cho sốt dầu giấm đã để nguội vào trộn đều nhẹ tay đến khi vừa ý."},{"step_number":6,"title":"Bước 6","description":"Cho 3 muỗng canh dầu tỏi phi vào chảo đun nóng, dầu nóng cho tôm vào đảo đều rồi cho chén nước sốt vào rim lửa nhỏ 5-7 phút, lật đều tôm cho thấm sốt. Rim đến khi sốt sệt lại thì rải tỏi phi lên tôm, thêm ngò trang trí tùy ý và tắt bếp."},{"step_number":7,"title":"Bước 7","description":"Cho tôm ra dĩa, ăn cùng cơm nóng và salad sốt dầu giấm và thưởng thức."}]'::jsonb,
    180.4, 24.6, 2.4, 15.2, 0.4, 3644.1,
    721.7, 98.3, 9.4, 60.8, 1.7, 14576.6, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 1, 'tôm: 500 gram', 'tôm', 500, 'gram', 500, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 50 gram', 'tỏi', 50, 'gram', 50, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, NULL, 3, 'Rau xà lách, ớt chuông, cà rốt, dưa leo, hành tây tím', 'Rau xà lách', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 4, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 5, 'dầu hào: 1 muỗng canh', 'dầu hào', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 6, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 7, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'đường: 3 muỗng canh', 'đường', 3, 'muỗng canh', 45, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, NULL, 9, 'giấm ăn: 4 muỗng canh', 'giấm ăn', 4, 'muỗng canh', 60, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 10, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [13] Recipe: thịt ba chỉ kho tiêu nước sệt ngon vô đối
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'thịt ba chỉ kho tiêu nước sệt ngon vô đối', 'cach-lam-thit-ba-chi-kho-tieu-nuoc-set-ngon-vo-doi', 'Thịt ba chỉ kho tiêu là món ăn rất đỗi quen thuộc trong những bữa ăn hàng ngày của chúng ta. Món ăn này có cách làm đơn giản, dễ ăn không ngán, hợp cho từ người lớn đến trẻ nhỏ. Bạn có thể kho một nồi thịt và để dành ăn cơm dần trong [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/04/maxresdefault.jpg', 'https://bepxua.vn/cach-lam-thit-ba-chi-kho-tieu-nuoc-set-ngon-vo-doi/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Thịt rửa sạch, xắt miếng vừa ăn. Cho vào tô thịt 1 muỗng cafe đường, 1 muỗng cafe hạt nêm, tiêu xay trộn đều ướp 15 phút. Cho tỏi, hành tím vào máy xay gia vị xay nhuyễn."},{"step_number":2,"title":"Bước 2","description":"Cho dầu ăn vào chảo đun nóng, dầu nóng cho thịt đã ướp vào áp chảo cho thịt săn lại rồi tắt bếp."},{"step_number":3,"title":"Bước 3","description":"Bắc nồi lên bếp, cho vào nồi 1 muỗng canh đường, 1 muỗng canh dầu ăn rồi bật lửa đảo đều làm màu kho thịt sau đó cho hành tỏi xay vào phi thơm rồi cho tiếp 200ml nước lọc vào nồi. Nêm 2 muỗng canh nước mắm, 2 muỗng canh tương ớt đảo đều."},{"step_number":4,"title":"Bước 4","description":"Cho thịt áp chảo vào nồi, đậy nắp kho lửa nhỏ 15-20 phút. Thỉnh thoảng mở nắp đảo đều thịt trong lúc kho, kho đến khi nước sệt vừa ý thì tắt bếp, thêm tiêu xay tùy thích."},{"step_number":5,"title":"Bước 5","description":"Cho thịt ba chỉ kho tiêu ra dĩa, ăn cùng cơm nóng và thưởng thức."}]'::jsonb,
    225.7, 13.2, 16.2, 6.7, 0.3, 528.7,
    902.9, 52.7, 64.9, 26.8, 1.2, 2114.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '4ea95eca-3921-4e1c-b8e1-9c193719c202'::uuid, 1, 'thịt ba chỉ: 300 gram', 'thịt ba chỉ', 300, 'gram', 300, 260, 16.5, 21.5, 0, 0, 55),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 2, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 4, 'đường: 1 muỗng cafe', 'đường', 1, 'muỗng cafe', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 7, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 8, 'tương ớt: 2 muỗng canh', 'tương ớt', 2, 'muỗng canh', 30, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 9, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  -- [14] Recipe: cánh gà om bia thơm ngon hấp dẫn
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'cánh gà om bia thơm ngon hấp dẫn', 'cach-lam-canh-ga-om-bia-thom-ngon-hap-dan', 'Bia không những là thức uống ưa thích của “cánh mày râu” mà còn là một nguyên liệu hay ho được dùng trong nhà bếp. Trong ẩm thực, so với rượu thì bia được đánh giá là có nồng độ cồn ít hơn, mùi vị nhẹ hơn, là yếu tố nâng tầm cho nhiều món [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/03/maxresdefault-8.jpg', 'https://bepxua.vn/cach-lam-canh-ga-om-bia-thom-ngon-hap-dan/', 'mon_man', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Cánh gà bóp muối rửa sạch, khứa đều. Hành tím, tỏi, gừng cho vào máy xay gia vị xay nhuyễn."},{"step_number":2,"title":"Bước 2","description":"Cho vào thố gà ½ muỗng canh hạt nêm, ½ muỗng cafe muối, 2 muỗng canh nước mắm, gừng tỏi hành tím đã xay, 2 muỗng canh tương ớt rồi trộn đều, ướp 15-30 phút."},{"step_number":3,"title":"Bước 3","description":"Cho 5 muỗng canh dầu ăn vào chảo đun nóng, dầu nóng cho 1 muỗng canh đường vào thắng màu rồi cho cánh gà vào chiên cháy cạnh đều 2 mặt."},{"step_number":4,"title":"Bước 4","description":"Cho bia vào chảo gà, nấu lửa vừa đến khi cạn thì tắt bếp."},{"step_number":5,"title":"Bước 5","description":"Cho cánh gà om bia ra dĩa, ăn cùng cơm nóng và thưởng thức."}]'::jsonb,
    484.5, 33.8, 34.1, 6.5, 0.2, 3093.8,
    1937.9, 135.2, 136.3, 25.9, 0.8, 12375.1, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'cánh gà giữa: 800 gram', 'cánh gà giữa', 800, 'gram', 800, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 2, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 3, 'gừng: 10 gram', 'gừng', 10, 'gram', 10, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 4, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'd15fd83c-9b2e-497e-887a-30df1bb77e1d'::uuid, 5, 'bia: 200 ml', 'bia', 200, 'ml', 200, 43, 0.5, 0, 2.3, 0, 4),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 7, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 8, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 9, 'tương ớt: 2 muỗng canh', 'tương ớt', 2, 'muỗng canh', 30, 41, 0.5, 0.5, 8.5, 0.9, 25);

  -- [15] Recipe: tôm khô xẻ dẻo thơm và công thức mắm me mê ly ăn tôm nướng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'tôm khô xẻ dẻo thơm và công thức mắm me mê ly ăn tôm nướng', 'cach-lam-tom-kho-xe-deo-thom-va-cong-thuc-mam-me-me-ly-an-tom-nuong', 'Tôm khô xẻ hay tôm lụi là một đặc sản của Cà Mau. Sở dĩ có tên gọi độc đáo này vì dựa trên hình dạng của tôm khô sau khi làm, phần thân tôm được bóc vỏ và cán dẹp ra, phần đuôi tôm thì giữ lại vỏ sau đó đem đi phơi nắng.Tôm [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/02/maxresdefault-4-1.jpg', 'https://bepxua.vn/cach-lam-tom-kho-xe-deo-thom-va-cong-thuc-mam-me-me-ly-an-tom-nuong/', 'mon_man', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Cho 1 muỗng canh muối vào thau đá rồi đổ nước vào sau đó cho tôm vào thau ngâm cho dễ lột. Tôm lột bỏ đầu, lột vỏ, xẻ tôm bỏ chỉ lưng, vừa làm vừa giữ trong thau đá lạnh cho tôm tươi."},{"step_number":2,"title":"Bước 2","description":"Trút tôm ra rổ, lau tôm cho ráo nước rồi cho ra tô. Cho vào tô tôm sa tế tôm, 1 muỗng cafe tiêu xay trộn đều."},{"step_number":3,"title":"Bước 3","description":"Xếp tôm đã ướp ra mẹt, dàn đều tôm rồi phơi nắng 1-2 ngày tùy thích đến khi tôm đạt độ dẻo khô vừa ý.Tôm phơi xong là có thể ăn liền, khi ăn bạn lấy phần tôm đủ  dùng, phần còn lại bảo quản ngăn mát."},{"step_number":4,"title":"Bước 4","description":"Cách làm tôm nướng chấm mắm me: Tôm cho vào nồi chiên không dầu nướng sơ. Cho vào chảo me chín và 1 chén nước lọc rồi dầm ra nước me sau đó rây lấy cốt me, bỏ xác me; cho vào chảo cốt me 6 muỗng canh đường, 6 muỗng canh nước mắm, 1 muỗng canh tương ớt, ½ muỗng canh bột ngọt khuấy đều nấu sôi 2-3 phút rồi tắt bếp. Múc mắm me ra chén, thêm ớt tùy thích nếu muốn ăn cay."},{"step_number":5,"title":"Bước 5","description":"Cho tôm nướng ra dĩa, chấm mắm me và thưởng thức."}]'::jsonb,
    552.2, 94.1, 5.1, 32.7, 0.9, 5196.9,
    2208.9, 376.3, 20.4, 130.6, 3.6, 20787.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '02975e3c-00a3-42e8-8fb5-6b9d1d671379'::uuid, 1, 'tôm thẻ: 2 kg', 'tôm thẻ', 2, 'kg', 2000, 82, 17.6, 0.9, 0.9, 0, 148),
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 2, 'sa tế tôm: 90 gram', 'sa tế tôm', 90, 'gram', 90, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, 'bf46a106-ab7e-49f2-86b0-7e3567d37f0a'::uuid, 3, 'me chín: 150 gram', 'me chín', 150, 'gram', 150, 54, 0.6, 0.2, 12.4, 1.2, 3),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 4, 'tiêu xay: 1 muỗng cafe', 'tiêu xay', 1, 'muỗng cafe', 5, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, 'bột ngọt: ½ muỗng canh', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'muối: 1 muỗng canh', 'muối', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 7, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'đường: 6 muỗng canh', 'đường', 6, 'muỗng canh', 90, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 9, 'nước mắm: 6 muỗng canh', 'nước mắm', 6, 'muỗng canh', 90, 28, 7.1, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [16] Recipe: tôm rang nước cốt dừa ngon bá cháy
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'tôm rang nước cốt dừa ngon bá cháy', 'cach-lam-tom-rang-nuoc-cot-dua-ngon-ba-chay', 'Tôm đất hay tôm chỉ, tôm rảo là loại tôm được ưa chuộng trong ẩm thực. Tôm đất có vị thịt ngon, chứa nhiều dưỡng chất tốt cho sức khỏe, được ví von là sản vật thiên nhiên ban tặng. Trong các bữa ăn hàng ngày, chúng ta có thể dễ dàng tìm và chế [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/02/maxresdefault-2-1.jpg', 'https://bepxua.vn/cach-lam-tom-rang-nuoc-cot-dua-ngon-ba-chay/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Tôm bỏ đầu, râu, chỉ lưng; cho tôm vào thố, thêm nước và 1 muỗng cafe muối vào khuấy đều rồi rửa tôm với nước muối sau đó rửa sạch lại bằng nước."},{"step_number":2,"title":"Bước 2","description":"Cho tôm vào tô, thêm ½ muỗng cafe muối, ½ muỗng cafe bột ngọt, tiêu xay, 1 muỗng canh dầu ăn trộn đều ướp 15 phút."},{"step_number":3,"title":"Bước 3","description":"Cho vào chén 2 muỗng canh đường, 2 muỗng canh nước mắm, 2 muỗng canh tương ớt, 100ml nước cốt dừa khuấy đều. Cho tỏi vào máy xay gia vị xay nhuyễn."},{"step_number":4,"title":"Bước 4","description":"Cho dầu ăn vào chảo đun nóng, dầu nóng cho tỏi xay vào phi thơm rồi cho tôm đã ướp vào xào cho tôm đổi màu sau đó cho chén gia vị đã pha vào chảo đảo đều với tôm, đậy nắp rim lửa nhỏ đến khi cạn nước khoảng 45-60 phút."},{"step_number":5,"title":"Bước 5","description":"Tiếp tục rang tôm với lửa nhỏ đến khi khô thì tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Cho tôm rang nước dừa ra dĩa, ăn cùng cơm, cháo… và thưởng thức."}]'::jsonb,
    195.8, 20.8, 1.9, 24, 1.3, 6130.2,
    783.3, 83, 7.5, 95.9, 5.2, 24520.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 1, 'tôm đất: 300 gram', 'tôm đất', 300, 'gram', 300, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'f930e7f4-5e34-426a-b63b-66bfb371965f'::uuid, 3, 'nước cốt dừa: 100 ml', 'nước cốt dừa', 100, 'ml', 100, 341, 24.2, 1.7, 57.3, 4, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 4, 'bột ngọt: ½ muỗng cafe', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, 'muối: 1,5 muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'đường: 2 muỗng canh', 'đường', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 7, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 8, 'tương ớt: 2 muỗng canh', 'tương ớt', 2, 'muỗng canh', 30, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 9, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [17] Recipe: tỏi ngâm giấm chua ngọt trắng giòn
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'tỏi ngâm giấm chua ngọt trắng giòn', 'cach-lam-toi-ngam-giam-chua-ngot-trang-gion', 'Tỏi là thực phẩm rất đỗi quen thuộc với chúng ta. Trong căn bếp của mọi nhà đều không thể thiếu loại gia vị này. Ngoài việc làm tăng thêm gia vị cho món ăn, tỏi còn sở hữu giá trị dinh dưỡng cao và còn được xem là một vị thuốc cho sức khỏe. [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/11/maxresdefault-5.jpg', 'https://bepxua.vn/cach-lam-toi-ngam-giam-chua-ngot-trang-gion/', 'mon_man', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Tỏi cắt cuốn đầu tỏi, cho vào thau nước ngâm 60’. Sau khi ngâm bóc vỏ, cho tỏi ra thau. Cho vào thau tỏi 2 muỗng canh đường, 500ml nước lọc vào khuấy tan đường rồi đậy kín thau tỏi, ngâm 5-6h."},{"step_number":2,"title":"Bước 2","description":"Cho vào nồi 250ml nước lọc, 250ml giấm, 125 gram đường khuấy tan, nấu sôi 3 phút rồi tắt bếp để thật nguội."},{"step_number":3,"title":"Bước 3","description":"Tỏi sau khi ngâm vớt ra. Bắc nồi nước khác lên bếp đun sôi rồi đợi cho nước bớt nóng (khoảng 80C thì cho tỏi vào trụng sơ sau đó vớt ra rửa sạch lại."},{"step_number":4,"title":"Bước 4","description":"Dàn tỏi ra mẹt phơi ráo nước. Sau khi tỏi ráo thì cho vào hũ đã rửa sạch trụng nước sôi, rót nước giấm đường vào ngập tỏi rồi đậy nắp ngâm. Để hũ tỏi ngâm 5-7 ngày."},{"step_number":5,"title":"Bước 5","description":"Sau khi ngâm đem tỏi ra dùng, múc tép nhỏ ăn trước, tép to để ngâm thêm khoảng 2 ngày sẽ ngon hơn. Bảo quản tỏi ngâm ở ngăn mát."}]'::jsonb,
    311.3, 7.5, 0.5, 69.4, 1.9, 22.5,
    1245.4, 30, 2, 277.4, 7.5, 90, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 1, 'tỏi: 500 gram', 'tỏi', 500, 'gram', 500, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, NULL, 2, 'giấm: 250 ml', 'giấm', 250, 'ml', 250, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 3, 'đường: 125 gram', 'đường', 125, 'gram', 125, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 4, 'đường: 2 muỗng canh', 'đường', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0);

  -- [18] Recipe: sườn chiên sả ớt ngon hết ý
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn chiên sả ớt ngon hết ý', 'cach-lam-suon-chien-sa-ot-ngon-het-y', 'Sườn non là phần thịt rất được ưa chuộng bởi sở hữu độ mềm ngọt tiêu chuẩn của thịt, dễ chế biến theo nhiều kiểu để cho ra nhiều món ăn thơm ngon, đa dạng. Sườn non xương nhỏ, nhiều thịt, sụn mềm, được đánh giá là phần ngon nhất trong các phần sườn heo, [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/07/suon-chien-sa-ot.jpg', 'https://bepxua.vn/cach-lam-suon-chien-sa-ot-ngon-het-y/', 'mon_man', 'vietnamese',
    4, 15, 25, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cho muối vào nồi nước đun sôi lăn tăn rồi cho sườn đã rửa sạch vào trụng 2-3 phút, vớt ra xả lại nước để ráo."},{"step_number":2,"title":"Bước 2","description":"Cho vào tô sườn 2 muỗng canh nước mắm, ½ muỗng cafe bột ngọt, ½ muỗng cafe muối, ½ muỗng cafe ngũ vị hương, 2 muỗng canh dầu ăn rồi trộn đều, ướp 15 phút. Tiếp theo cho 2 muỗng canh bột bắp vào sườn trộn đều."},{"step_number":3,"title":"Bước 3","description":"Sả xắt lát. Tỏi bỏ vỏ. Cho tỏi, sả, ớt vào máy xay gia vị xay nhuyễn."},{"step_number":4,"title":"Bước 4","description":"Cho dầu ăn xăm xắp vào chảo (độ ngập khoảng ⅔ miếng sườn) đun nóng, dầu nóng cho sườn vào chiên lửa lớn đến khi vừa vàng rồi hạ lửa vừa chiên đến khi thịt chín đều thì tắt bếp vớt sườn ra, chừa lại 3 muỗng canh dầu."},{"step_number":5,"title":"Bước 5","description":"Đun nóng lại chảo dầu rồi cho tỏi sả ớt xay vào phi thơm, nêm ⅓ muỗng canh hạt nêm, ⅓ muỗng canh đường đảo đều đến khi sả thơm thì cho sườn chiên vào đảo đều, tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Cho sườn chiên sả ớt ra dĩa, ăn kèm cơm nóng và thưởng thức."}]'::jsonb,
    399.7, 32.4, 22.5, 16.9, 0.6, 8831.7,
    1598.7, 129.7, 89.9, 67.5, 2.4, 35326.6, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non heo: 700 gram', 'sườn non heo', 700, 'gram', 700, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 3, 'sả: 5 cây', 'sả', 5, 'cây', 125, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 4, 'ớt: 2 cây', 'ớt', 2, 'cây', 40, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 5, 'bột bắp: 2 muỗng canh', 'bột bắp', 2, 'muỗng canh', 30, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'bột ngọt: ½ muỗng cafe', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 8, 'ngũ vị hương: ½ muỗng cafe', 'ngũ vị hương', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'hạt nêm: ⅓ muỗng canh', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: ⅓ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0);

  -- [19] Recipe: Cách mới làm gà hấp muối trộn gỏi bắp chuối hấp dẫn ngon mê ly
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cách mới làm gà hấp muối trộn gỏi bắp chuối hấp dẫn ngon mê ly', 'cach-moi-lam-ga-hap-muoi-tron-goi-bap-chuoi-hap-dan-ngon-me-ly', 'Gà hấp muối là một món gà thơm ngon với cách hấp không cần nước giúp giữ được trọn vẹn hương vị của thịt gà. Món này được nhiều người ưu ái chọn cho các bữa tiệc ngày lễ, ngày họp mặt vì sở hữu hương vị cuốn hút, không nhiều dầu mỡ gây ngấy, [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/02/ga-hap-muoi-tron-goi.jpg', 'https://bepxua.vn/cach-moi-lam-ga-hap-muoi-tron-goi-bap-chuoi-hap-dan-ngon-me-ly/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Gà chà chanh muối rửa sạch, để ráo. Cho vào chén 1 muỗng canh hạt nêm, ⅓ muỗng cafe nghệ bột, 1 muỗng canh dầu ăn trộn đều. Dùng hỗn hợp vừa trộn xoa đều gà."},{"step_number":2,"title":"Bước 2","description":"Lót giấy bạc vào đáy nồi hấp, dàn đều muối hột lên giấy bạc. Sả đập dập, cắt khúc cho vào dàn đều trên lớp muối rồi đặt gà lên, đậy nắp hấp 30-35 phút."},{"step_number":3,"title":"Bước 3","description":"Bắp chuối lột bỏ phần già, xắt mỏng. Cho muối, vắt chanh pha loãng vào thau nước rồi cho bắp chuối vừa xắt vào ngâm để không bị thâm đen, xắt đến đâu ngâm đến đó. Ngâm bắp chuối 15-30 phút rồi vớt ra rửa lại 2-3 lần nước, để ráo."},{"step_number":4,"title":"Bước 4","description":"Lấy 2 quả ớt bỏ hạt, xắt sợi, 1 quả xắt nhỏ. Rau răm, húng lủi xắt nhỏ."},{"step_number":5,"title":"Bước 5","description":"Cho 1 muỗng canh muối hột, 3-4 muỗng canh đường, ớt xắt nhỏ vào cối giã nhuyễn rồi cho tiếp 1 muỗng canh nước mắm vào khuấy đều. Lấy 2 quả chanh vắt nước cốt rồi cho 3-4 muỗng canh nước cốt chanh vào cối nước mắm pha, thích chua hơn thì cho hết rồi khuấy đều."},{"step_number":6,"title":"Bước 6","description":"Gà hấp xong đem ra xé vừa ăn. Cho bắp chuối vào tô, rưới từ từ nước mắm trộn lên bóp trộn đều sau đó cho lần lượt gà xé, ớt sừng, rau răm, húng lủi vào trộn tiếp đến khi vừa ý."},{"step_number":7,"title":"Bước 7","description":"Cho gà trộn gỏi ra dĩa, rắc thêm đậu phộng rang hoặc mè rang tùy thích ăn kèm bánh phồng chiên và thưởng thức."}]'::jsonb,
    127.2, 2.2, 1.3, 26.6, 0.5, 3116.6,
    508.6, 8.9, 5.2, 106.6, 2.1, 12466.4, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'gà: 1,5 kg', 'gà', 1, 'phần', 30, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 2, 'sả: 6-7 cây', 'sả', 6, 'phần', 180, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 3, 'ớt: 2 quả', 'ớt', 2, 'quả', 10, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'ff6afb1d-757b-462b-bd2d-4d245b759fbe'::uuid, 4, 'bắp chuối: 1', 'bắp chuối', 1, 'phần', 30, 100, 1.5, 0.2, 23, 0.8, 19),
    (v_recipe_id, '7904af70-6c25-464d-80ee-1262d76c92a4'::uuid, 5, 'Chanh, rau răm, húng lủi', 'Chanh', 1, 'ít', 2, 77, 1.5, 0, 17.7, 1.3, 94),
    (v_recipe_id, NULL, 6, 'nghệ bột: ⅓ muỗng cafe', 'nghệ bột', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, 'muối hột: 1 muỗng canh', 'muối hột', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 9, 'nước mắm: 1 muỗng canh', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: 3-4 muỗng canh', 'đường', 3, 'phần', 90, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'Muối hột', 'Muối hột', 1, 'ít', 2, 0, 0, 0, 0, 0, 38758);

  -- [20] Recipe: sườn xào chua ngọt cực ngon ăn là ghiền
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'sườn xào chua ngọt cực ngon ăn là ghiền', 'cach-lam-suon-xao-chua-ngot-cuc-ngon-an-la-ghien', 'Rất nhiều người ưa chuộng các món từ thịt sườn bởi hương vị thơm ngon, thịt sườn không béo ngậy như thịt mỡ cũng không quá khô như thịt nạc. Thịt sườn mềm ngọt, có thể được chế biến theo nhiều kiểu khác nhau tạo ra nhiều món đa dạng được lòng từ người lớn [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/02/suon-xao-chua-ngot.jpg', 'https://bepxua.vn/cach-lam-suon-xao-chua-ngot-cuc-ngon-an-la-ghien/', 'mon_xao', 'vietnamese',
    4, 15, 20, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cho gừng, hành tím, ít muối vào nồi nước, đun nước sủi tăm rồi cho sườn vào trụng 5 phút. Vớt sườn ra rửa lại, để ráo."},{"step_number":2,"title":"Bước 2","description":"Cho hành tím và tỏi vào máy xay gia vị xay nhuyễn. Cho sườn ra tô, thêm 1 muỗng canh hành tỏi xay, 1 muỗng canh hạt nêm, tiêu xay vào trộn đều, ướp 15 phút."},{"step_number":3,"title":"Bước 3","description":"Cho vào chén 3 muỗng canh đường, 3 muỗng canh nước mắm, 3 muỗng canh tương xí muội, 1 muỗng canh tương ớt, 1 muỗng canh tương cà, 3 muỗng canh giấm ăn, tiêu xay, ½ muỗng cafe bột ngọt, 200ml nước lọc rồi khuấy tan."},{"step_number":4,"title":"Bước 4","description":"Cho 3 muỗng canh bột năng vào tô sườn đã ướp trộn đều. Cho dầu ăn vào chảo đun nóng, dầu sôi cho sườn vào chiên vừa vàng thì tắt bếp, gắp sườn ra."},{"step_number":5,"title":"Bước 5","description":"Cho hết phần hành tỏi xay còn lại vào chảo phi thơm rồi cho sườn chiên và sốt chua ngọt đã pha vào đảo đều, rim lửa vừa 3-5 phút. Lật đều sườn trong lúc rim để sườn ngấm đều sốt. Đậy nắp, hạ lửa nhỏ rim cho sườn mềm."},{"step_number":6,"title":"Bước 6","description":"Cho gốc hành, ngò rí, mè trắng rang vào chảo sườn rồi tắt bếp. Múc sườn xào chua ngọt ra dĩa, ăn kèm salad, cơm nóng và thưởng thức."}]'::jsonb,
    417.9, 32, 22.5, 21.7, 0.4, 4467.8,
    1671.8, 128.1, 90, 86.9, 1.4, 17871.2, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '36a39f65-7a14-45b6-ac03-c039b37690d8'::uuid, 1, 'sườn non: 700 gram', 'sườn non', 700, 'gram', 700, 187, 17.9, 12.8, 0, 0, 60),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 2, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 4, 'Gừng, gốc hành, ngò rí, mè rang', 'Gừng', 1, 'ít', 2, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 5, 'bột năng: 3 muỗng canh', 'bột năng', 3, 'muỗng canh', 45, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'bột ngọt: ½ muỗng cafe', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 8, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 9, 'tương cà: 1 muỗng canh', 'tương cà', 1, 'muỗng canh', 15, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: 3 muỗng canh', 'đường', 3, 'muỗng canh', 45, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, NULL, 11, 'tương xí muội: 3 muỗng canh', 'tương xí muội', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 12, 'giấm ăn: 3 muỗng canh', 'giấm ăn', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 13, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  -- [21] Recipe: Công Thức Sốt Trộn Hủ Tiếu Gà Đậm Đà – Trộn Là Ghiền, Làm Là Mê!
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Công Thức Sốt Trộn Hủ Tiếu Gà Đậm Đà – Trộn Là Ghiền, Làm Là Mê!', '-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me', 'Công thức sốt trộn hủ tiếu gà đậm đà, sánh mịn, thơm mùi dầu mè – Bếp chỉ tận tình từng bước để mọi người trộn tô hủ tiếu ngon như ngoài hàng ngay tại nhà.', 'https://bepxua.vn/wp-content/uploads/2026/09/668880788_1245887904364515_625230941822446975_n.jpg', 'https://bepxua.vn/%f0%9f%8d%9c-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me/', 'mon_man', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1: 🍲 Luộc gà và chuẩn bị nước súp","description":"Đầu tiên, Bếp cho gà, hành tây, hành tím, gốc ngò rí, đường phèn và muối hột vào nồi cùng 3 lít nước. Luộc gà khoảng 15–20 phút tính từ lúc nước sôi, nhớ lật gà trong lúc luộc để gà chín đều từ trong ra ngoài nha mọi người.\n\n\n\nGà chín thì vớt ra để nguội bớt rồi xé thành từng miếng vừa ăn.\n\n\n\nPhần nước súp còn lại, Bếp vớt bỏ hành và gốc ngò rí, cho thêm gốc hành lá vào, nêm nếm lại cho vừa miệng để dùng kèm khi ăn – húp một ngụm là thấy ấm bụng liền!"},{"step_number":2,"title":"Bước 2: 🥢 Làm sốt trộn hủ tiếu \"bất bại\"","description":"Đây là bước quan trọng nhất quyết định độ ngon của cả tô hủ tiếu, các bạn làm kỹ nha:\n\n\n\n\nBắc chảo, phi thơm hành tỏi xay với 3 muỗng canh dầu ăn.\n\n\n\nCho lần lượt dầu hào Kum Chun, nước tương, đường, nước mắm và 1 vá nước luộc gà vào chảo.\n\n\n\nNấu sôi khoảng 2–3 phút đến khi sốt sánh lại, dậy mùi thơm là được.\n\n\n\nTắt bếp, cho tiêu xay và dầu mè vào khuấy đều là hoàn thành phần sốt.\n\n\n\n\nNước sốt lúc này phải sánh nhẹ, có màu nâu cánh gián đẹp mắt, nếm thử thấy vị mặn ngọt hài hoà, thoang thoảng thơm dầu mè là đạt chuẩn rồi đó!"},{"step_number":3,"title":"Bước 3: 🍽️ Trình bày và thưởng thức","description":"🔥 Trụng hủ tiếu: Trụng hủ tiếu khô trong nước sôi khoảng 2 phút, sau đó trụng nhanh giá và hẹ, giũ ráo nước.\n\n\n\n🥄 Trộn hủ tiếu: Cho 1 muỗng canh sốt trộn vào phần hủ tiếu vừa trụng, trộn đều để sợi hủ tiếu thấm sốt.\n\n\n\n✨ Hoàn thiện tô hủ tiếu:\n\n\n\n\nXếp gà xé lên trên mặt\n\n\n\nRưới thêm 1 muỗng sốt trộn nữa\n\n\n\nThêm rau răm, ớt sừng, xà lách\n\n\n\nRắc hành phi, tóp mỡ, tiêu xay lên trên\n\n\n\n\nNước súp thì múc ra bát riêng, ai thích thì thêm hành ngò, tiêu, vắt thêm chút chanh cho dậy vị.\n\n\n\nVậy là mọi người đã có ngay tô hủ tiếu trộn gà xé đậm đà, thơm phức, đẹp mắt như ngoài quán rồi đó!"}]'::jsonb,
    294.2, 5.9, 21.6, 19.1, 2.2, 2969.2,
    1176.7, 23.6, 86.3, 76.6, 8.7, 11877, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'Gà: 1,5 kg', 'Gà', 1, 'phần', 30, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 2, 'Hành tây: 50g', 'Hành tây', 50, 'g', 50, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'Hành tím: 10g', 'Hành tím', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 4, 'Gốc ngò rí: 5 nhánh', 'Gốc ngò rí', 5, 'nhánh', 100, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 5, 'Đường phèn: 1 muỗng canh', 'Đường phèn', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'Muối hột: 1 muỗng canh', 'Muối hột', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 7, 'Nước lọc: 3 lít', 'Nước lọc', 3, 'lít', 3000, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 8, 'Ăn kèm nước súp: gốc hành lá, ngò rí, tiêu xay', 'Ăn kèm nước súp', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 9, 'Dầu ăn: 3 muỗng canh', 'Dầu ăn', 3, 'muỗng canh', 45, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 10, 'Hành tím xay: 10g', 'Hành tím xay', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 11, 'Tỏi xay: 10g', 'Tỏi xay', 10, 'g', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 12, 'Dầu hào Kum Chun: 4 muỗng canh', 'Dầu hào Kum Chun', 4, 'muỗng canh', 60, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 13, 'Nước tương: 3 muỗng canh', 'Nước tương', 3, 'muỗng canh', 45, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 14, 'Đường: 2 muỗng canh', 'Đường', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 15, 'Nước mắm: 1 muỗng canh', 'Nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 16, 'Nước luộc gà: 1 vá (khoảng 150ml)', 'Nước luộc gà', 1, 'vá', 30, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 17, 'Tiêu xay: 1/2 muỗng cà phê', 'Tiêu xay', 0.5, 'muỗng cà', 15, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 18, 'Dầu mè: 1 muỗng cà phê', 'Dầu mè', 1, 'muỗng cà', 30, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, NULL, 19, 'Hủ tiếu khô', 'Hủ tiếu khô', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'b603119d-75cb-488b-a13b-e35b4dee2096'::uuid, 20, 'Giá, hẹ', 'Giá', 1, 'ít', 2, 164, 9.5, 0.5, 30.3, 0.8, 1),
    (v_recipe_id, '1ac30f04-1dbf-4051-9e9a-269d319b79c9'::uuid, 21, 'Rau răm', 'Rau răm', 1, 'ít', 2, 45, 4.7, 0, 6.6, 3.8, 5),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 22, 'Ớt sừng', 'Ớt sừng', 1, 'ít', 2, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, NULL, 23, 'Xà lách', 'Xà lách', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '7904af70-6c25-464d-80ee-1262d76c92a4'::uuid, 24, 'Chanh', 'Chanh', 1, 'ít', 2, 77, 1.5, 0, 17.7, 1.3, 94),
    (v_recipe_id, NULL, 25, 'Hành phi', 'Hành phi', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 26, 'Tóp mỡ', 'Tóp mỡ', 1, 'ít', 2, 0, 0, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 8),
    (v_recipe_id, 4),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [22] Recipe: bò lúc lắc khoai tây nhanh gọn siêu ngon
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'bò lúc lắc khoai tây nhanh gọn siêu ngon', 'cach-lam-bo-luc-lac-khoai-tay-nhanh-gon-sieu-ngon', 'Bò lúc lắc-món ăn lấy cảm hứng từ ẩm thực Pháp là một trong những món ăn từ thịt bò rất được yêu thích. Tên gọi "lúc lắc" có thuyết là hiểu theo cách gọi lái từ "xúc xắc" vì hình dáng của thịt bò giống như các viên xúc xắc nhưng cũng được cho [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/MRl2D75l_Gw-HD.jpg', 'https://bepxua.vn/cach-lam-bo-luc-lac-khoai-tay-nhanh-gon-sieu-ngon/', 'mon_man', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Thịt thăn bò rửa sạch, xắt miếng vuông. Cho vào tô thịt bò 1 muỗng canh nước tương, 1 muỗng canh dầu hào, 2 muỗng canh nước cam rồi trộn đều."},{"step_number":2,"title":"Bước 2","description":"Khoai tây gọt vỏ, rửa sạch, xắt miếng vuông. Cho 1 muỗng cafe muối vào tô nước khuấy đều rồi ngâm khoai tây khoảng 10 phút sau đó rửa sạch lại khoai tây, lau khô."},{"step_number":3,"title":"Bước 3","description":"Hành tây lột vỏ, xắt và tách thành từng lát. Hành lá xắt nhỏ. Tỏi cho vào máy xay gia vị xay nhuyễn."},{"step_number":4,"title":"Bước 4","description":"Cho vào chén 1 muỗng canh hắc xì dầu, 1 muỗng canh dầu hào, 1 muỗng canh tương ớt, 1 muỗng cafe đường, 1 muỗng cafe tiêu xay rồi khuấy đều làm sốt xào."},{"step_number":5,"title":"Bước 5","description":"Cho 200ml dầu ăn vào chảo đun nóng, dầu nóng cho khoai tây vào chiên lửa vừa đến khi vàng đều rồi vớt ra để ráo dầu."},{"step_number":6,"title":"Bước 6","description":"Cho thịt bò vào chảo dầu chiên lửa lớn một phút rồi vớt ra."},{"step_number":7,"title":"Bước 7","description":"Chắt dầu trong chảo, để lại 2 muỗng canh rồi cho tỏi xay vào phi thơm. Cho thịt bò, khoai tây, hành tây, sốt xào vào đảo đều với lửa lớn khoảng một phút. Cho tiếp hành lá vào đảo đều và tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Cho bò lúc lắc khoai tây ra dĩa và thưởng thức."}]'::jsonb,
    314, 26, 3.3, 45.2, 2.6, 1373.7,
    1255.9, 103.8, 13.3, 180.7, 10.4, 5494.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '6a55dd9d-5afd-4343-9d89-953ebd532747'::uuid, 1, 'thịt thăn bò: 400 gram', 'thịt thăn bò', 400, 'gram', 400, 118, 23, 2.9, 0, 0, 0),
    (v_recipe_id, '821cb270-af63-4c1b-93ee-64689ac03356'::uuid, 2, 'khoai tây: 500 gram', 'khoai tây', 500, 'gram', 500, 124, 0.8, 0.2, 29.8, 1.3, 31),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 4, 'hành tây tím: 1 củ', 'hành tây tím', 1, 'củ', 120, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 5, 'Hành lá', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '608b37e7-e547-416e-88db-0a85d577cb64'::uuid, 6, 'nước cam: 2 muỗng canh', 'nước cam', 2, 'muỗng canh', 30, 23, 0.7, 0.2, 4.7, 0, 1),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'đường: 1 muỗng cafe', 'đường', 1, 'muỗng cafe', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 9, 'tiêu xay: 1 muỗng cafe', 'tiêu xay', 1, 'muỗng cafe', 5, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 10, 'nước tương: 1 muỗng canh', 'nước tương', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 11, 'hắc xì dầu: 1 muỗng canh', 'hắc xì dầu', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 12, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 13, 'dầu hào: 2 muỗng canh', 'dầu hào', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [23] Recipe: súp nui gà xé đặc biệt thơm ngon dinh dưỡng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'súp nui gà xé đặc biệt thơm ngon dinh dưỡng', 'cach-nau-sup-nui-ga-xe-dac-biet-thom-ngon-dinh-duong', 'Thịt gà là một trong những loại thịt phổ biến và được ưa chuộng nhất. Với hương vị thơm ngon, kết cấu mềm ngọt và giá trị dinh dưỡng cao, thịt gà đã trở thành nguyên liệu không thể thiếu trong nhiều món ăn đa dạng, từ các món truyền thống đến các món hiện [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/youthumb_Ub3ODJscg3s_maxres.jpg', 'https://bepxua.vn/cach-nau-sup-nui-ga-xe-dac-biet-thom-ngon-dinh-duong/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Sơ chế gà: chà muối cho sạch da, làm sạch lòng gà, bóp sạch nhớt mũi họng gà, chà chanh khử mùi hôi rồi rửa sạch lại. Cắt gà làm đôi."},{"step_number":2,"title":"Bước 2","description":"Cho vào tô nước lọc, 1 muỗng canh bột mì khuấy đều. Nấm rơm gọt chỗ dơ, cho vào tô nước bột mì ngâm 10 phút rồi rửa sạch lại, chẻ đôi nấm to."},{"step_number":3,"title":"Bước 3","description":"Hành tây, hành tím lột vỏ. Cà rốt, củ sắn bào vỏ. Bắp bỏ vỏ. Hành ngò bỏ gốc. Cho rau củ vào thau ngâm nước muối  rồi rửa sạch lại. Cà rốt, củ sắn xắt miếng to. Bắp xắt khúc dày 2cm.Hành tím xắt lát. Giá hẹ rửa sạch."},{"step_number":4,"title":"Bước 4","description":"Cho vào nồi 3,5l nước lọc, 1 muỗng canh muối hạt, 1 muỗng canh đường phèn rồi cho hành tây, bắp, cà rốt, củ sắn vào nồi hầm 20 phút với lửa nhỏ cho ra nước ngọt."},{"step_number":5,"title":"Bước 5","description":"Thêm 1 chén nước lọc vào nồi rau củ rồi cho gà vào luộc 25-30 phút, lật gà trong lúc luộc cho gà chín đều."},{"step_number":6,"title":"Bước 6","description":"Cho dầu ăn vào chảo đun nóng, dầu nóng cho hành tím vào phi vừa vàng thì tắt bếp trút ra chén."},{"step_number":7,"title":"Bước 7","description":"Cho 2l nước lọc và 1 muỗng canh dầu ăn vào nồi khác đun nóng, dầu nóng cho ½ muỗng cafe muối và nui vào luộc nui khoảng 10-12 phút( gia giảm tùy theo loại nui). Nui mềm thì vớt nui ra xả lại nước lạnh, rưới 2 muỗng canh dầu hành phi vào trộn đều để nui bóng và không bị dính."},{"step_number":8,"title":"Bước 8","description":"Sau khi gà chín thì vớt gà ra để bớt nóng rồi xé thịt gà thành miếng vừa ăn. Vớt bỏ hành tây trong nồi rồi cho nấm rơm, 1 muỗng canh hạt nêm, 1 muỗng cafe muối hạt vào đảo đều nấu thêm 5 phút thì tắt bếp, cho gốc hành lá vào."},{"step_number":9,"title":"Bước 9","description":"Xếp thịt gà ra dĩa, thêm hành phi và ngò rí tùy thích. Cho giá, hẹ, nui, thịt gà vào tô rồi chan nước súp vào, thêm hành ngò, ớt, tiêu xay, hành phi, chanh… tùy ý và thưởng thức."}]'::jsonb,
    151.5, 4.9, 3.4, 25.4, 1.7, 6323.9,
    606.2, 19.4, 13.6, 101.5, 6.9, 25295.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'thịt gà: 1,8 kg', 'thịt gà', 1, 'phần', 30, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, NULL, 2, 'nui: 500 gram', 'nui', 500, 'gram', 500, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '998c09a4-f38e-42ff-a133-7f8bd2d6ae99'::uuid, 3, 'nấm rơm: 200 gram', 'nấm rơm', 200, 'gram', 200, 61, 3.6, 3.2, 4.5, 1.1, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 4, 'hành tím: 80 gram', 'hành tím', 80, 'gram', 80, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 5, 'cà rốt: 1 củ', 'cà rốt', 1, 'củ', 100, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, '15b2cd66-9ebb-4df6-8d82-6fb41b8470d1'::uuid, 6, 'sắn: 1 củ', 'sắn', 1, 'củ', 50, 352, 3, 0.7, 83.3, 3, 0),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 7, 'hành tây: 1 củ', 'hành tây', 1, 'củ', 120, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, '04c51b40-a02a-4296-b26d-b1aa675d578b'::uuid, 8, 'bắp vàng: 1 trái', 'bắp vàng', 1, 'trái', 60, 52, 0.9, 0.3, 11.4, 0.1, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 9, 'Hành lá, ngò, giá, hẹ', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '5b441af9-af33-48c9-b6b2-127992c9884a'::uuid, 10, 'bột mì: 1 muỗng canh', 'bột mì', 1, 'muỗng canh', 15, 200, 3.7, 6.8, 31.1, 0.2, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 12, 'muối hạt: 1 muỗng cafe', 'muối hạt', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 13, 'muối hạt: 1 muỗng canh', 'muối hạt', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 14, 'đường phèn: 1 muỗng canh', 'đường phèn', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 7)
  ON CONFLICT DO NOTHING;

  -- [24] Recipe: ốc nướng tiêu xanh siêu thơm ngon quên sầu
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'ốc nướng tiêu xanh siêu thơm ngon quên sầu', 'cach-lam-oc-nuong-tieu-xanh-sieu-thom-ngon-kho-quen', '“Đi ăn ốc đi” là câu nói quen miệng của những hội tín đồ ẩm thực khi tụ họp. Từ Nam ra Bắc, món ốc luôn rất được ưa chuộng. Món ăn đường phố nức tiếng này không bao giờ mất đi sức hút, rất dễ thấy trên các nẻo đường những hàng quán bán [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/07/maxresdefault-5-1.jpg', 'https://bepxua.vn/cach-lam-oc-nuong-tieu-xanh-sieu-thom-ngon-kho-quen/', 'mon_nuong', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cho vào thau ốc lác và vài cái muỗng, nĩa inox, 10 gram ớt xắt nhỏ rồi đổ nước ngập ngâm cho ốc nhả nhớt sau đó rửa sạch lại."},{"step_number":2,"title":"Bước 2","description":"Cho vào chảo sả cây đập dập rồi cho ốc, lá ổi vò sơ vào, đậy nắp đun sôi bùng. Chảo sôi mở nắp đảo đều cho ốc bung mài là được. Đem ốc ra giũ, lau sạch nước, nếu nướng than thì cắt đuôi ốc."},{"step_number":3,"title":"Bước 3","description":"Cho gốc hành lá, hành tím, gừng, 10 gram ớt vào máy xay gia vị xay nhuyễn. Tiêu xanh đem giã nát."},{"step_number":4,"title":"Bước 4","description":"Cho 2 muỗng canh dầu ăn vào chảo khác đun nóng, dầu nóng cho hành gừng ớt xay vào phi thơm rồi cho 2 muỗng canh nước mắm, 1 muỗng canh dầu hào,1 muỗng canh tương ớt, 1 muỗng cafe hạt nêm, ½ muỗng canh đường, 1 muỗng cafe tiêu xay, tiêu xanh đã giã sơ, 1 muỗng canh sốt ướp thịt nướng, 4 muỗng canh nước lọc khuấy đều nấu sôi và tắt bếp."},{"step_number":5,"title":"Bước 5","description":"Xếp ốc vào khay nướng, rưới sốt lên từng con ốc, xếp thêm lá chanh vào khay. Làm nóng nồi chiên không dầu 180 độ trong 5 phút rồi cho khay ốc vào nồi nướng 10 phút."},{"step_number":6,"title":"Bước 6","description":"Ốc nướng xong rắc thêm lá chanh xắt sợi nhỏ, kẹp rau răm tùy ý, chấm muối tiêu chanh và thưởng thức."}]'::jsonb,
    262.7, 32.4, 3.6, 25.2, 8.3, 1441.8,
    1050.8, 129.6, 14.3, 100.7, 33.1, 5767.1, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '9d9b2818-078c-44fb-aa73-00a5ee601a54'::uuid, 1, 'ốc lác: 1 kg', 'ốc lác', 1, 'kg', 1000, 54, 11.9, 0.7, 0, 0, 293),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 2, 'tiêu xanh: 3-4 nhánh', 'tiêu xanh', 3, 'phần', 90, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 3, 'gừng: 10 gram', 'gừng', 10, 'gram', 10, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 4, 'gốc hành lá: 10 gram', 'gốc hành lá', 10, 'gram', 10, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 5, 'ớt: 20 gram', 'ớt', 20, 'gram', 20, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 6, 'hành tím: 30 gram', 'hành tím', 30, 'gram', 30, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 7, 'Sả, lá ổi, lá chanh, rau răm', 'Sả', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 9, 'tiêu xay: 1 muỗng cafe', 'tiêu xay', 1, 'muỗng cafe', 5, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: ½ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 11, 'dầu hào: 1 muỗng canh', 'dầu hào', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 12, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, NULL, 13, 'sốt ướp thịt nướng: 1 muỗng canh', 'sốt ướp thịt nướng', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 14, 'nước mắm: 2 muỗng canh', 'nước mắm', 2, 'muỗng canh', 30, 28, 7.1, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [25] Recipe: cơm chiên trứng tỏi thơm mềm ngon miệng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'cơm chiên trứng tỏi thơm mềm ngon miệng', 'cach-lam-com-chien-trung-toi-thom-mem-ngon-mieng', 'Cơm chiên là món ăn biến tấu với cơm quen thuộc rất được ưa thích. Với món cơm chiên, bạn có thể tiết kiệm được thời gian lẫn công sức thực hiện nhưng vẫn có ngay một món thơm ngon, dinh dưỡng. Tùy theo sở thích mà bạn dùng những nguyên liệu khác nhau chiên [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/06/maxresdefault-7.jpg', 'https://bepxua.vn/cach-lam-com-chien-trung-toi-thom-mem-ngon-mieng/', 'mon_an_sang', 'vietnamese',
    4, 15, 25, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Tỏi cho vào máy xay gia vị xay nhuyễn. Đập 2 trứng vào tô cơm, thêm 1 muỗng cafe hạt nêm, 2 muỗng canh nước tương, ½ muỗng canh dầu điều, tiêu xay trộn đều. Hành lá xắt nhỏ."},{"step_number":2,"title":"Bước 2","description":"Cho 3 muỗng canh dầu ăn vào chảo và đun nóng, dầu nóng cho tỏi xay vào phi thơm đến khi tỏi vàng thì vớt ra. Đập 2 trứng vào chảo đánh tơi ra rồi cho cơm trộn vào đảo đều."},{"step_number":3,"title":"Bước 3","description":"Chiên cơm đến khi hạt cơm tơi và khô thì nêm 1 muỗng canh nước mắm, 1 muỗng cafe đường đảo đều rồi cho hành lá vào đảo tiếp. Sau đó cho tỏi phi vào trộn đều theo ý thích và tắt bếp."},{"step_number":4,"title":"Bước 4","description":"Cho cơm chiên ra dĩa, thêm tiêu xay tùy ý và thưởng thức."}]'::jsonb,
    650.7, 21.7, 9.8, 118.8, 1.4, 1040.1,
    2602.8, 86.7, 39.2, 475.4, 5.4, 4160.4, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '893efa61-7553-48ce-b9f8-0489b6990882'::uuid, 1, 'cơm nguội: 3 chén', 'cơm nguội', 3, 'chén', 600, 347, 8.1, 1.3, 75.7, 0.7, 5),
    (v_recipe_id, '86b15d82-1c09-4925-941d-d845f8953cc0'::uuid, 2, 'trứng vịt: 4 quả', 'trứng vịt', 4, 'quả', 260, 172, 13, 12, 2.9, 0, 191),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 4, 'Hành lá', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, NULL, 5, 'dầu điều: ½ muỗng canh', 'dầu điều', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'đường: 1 muỗng cafe', 'đường', 1, 'muỗng cafe', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 8, 'nước mắm: 1 muỗng canh', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 9, 'nước tương: 2 muỗng canh', 'nước tương', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 10, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 2),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [26] Recipe: gà nấu nấm đông cô thập cẩm màu đẹp thơm nức ngon vô đối
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'gà nấu nấm đông cô thập cẩm màu đẹp thơm nức ngon vô đối', 'cach-lam-ga-nau-nam-dong-co-thap-cam-mau-dep-thom-nuc-ngon-vo-doi', 'Thịt gà là nguyên liệu được nhiều người yêu thích lựa chọn cho các món ăn thơm ngon và giàu dinh dưỡng. Nằm trong nhóm thịt trắng được đánh giá là tốt cho sức khỏe hơn thịt đỏ, thịt gà là một loại thực phẩm không thể thiếu trong nhiều nền ẩm thực, trong đó [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/05/maxresdefault-1-4.jpg', 'https://bepxua.vn/cach-lam-ga-nau-nam-dong-co-thap-cam-mau-dep-thom-nuc-ngon-vo-doi/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Gà rửa sạch, chặt thành từng miếng vừa ăn. Nấm đông cô khô đem ngâm nước lạnh cho mềm."},{"step_number":2,"title":"Bước 2","description":"Cho vào tô 1 muỗng canh bột bắp và nước lọc khuấy đều. Nấm rơm gọt phần dơ, vừa gọt vừa cho vào tô ngâm nước bột bắp khoảng 15 phút cho sạch."},{"step_number":3,"title":"Bước 3","description":"Hành tây, hành tím lột vỏ. Cà rốt bào vỏ. Bắp non gọt bỏ bớt phần cùi. Ngò rí cạo phần gốc cho sạch đất cát. Sau khi sơ chế rửa sạch rau củ quả. Hành tím cho vào máy xay gia vị xay nhuyễn. Hành tây xắt lát."},{"step_number":4,"title":"Bước 4","description":"Cho vào tô gà, ½ muỗng canh muối, ½ muỗng canh hạt nêm, ⅓ muỗng canh bột ngọt, ½ muỗng canh đường, ½ muỗng canh ớt rim, 1 muỗng canh hành tím xay, ½ muỗng cafe tiêu xay trộn đều, ướp 15-30 phút."},{"step_number":5,"title":"Bước 5","description":"Nấm đông cô ngâm xong rửa lại nhiều lần nước, nấm rơm rửa sạch lại. Cà rốt xắt lát sóng dày khoảng 0,5cm (tỉa hoa nếu thích), nấm rơm chẻ đôi nấm to."},{"step_number":6,"title":"Bước 6","description":"Cho 3 muỗng canh dầu điều vào nồi đun nóng, dầu nóng cho 1 muỗng canh hành tím xay vào phi thơm rồi cho thịt gà vào đảo đều đến khi thịt săn. Cho tiếp nước dừa tươi và 1l nước lọc vào nồi, xắt gốc ngò rí cho vào rồi đậy nắp nồi nấu đến khi nước sôi. Nước sôi hạ lửa vừa tiếp tục nấu thêm 5 phút nữa, vớt bọt khi nước sôi."},{"step_number":7,"title":"Bước 7","description":"Cho 2 muỗng canh dầu ăn vào chảo đun nóng rồi cho phần hành tím xay còn lại vào phi thơm sau đó cho cà rốt vào chảo đảo đều. Tiếp đến cho nấm và bắp non, nêm ½ muỗng canh hạt nêm xào đều khoảng 1 phút."},{"step_number":8,"title":"Bước 8","description":"Vớt bỏ gốc ngò rí trong nồi thịt gà rồi cho củ vừa xào vào nấu thêm 10 phút, luôn vớt bọt trong lúc nấu. Nêm thêm 1 muỗng cafe hạt nêm, 1 muỗng cafe muối vào đảo đều, nấu thêm một chút rồi cho hành tây vào và tắt bếp."},{"step_number":9,"title":"Bước 9","description":"Múc gà nấu nấm đông cô ra tô, ăn với bún hoặc cơm nóng và thưởng thức."}]'::jsonb,
    1300.3, 88.2, 87.5, 35.2, 5.4, 13615.6,
    5201.4, 352.8, 350.1, 140.8, 21.5, 54462.2, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'gà: 2 kg', 'gà', 2, 'kg', 2000, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, '053f634e-803c-4063-8750-90b74b4b4504'::uuid, 2, 'nấm đông cô khô: 50 gram', 'nấm đông cô khô', 50, 'gram', 50, 33, 3.8, 0, 4.4, 2, 98),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'hành tím: 50 gram', 'hành tím', 50, 'gram', 50, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '998c09a4-f38e-42ff-a133-7f8bd2d6ae99'::uuid, 4, 'nấm rơm: 200 gram', 'nấm rơm', 200, 'gram', 200, 61, 3.6, 3.2, 4.5, 1.1, 0),
    (v_recipe_id, '04c51b40-a02a-4296-b26d-b1aa675d578b'::uuid, 5, 'bắp non: 200 gram', 'bắp non', 200, 'gram', 200, 52, 0.9, 0.3, 11.4, 0.1, 0),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 6, 'cà rốt: 250 gram', 'cà rốt', 250, 'gram', 250, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 7, 'ngò rí: 5-7 cây', 'ngò rí', 5, 'phần', 150, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 8, 'hành tây: 1 củ', 'hành tây', 1, 'củ', 120, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 9, 'bột bắp: 1 muỗng canh', 'bột bắp', 1, 'muỗng canh', 15, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, '6bc90d7d-c381-471d-91c7-01a99c85fb89'::uuid, 10, 'nước dừa tươi: 1,5 lít', 'nước dừa tươi', 1, 'phần', 30, 224, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 11, 'dầu điều: 3 muỗng canh', 'dầu điều', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 12, 'tiêu xay: ½ muỗng cafe', 'tiêu xay', 1, 'phần', 30, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 13, 'hạt nêm: ½ muỗng cafe', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 14, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'bột ngọt: ⅓ muỗng canh', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 16, 'muối: ½ muỗng canh', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 17, 'đường: ½ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 18, 'ớt rim: ½ muỗng canh', 'ớt rim', 1, 'phần', 30, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 19, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758);

  -- [27] Recipe: Cá Chim Kho Thơm Đậm Đà, Cá Mềm Không Tanh
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cá Chim Kho Thơm Đậm Đà, Cá Mềm Không Tanh', 'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc', 'Mấy chị em nội trợ ơi, hôm nay mình chia sẻ món cá chim kho thơm – món ăn quen thuộc của bữa cơm nhà mà lúc nào nấu lên cũng hết sạch nồi cơm luôn á. Vị chua nhẹ của thơm hòa cùng nước kho đậm đà, cá chim mềm béo thấm gia vị [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/Snapshot_20260902160033.jpg', 'https://bepxua.vn/cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1: Sơ chế cá","description":"Cá chim mua về chà đều gừng giã nát, muối và chanh khắp mình cá, chà từ ngoài vào trong để khử sạch mùi tanh. Sau đó rửa lại với nước sạch, cắt khúc vừa ăn để ráo."},{"step_number":2,"title":"Bước 2: Chuẩn bị nguyên liệu","description":"Hành tím, tỏi, ớt đem xay nhuyễn. Thơm chia làm hai phần: một ít cắt lát, một ít băm nhỏ. Hành lá xắt khúc, ớt trái đập dập để riêng."},{"step_number":3,"title":"Bước 3: Chiên sơ cá","description":"Bắc chảo dầu nóng, cho gừng băm, hỗn hợp hành tỏi ớt xay và 1 muỗng cà phê muối vào phi thơm. Sau đó cho cá vào chiên sơ đến khi cá săn lại thì chắt bớt dầu ra, chỉ để lại khoảng 1 muỗng canh dầu trong chảo."},{"step_number":4,"title":"Bước 4: Xào sốt kho","description":"Cho thêm 1 muỗng canh hành, tỏi, ớt vào phi thơm lại lần nữa, tiếp đến cho thơm băm vào xào khoảng 1-2 phút cho dậy mùi. Nêm vào 1 muỗng canh đường, 3 muỗng canh nước mắm, 1 muỗng canh tương ớt và 1 muỗng canh tương cà, đảo đều cho hòa quyện."},{"step_number":5,"title":"Bước 5: Kho cá","description":"Cho cá đã chiên vào chảo sốt, lật đều hai mặt cho cá thấm gia vị. Đổ vào 400ml nước nóng cùng 1 muỗng cà phê nước màu dừa, kho với lửa vừa khoảng 10 phút cho cá thấm đều và nước kho sánh lại."},{"step_number":6,"title":"Bước 6: Hoàn thành","description":"Cho phần thơm cắt lát vào, kho thêm 5 phút cho thơm chín mềm mà vẫn giữ được độ giòn nhẹ. Cuối cùng rắc hành lá và ớt lên trên là xong."}]'::jsonb,
    101.9, 2.2, 0.6, 22.1, 1.3, 3134.2,
    407.6, 8.9, 2.2, 88.5, 5, 12536.7, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '8686ff4c-79de-4f30-9164-810747de4e30'::uuid, 1, 'Cá chim biển (1 con vừa ăn)', 'Cá chim biển (1 con vừa ăn)', 1, 'ít', 2, 70, 15.8, 0.8, 0, 0, 0),
    (v_recipe_id, '55e5e96b-c33f-4dfe-99a6-03ad1bab890b'::uuid, 2, 'Thơm (dứa): 500g, một ít cắt lát, một ít băm nhỏ', 'Thơm (dứa)', 500, 'g', 500, 32, 0.8, 0, 7.3, 0.8, 24),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'Tỏi: 10g', 'Tỏi', 10, 'g', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 4, 'Hành tím: 10g', 'Hành tím', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 5, 'Gừng: 1 ít giã nát (để khử tanh cá) + 10g băm nhỏ', 'Gừng', 1, 'ít giã', 2, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 6, 'Ớt: 2 trái đập dập + ớt băm', 'Ớt', 2, 'trái đập', 10, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 7, 'Hành lá: xắt khúc', 'Hành lá', 1, 'phần', 30, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, 'Muối, chanh (để sơ chế cá)', 'Muối', 1, 'ít', 2, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'Muối: 1 muỗng cà phê', 'Muối', 1, 'muỗng cà', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'Đường: 1 muỗng canh', 'Đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 11, 'Nước mắm: 3 muỗng canh', 'Nước mắm', 3, 'muỗng canh', 45, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 12, 'Tương ớt: 1 muỗng canh', 'Tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 13, 'Tương cà: 1 muỗng canh', 'Tương cà', 1, 'muỗng canh', 15, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 14, 'Nước màu dừa: 1 muỗng cà phê', 'Nước màu dừa', 1, 'muỗng cà', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, NULL, 15, 'Nước nóng: 400ml', 'Nước nóng', 400, 'ml', 400, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 16, 'Dầu ăn', 'Dầu ăn', 1, 'ít', 2, 897, 0, 99.7, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 8),
    (v_recipe_id, 4)
  ON CONFLICT DO NOTHING;

  -- [28] Recipe: Gà Rang Muối Giòn Rụm Thơm Lừng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Gà Rang Muối Giòn Rụm Thơm Lừng', 'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc', 'Nhà mình hay đổi món cuối tuần, mà món gà rang muối này là "cứu tinh" mỗi khi cả nhà thèm ăn vặt mà lười ra ngoài. Da gà giòn rụm, thịt bên trong mềm mọng không hề bị khô, lại thơm nức mùi sả với lá chanh. Làm một lần là ghiền, con nít [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/08/ga-rang-muoi-web.jpg', 'https://bepxua.vn/ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc/', 'mon_man', 'vietnamese',
    3, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1: Ướp gà","description":"Gà cắt miếng vừa ăn cho vào tô, thêm 1 muỗng canh nước mắm, trộn đều rồi ướp khoảng 15-20 phút cho gà thấm gia vị. Sau đó cho thêm 1 muỗng canh bột chiên giòn vào, trộn đều lần nữa. Bột chiên giòn này là bí quyết giúp lớp da gà sau khi chiên giòn tan mà không bị cứng đâu nha."},{"step_number":2,"title":"Bước 2: Chiên sả và lá chanh","description":"Bắc chảo dầu lên bếp, đun nóng dầu rồi cho sả và lá chanh vào chiên lửa vừa cho đến khi vàng giòn và dậy mùi thơm. Bước này đơn giản nhưng quan trọng lắm, vì sả lá chanh chiên giòn chính là \"linh hồn\" tạo mùi thơm đặc trưng cho món ăn."},{"step_number":3,"title":"Bước 3: Chiên gà","description":"Cho thịt gà đã ướp vào chảo dầu, chiên với lửa vừa. Khi thấy gà vừa lên màu vàng thì tăng lửa lớn để gà giòn hơn và bớt ngấm dầu. Chiên đến khi miếng gà vàng ươm, thơm ngất ngây thì vớt ra để ráo dầu."},{"step_number":4,"title":"Bước 4: Trộn gia vị rang muối","description":"Cho gà vừa chiên ra tô, thêm phần sả chiên đã làm ở bước 2, rắc 2 muỗng canh bột rang muối và một ít lá chanh xắt sợi vào, đảo đều tay cho gia vị bám đều lên từng miếng gà."}]'::jsonb,
    1162.7, 3.1, 1, 285.4, 5.4, 3883.7,
    3488, 9.3, 3, 856.1, 16.3, 11651.2, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '7a02b320-d9d5-4dbc-b7b6-4d30d4412b04'::uuid, 1, '1kg gà tre (cắt miếng vừa ăn)', 'gà tre (cắt miếng vừa ăn)', 1, 'kg', 1000, 338, 0.6, 0.1, 83.7, 1.5, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 2, '1 muỗng canh nước mắm', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '9d6406c5-9f12-4a67-a7a3-985e9b3fd989'::uuid, 3, '1 muỗng canh bột chiên giòn', 'bột chiên giòn', 1, 'muỗng canh', 15, 335, 4, 0.2, 79.4, 0.5, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 4, '5 cây sả (xắt lát xéo)', 'sả (xắt lát xéo)', 5, 'cây', 125, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '7904af70-6c25-464d-80ee-1262d76c92a4'::uuid, 5, '4-5 lá chanh (xắt sợi, để riêng một ít cho công đoạn cuối)', '4-5 lá chanh (xắt sợi', 1, 'ít', 2, 77, 1.5, 0, 17.7, 1.3, 94),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, '2 muỗng canh bột rang muối', 'bột rang muối', 2, 'muỗng canh', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 7, 'Dầu ăn (đủ để chiên ngập gà)', 'Dầu ăn (đủ để chiên ngập gà)', 1, 'ít', 2, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, '7904af70-6c25-464d-80ee-1262d76c92a4'::uuid, 8, 'Muối tiêu chanh (để chấm)', 'Muối tiêu chanh (để chấm)', 1, 'ít', 2, 77, 1.5, 0, 17.7, 1.3, 94);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 8),
    (v_recipe_id, 4)
  ON CONFLICT DO NOTHING;

  -- [29] Recipe: mắm kho chuẩn vị đậm chất đồng quê
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'mắm kho chuẩn vị đậm chất đồng quê', 'cach-nau-mam-kho-chuan-vi-dam-chat-dong-que', '“Muốn ăn bông súng mắm kho, thì về Đồng Tháp ăn cho đỡ thèm.” Không chỉ Đồng Tháp, mà trên khắp xứ mắm miền Tây sông nước, các món mắm từ đâu đã nổi danh là đặc sản nơi đây. Hương vị của mắm đã trở thành một nét đặc trưng không thể thiếu trong [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/10/a74BAoOOSRY-HD.jpg', 'https://bepxua.vn/cach-nau-mam-kho-chuan-vi-dam-chat-dong-que/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cho mắm cá linh, mắm cá sặc, nước dừa tươi vào nồi nấu sôi, vớt bọt. Nấu đến khi mắm nhừ."},{"step_number":2,"title":"Bước 2","description":"Cà tím xắt khúc, chẻ vừa ăn. Đậu bún xắt khúc, bỏ cọng sâu. Đậu bắp lặt bỏ râu. Cho tất cả vào ngâm nước muối 10 phút rồi rửa sạch vớt ra. Đậu bắp bỏ đầu xắt khúc. Rau ăn kèm lặt lá hư, rửa sạch."},{"step_number":3,"title":"Bước 3","description":"Cá bông lau làm rửa sạch, xắt khúc dày 2cm. Thịt ba chỉ bóp muối rửa sạch, xắt miếng vừa ăn."},{"step_number":4,"title":"Bước 4","description":"Tỏi, sả bào, hành tím, ớt sừng cho vào máy xay gia vị xay nhuyễn. Cho vào thau thịt, cá, ½ phần hành tỏi sả ớt xay, 1 muỗng canh hạt nêm, ⅓ muỗng canh bột ngọt trộn đều."},{"step_number":5,"title":"Bước 5","description":"Cho 2 muỗng canh dầu ăn vào nồi khác đun nóng, dầu nóng cho phần hành tỏi sả ớt xay còn lại vào phi thơm rồi cho thịt đã ướp vào xào săn. Tiếp theo cho cá vào, lật cá xào săn đều 2 mặt."},{"step_number":6,"title":"Bước 6","description":"Rây mắm cho vào nồi, nêm 1 muỗng canh nước màu đường nấu lửa vừa khoảng 15 phút."},{"step_number":7,"title":"Bước 7","description":"Vớt cá ra, cho cà tím, đậu bắp vào nồi nấu lửa vừa khoảng 2 phút thì cho đậu bún, 1 muỗng canh đường, ⅓ muỗng canh bột ngọt (gia giảm theo khẩu vị) vào đảo đều."},{"step_number":8,"title":"Bước 8","description":"Cho lại cá vào nồi, thêm ớt sừng xắt nhỏ nấu sôi lại rồi tắt bếp. Múc mắm kho ra tô, ăn với rau xanh và thưởng thức."}]'::jsonb,
    498.7, 25.4, 27.2, 33.9, 3.4, 4544.2,
    1994.9, 101.6, 108.7, 135.5, 13.4, 18176.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, NULL, 1, 'mắm cá linh: 200 gram', 'mắm cá linh', 200, 'gram', 200, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 2, 'mắm cá sặc: 200 gram', 'mắm cá sặc', 200, 'gram', 200, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '04c51b40-a02a-4296-b26d-b1aa675d578b'::uuid, 3, 'đậu bắp: 200 gram', 'đậu bắp', 200, 'gram', 200, 52, 0.9, 0.3, 11.4, 0.1, 0),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 4, 'đậu bún: 200-300 gram', 'đậu bún', 200, 'phần', 200, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, '1632489a-27df-4418-8784-01f5baeff8ab'::uuid, 5, 'cà tím: 500 gram', 'cà tím', 500, 'gram', 500, 22, 2.1, 0.1, 3.3, 2, 85),
    (v_recipe_id, '4ea95eca-3921-4e1c-b8e1-9c193719c202'::uuid, 6, 'thịt ba chỉ: 500 gram', 'thịt ba chỉ', 500, 'gram', 500, 260, 16.5, 21.5, 0, 0, 55),
    (v_recipe_id, NULL, 7, 'cá bông lau: 900 gram', 'cá bông lau', 900, 'gram', 900, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 8, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 9, 'ớt sừng: 10 gram', 'ớt sừng', 10, 'gram', 10, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 10, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '6bc90d7d-c381-471d-91c7-01a99c85fb89'::uuid, 11, 'nước dừa tươi: 1,3 lít', 'nước dừa tươi', 1, 'phần', 30, 224, 0, 0, 0, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 12, 'sả bào: 1 chén', 'sả bào', 1, 'chén', 200, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, NULL, 13, 'Rau ăn kèm: salad, càng cua, chuối cây bào, bắp chuối&#8230;', 'Rau ăn kèm', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 14, 'bột ngọt: ⅓ +⅓ muỗng canh', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 16, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 17, 'nước màu đường: 1 muỗng canh', 'nước màu đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0);

  -- [30] Recipe: canh chua cá diêu hồng ngọt thanh đậm đà
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'canh chua cá diêu hồng ngọt thanh đậm đà', 'cach-nau-canh-chua-ca-dieu-hong-ngot-thanh-dam-da', 'Cá diêu hồng là một loại cá nước ngọt phổ biến ở Việt Nam, thường được nuôi trong ao hồ hoặc sông suối. Loài cá này có nguồn gốc từ cá rô phi và được lai tạo để có màu hồng cam đẹp mắt. Cá diêu hồng là một lựa chọn tuyệt vời cho những [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/10/bhP9n1ee9I-HD.jpg', 'https://bepxua.vn/cach-nau-canh-chua-ca-dieu-hong-ngot-thanh-dam-da/', 'mon_canh', 'vietnamese',
    4, 15, 20, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cá diêu hồng chà chanh muối cho sạch nhớt, khử mùi tanh rồi rửa sạch, xắt khúc vừa ăn, rửa lại cho sạch."},{"step_number":2,"title":"Bước 2","description":"Bạc hà tuốt vỏ, rửa sạch cùng rau củ khác. Bạc hà, thơm xắt lát. Cà chua xắt múi. Đậu bắp xắt khúc xéo. Rau nêm xắt nhỏ. Ớt sừng xắt lát. Tỏi cho vào máy xay gia vị xay nhuyễn."},{"step_number":3,"title":"Bước 3","description":"Cho 2 muỗng canh dầu ăn vào chảo đun nóng, dầu nóng cho tỏi xay vào phi vừa vàng rồi cho ra chén, chừa lại ít trong chảo."},{"step_number":4,"title":"Bước 4","description":"Cho vào chảo thơm, cà chua, 2 muỗng cafe đường, 1 muỗng cafe hạt nêm xào sơ 1-2 phút rồi cho ra tô."},{"step_number":5,"title":"Bước 5","description":"Cho cá vào chảo chiên sơ, gắp ra dĩa."},{"step_number":6,"title":"Bước 6","description":"Nấu sôi sủi tăm 1,7l nước rồi cho cá vào, nêm 1 muỗng cafe vung muối,  2 muỗng canh đường nấu sôi sau đó cho me chín vào gạn lấy nước chua; nấu tiếp cho cá chín khoảng 10 phút."},{"step_number":7,"title":"Bước 7","description":"Vớt cá ra, cho thơm, cà chua, đậu bắp vào nấu lửa vừa khoảng 1 phút rồi cho bạc hà, giá đỗ, 1 muỗng canh nước mắm vào đảo đều."},{"step_number":8,"title":"Bước 8","description":"Cho cá lại vào nồi, cho tiếp rau nêm, ớt, tỏi phi (nếu ăn liền) vào và tắt bếp."},{"step_number":9,"title":"Bước 9","description":"Múc canh chua cá diêu hồng ra tô, ăn với cơm nóng và thưởng thức."}]'::jsonb,
    251.5, 11.5, 1.9, 46.7, 0.9, 1150.9,
    1006, 46.2, 7.7, 187, 3.7, 4603.7, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'e7757c3e-c653-4979-a504-0c5652a807b0'::uuid, 1, 'cá diêu hồng: 800 gram', 'cá diêu hồng', 800, 'gram', 800, 45, 4.5, 0.7, 5.1, 0, 86),
    (v_recipe_id, 'bf46a106-ab7e-49f2-86b0-7e3567d37f0a'::uuid, 2, 'me chín: 70 gram', 'me chín', 70, 'gram', 70, 54, 0.6, 0.2, 12.4, 1.2, 3),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, '48bc5dcf-8b1e-4dd6-b36a-3e0a27f86d5a'::uuid, 4, 'bạc hà: 1 bẹ', 'bạc hà', 1, 'bẹ', 30, 356, 5.2, 0, 83.8, 0, 0),
    (v_recipe_id, '55e5e96b-c33f-4dfe-99a6-03ad1bab890b'::uuid, 5, 'thơm: ½ trái', 'thơm', 1, 'phần', 30, 32, 0.8, 0, 7.3, 0.8, 24),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 6, 'cà chua: 3 trái', 'cà chua', 3, 'trái', 225, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '04c51b40-a02a-4296-b26d-b1aa675d578b'::uuid, 7, 'đậu bắp: 8 trái', 'đậu bắp', 8, 'trái', 480, 52, 0.9, 0.3, 11.4, 0.1, 0),
    (v_recipe_id, NULL, 8, 'Rau nêm: lá quế, ngò gai, ngò om; ớt sừng; giá đỗ', 'Rau nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'muối: 1 muỗng cafe vung', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 11, 'đường: 2 muỗng cafe', 'đường', 2, 'muỗng cafe', 10, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 12, 'nước mắm: 1 muỗng canh', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 13, 'đường: 2 muỗng canh', 'đường', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [31] Recipe: đuôi heo hầm hạt sen táo đỏ thơm ngon bổ dưỡng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'đuôi heo hầm hạt sen táo đỏ thơm ngon bổ dưỡng', 'cach-nau-duoi-heo-ham-hat-sen-tao-do-thom-ngon-bo-duong', 'Trong y học và ẩm thực phương Đông, đuôi heo được xem là một kho tàng chất dinh dưỡng, mang lại những lợi ích sức khỏe đáng kể, là nguyên liệu góp mặt trong nhiều món ăn ngon bổ. Đuôi heo khá dễ chế biến, từ đuôi heo có thể tạo ra nhiều món ăn [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/JQV-o5DxsDY-HD.jpg', 'https://bepxua.vn/cach-nau-duoi-heo-ham-hat-sen-tao-do-thom-ngon-bo-duong/', 'mon_man', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Bào vỏ các củ. Cho vào thau nước 1 muỗng canh muối khuấy tan rồi cho cà rốt, củ sen, nấm đông cô đã bỏ cùi, hành ngò đã lặt vào ngâm rửa sạch, xả lại nước. Củ sen, cà rốt xắt miếng. Tỉa nấm nếu thích. Tỏi, hành tím cho vào máy xay gia vị xay nát."},{"step_number":2,"title":"Bước 2","description":"Cho vào thau 1 muỗng canh muối và đuôi heo rồi bóp cạo đuôi heo và rửa sạch lại."},{"step_number":3,"title":"Bước 3","description":"Cho vào nồi 1l nước lọc, 1 muỗng canh nước mắm khuấy đều rồi cho đuôi heo vào trụng 4-5 phút sau đó vớt ra rửa sạch từng cục."},{"step_number":4,"title":"Bước 4","description":"Cho vào tô đuôi heo, ½ muỗng canh hạt nêm, 1 muỗng canh đường phèn, ½ muỗng cafe bột ngọt, ½ muỗng cafe muối, 2 muỗng canh nước tương, ½ hành tỏi xay, tiêu xay rồi trộn đều."},{"step_number":5,"title":"Bước 5","description":"Cho 1 muỗng canh dầu ăn vào nồi khác đun nóng, dầu nóng cho phần hành tỏi xay còn lại vào phi thơm rồi cho đuôi heo vào xào đều 1-2 phút."},{"step_number":6,"title":"Bước 6","description":"Cho 2,5l nước lọc vào nồi, nấu sôi 2-3 phút rồi vớt bọt, hầm đuôi heo 20 phút."},{"step_number":7,"title":"Bước 7","description":"Cho hạt sen, cà rốt, củ sen vào nồi hầm tiếp 15-20 phút thì cho táo đỏ và nấm đông cô vào nấu thêm 5 phút. Nêm 1 muỗng canh hạt nêm, ½ muỗng canh muối vào khuấy đều và thêm gốc hành lá, tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Múc đuôi heo hầm hạt sen táo đỏ ra tô, thêm hành lá tiêu xay tùy thích và thưởng thức."}]'::jsonb,
    142.1, 7.9, 0.4, 26.7, 2, 15021.4,
    568.6, 31.5, 1.6, 106.7, 8.1, 60085.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, NULL, 1, 'đuôi heo: 1 kg', 'đuôi heo', 1, 'kg', 1000, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'tỏi: 10 gram', 'tỏi', 10, 'gram', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'hành tím: 10 gram', 'hành tím', 10, 'gram', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '053f634e-803c-4063-8750-90b74b4b4504'::uuid, 4, 'nấm đông cô tươi: 150 gram', 'nấm đông cô tươi', 150, 'gram', 150, 33, 3.8, 0, 4.4, 2, 98),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 5, 'cà rốt: 200 gram', 'cà rốt', 200, 'gram', 200, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, 'b603119d-75cb-488b-a13b-e35b4dee2096'::uuid, 6, 'hạt sen: 200 gram', 'hạt sen', 200, 'gram', 200, 164, 9.5, 0.5, 30.3, 0.8, 1),
    (v_recipe_id, NULL, 7, 'củ sen: 300 gram', 'củ sen', 300, 'gram', 300, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 8, 'Hành ngò', 'Hành ngò', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'bột ngọt: ½ muỗng cafe', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 11, 'nước mắm: 1 muỗng canh', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 12, 'đường phèn: 1 muỗng canh', 'đường phèn', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 13, 'hạt nêm: 1,5 muỗng canh', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 14, 'nước tương: 2 muỗng canh', 'nước tương', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'muối: 2,5 muỗng canh', 'muối', 2, 'phần', 60, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 16, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [32] Recipe: Muối Tôm Khô Campuchia Tại Nhà – Ăn Là Ghiền, Chấm Gì Cũng Cuốn
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Muối Tôm Khô Campuchia Tại Nhà – Ăn Là Ghiền, Chấm Gì Cũng Cuốn', 'cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon', 'Hôm nay mình muốn chia sẻ với cả nhà công thức làm muối tôm khô Campuchia mà mình hay làm ở nhà mỗi khi thèm ăn vặt hay đổi món cho bữa cơm gia đình. Món này thơm mùi tôm khô với ruốc rang, vị mặn ngọt cay hài hòa, ăn với cơm nóng cũng [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/08/muoi-tom-kho-campuchia2.jpg', 'https://bepxua.vn/cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon/', 'mon_man', 'vietnamese',
    4, 15, 30, 'easy', '[{"step_number":1,"title":"Bước 1: Sơ chế tôm khô","description":"Tôm khô đem ngâm nước nóng khoảng 30 phút cho mềm ra, sau đó vớt ra để thật ráo nước. Bước này quan trọng lắm nha, tôm mềm thì giã mới nhuyễn và dẻo được."},{"step_number":2,"title":"Bước 2: Rang ruốc khô","description":"Bắc chảo lên rang ruốc khô cho thơm, rang thêm khoảng 1 phút cho ruốc dậy mùi rồi cho ra thau hoặc cối."},{"step_number":3,"title":"Bước 3: Giã muối, tỏi, ớt","description":"Cho muối hột, muối hầm, bột ngọt, ớt, tỏi vào giã cho thật nhuyễn. Sau đó cho tôm khô đã ráo nước vào giã sơ chung, không cần giã quá nhuyễn để còn cảm nhận được xác tôm."},{"step_number":4,"title":"Bước 4: Rang muối tôm","description":"Cho hỗn hợp vừa giã cùng với đường thốt nốt vào chảo, rang lửa nhỏ liu riu, đảo đều tay đến khi hỗn hợp keo sệt lại là được. Nhớ để lửa nhỏ thôi để muối không bị khét mà lại lên màu đẹp."},{"step_number":5,"title":"Bước 5: Để nguội và thưởng thức","description":"Tắt bếp, để muối tôm nguội hẳn thì hỗn hợp sẽ kẹo dẻo lại, đúng chuẩn muối tôm Campuchia ăn là ghiền. Cho vào hũ thủy tinh sạch, đậy kín để bảo quản ăn dần được lâu."}]'::jsonb,
    243.7, 16.9, 0.9, 42, 0.4, 12378.6,
    974.7, 67.7, 3.6, 167.8, 1.8, 49514.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '4e797932-118f-45f4-91f2-b3903fca9990'::uuid, 1, 'Tôm khô: 80g', 'Tôm khô', 80, 'g', 80, 347, 75.6, 3.8, 2.5, 0, 0),
    (v_recipe_id, '9d9b2818-078c-44fb-aa73-00a5ee601a54'::uuid, 2, 'Ruốc khô: 30g', 'Ruốc khô', 30, 'g', 30, 54, 11.9, 0.7, 0, 0, 293),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 3, 'Muối hột: 5 muỗng canh vơi', 'Muối hột', 5, 'muỗng canh', 75, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 4, 'Muối hầm (muối hột hầm): 3 muỗng canh vơi', 'Muối hầm (muối hột hầm)', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 5, 'Bột ngọt: 1/2 muỗng canh', 'Bột ngọt', 0.5, 'muỗng canh', 7.5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, 'Đường thốt nốt: 150g', 'Đường thốt nốt', 150, 'g', 150, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 7, 'Ớt tươi: 50g', 'Ớt tươi', 50, 'g', 50, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 8, 'Tỏi: 50g', 'Tỏi', 50, 'g', 50, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, NULL, 9, 'Chấm các loại trái cây chua: xoài xanh, cóc, ổi, me', 'Chấm các loại trái cây chua', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '893efa61-7553-48ce-b9f8-0489b6990882'::uuid, 10, 'Rắc lên cơm trắng nóng hổi, trộn thêm chút mỡ hành', 'Rắc lên cơm trắng nóng hổi', 1, 'ít', 2, 347, 8.1, 1.3, 75.7, 0.7, 5),
    (v_recipe_id, NULL, 11, 'Ăn kèm bánh tráng, xoài lắc', 'Ăn kèm bánh tráng', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 12, 'Làm quà biếu, quà vặt cho gia đình bạn bè đều hợp', 'Làm quà biếu', 1, 'ít', 2, 0, 0, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [33] Recipe: Lẩu Thái Siêu Ngon Tại Nhà – Chua Cay Đậm Đà, Ai Ăn Cũng Ghiền
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Lẩu Thái Siêu Ngon Tại Nhà – Chua Cay Đậm Đà, Ai Ăn Cũng Ghiền', 'cach-nau-lau-thai-sieu-ngon-tai-nha-chua-cay-dam-da-ai-an-cung-ghien', 'Nồi lẩu này đủ cho khoảng 3-4 người ăn no nê, chị em cứ yên tâm chuẩn bị theo định lượng bên dưới nhé.', 'https://bepxua.vn/wp-content/uploads/2026/08/757A3895.jpg', 'https://bepxua.vn/cach-nau-lau-thai-sieu-ngon-tai-nha-chua-cay-dam-da-ai-an-cung-ghien/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1: Phi thơm nguyên liệu tạo màu và mùi","description":"Bắc nồi lên bếp, cho 2 muỗng canh dầu điều vào đun nóng. Cho thơm, cà chua, sả, riềng vào đảo đều cho dậy mùi thơm."},{"step_number":2,"title":"Bước 2: Nêm gia vị tạo vị chua cay đặc trưng","description":"Cho vào nồi 10 muỗng canh tương cà, 8 muỗng canh tương ớt, 5 muỗng canh đường phèn. Xào đều trong 2-3 phút, thích ăn cay thì cho thêm ớt tươi tùy khẩu vị."},{"step_number":3,"title":"Bước 3: Nấu nước lẩu","description":"Đổ vào nồi 2,5 lít nước lọc cùng 4-5 lá chanh đã vò sơ. Nấu cho sôi, nhớ vớt bọt để nước lẩu được trong. Sau đó hạ lửa, nấu tiếp 10-15 phút cho sả, riềng ra hết mùi thơm."},{"step_number":4,"title":"Bước 4: Lọc lấy nước lẩu","description":"Vớt bỏ hết phần xác (sả, riềng, thơm, cà chua) ra khỏi nồi, chỉ giữ lại phần nước lẩu trong veo, thơm phức."},{"step_number":5,"title":"Bước 5: Nêm nếm cho vừa vị","description":"Cho vào nồi 3 muỗng canh hạt nêm, 5 muỗng canh nước mắm, 10 muỗng canh nước cốt me, 1 muỗng canh bột ngọt. Khuấy đều rồi nếm lại, canh sao cho nước lẩu có vị chua cay mặn ngọt hài hòa, đậm đà là được (vì lát nữa ăn kèm topping và rau nữa nên đừng nêm quá nhạt)."},{"step_number":6,"title":"Bước 7: Thưởng thức","description":"Nhúng rau ăn lẩu khoảng 30 giây là chín tới, giòn ngọt. Thịt bò thì chỉ cần nhúng 15 giây là mềm, không bị dai. Gắp rau và topping ra ăn cùng bún tươi, chấm với nước mắm sả ớt tỏi phi là ngon hết sẩy!"}]'::jsonb,
    453.7, 58.8, 6.5, 40, 2.5, 6514.7,
    1814.7, 235.3, 25.9, 159.8, 9.9, 26058.8, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 1, 'Sả: 2 cây (đập dập, cắt khúc)', 'Sả', 2, 'cây', 50, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 2, 'Cà chua: 250g (xắt nhỏ)', 'Cà chua', 250, 'g', 250, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, NULL, 3, 'Củ riềng: 70g (xắt lát)', 'Củ riềng', 70, 'g', 70, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '55e5e96b-c33f-4dfe-99a6-03ad1bab890b'::uuid, 4, 'Thơm (dứa): 250g (xắt miếng)', 'Thơm (dứa)', 250, 'g', 250, 32, 0.8, 0, 7.3, 0.8, 24),
    (v_recipe_id, NULL, 5, 'Dầu điều: 2 muỗng canh', 'Dầu điều', 2, 'muỗng canh', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 6, 'Tương cà: 10 muỗng canh', 'Tương cà', 10, 'muỗng canh', 150, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 7, 'Tương ớt: 8 muỗng canh', 'Tương ớt', 8, 'muỗng canh', 120, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 8, 'Đường phèn: 5 muỗng canh', 'Đường phèn', 5, 'muỗng canh', 75, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 9, 'Ớt tươi: tùy khẩu vị', 'Ớt tươi', 1, 'phần', 30, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, NULL, 10, 'Nước lọc: 2,5 lít', 'Nước lọc', 2, 'phần', 60, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '7904af70-6c25-464d-80ee-1262d76c92a4'::uuid, 11, 'Lá chanh: 4-5 lá (vò sơ)', 'Lá chanh', 4, 'phần', 120, 77, 1.5, 0, 17.7, 1.3, 94),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 12, 'Hạt nêm: 3 muỗng canh', 'Hạt nêm', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 13, 'Nước mắm: 5 muỗng canh', 'Nước mắm', 5, 'muỗng canh', 75, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, 'bf46a106-ab7e-49f2-86b0-7e3567d37f0a'::uuid, 14, 'Me chín: 80g (dầm với 150ml nước nóng, lấy 10 muỗng canh nước cốt)', 'Me chín', 80, 'g', 80, 54, 0.6, 0.2, 12.4, 1.2, 3),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'Bột ngọt: 1 muỗng canh', 'Bột ngọt', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'b3e91883-2604-4be7-ab68-2b7253f35757'::uuid, 16, 'Mực lá: 400g (khứa hoa, cắt miếng vừa ăn)', 'Mực lá', 400, 'g', 400, 73, 16.3, 0.9, 0, 0, 44),
    (v_recipe_id, 'e7757c3e-c653-4979-a504-0c5652a807b0'::uuid, 17, 'Cá diêu hồng: 1 con (cắt khúc)', 'Cá diêu hồng', 1, 'con', 30, 45, 4.5, 0.7, 5.1, 0, 86),
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 18, 'Tôm: 500g', 'Tôm', 500, 'g', 500, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, 'c893db6c-a1b2-4e27-bbb0-92724957e044'::uuid, 19, 'Thịt bò: 300g (thái mỏng để nhúng)', 'Thịt bò', 300, 'g', 300, 118, 21, 3.8, 0, 0, 83),
    (v_recipe_id, NULL, 20, 'Rau ăn lẩu: kèo nèo, nấm, bông sua đũa, rau nhút, rau muống', 'Rau ăn lẩu', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 21, 'Ngò gai, ngò om, ớt xắt lát', 'Ngò gai', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 22, 'Bún tươi', 'Bún tươi', 1, 'ít', 2, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 23, 'Sả xắt mỏng (2 cây) + ớt xắt nhỏ + tỏi phi + nước mắm', 'Sả xắt mỏng (2 cây) + ớt xắt nhỏ + tỏi phi + nước mắm', 1, 'ít', 2, 28, 7.1, 0, 0, 0, 0);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [34] Recipe: Cá Biển Kho Cà Chua – Món Kho Đưa Cơm Cả Nhà Ai Cũng Mê
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cá Biển Kho Cà Chua – Món Kho Đưa Cơm Cả Nhà Ai Cũng Mê', 'ca-bien-kho-ca-chua-mon-kho-dua-com-ca-nha-ai-cung-me', 'Bếp chia sẻ công thức cá biển kho cà chua đậm đà, thịt cá mềm ngọt, nước kho sánh thơm, chan cơm hết sạch nồi – làm một lần là ghiền!', 'https://bepxua.vn/wp-content/uploads/2026/08/cabienkhocachua.jpg', 'https://bepxua.vn/ca-bien-kho-ca-chua-mon-kho-dua-com-ca-nha-ai-cung-me/', 'mon_an_sang', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1: Sơ chế nguyên liệu","description":"Cá làm sạch, cắt khúc vừa ăn. Tỏi và hành tím băm nhuyễn (hoặc xay nhuyễn cho nhanh). Cà chua xắt múi cau, hành lá xắt nhỏ, ớt sừng xắt lát, ớt cay đập dập. Các bạn nên chuẩn bị sẵn hết ra chén cho tiện thao tác nhé."},{"step_number":2,"title":"Bước 2: Thắng đường tạo màu","description":"Bắc nồi lên bếp, cho mỡ heo và 1,5 muỗng canh đường vào, nấu tan cho đến khi đường chuyển màu cánh gián. Đây là bí quyết giúp nồi cá kho lên màu đẹp tự nhiên mà không cần nước màu công nghiệp."},{"step_number":3,"title":"Bước 3: Phi thơm hành tỏi, áp chảo cá","description":"Cho hành tỏi băm vào phi thơm, sau đó cho cá vào, lật đều tay cho cá săn lại hai mặt. Bước này giúp cá không bị nát khi kho lâu."},{"step_number":4,"title":"Bước 4: Nêm nếm và kho sơ","description":"Nêm vào nồi: 1 muỗng canh đường, 1/2 muỗng cà phê muối, 1 muỗng cà phê bột ngọt, 4 muỗng canh nước mắm. Kho lửa nhỏ khoảng 2-3 phút cho cá thấm đều gia vị."},{"step_number":5,"title":"Bước 5: Cho nước, cà chua, ớt vào kho","description":"Đổ 500ml nước nóng vào nồi, cho cà chua và ớt vào. Kho lửa nhỏ liu riu 30-40 phút cho đến khi cà chua nhừ, cá mềm và thấm vị đậm đà. Trong lúc kho, các bạn nhớ thỉnh thoảng vớt bọt và trở cá nhẹ tay để cá chín đều mà không bị vỡ."},{"step_number":6,"title":"Bước 6: Hoàn thành","description":"Khi nước kho sánh lại, cá mềm thơm, rắc hành lá xắt nhỏ vào, đảo nhẹ rồi tắt bếp. Vậy là xong nồi cá biển kho cà chua thơm phức, sẵn sàng lên mâm!"}]'::jsonb,
    120, 2, 7, 12.2, 0.9, 4369.4,
    479.9, 7.9, 28, 48.7, 3.5, 17477.6, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, NULL, 1, 'Cá ngân (hoặc cá biển thịt chắc tương tự): 700g, cắt khúc vừa ăn', 'Cá ngân (hoặc cá biển thịt chắc tương tự)', 700, 'g', 700, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 2, 'Tỏi băm: 10g', 'Tỏi băm', 10, 'g', 10, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'Hành tím băm: 10g', 'Hành tím băm', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 4, 'Cà chua: 3 trái to, xắt múi cau', 'Cà chua', 3, 'trái to', 225, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 5, 'Hành lá: xắt nhỏ', 'Hành lá', 1, 'phần', 30, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 6, 'Ớt sừng không cay: xắt lát', 'Ớt sừng không cay', 1, 'phần', 30, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 7, 'Ớt cay: đập dập', 'Ớt cay', 1, 'phần', 30, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 8, 'Mỡ heo: 2 muỗng canh', 'Mỡ heo', 2, 'muỗng canh', 30, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 9, 'Đường: 1,5 muỗng canh (để thắng nước màu) + 1 muỗng canh (để ướp cá)', 'Đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'Muối: 1/2 muỗng cà phê', 'Muối', 0.5, 'muỗng cà', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'Bột ngọt: 1 muỗng cà phê', 'Bột ngọt', 1, 'muỗng cà', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 12, 'Nước mắm ngon: 4 muỗng canh', 'Nước mắm ngon', 4, 'muỗng canh', 60, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, NULL, 13, 'Nước nóng: 500ml', 'Nước nóng', 500, 'ml', 500, 0, 0, 0, 0, 0, 0);

  -- [35] Recipe: trứng kho quẹt béo ngon ăn là ghiền
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'trứng kho quẹt béo ngon ăn là ghiền', 'cach-lam-trung-kho-quet-beo-ngon-an-la-ghien', 'Kho quẹt là món ăn dân dã thân thương đặc trưng của người Nam Bộ. Món ăn này có cách chế biến đơn giản từ những nguyên liệu gần gũi trong căn bếp mỗi nhà như tóp mỡ, tôm khô, hành ớt… Kho quẹt được gọi vui là món “nhà nghèo” vì tiết kiệm, một [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/10/imshYdnU6QE-HD.jpg', 'https://bepxua.vn/cach-lam-trung-kho-quet-beo-ngon-an-la-ghien/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'easy', '[{"step_number":1,"title":"Bước 1","description":"Cho 2 muỗng canh mỡ heo vào chảo đun nóng, mỡ nóng cho 1 phần hành tím, gốc hành lá xắt lát vào phi thơm rồi cho nước mắm và đường vào nấu tan đường."},{"step_number":2,"title":"Bước 2","description":"Cho tiếp 1 muỗng canh tương ớt, ½ muỗng cafe bột ngọt vào nấu sôi lại rồi cho tôm khô đã ngâm mềm vào kho lửa vừa khoảng 2-3 phút."},{"step_number":3,"title":"Bước 3","description":"Sốt sôi đập trứng cho vào chảo kho lửa nhỏ, canh độ chín của trứng theo ý thích rồi cho 1 muỗng canh tóp mỡ, phần hành tím, gốc hành lá còn lại, hành lá- ớt xắt nhỏ, tiêu xay vào và tắt bếp."},{"step_number":4,"title":"Bước 4","description":"Chấm kho quẹt với rau củ hoặc ăn với cơm nóng và thưởng thức."}]'::jsonb,
    198, 13.4, 8.9, 16.1, 0.2, 2931.8,
    791.8, 53.5, 35.6, 64.3, 0.8, 11727.2, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '4e797932-118f-45f4-91f2-b3903fca9990'::uuid, 1, 'tôm khô: 50 gram', 'tôm khô', 50, 'gram', 50, 347, 75.6, 3.8, 2.5, 0, 0),
    (v_recipe_id, 'f83ca0a5-8fa3-43c1-b1fc-0ca11430526b'::uuid, 2, 'trứng gà: 2-4 quả', 'trứng gà', 2, 'phần', 60, 150, 13, 10.3, 1.3, 0, 158),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, 'Hành tím, hành lá, ớt', 'Hành tím', 1, 'ít', 2, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 4, 'đường: 60 gram', 'đường', 60, 'gram', 60, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 5, 'nước mắm: 100 ml', 'nước mắm', 100, 'ml', 100, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 6, 'bột ngọt: ½ muỗng cafe', 'bột ngọt', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 7, 'tóp mỡ: 1 muỗng canh', 'tóp mỡ', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 8, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 9, 'mỡ heo: 2 muỗng canh', 'mỡ heo', 2, 'muỗng canh', 30, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 10, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 2)
  ON CONFLICT DO NOTHING;

  -- [36] Recipe: mì xào hải sản siêu ngon khó cưỡng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'mì xào hải sản siêu ngon khó cưỡng', 'cach-lam-mi-xao-hai-san-sieu-ngon-kho-cuong', 'Nếu bạn đang muốn đổi gió bởi những món ăn quen thuộc hàng ngày, hãy thử ngay món mì xào nhé. Mì xào là món ăn phổ biến trong ẩm thực châu Á cũng như ẩm thực Việt. Sự đa dạng trong cách chế biến và nguyên liệu tạo ra nhiều phiên bản mì xào [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/10/maxresdefault.jpg', 'https://bepxua.vn/cach-lam-mi-xao-hai-san-sieu-ngon-kho-cuong/', 'mon_an_sang', 'vietnamese',
    4, 15, 20, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Mì đem ngâm nước 12-15 phút rồi vớt mì ra để ráo. Tôm mực làm rửa sạch; mực xắt miếng vừa ăn; tôm lột vỏ, bỏ chỉ lưng, xẻ sâu ⅔."},{"step_number":2,"title":"Bước 2","description":"Cho tôm mực vào thau, thêm 1 muỗng cafe muối rồi chế nước sôi vào trụng 30s sau đó vớt tôm mực ra đem ngâm đá 10 phút cho tôm, mực săn giòn. Tôm mực sau khi ngâm thì vớt ra để ráo."},{"step_number":3,"title":"Bước 3","description":"Rau củ làm rửa sạch. Cải thảo, cà rốt xắt miếng vừa không quá dày. Nấu sôi 1l nước rồi cho gốc cải thảo, cà rốt vào luộc 1 phút, vớt ra. Tỏi cho vào máy xay gia vị xay nhuyễn."},{"step_number":4,"title":"Bước 4","description":"Cho vào chén ½ muỗng canh hạt nêm, 2 muỗng canh nước tương, ½ muỗng canh hắc xì dầu, 2 muỗng canh dầu hào, 1 muỗng canh tương ớt, 1 muỗng canh tương cà, 1 muỗng canh đường, ½ muỗng cafe tiêu xay rồi khuấy đều làm sốt xào."},{"step_number":5,"title":"Bước 5","description":"Cho 1 muỗng canh dầu ăn vào chảo đun nóng, dầu nóng cho ½ phần tỏi xay vào phi thơm rồi cho cá viên vào chiên 2 phút sau đó cho tôm mực vào, rưới 2 muỗng canh sốt xào xào đều 1 phút rồi cho ra dĩa."},{"step_number":6,"title":"Bước 6","description":"Rửa sạch chảo, cho 3 muỗng canh dầu ăn vào chảo đun nóng, dầu nóng cho hết phần tỏi xay còn lại vào phi thơm rồi cho lá cải thảo vào xào sau đó cho gốc cải thảo và cà rốt vào, rưới 2 muỗng canh sốt xào xào đều."},{"step_number":7,"title":"Bước 7","description":"Cho mì vào chảo rau củ, rưới hết sốt xào vào xốc đều rồi cho tiếp hải sản đã xào vào xốc đều. Thêm hành lá, ngò rí, ớt xắt nhỏ và rưới 1 muỗng cafe dầu mè vào xốc đều và tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Cho mì xào hải sản ra dĩa, thêm tiêu xay tùy ý và thưởng thức."}]'::jsonb,
    416.9, 37.6, 7.1, 50.5, 4.7, 5420,
    1667.5, 150.3, 28.3, 201.9, 18.7, 21680.1, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '5b441af9-af33-48c9-b6b2-127992c9884a'::uuid, 1, 'mì: 3 gói', 'mì', 3, 'gói', 90, 200, 3.7, 6.8, 31.1, 0.2, 0),
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 2, 'tôm, mực: 700 gram', 'tôm, mực', 700, 'gram', 700, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, '9a653b1d-5647-4180-92aa-60a054f485bc'::uuid, 3, 'cải thảo, cà rốt: 700 gram', 'cải thảo, cà rốt', 700, 'gram', 700, 78, 1.2, 0.3, 17.5, 1, 13),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 4, 'tỏi: 30 gram', 'tỏi', 30, 'gram', 30, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'deaeb2f5-c97b-456f-9b83-c0fc735218ba'::uuid, 5, 'dầu mè: 1 muỗng cafe', 'dầu mè', 1, 'muỗng cafe', 5, 897, 0, 99.7, 0, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 6, 'Hành lá, ngò rí, ớt', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 7, 'tiêu xay: ½ muỗng cafe', 'tiêu xay', 1, 'phần', 30, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'hạt nêm: ½ muỗng canh', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 10, 'hắc xì dầu: ½ muỗng canh', 'hắc xì dầu', 1, 'phần', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 11, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '14677a69-5804-4893-a0f2-66be0f75e398'::uuid, 12, 'tương ớt: 1 muỗng canh', 'tương ớt', 1, 'muỗng canh', 15, 41, 0.5, 0.5, 8.5, 0.9, 25),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 13, 'tương cà: 1 muỗng canh', 'tương cà', 1, 'muỗng canh', 15, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 14, 'nước tương: 2 muỗng canh', 'nước tương', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 15, 'dầu hào: 2 muỗng canh', 'dầu hào', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 7),
    (v_recipe_id, 1),
    (v_recipe_id, 8),
    (v_recipe_id, 4),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [37] Recipe: Cá Chốt Kho Tiêu Đậm Đà, Thơm Ngon Như Ngoài Hàng
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Cá Chốt Kho Tiêu Đậm Đà, Thơm Ngon Như Ngoài Hàng', 'cach-kho-ca-chot-kho-tieu-dam-da-thom-ngon-nhu-ngoai-hang', 'Nhà mình hay nấu món này vào những hôm trời se lạnh hoặc đơn giản là muốn đổi vị cho mâm cơm gia đình. Cá chốt kho tiêu tuy dân dã nhưng lại "đưa cơm" cực kỳ – thịt cá chắc, ngọt tự nhiên, quyện với vị mặn mà của nước mắm, cay nồng của tiêu xanh và ớt, ăn hoài không ngán. Hôm nay mình chia sẻ công t', 'https://bepxua.vn/wp-content/uploads/2026/09/Snapshot_20260902163134.jpg', 'https://bepxua.vn/cach-kho-ca-chot-kho-tieu-dam-da-thom-ngon-nhu-ngoai-hang/', 'mon_kho', 'vietnamese',
    4, 20, 45, 'medium', '[{"step_number":1,"title":"Bước 1 – Làm hành ớt: ","description":"Hành tím và ớt đem xay hoặc băm cho thật nhuyễn."},{"step_number":2,"title":"Bước 2 – Phi thơm: ","description":"Bắc chảo lên bếp, cho 2 muỗng canh mỡ heo vào, đợi nóng rồi cho hành ớt vào phi cho dậy mùi thơm."},{"step_number":3,"title":"Bước 3 – Ướp và nêm cá: ","description":"Cho cá chốt vào chảo, nêm 1 muỗng canh đường, 1/2 muỗng cà phê bột ngọt, 5 muỗng canh nước mắm, đảo nhẹ tay cho cá thấm đều gia vị."},{"step_number":4,"title":"Bước 4 – Lên màu và kho lửa vừa: ","description":"Thêm 2 muỗng canh nước màu thốt nốt vào, kho ở lửa vừa khoảng 3-5 phút cho cá săn lại và lên màu đẹp."},{"step_number":5,"title":"Bước 5 – Kho thêm cho thấm: ","description":"Chan 150ml nước nóng vào, kho thêm 5-7 phút nữa để cá chín đều và ngấm gia vị từ trong ra ngoài."},{"step_number":6,"title":"Bước 6 – Thêm tiêu xanh: ","description":"Trong lúc chờ, xắt nhỏ hành lá, ớt, tiêu xanh đập dập cắt khúc. Cho tiêu xanh vào nồi cá để dậy mùi thơm đặc trưng."},{"step_number":7,"title":"Bước 7 – Hoàn thiện: ","description":"Thêm 1 muỗng canh mỡ heo để nước kho bóng đẹp, sau đó rắc hành lá, ớt, tiêu xay lên trên là hoàn thành."}]'::jsonb,
    204.3, 21.3, 7.9, 12.2, 0.2, 243,
    817, 85.2, 31.5, 48.8, 0.8, 971.9, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '8686ff4c-79de-4f30-9164-810747de4e30'::uuid, 1, '500g cá chốt', 'cá chốt', 500, 'g', 500, 70, 15.8, 0.8, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 2, 'Đường, chanh (để sơ chế cá)', 'Đường', 1, 'ít', 2, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 3, '10g hành tím', 'hành tím', 10, 'g', 10, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 4, 'Ớt (tùy khẩu vị)', 'Ớt (tùy khẩu vị)', 1, 'ít', 2, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 5, '2 muỗng canh mỡ heo (chia làm 2 lần dùng)', 'mỡ heo (chia làm 2 lần dùng)', 2, 'muỗng canh', 30, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 6, '1 muỗng canh đường', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 7, '1/2 muỗng cà phê bột ngọt', 'bột ngọt', 0.5, 'muỗng cà phê', 2.5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 8, '5 muỗng canh nước mắm', 'nước mắm', 5, 'muỗng canh', 75, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 9, '2 muỗng canh nước màu thốt nốt', 'nước màu thốt nốt', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, NULL, 10, '150ml nước nóng', 'nước nóng', 150, 'ml', 150, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 11, 'Hành lá, ớt xắt nhỏ', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 12, 'Tiêu xanh (đập dập, cắt khúc)', 'Tiêu xanh (đập dập', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [38] Recipe: Miến Mềm Tơi Ngon, Đảm Bảo Không Dính
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'Miến Mềm Tơi Ngon, Đảm Bảo Không Dính', 'cach-xao-mien-mem-toi-ngon-dam-bao-khong-dinh', 'Mấy chị em nội trợ chắc không lạ gì cảnh xào miến xong mà sợi miến cứ dính chùm lại với nhau, ăn không ngon. Hôm nay mình chia sẻ cách xào miến gà rau củ mềm tơi từng sợi, không hề bết dính, mà vị lại đậm đà thơm ngon. Công thức này nhà [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2026/09/cach-xao-mien-mem-toi-dai-ngon-dam-bao-ko-dinh.mp4_snapshot_00.06.745.jpg', 'https://bepxua.vn/cach-xao-mien-mem-toi-ngon-dam-bao-khong-dinh/', 'mon_an_sang', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1: Sơ chế miến","description":"Miến dong ngâm với nước lạnh khoảng 30 phút cho mềm, sau đó rửa lại và để ráo, cắt khúc vừa ăn. Đây là bước quan trọng nhất quyết định miến có tơi mềm hay không, chị em nhớ ngâm đủ thời gian, đừng ngâm nước nóng vì miến sẽ nhão và dễ dính cục khi xào."},{"step_number":2,"title":"Bước 2: Sơ chế rau củ và thịt gà","description":"Cải thìa bỏ bớt lá, chẻ cọng to cho nhanh chín đều. Cà rốt bào sợi, nấm mèo ngâm mềm rồi xắt sợi. Đùi gà lóc lấy thịt, rửa sạch, xắt miếng vừa ăn. Hành tím xắt lát, hành lá và ngò rí xắt khúc để riêng."},{"step_number":3,"title":"Bước 3: Trộn miến với gia vị","description":"Cho cải thìa, cà rốt, nấm mèo và miến dong vào chung một tô lớn. Nêm vào 1/2 muỗng canh hạt nêm, 1/2 muỗng canh đường, 2 muỗng canh nước tương, 2 muỗng canh dầu hào rồi trộn đều cho miến và rau củ thấm gia vị."},{"step_number":4,"title":"Bước 4: Phi hành, xào gà","description":"Bắc chảo với 5 muỗng canh mỡ heo, cho hành tím vào phi thơm vàng, vớt ra để riêng làm hành phi rắc lên món ăn sau này. Múc bớt mỡ ra chỉ chừa lại khoảng 2 muỗng canh trong chảo, cho thịt gà vào xào săn."},{"step_number":5,"title":"Bước 5: Nêm nếm thịt gà","description":"Thêm vào 2 muỗng canh nước tương, 1 muỗng canh dầu hào, 1/2 muỗng cà phê tiêu xay, đảo đều khoảng 5 phút cho thịt gà thấm vị. Nếu thấy gà xào ra ít nước thì cho thêm khoảng 100ml nước vào để chảo có đủ độ ẩm cho bước xào miến sau."},{"step_number":6,"title":"Bước 6: Cho miến vào xào","description":"Đổ phần miến và rau củ đã trộn gia vị vào chảo, xốc đều tay khoảng 5 phút cho miến chín và mềm tơi ra từng sợi, không bị vón cục. Khi thấy sợi miến trong, mềm là đã đạt."},{"step_number":7,"title":"Bước 7: Hoàn thành","description":"Cho giá đỗ, hành lá, ngò rí vào, xốc đều thêm 1 phút rồi tắt bếp. Múc miến ra đĩa, rắc thêm hành phi lên trên là có ngay món miến xào thơm ngon, hấp dẫn."}]'::jsonb,
    805.7, 32.9, 43.3, 70.8, 4, 1783.4,
    3223, 131.7, 173.4, 283.3, 16, 7133.6, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '7a02b320-d9d5-4dbc-b7b6-4d30d4412b04'::uuid, 1, 'Miến dong: 200g', 'Miến dong', 200, 'g', 200, 338, 0.6, 0.1, 83.7, 1.5, 0),
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 2, 'Đùi gà góc tư: 2 cái (600g), lóc lấy thịt, xắt miếng vừa ăn', 'Đùi gà góc tư', 2, 'cái', 600, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, '7ef588d9-36cf-4438-8ed3-d5d4706bd73b'::uuid, 3, 'Cải thìa: 200g, bỏ bớt lá, chẻ cọng to', 'Cải thìa', 200, 'g', 200, 54, 3.7, 0.2, 9.4, 1.5, 96),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 4, 'Cà rốt: 150g, bào sợi', 'Cà rốt', 150, 'g', 150, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, '156efcb2-c812-47b4-8dd8-ee957c973a1f'::uuid, 5, 'Nấm mèo: 20g, ngâm mềm, xắt sợi', 'Nấm mèo', 20, 'g', 20, 16, 0.8, 0, 3.2, 1.4, 0),
    (v_recipe_id, 'b603119d-75cb-488b-a13b-e35b4dee2096'::uuid, 6, 'Giá đỗ: 150g', 'Giá đỗ', 150, 'g', 150, 164, 9.5, 0.5, 30.3, 0.8, 1),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 7, 'Hành tím: 80g, xắt lát', 'Hành tím', 80, 'g', 80, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 8, 'Hành lá, ngò rí: xắt khúc', 'Hành lá, ngò rí', 1, 'phần', 30, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'cdab1be9-dcbe-48b8-88f0-1307856e2736'::uuid, 9, 'Mỡ heo: 5 muỗng canh', 'Mỡ heo', 5, 'muỗng canh', 75, 827, 2, 91, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'Hạt nêm: 1/2 muỗng canh', 'Hạt nêm', 0.5, 'muỗng canh', 7.5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 11, 'Đường: 1/2 muỗng canh', 'Đường', 0.5, 'muỗng canh', 7.5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 12, 'Nước tương: 2 muỗng canh (trộn miến) + 2 muỗng canh (xào gà)', 'Nước tương', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 13, 'Dầu hào: 2 muỗng canh (trộn miến) + 1 muỗng canh (xào gà)', 'Dầu hào', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 14, 'Tiêu xay: 1/2 muỗng cà phê', 'Tiêu xay', 0.5, 'muỗng cà', 15, 365, 7, 7.4, 67.6, 33.5, 44),
    (v_recipe_id, '1a39ae13-6c10-4908-bd42-4d9cbad7fcce'::uuid, 15, 'Nước: 100ml (nếu cần)', 'Nước', 100, 'ml', 100, 41, 0.3, 0.1, 9.7, 0.4, 2);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [39] Recipe: lẩu riêu tôm siêu ngon bất bại
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'lẩu riêu tôm siêu ngon bất bại', 'cach-nau-lau-rieu-tom-sieu-ngon-bat-bai', 'Nếu như riêu cua là nguyên liệu quá đỗi quen thuộc trong ẩm thực với món bún riêu cua trứ danh thì riêu tôm có vẻ khá lạ với nhiều người. Tuy nhiên riêu tôm ngon không kém gì riêu cua đâu nha, và tương tự như nấu riêu cua, bạn cũng có thể làm [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/12/maxresdefault-2-1.jpg', 'https://bepxua.vn/cach-nau-lau-rieu-tom-sieu-ngon-bat-bai/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Tôm chà rửa sạch, cắt càng. Bắc nồi hấp lên bếp, cho ½ phần tôm vào hấp 15 phút. Phần tôm còn lại cắt bỏ chân râu, bỏ cục bẩn đầu tôm, lột vỏ để riêng đầu và thịt tôm."},{"step_number":2,"title":"Bước 2","description":"Cho càng tôm vào máy xay, ấn nút xay trong 30s rồi thả ra, tiếp tục ấn; cho vào 1,2l nước lọc chia 2 lần rây khuấy đều, trút ra rây lấy nước riêu. Cho vào nồi khác nước riêu tôm vừa rây hành tím, 1 muỗng cafe muối rồi nấu sôi."},{"step_number":3,"title":"Bước 3","description":"Cho thịt tôm, giò heo sống( đã để ngăn đông 1h) vào máy xay xay nhuyễn. Thêm 1 muỗng cafe hạt nêm, ½ muỗng canh nước mắm, tiêu xay, 1 muỗng canh hành phi trộn đều."},{"step_number":4,"title":"Bước 4","description":"Cà chua, hành tím xắt lát. Ngò gai, hành lá xắt nhỏ. Huyết heo xắt miếng vừa ăn."},{"step_number":5,"title":"Bước 5","description":"Cho dầu ăn vào chảo đun nóng, dầu nóng cho hành tím vào phi thơm rồi cho đầu tôm vào đảo đều 1’ sau đó cho cà chua vào, nêm 1 muỗng canh nước mắm, ½ muỗng canh đường đảo đều."},{"step_number":6,"title":"Bước 6","description":"Mở nắp nồi riêu nấu sôi, cho lần lượt nước hấp tôm, cà chua và đầu tôm đã xào, huyết heo, vo viên chả tôm thịt cho vào nấu 15’ với mức nấu nhỏ; hớt bọt cho nước trong. Nêm 1 muỗng canh hạt nêm, 1 muỗng canh mắm tôm vào nấu sôi."},{"step_number":7,"title":"Bước 7","description":"Cho bún, rau sống vào tô, chan nước lẩu lên kèm chả tôm thịt, huyết heo rồi thêm ngò gai, hành lá, nặn chanh; ăn kèm mắm tôm pha chanh ớt và thưởng thức. Tôm hấp chấm muối tiêu chanh hoặc muối ớt xanh và thưởng thức."}]'::jsonb,
    44, 2.9, 0.4, 7.2, 0.7, 2613.9,
    175.8, 11.7, 1.4, 28.7, 2.7, 10455.7, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 1, 'tôm càng: 1,5 kg', 'tôm càng', 1, 'phần', 30, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, NULL, 2, 'giò sống: 150 gram ((hoặc thịt heo))', 'giò sống', 150, 'gram', 150, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 3, 'huyết heo: 150 gram', 'huyết heo', 150, 'gram', 150, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 4, 'hành tím: 20 gram', 'hành tím', 20, 'gram', 20, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 5, 'cà chua: 3 trái', 'cà chua', 3, 'trái', 225, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 6, 'Ngò gai, hành lá, ớt, chanh, rau ăn kèm', 'Ngò gai', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 7, 'Bún', 'Bún', 1, 'ít', 2, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 8, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'hạt nêm: 1 muỗng canh', 'hạt nêm', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 11, 'đường: 1 muỗng canh', 'đường', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2f66865c-8e90-4140-9ca7-e52a83eb368b'::uuid, 12, 'mắm tôm: 1 muỗng canh', 'mắm tôm', 1, 'muỗng canh', 15, 73, 14.8, 1.5, 0, 0, 4054),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 13, 'nước mắm: 1,5 muỗng canh', 'nước mắm', 1, 'phần', 30, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 14, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1)
  ON CONFLICT DO NOTHING;

  -- [40] Recipe: bún riêu cua đồng hải sản độc đáo tuyệt vời
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'bún riêu cua đồng hải sản độc đáo tuyệt vời', 'cach-nau-bun-rieu-cua-dong-hai-san-ngon-dam-da', 'Bún riêu là một món ăn truyền thống nổi tiếng trong ẩm thực Việt. Khởi nguồn từ vùng đất Bắc bộ, bún riêu dần lan truyền và trở thành món ăn người người nhà nhà đều biết; có mặt ở các hàng quán trên khắp các nẻo đường từ làng quê lên thành thị. Không [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/11/maxresdefault-4.jpg', 'https://bepxua.vn/cach-nau-bun-rieu-cua-dong-hai-san-ngon-dam-da/', 'mon_an_sang', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cua đồng lấy gạch, bỏ yếm, chà rửa sạch rồi giã nát. Cho thịt cua vừa giã vào tô, thêm nước lọc vào bóp đều rây lấy nước cua; rây 2-3 lần với 1l nước."},{"step_number":2,"title":"Bước 2","description":"Cho vào nồi nước cua, 1 muỗng cafe muối, 2 củ hành tím nấu sôi, vớt riêu cua ra rồi tắt bếp."},{"step_number":3,"title":"Bước 3","description":"Hải sản, đậu hũ, rau rửa sạch. Mực xắt khoanh vừa ăn, huyết heo xắt miếng vừa ăn. Tôm lột vỏ, bỏ đầu và chỉ lưng. Cà chua xắt khúc. Ngò gai xắt khúc. Chanh xắt làm 2 làm 3, ớt xắt nhỏ. Hành tím còn lại cho vào máy xay gia vị xay nhuyễn."},{"step_number":4,"title":"Bước 4","description":"Cho 2 muỗng canh dầu ăn vào chảo rồi cho hạt điều đỏ vào phi lấy dầu điều sau đó cho hành tím xay vào phi thơm."},{"step_number":5,"title":"Bước 5","description":"Cho lần lượt gạch cua, cà chua, tôm, mực vào chảo rồi nêm 1 muỗng canh hạt nêm, ½ muỗng canh đường xào đều."},{"step_number":6,"title":"Bước 6","description":"Cho thêm 2l nước lọc vào nồi nước cua rồi cho tôm mực xào, 2 muỗng canh hạt nêm, 1 muỗng canh đường phèn, 1 muỗng canh nước mắm, đậu hũ, huyết heo vào, nấu 2-3 phút cho sôi. Nước sôi hớt bọt, cho 1 muỗng canh mắm tôm vào nồi rồi tắt bếp."},{"step_number":7,"title":"Bước 7","description":"Gắp bún tươi đã trụng nước sôi vào tô, thêm rau sống, riêu cua, ngò gai, ớt xắt nhỏ tùy thích rồi chan nước dùng vào; ăn kèm mắm tôm pha nước cốt chanh thêm ớt và thưởng thức."}]'::jsonb,
    450.8, 86.7, 4.9, 15.1, 0.6, 5585.5,
    1803.1, 346.9, 19.6, 60.3, 2.3, 22342.2, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'f1a36b9e-2f62-4b7c-925d-51ac03e3bd6e'::uuid, 1, 'cua đồng: 1 kg', 'cua đồng', 1, 'kg', 1000, 71, 16.7, 0.5, 0, 0, 0),
    (v_recipe_id, 'b3e91883-2604-4be7-ab68-2b7253f35757'::uuid, 2, 'mực: 500 gram', 'mực', 500, 'gram', 500, 73, 16.3, 0.9, 0, 0, 44),
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 3, 'tôm: 500 gram', 'tôm', 500, 'gram', 500, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 4, 'cà chua: 2 quả', 'cà chua', 2, 'quả', 150, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 5, 'hành tím: 10 củ', 'hành tím', 10, 'củ', 150, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, NULL, 6, 'Huyết heo', 'Huyết heo', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'd9ce50a4-4865-4c7e-9a1c-20a8146f3c33'::uuid, 7, 'Đậu hũ', 'Đậu hũ', 1, 'ít', 2, 97, 10.9, 5.4, 1.1, 0.4, 7),
    (v_recipe_id, NULL, 8, 'Hạt điều đỏ', 'Hạt điều đỏ', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 9, 'Bún tươi', 'Bún tươi', 1, 'ít', 2, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 10, 'Ngò gai, chanh, ớt, rau sống', 'Ngò gai', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 12, 'đường: ½ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 13, 'đường phèn: 1 muỗng canh', 'đường phèn', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 14, 'nước mắm: 1 muỗng canh', 'nước mắm', 1, 'muỗng canh', 15, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '2f66865c-8e90-4140-9ca7-e52a83eb368b'::uuid, 15, 'mắm tôm: 1 muỗng canh', 'mắm tôm', 1, 'muỗng canh', 15, 73, 14.8, 1.5, 0, 0, 4054),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 16, 'hạt nêm: 3 muỗng canh', 'hạt nêm', 3, 'muỗng canh', 45, 0, 0, 0, 0, 0, 38758);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [41] Recipe: bún riêu cua đồng thơm ngon đậm đà
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'bún riêu cua đồng thơm ngon đậm đà', 'cach-nau-bun-rieu-cua-dong-thom-ngon-dam-da', 'Nhắc đến những món bún trứ danh trong ẩm thực Việt thì không thể nào không kể đến bún riêu. Món ăn truyền thống đậm đà hồn quê này không chỉ phổ biến trong nước mà còn được đông đảo du khách yêu thích. Từ Bắc đến Nam, bạn rất dễ tìm và nếm thử [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2022/10/bun-rieu-cua.jpg', 'https://bepxua.vn/cach-nau-bun-rieu-cua-dong-thom-ngon-dam-da/', 'mon_an_sang', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cua đồng tách mai, làm sạch, lấy gạch cua sau đó cho cua vào máy xay xay nát. Cho cua xay ra thố, thêm 1l nước lọc vào rây bỏ xác cua. Cho vào nồi nước cua hành tím, ½ muỗng cafe muối nấu sôi, vớt riêu cua nổi lên và hành tím bỏ ra."},{"step_number":2,"title":"Bước 2","description":"Cho riêu cua, thịt heo xay ra dĩa, đập thêm 3 quả trứng gà, thêm 1,5 muỗng canh hạt nêm, ½ muỗng canh đường, 1 muỗng canh nước mắm, hành phi, 1 muỗng canh dầu hành phi, tiêu xay vào trộn đều. Đem hỗn hợp vừa trộn đi hấp 20 phút."},{"step_number":3,"title":"Bước 3","description":"Cho vào chén gạch cua 1 muỗng canh dầu điều, 1 ít muối và khuấy đều sau đó đem phết lên hỗn hợp vừa hấp sau đó hấp thêm 10-15 phút là xong phần chả cua. Rắc thêm hành lá, ngò gai xắt nhỏ và tiêu xay lên để chả cua ngon hơn."},{"step_number":4,"title":"Bước 4","description":"Cho huyết heo vào nước sôi trụng sơ rồi vớt ra. Cho tiếp giò, xương, da heo vào nồi nước luộc 10 phút rồi vớt ra rửa lại nước."},{"step_number":5,"title":"Bước 5","description":"Cho 3l nước lọc vào nồi rồi cho giò, xương heo, 1 muỗng canh muối hột, hành tím vào nấu sôi. Cho ½ ống màu gạch tôm vào nồi và hầm lửa nhỏ 40 phút, nhớ vớt bọt để nước trong."},{"step_number":6,"title":"Bước 6","description":"Cho nước nấu riêu cua vào nồi nước hầm, cho tiếp cà chua đã xắt múi cau, huyết, da heo, đậu hũ viên, 3 muỗng canh đường phèn, ½ muỗng canh muối, 4 muỗng canh nước mắm, 2,5 muỗng canh mắm tôm vào nấu 10-15 phút. Tiếp theo cho 1 muỗng canh bột ngọt vào nấu sôi, vớt bọt."},{"step_number":7,"title":"Bước 7","description":"Vắt chanh vào chén mắm tôm, khuấy đều cho mắm sủi bọt rồi cho thêm ớt xay vào. Cho bún ra tô, chan nước dùng, cho thêm chả cua, hành lá, ớt xay và vắt thêm chanh vào rồi thưởng thức."}]'::jsonb,
    496.9, 70.8, 13.4, 23.2, 0.9, 12580.1,
    1987.4, 283.3, 53.6, 93, 3.7, 50320.4, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'f1a36b9e-2f62-4b7c-925d-51ac03e3bd6e'::uuid, 1, 'cua đồng: 1 kg', 'cua đồng', 1, 'kg', 1000, 71, 16.7, 0.5, 0, 0, 0),
    (v_recipe_id, NULL, 2, 'giò, xương heo: 1,2 kg', 'giò, xương heo', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 3, 'huyết heo: 250 gram', 'huyết heo', 250, 'gram', 250, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '053ccf2e-c2ce-4ec7-a3e0-1acac583971d'::uuid, 4, 'thịt heo xay: 250 gram', 'thịt heo xay', 250, 'gram', 250, 139, 19, 7, 0, 0, 76),
    (v_recipe_id, 'd9ce50a4-4865-4c7e-9a1c-20a8146f3c33'::uuid, 5, 'đậu hũ viên: 250 gram', 'đậu hũ viên', 250, 'gram', 250, 97, 10.9, 5.4, 1.1, 0.4, 7),
    (v_recipe_id, 'e5578d52-6ace-48bb-adc2-98de48dee2e2'::uuid, 6, 'Da heo', 'Da heo', 1, 'ít', 2, 118, 23.3, 2.7, 0, 0, 0),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 7, 'hành tím: 30 gram', 'hành tím', 30, 'gram', 30, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, 'f83ca0a5-8fa3-43c1-b1fc-0ca11430526b'::uuid, 8, 'trứng gà: 3 quả', 'trứng gà', 3, 'quả', 150, 150, 13, 10.3, 1.3, 0, 158),
    (v_recipe_id, '5d0a76ac-8efc-4ef4-b6c4-16ccd1982ac4'::uuid, 9, 'cà chua: 3 quả', 'cà chua', 3, 'quả', 225, 24, 0.6, 0.2, 4.8, 0.8, 12),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 10, 'Hành lá, ngò gai, hành phi, ớt, chanh', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, '0c42c761-b80a-4b38-b4c5-43c1e207b6d9'::uuid, 11, 'màu gạch tôm: ½ ống', 'màu gạch tôm', 1, 'phần', 30, 90, 18.4, 1.8, 0, 0, 418),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 12, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 13, 'muối: ½ muỗng canh', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 14, 'đường: ½ muỗng canh', 'đường', 1, 'phần', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'muối hột: 1 muỗng canh', 'muối hột', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 16, 'muối: 1 ít', 'muối', 1, 'ít', 2, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 17, 'bột ngọt: 1 muỗng canh', 'bột ngọt', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 18, 'dầu hành phi: 1 muỗng canh', 'dầu hành phi', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 19, 'dầu điều: 1 muỗng canh', 'dầu điều', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 20, 'hạt nêm: 1,5 muỗng canh', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2f66865c-8e90-4140-9ca7-e52a83eb368b'::uuid, 21, 'mắm tôm: 2,5 muỗng canh', 'mắm tôm', 2, 'phần', 60, 73, 14.8, 1.5, 0, 0, 4054),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 22, 'đường phèn: 3 muỗng canh', 'đường phèn', 3, 'muỗng canh', 45, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 23, 'nước mắm: 5 muỗng canh', 'nước mắm', 5, 'muỗng canh', 75, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 24, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 1),
    (v_recipe_id, 6),
    (v_recipe_id, 2)
  ON CONFLICT DO NOTHING;

  -- [42] Recipe: bún bò Huế chay đậm vị ngon lành
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'bún bò Huế chay đậm vị ngon lành', 'cach-nau-bun-bo-hue-chay-dam-vi-ngon-lanh', 'Bún bò Huế trứ danh trong bản đồ ẩm thực Việt, bún bò Huế chay cũng không ngoại lệ. Hương vị thơm ngon đặc trưng của món bún đến từ cố đô luôn dễ dàng làm những người sành ăn hài lòng. Món bún bò Huế chay càng ghi điểm hơn đối với những người [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2022/09/bun-bo-hue-chay.jpg', 'https://bepxua.vn/cach-nau-bun-bo-hue-chay-dam-vi-ngon-lanh/', 'mon_chay', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Củ cải trắng, cà rốt, mướp, su su bào vỏ. Bắp lột vỏ. Nấm gọt sơ. Hành tím bóc vỏ. Rau ăn kèm lặt rồi ngâm rửa sạch hết rau củ. Sả xắt lát cho vào máy xay với hành tím xay nhuyễn."},{"step_number":2,"title":"Bước 2","description":"Củ cải trắng, cà rốt tỉa hoa, xắt lát. Mướp, bắp xắt khúc. Su su bỏ hạt xắt khúc. Thơm xắt lát. Tàu hủ ky non xắt vừa ăn. Chả quế chay xắt lát. Tàu hủ ky lá xé nhỏ cho dễ chiên. Bò lát chay ngâm mềm rồi xả lại với nước sạch, vắt xả 2-3 lần nước, vắt khô."},{"step_number":3,"title":"Bước 3","description":"Cho 3l nước lọc vào nồi rồi cho hết các củ quả đã xắt khúc vào, đậy nắp nấu sôi sau đó hạ lửa nhỏ hầm 60 phút."},{"step_number":4,"title":"Bước 4","description":"Cho 4 muỗng canh dầu ăn vào chảo đun nóng rồi cho 2 muỗng canh hạt điều đỏ DH Foods vào nấu lấy dầu màu điều, vớt bỏ hạt. Tiếp tục cho hành sả xay vào phi thơm rồi cho bò lát chay và thêm khoảng 2 muỗng canh dầu ăn vào đảo đều 1-2 phút. Cho tiếp nấm rơm vào chảo đảo đều, thêm 1 muỗng cafe đường, 1 muỗng cafe muối, 1 muỗng canh nước mắm chay vào đảo đều rồi tắt bếp."},{"step_number":5,"title":"Bước 5","description":"Cho dầu ăn vào chảo khác đun nóng rồi cho tàu hủ ky lá vào chiên giòn gắp ra. Cho tiếp chả chay và tàu hủ ky non vào chiên sơ, gắp ra."},{"step_number":6,"title":"Bước 6","description":"Cho gia vị nấu bún bò Huế DH Foods vào túi lọc, buộc chặt miệng túi. Mở nắp nồi hầm củ quả vớt củ quả ra, cho túi gia vị bún bò Huế DH Foods vào nồi nước hầm rồi cho thơm, cà rốt, củ cải trắng, 1 muỗng canh muối hột vào đậy nắp nấu sôi 20 phút."},{"step_number":7,"title":"Bước 7","description":"Sau khi sôi mở nắp nồi hầm vớt túi gia vị ra, cho nấm và bò lát chay đã xào vào đảo đều, thêm 1 muỗng canh muối hột, 2 muỗng canh nước mắm chay nêm cho nước lèo đậm vị. Nấu sôi rồi tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Cho bún vào tô, sắp chả chay, tàu hủ ky non, tàu hủ ky lá lên rồi chan nước lèo; thêm rau răm, tiêu đen xay Phú Quốc DH Foods, vắt thêm chanh, thêm rau ăn kèm, nước mắm chay sa tế theo ý thích và thưởng thức."}]'::jsonb,
    147.3, 10.4, 2.8, 20.1, 2.7, 3459.8,
    589.4, 41.7, 11.2, 80.6, 10.8, 13839.3, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '01be3eb9-d5a1-4cbb-865a-7a8e652e23e0'::uuid, 1, 'su su: 1 quả', 'su su', 1, 'quả', 60, 23, 0.8, 0.1, 4.6, 1, 2),
    (v_recipe_id, 'bc8ce594-a9a2-4a72-afa9-7ca1d1a1e89b'::uuid, 2, 'mướp: 1 quả', 'mướp', 1, 'quả', 60, 18, 0.9, 0.1, 3.4, 0.5, 3),
    (v_recipe_id, '04c51b40-a02a-4296-b26d-b1aa675d578b'::uuid, 3, 'bắp: 1 quả', 'bắp', 1, 'quả', 60, 52, 0.9, 0.3, 11.4, 0.1, 0),
    (v_recipe_id, '395cfd1b-5398-4f07-a183-91bbc75c15f6'::uuid, 4, 'củ cải trắng: 2 củ', 'củ cải trắng', 2, 'củ', 100, 27, 1.5, 0.1, 5.1, 1.5, 10),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 5, 'cà rốt: 2 củ', 'cà rốt', 2, 'củ', 200, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 6, 'sả: 5 cây', 'sả', 5, 'cây', 125, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 7, 'hành tím: 30 gram', 'hành tím', 30, 'gram', 30, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, NULL, 8, 'tàu hủ ky non: 50 gram', 'tàu hủ ky non', 50, 'gram', 50, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 9, 'tàu hủ ky lá: 50 gram', 'tàu hủ ky lá', 50, 'gram', 50, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'c893db6c-a1b2-4e27-bbb0-92724957e044'::uuid, 10, 'bò lát chay: 100 gram', 'bò lát chay', 100, 'gram', 100, 118, 21, 3.8, 0, 0, 83),
    (v_recipe_id, '998c09a4-f38e-42ff-a133-7f8bd2d6ae99'::uuid, 11, 'nấm rơm: 200 gram', 'nấm rơm', 200, 'gram', 200, 61, 3.6, 3.2, 4.5, 1.1, 0),
    (v_recipe_id, '55e5e96b-c33f-4dfe-99a6-03ad1bab890b'::uuid, 12, 'thơm: 200 gram', 'thơm', 200, 'gram', 200, 32, 0.8, 0, 7.3, 0.8, 24),
    (v_recipe_id, NULL, 13, 'Chả quế chay', 'Chả quế chay', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 14, 'Rau ăn kèm, rau răm, chanh', 'Rau ăn kèm', 1, 'ít', 2, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 15, 'muối: 1 muỗng cafe', 'muối', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 16, 'đường: 1 muỗng cafe', 'đường', 1, 'muỗng cafe', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 17, 'muối hột: 2 muỗng canh', 'muối hột', 2, 'muỗng canh', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 18, 'nước mắm chay: 3 muỗng canh', 'nước mắm chay', 3, 'muỗng canh', 45, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, NULL, 19, 'hạt điều đỏ DH Foods: 2 muỗng canh', 'hạt điều đỏ DH Foods', 2, 'muỗng canh', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 20, 'gia vị nấu bún bò Huế DH Foods: 1 túi', 'gia vị nấu bún bò Huế DH Foods', 1, 'túi', 30, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 21, 'Tiêu đen xay Phú Quốc DH Foods', 'Tiêu đen xay Phú Quốc DH Foods', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  -- [43] Recipe: cơm chiên Dương Châu đậm đà ngon số dách
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'cơm chiên Dương Châu đậm đà ngon số dách', 'cach-lam-com-chien-duong-chau-dam-da-ngon-so-dach', 'Cơm chiên Dương Châu đến từ ẩm thực Trung Hoa, bắt nguồn nơi thành phố Dương Châu từ lâu đã được du nhập và trở thành món ăn quen thuộc với người Việt. Sự nổi bật cả về hình thức lẫn hương vị khiến món cơm chiên này trở thành món ăn yêu thích của [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/09/2XVE_Snq8No-HD.jpg', 'https://bepxua.vn/cach-lam-com-chien-duong-chau-dam-da-ngon-so-dach/', 'mon_an_sang', 'vietnamese',
    4, 15, 25, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Cơm trắng để ngăn mát tủ lạnh 1 đêm. Cà rốt, đậu hà lan, hành lá rửa sạch. Cà rốt, chả lụa, lạp xưởng khô xắt hạt lựu. Hành lá xắt nhỏ."},{"step_number":2,"title":"Bước 2","description":"Trước khi chiên 30 phút lấy cơm ra ngoài cho hết lạnh, sau đó đập trứng vào cơm, thêm ⅔ muỗng canh hạt nêm, 1 muỗng canh dầu màu điều rồi trộn đều, bóp cho cơm tơi ra."},{"step_number":3,"title":"Bước 3","description":"Nấu sôi 500ml nước, nước sôi cho cà rốt, đậu hà lan vào luộc 4 phút rồi vớt ra."},{"step_number":4,"title":"Bước 4","description":"Làm nóng chảo rồi cho lạp xưởng vào đảo đều lạp xưởng đến khi ra mỡ thì cho chả lụa, cà rốt, đậu hà lan, 2 muỗng canh nước tương và đảo đều khoảng 2 phút rồi cho ra tô."},{"step_number":5,"title":"Bước 5","description":"Tỏi cho vào máy xay gia vị xay nhuyễn. Cho 2 muỗng canh dầu ăn vào chảo đun nóng, dầu nóng cho tỏi xay vào phi thơm rồi cho cơm vào đảo lửa vừa đến khi cơm khô, tơi ra, nổ lách tách thì cho hỗn hợp  lạp xưởng, chả lụa, cà rốt, đậu hà lan và 1 muỗng cafe đường hoặc ½ muỗng cafe bột ngọt vào đảo đều, rắc thêm hành lá rồi tắt bếp."},{"step_number":6,"title":"Bước 6","description":"Cho cơm chiên Dương Châu ra dĩa, ăn kèm cà chua, dưa leo, trứng ốp la, tiêu xay, tương ớt tùy ý… và thưởng thức."}]'::jsonb,
    791.2, 21.8, 23.5, 123, 1.6, 3516.1,
    3164.8, 87.3, 94.2, 492, 6.5, 14064.5, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '893efa61-7553-48ce-b9f8-0489b6990882'::uuid, 1, 'cơm trắng: 600 gram', 'cơm trắng', 600, 'gram', 600, 347, 8.1, 1.3, 75.7, 0.7, 5),
    (v_recipe_id, '964b93b9-05d8-4dd1-b896-d2c149bdf5fc'::uuid, 2, 'chả lụa: 150 gram', 'chả lụa', 150, 'gram', 150, 517, 10.8, 50.4, 5.1, 0, 339),
    (v_recipe_id, NULL, 3, 'lạp xưởng khô: 120 gram', 'lạp xưởng khô', 120, 'gram', 120, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '87c3539c-cc28-4dfa-b3d1-5c0e2bf031a3'::uuid, 4, 'cà rốt: 80 gram', 'cà rốt', 80, 'gram', 80, 44, 1.5, 0.2, 9, 1.2, 52),
    (v_recipe_id, 'b623ee68-a367-47e5-b521-5c6a749717f8'::uuid, 5, 'đậu hà lan: 80 gram', 'đậu hà lan', 80, 'gram', 80, 75, 6.5, 0.3, 11.7, 1, 5),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 6, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'f83ca0a5-8fa3-43c1-b1fc-0ca11430526b'::uuid, 7, 'trứng gà: 2 quả', 'trứng gà', 2, 'quả', 100, 150, 13, 10.3, 1.3, 0, 158),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 8, 'Hành lá', 'Hành lá', 1, 'ít', 2, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, NULL, 9, 'dầu màu điều: 1 muỗng canh', 'dầu màu điều', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 10, 'đường: 1 muỗng cafe ((hoặc ½ muỗng cafe bột ngọt))', 'đường', 1, 'muỗng cafe', 5, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'hạt nêm: ⅔ muỗng canh', 'hạt nêm', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 12, 'nước tương: 2 muỗng canh', 'nước tương', 2, 'muỗng canh', 30, 55, 6.3, 0, 7.5, 0.8, 5637);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 2),
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

  -- [44] Recipe: lẩu gà lá giang thơm ngon bổ dưỡng trứ danh
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'lẩu gà lá giang thơm ngon bổ dưỡng trứ danh', 'cach-nau-lau-ga-la-giang-thom-ngon-bo-duong-tru-danh', 'Lẩu gà lá giang là một trong những món lẩu nằm top phổ biến nhất và rất được các tín đồ sành ăn yêu thích khi nhắc đến những món lẩu gà. Thịt gà mềm ngọt và lá giang chát chua tưởng không hợp mà lại hợp không tưởng, sự kết hợp này đã đem [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2024/07/maxresdefault-4.jpg', 'https://bepxua.vn/cach-nau-lau-ga-la-giang-thom-ngon-bo-duong-tru-danh/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Dùng muối thoa đều gà, cắt bỏ móng rồi rửa sạch. Tiếp tục dùng chanh thoa gà khử mùi rồi rửa sạch, chặt miếng vừa ăn và rửa sạch lại lần nữa. Lá giang lặt lá, ngâm rửa sạch với nước muối, vò sơ. Rau ăn kèm làm rửa sạch, ngò om ngò gai ớt xắt nhỏ."},{"step_number":2,"title":"Bước 2","description":"Cho gừng xắt lát và 1 muỗng canh nước mắm vào nồi 2l nước rồi nấu sôi, nước sôi cho gà vào trụng sơ 2 phút để khi nấu nước dùng sẽ trong, không bị tanh. Sau khi trụng vớt gà ra."},{"step_number":3,"title":"Bước 3","description":"Tỏi, hành tím cho vào máy xay gia vị xay nhuyễn. Cho gà ra tô, cho ½ phần hành tỏi xay, 1 muỗng cafe muối, 1 muỗng cafe hạt nêm, 1 muỗng canh đường phèn, 2 muỗng canh nước mắm, 1-2 muỗng canh sa tế, tiêu xay vào tô trộn đều gà, ướp 15 phút."},{"step_number":4,"title":"Bước 4","description":"Cho 3 muỗng canh dầu ăn vào nồi và đun nóng, dầu nóng cho sả đập dập và phần hành tỏi xay còn lại vào phi thơm rồi cho thịt gà vào đảo đều khoảng 5 phút."},{"step_number":5,"title":"Bước 5","description":"Cho 2,5l nước lọc vào nồi đậy nắp nấu sôi với lửa lớn, nước sôi mở nắp hớt bọt, nấu tiếp 15-20 phút với lửa nhỏ vừa."},{"step_number":6,"title":"Bước 6","description":"Cho 1 muỗng canh dầu ăn vào chảo và đun nóng, dầu nóng cho lá giang vào xào sơ 1 phút để khi nấu nước dùng không bị chát."},{"step_number":7,"title":"Bước 7","description":"Cho từ từ lá giang vào nồi lẩu, gia giảm tùy độ chua và khẩu vị, nêm 1 muỗng cafe muối, 1 muỗng canh đường phèn, ½ muỗng cafe bột ngọt, 2 muỗng canh nước mắm đảo đều."},{"step_number":8,"title":"Bước 8","description":"Cho 1 muỗng canh muối hột, ½ muỗng canh đường phèn, ½ muỗng cafe bột ngọt, ớt tùy thích vào cối rồi giã nát, vắt thêm nước cốt chanh vào khuấy đều làm muối chấm."},{"step_number":9,"title":"Bước 9","description":"Cho vào nồi lẩu ngò om, ngò gai, ớt, nấm, rau muống, chuối cây, bắp chuối vừa nấu vừa ăn. Múc bún vào chén, chan nước lẩu, chấm thịt gà với muối chấm và thưởng thức."}]'::jsonb,
    95.8, 2.9, 1.4, 18, 0.6, 3402.8,
    383, 11.6, 5.5, 71.8, 2.3, 13611.3, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, 'ac0b5613-b6df-4e08-97c2-4743e580137b'::uuid, 1, 'gà: 1,8 kg', 'gà', 1, 'phần', 30, 219, 16.4, 17, 0, 0, 91),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 2, 'gừng: 20 gram', 'gừng', 20, 'gram', 20, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, '4059eb95-abd3-43e0-93b0-d8947e213d98'::uuid, 3, 'tỏi: 20 gram', 'tỏi', 20, 'gram', 20, 126, 6, 0.4, 24.7, 1.5, 18),
    (v_recipe_id, 'a03bdc86-0e48-46f4-8e31-014a3c0b6abb'::uuid, 4, 'hành tím: 20 gram', 'hành tím', 20, 'gram', 20, 29, 1.3, 0.3, 5.2, 0.7, 17),
    (v_recipe_id, NULL, 5, 'lá giang: 1 bó', 'lá giang', 1, 'bó', 300, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '932b64dd-8644-4df5-b6e9-070b380b4558'::uuid, 6, 'sả: 2 cây', 'sả', 2, 'cây', 50, 26, 1.3, 0, 5.2, 0.9, 16),
    (v_recipe_id, 'fc7d530a-5385-4589-ae9f-8c73aba15975'::uuid, 7, 'Ngò gai, ngò om, nấm, rau muống, chuối cây, bắp chuối, ớt, chanh', 'Ngò gai', 1, 'ít', 2, 30, 2.9, 0, 4.5, 1.8, 72),
    (v_recipe_id, 'b63330e5-f98b-4aeb-8c38-01a914920a2e'::uuid, 8, 'Bún tươi', 'Bún tươi', 1, 'ít', 2, 112, 1.7, 0, 26.2, 0.5, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 9, 'bột ngọt: 1 muỗng cafe', 'bột ngọt', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 10, 'hạt nêm: 1 muỗng cafe', 'hạt nêm', 1, 'muỗng cafe', 5, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 11, 'muối: 2 muỗng cafe', 'muối', 2, 'muỗng cafe', 10, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 12, 'muối hột: 1 muỗng canh', 'muối hột', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 13, 'sa tế: 1-2 muỗng canh', 'sa tế', 1, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 14, 'đường phèn: 2,5 muỗng canh', 'đường phèn', 2, 'phần', 60, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '0f9ff070-81cb-4e32-a661-44927b971958'::uuid, 15, 'nước mắm: 4 muỗng canh', 'nước mắm', 4, 'muỗng canh', 60, 28, 7.1, 0, 0, 0, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 16, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  -- [45] Recipe: lẩu bò Mông Cổ thơm ngon đơn giản tại nhà
  INSERT INTO public.recipes (
    title, slug, description, image_url, source_url, category, cuisine,
    servings, prep_time_minutes, cook_time_minutes, difficulty, instructions,
    calories_per_serving, protein_g_per_serving, fat_g_per_serving, carbs_g_per_serving, fiber_g_per_serving, sodium_mg_per_serving,
    total_calories, total_protein_g, total_fat_g, total_carbs_g, total_fiber_g, total_sodium_mg, is_verified
  ) VALUES (
    'lẩu bò Mông Cổ thơm ngon đơn giản tại nhà', 'cach-nau-lau-bo-mong-co-thom-ngon-don-gian-tai-nha', 'Trong thời gian gần đây, lẩu bò Mông Cổ nổi lên như một hiện tượng đối với những tín đồ yêu ẩm thực. Món ăn bắt nguồn từ ẩm thực Trung Hoa này nhanh chóng chiếm được cảm tình của hội sành ăn. Với sức hút như vậy, không khó hiểu khi lẩu bò Mông [&hellip;]', 'https://bepxua.vn/wp-content/uploads/2023/12/maxresdefault-7.jpg', 'https://bepxua.vn/cach-nau-lau-bo-mong-co-thom-ngon-don-gian-tai-nha/', 'mon_man', 'vietnamese',
    4, 15, 30, 'medium', '[{"step_number":1,"title":"Bước 1","description":"Nguyên liệu sơ chế rửa sạch. Bắp bò, thịt bò, rìa thăn bò xắt lát mỏng."},{"step_number":2,"title":"Bước 2","description":"Cho rìa thăn bò, 20 gram gừng và hành baro xắt nhỏ, ½ muỗng canh đường, ½ muỗng canh hạt nêm, 1 muỗng canh dầu hào, tiêu xay vào máy xay xay nhuyễn vừa."},{"step_number":3,"title":"Bước 3","description":"Cho thịt xay vào bao tử dê cuộn tròn lại ,dùng dây chỉ buộc chặt. Làm tương tự cho đến khi chỉ còn phần rìa thì xắt phần rìa thành từng miếng vừa ăn."},{"step_number":4,"title":"Bước 4","description":"Cho vào nồi sả, 20 gram gừng xắt lát và 50ml rượu rồi đun sôi sau đó cho bao tử nhồi thịt và phần rìa bao tử vào luộc 2-3 phút xong vớt ra."},{"step_number":5,"title":"Bước 5","description":"Lấy 30 gram gừng xắt lát và hành tây cho lên vỉ nướng nướng sơ."},{"step_number":6,"title":"Bước 6","description":"Cho vào nồi khác 2,5l nước dừa tươi hoặc nước hầm xương, bao tử nhồi thịt đã luộc, hành tây và gừng vừa nướng, quế cây, hoa hồi, táo đỏ, đông trùng, ớt (tùy khẩu vị), 1 muỗng canh muối hạt, 1 muỗng canh đường phèn đậy nắp nấu sôi, vớt bọt cho nước trong. Hầm lẩu 60 phút với lửa nhỏ vừa."},{"step_number":7,"title":"Bước 7","description":"Sau 60 phút mở nắp nồi nước lẩu đảo đều, thêm nấm hương, 1,5 muỗng canh hạt nêm nấu sôi lại tắt bếp."},{"step_number":8,"title":"Bước 8","description":"Hoa hẹ, táo bơm xắt khúc. Cho ⅔ hoa hẹ, táo bơm, ½ muỗng cafe muối, 30ml nước lọc vào máy xay xay nhuyễn cho ra chén làm nước chấm hoa hẹ."},{"step_number":9,"title":"Bước 9","description":"Cho vào chén 2 muỗng canh chao, 1 muỗng canh sa tế, ½ muỗng canh đường khuấy đều làm nước chấm chao sa tế."},{"step_number":10,"title":"Bước 10","description":"Múc nước lẩu ra thố nhỏ, bẻ mì gói hoặc mì trứng cho vào, thêm cải, nấm linh chi, bao tử nhồi thịt, bắp bò, rau tần ô nấu sôi lại, chấm nước chấm chao sa tế; dùng dao xẻ đôi bao tử nhồi thịt, chấm nước chấm hoa hẹ và thưởng thức."}]'::jsonb,
    292.3, 30.7, 5.2, 22.2, 2.8, 7662.1,
    1169.1, 122.8, 21, 88.9, 11.1, 30648.3, true
  )
  ON CONFLICT (slug) DO UPDATE SET
    title = EXCLUDED.title, description = EXCLUDED.description, image_url = EXCLUDED.image_url,
    instructions = EXCLUDED.instructions, calories_per_serving = EXCLUDED.calories_per_serving,
    protein_g_per_serving = EXCLUDED.protein_g_per_serving, fat_g_per_serving = EXCLUDED.fat_g_per_serving,
    carbs_g_per_serving = EXCLUDED.carbs_g_per_serving, fiber_g_per_serving = EXCLUDED.fiber_g_per_serving,
    sodium_mg_per_serving = EXCLUDED.sodium_mg_per_serving, total_calories = EXCLUDED.total_calories,
    total_protein_g = EXCLUDED.total_protein_g, total_fat_g = EXCLUDED.total_fat_g,
    total_carbs_g = EXCLUDED.total_carbs_g, total_fiber_g = EXCLUDED.total_fiber_g,
    total_sodium_mg = EXCLUDED.total_sodium_mg, updated_at = now()
  RETURNING id INTO v_recipe_id;

  DELETE FROM public.recipe_ingredients WHERE recipe_id = v_recipe_id;
  DELETE FROM public.recipe_allergens WHERE recipe_id = v_recipe_id;

  INSERT INTO public.recipe_ingredients (
    recipe_id, ingredient_id, order_index, raw_text, ingredient_name_raw,
    amount, unit, amount_g, calories_per_100g, protein_per_100g, fat_per_100g,
    carbs_per_100g, fiber_per_100g, sodium_mg_per_100g
  ) VALUES
    (v_recipe_id, '91962843-c7e5-4871-888f-1c18c31f5c5c'::uuid, 1, 'Bắp bò', 'Bắp bò', 1, 'ít', 2, 85, 20, 0.5, 0, 0, 80),
    (v_recipe_id, 'c893db6c-a1b2-4e27-bbb0-92724957e044'::uuid, 2, 'rìa thăn bò: 500 gram', 'rìa thăn bò', 500, 'gram', 500, 118, 21, 3.8, 0, 0, 83),
    (v_recipe_id, NULL, 3, 'hoa hẹ: 100 gram', 'hoa hẹ', 100, 'gram', 100, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 4, 'táo bơm: 50 gram', 'táo bơm', 50, 'gram', 50, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '9acb5257-719c-4de4-a431-c292d5c8b914'::uuid, 5, 'gừng: 50 gram', 'gừng', 50, 'gram', 50, 41, 0.4, 0.5, 8.6, 3.3, 7),
    (v_recipe_id, NULL, 6, 'hành baro: 30 gram', 'hành baro', 30, 'gram', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 7, 'bao tử dê: 2 cái', 'bao tử dê', 2, 'cái', 60, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 8, 'quế cây: 1 nhánh', 'quế cây', 1, 'nhánh', 20, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'ede989e9-6f06-4f8c-88a2-3f07edf3b5ce'::uuid, 9, 'hành tây: 2 củ', 'hành tây', 2, 'củ', 240, 45, 1.8, 0.1, 9.3, 1.1, 8),
    (v_recipe_id, NULL, 10, 'hoa hồi: 2 cái', 'hoa hồi', 2, 'cái', 60, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '053f634e-803c-4063-8750-90b74b4b4504'::uuid, 11, 'nấm hương: 10 cái', 'nấm hương', 10, 'cái', 300, 33, 3.8, 0, 4.4, 2, 98),
    (v_recipe_id, NULL, 12, 'táo đỏ: 15 trái', 'táo đỏ', 15, 'trái', 900, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, NULL, 13, 'đông trùng: 30-40 sợi', 'đông trùng', 30, 'phần', 30, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, '6bc90d7d-c381-471d-91c7-01a99c85fb89'::uuid, 14, 'nước dừa tươi: 2,5 lit', 'nước dừa tươi', 2, 'phần', 60, 224, 0, 0, 0, 0, 0),
    (v_recipe_id, 'ae3c3f17-5590-4504-904f-58cc10eb3f3a'::uuid, 15, 'Ớt, rau ăn kèm( cải thảo, tần ô&#8230;.), mì gói(mì trứng)', 'Ớt', 1, 'ít', 2, 31, 1, 0.3, 6, 2, 2),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 16, 'muối: ½ muỗng cafe', 'muối', 1, 'phần', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 17, 'muối hạt: 1 muỗng canh', 'muối hạt', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, NULL, 18, 'sa tế: 1 muỗng canh', 'sa tế', 1, 'muỗng canh', 15, 0, 0, 0, 0, 0, 0),
    (v_recipe_id, 'f4640bc8-ba64-421c-9999-bdcc3085f958'::uuid, 19, 'dầu hào: 1 muỗng canh', 'dầu hào', 1, 'muỗng canh', 15, 55, 6.3, 0, 7.5, 0.8, 5637),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 20, 'đường phèn: 1 muỗng canh', 'đường phèn', 1, 'muỗng canh', 15, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '2db5aeaf-7420-4bb2-bec8-2fe53626a8cb'::uuid, 21, 'đường: 2 muỗng canh', 'đường', 2, 'muỗng canh', 30, 397, 0, 0, 99.3, 0, 0),
    (v_recipe_id, '24096fde-c19d-4a46-a53c-6861038a87a9'::uuid, 22, 'hạt nêm: 2 muỗng canh', 'hạt nêm', 2, 'muỗng canh', 30, 0, 0, 0, 0, 0, 38758),
    (v_recipe_id, '9d64e786-24bd-4fab-9211-a1c17c224b50'::uuid, 23, 'chao: 2 muỗng canh', 'chao', 2, 'muỗng canh', 30, 69, 1.4, 4.4, 6, 0.1, 0),
    (v_recipe_id, '041bae1a-b3c2-460b-b13a-76a71fcee84f'::uuid, 24, 'Tiêu xay', 'Tiêu xay', 1, 'ít', 2, 365, 7, 7.4, 67.6, 33.5, 44);

  INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
    (v_recipe_id, 6)
  ON CONFLICT DO NOTHING;

END $$;
