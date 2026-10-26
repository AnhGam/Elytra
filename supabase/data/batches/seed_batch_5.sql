DO $$
DECLARE
  v_recipe_id UUID;
BEGIN

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
