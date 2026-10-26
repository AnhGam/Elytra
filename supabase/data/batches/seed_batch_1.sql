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

END $$;
