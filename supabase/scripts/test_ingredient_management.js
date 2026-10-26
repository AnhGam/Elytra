const SUPABASE_URL = process.env.SUPABASE_URL || 'https://iwmnkygicqfesvbilmrw.supabase.co';
// Lấy anon key: supabase projects api-keys (key công khai, nhưng không gắn cứng để gitleaks không báo)
const ANON_KEY = process.env.ANON_KEY;
if (!ANON_KEY) throw new Error('Thiếu biến môi trường ANON_KEY');

async function testIngredientRPCs() {
  console.log('Testing public.search_ingredients...');
  const searchRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/search_ingredients`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({
      p_query: 'bò',
      p_limit: 3
    })
  });

  console.log('Search status:', searchRes.status);
  const items = await searchRes.json();
  console.log(`Found ${items.length} items for "bò":`);
  items.forEach(i => {
    console.log(` - [${i.code}] ${i.name_vi} (${i.category_name}) | Calo: ${i.calories_per_100g} | Protein: ${i.protein_per_100g}g | Dị ứng:`, i.allergens);
  });

  if (items.length > 0) {
    const firstId = items[0].id;
    console.log(`\nTesting public.get_ingredient_details for ID: ${firstId}...`);
    const detailRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/get_ingredient_details`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`
      },
      body: JSON.stringify({
        p_ingredient_id: firstId
      })
    });

    console.log('Detail status:', detailRes.status);
    const detail = await detailRes.json();
    console.log('Detail result:', JSON.stringify(detail, null, 2));
  }
}

testIngredientRPCs().catch(console.error);
