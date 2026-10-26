const fs = require('fs');
const path = require('path');

const SUPABASE_URL = "https://iwmnkygicqfesvbilmrw.supabase.co";
const ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ";

async function exportAllergens() {
  const headers = { 'apikey': ANON_KEY, 'Authorization': `Bearer ${ANON_KEY}` };
  
  const resAllergens = await fetch(`${SUPABASE_URL}/rest/v1/allergens?select=*`, { headers });
  const allergens = await resAllergens.json();
  
  const resIngrAllergens = await fetch(`${SUPABASE_URL}/rest/v1/ingredient_allergens?select=*&limit=1000`, { headers });
  const ingrAllergens = await resIngrAllergens.json();

  const outDir = path.join(__dirname, '../data');
  fs.writeFileSync(path.join(outDir, 'allergens.json'), JSON.stringify(allergens, null, 2), 'utf-8');
  fs.writeFileSync(path.join(outDir, 'ingredient_allergens.json'), JSON.stringify(ingrAllergens, null, 2), 'utf-8');
  console.log(`Saved ${allergens.length} allergens and ${ingrAllergens.length} ingredient allergen links.`);
}

exportAllergens().catch(console.error);
