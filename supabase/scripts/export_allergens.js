const fs = require('fs');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL;
// Lấy anon key: supabase projects api-keys (key công khai, nhưng không gắn cứng để gitleaks không báo)
const ANON_KEY = process.env.ANON_KEY;
if (!SUPABASE_URL || !ANON_KEY) throw new Error('Thiếu biến môi trường SUPABASE_URL hoặc ANON_KEY');

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
