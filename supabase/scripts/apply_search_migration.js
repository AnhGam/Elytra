const fs = require('fs');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function applyMigration() {
  const sql = fs.readFileSync('d:/Antigravity/DA1/Elytra/supabase/migrations/20261005000009_create_recipe_search_function.sql', 'utf8');

  console.log('Applying search_recipes migration to Supabase...');
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

  // Test the function via RPC call: search vegetarian recipes excluding allergens
  console.log('\nTesting search_recipes RPC:');
  const testRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/search_recipes`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({
      p_query: 'gà',
      p_limit: 3
    })
  });

  const testData = await testRes.json();
  console.log(`Found ${testData.length} matching recipes for query 'gà':`);
  testData.forEach(r => {
    console.log(`- ${r.title} | ${r.calories_per_serving} kcal/srv | Video: ${r.video_url ? 'Yes' : 'No'} | Image: ${r.image_url.includes('supabase.co') ? 'Supabase Storage' : 'Other'}`);
  });
}

applyMigration().catch(console.error);
