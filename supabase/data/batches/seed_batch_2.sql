DO $$
DECLARE
  v_recipe_id UUID;
BEGIN

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

END $$;
