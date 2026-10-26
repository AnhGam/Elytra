const fs = require('fs');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function applyEngine() {
  const sql = fs.readFileSync('d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000010_create_recipe_creation_engine.sql', 'utf8');

  console.log('Applying create_recipe_with_nutrition migration to Supabase...');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query: sql })
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Failed to apply migration: ${res.status} ${err}`);
  }

  console.log('Migration applied successfully!');

  // Test the function: create a custom community recipe
  // 1. Get an ingredient ID for beef:
  const beefRes = await fetch(`${SUPABASE_URL}/rest/v1/ingredients?name_vi=ilike.*thịt bò*&limit=1`, {
    headers: { 'apikey': ANON_KEY, 'Authorization': `Bearer ${ANON_KEY}` }
  });
  const beef = (await beefRes.json())[0];
  console.log('Sample ingredient found:', beef.name_vi, beef.id, beef.calories);

  // 2. Call create_recipe_with_nutrition RPC:
  console.log('\nTesting create_recipe_with_nutrition RPC...');
  const createRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/create_recipe_with_nutrition`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({
      p_title: 'Bò Xào Cần Tây Kiểm Thử Tự Động',
      p_description: 'Món ăn do người dùng tự tạo để kiểm thử động cơ tính dinh dưỡng',
      p_servings: 2,
      p_prep_time_minutes: 10,
      p_cook_time_minutes: 15,
      p_category: 'mon_xao',
      p_ingredients: [
        {
          ingredient_id: beef.id,
          ingredient_name_raw: 'Thịt bò phi lê',
          amount: 300,
          unit: 'g',
          amount_g: 300
        }
      ]
    })
  });

  const createdData = await createRes.json();
  console.log('Successfully created recipe with automated nutrition calculation:');
  console.log(JSON.stringify(createdData, null, 2));

  // Clean up test recipe
  await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'apikey': ANON_KEY, 'Authorization': `Bearer ${ANON_KEY}` },
    body: JSON.stringify({ query: `DELETE FROM public.recipes WHERE id = '${createdData.id}';` })
  });
  console.log('Cleaned up test recipe.');
}

applyEngine().catch(console.error);
