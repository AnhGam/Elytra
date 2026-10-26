-- SEED: Danh mục nhóm thực phẩm và Dị ứng

INSERT INTO ingredient_categories (id, code, roman, name_vi, name_en, display_order)
VALUES
  (1, 'cereal', 'I', 'Ngũ cốc và sản phẩm chế biến', 'Cereals and cereal products', 1),
  (2, 'tuber', 'II', 'Khoai củ và sản phẩm chế biến', 'Starchy roots, tubers and products', 2),
  (3, 'legume_nut', 'III', 'Hạt, quả giàu đạm, béo và sản phẩm chế biến', 'Nuts, seeds and legumes', 3),
  (4, 'vegetable', 'IV', 'Rau, quả, củ dùng làm rau', 'Vegetables and vegetable products', 4),
  (5, 'fruit', 'V', 'Quả chín', 'Fruits', 5),
  (6, 'fat_oil', 'VI', 'Dầu, mỡ, bơ', 'Fats and oils', 6),
  (7, 'meat', 'VII', 'Thịt và sản phẩm chế biến', 'Meat and meat products', 7),
  (8, 'seafood', 'VIII', 'Thủy sản và sản phẩm chế biến', 'Fish, seafood and products', 8),
  (9, 'egg', 'IX', 'Trứng và sản phẩm chế biến', 'Eggs and egg products', 9),
  (10, 'milk', 'X', 'Sữa và sản phẩm chế biến', 'Milk and milk products', 10),
  (11, 'canned', 'XI', 'Đồ hộp', 'Canned foods', 11),
  (12, 'sweet', 'XII', 'Đồ ngọt (đường, bánh, mứt, kẹo)', 'Sugars, confectionery and sweets', 12),
  (13, 'seasoning', 'XIII', 'Gia vị, nước chấm', 'Spices, sauces and condiments', 13),
  (14, 'beverage', 'XIV', 'Nước giải khát', 'Beverages', 14),
  (15, 'traditional', 'XV', 'Thức ăn truyền thống', 'Traditional dishes', 15)
ON CONFLICT (id) DO UPDATE SET name_vi = EXCLUDED.name_vi, name_en = EXCLUDED.name_en;

SELECT setval('ingredient_categories_id_seq', (SELECT MAX(id) FROM ingredient_categories));

INSERT INTO allergens (id, code, name_vi, description)
VALUES
  (1, 'seafood', 'Hải sản (Tôm, Cua, Mực, Cá)', 'Dị ứng các loại động vật thủy hải sản, giáp xác, nhuyễn thể'),
  (2, 'egg', 'Trứng', 'Trứng gia cầm và các chế phẩm từ trứng'),
  (3, 'dairy', 'Sữa & Chế phẩm từ sữa', 'Đường lactose hoặc protein trong sữa động vật (bò, dê)'),
  (4, 'peanut', 'Đậu phộng (Lạc)', 'Đậu phộng và dầu đậu phộng ép thô'),
  (5, 'tree_nut', 'Hạt cây (Hạt điều, Hạnh nhân, Óc chó)', 'Các loại hạt có vỏ cứng'),
  (6, 'soy', 'Đậu nành & Chế phẩm đậu nành', 'Đậu nành, đậu phụ, tương bần, xì dầu'),
  (7, 'gluten', 'Gluten (Lúa mì, Lúa mạch)', 'Protein gluten trong bột mì, bánh mì'),
  (8, 'sesame', 'Mè (Vừng)', 'Hạt mè, dầu mè')
ON CONFLICT (id) DO UPDATE SET name_vi = EXCLUDED.name_vi, description = EXCLUDED.description;

SELECT setval('allergens_id_seq', (SELECT MAX(id) FROM allergens));
