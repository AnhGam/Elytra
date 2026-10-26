const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

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
