DO $$
DECLARE
  v_recipe_id UUID;
BEGIN

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

END $$;
