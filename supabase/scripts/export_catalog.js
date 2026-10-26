const fs = require('fs');
const path = require('path');

const SUPABASE_URL = "https://iwmnkygicqfesvbilmrw.supabase.co";
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ";

async function exportCatalog() {
  const url = `${SUPABASE_URL}/rest/v1/ingredients?select=id,code,name_vi,name_unaccented,category_id,calories_per_100g,protein_per_100g,fat_per_100g,carbs_per_100g,fiber_per_100g,sodium_mg,edible_portion_pct,density_g_per_ml&limit=1000`;
  
  const res = await fetch(url, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    }
  });

  if (!res.ok) {
    throw new Error(`Failed to fetch: ${res.status} ${await res.text()}`);
  }

  const data = await res.json();
  console.log(`Fetched ${data.length} ingredients from Supabase.`);

  const outDir = path.join(__dirname, '../data');
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }

  const outPath = path.join(outDir, 'ingredients_catalog.json');
  fs.writeFileSync(outPath, JSON.stringify(data, null, 2), 'utf-8');
  console.log(`Saved catalog to ${outPath}`);
}

exportCatalog().catch(console.error);
