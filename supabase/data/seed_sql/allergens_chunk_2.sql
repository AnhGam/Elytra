INSERT INTO public.recipe_allergens (recipe_id, allergen_id) VALUES
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-tom-rang-nuoc-cot-dua-ngon-ba-chay'), 1),
  ((SELECT id FROM public.recipes WHERE slug = '-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me'), 8),
  ((SELECT id FROM public.recipes WHERE slug = '-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me'), 4),
  ((SELECT id FROM public.recipes WHERE slug = '-cong-thuc-sot-tron-hu-tieu-ga-dam-da-tron-la-ghien-lam-la-me'), 6),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-bo-luc-lac-khoai-tay-nhanh-gon-sieu-ngon'), 6),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-nau-sup-nui-ga-xe-dac-biet-thom-ngon-dinh-duong'), 7),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-oc-nuong-tieu-xanh-sieu-thom-ngon-kho-quen'), 1),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-oc-nuong-tieu-xanh-sieu-thom-ngon-kho-quen'), 6),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-com-chien-trung-toi-thom-mem-ngon-mieng'), 2),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-com-chien-trung-toi-thom-mem-ngon-mieng'), 6),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc'), 1),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc'), 8),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc'), 4),
  ((SELECT id FROM public.recipes WHERE slug = 'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc'), 8),
  ((SELECT id FROM public.recipes WHERE slug = 'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc'), 4),
  ((SELECT id FROM public.recipes WHERE slug = 'cach-nau-canh-chua-ca-dieu-hong-ngot-thanh-dam-da'), 1)
ON CONFLICT DO NOTHING;