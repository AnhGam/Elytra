DO $$
DECLARE
  v_recipe_id UUID;
BEGIN

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

END $$;
