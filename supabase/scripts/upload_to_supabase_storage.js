const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function uploadImages() {
  const imagesDir = 'd:/Antigravity/DA1/Elytra/data/recipe_images';
  const files = fs.readdirSync(imagesDir).filter(f => f.endsWith('.jpg') || f.endsWith('.png') || f.endsWith('.webp'));
  console.log(`Found ${files.length} images to upload to Supabase Storage bucket 'recipe-images'...`);

  let successCount = 0;
  let failCount = 0;
  const urlMap = {};

  for (let i = 0; i < files.length; i++) {
    const filename = files[i];
    const filePath = path.join(imagesDir, filename);
    const fileBuffer = fs.readFileSync(filePath);

    // slug from filename
    const slug = path.parse(filename).name;

    console.log(`[${i + 1}/${files.length}] Uploading ${filename} (${(fileBuffer.length / 1024).toFixed(1)} KB)...`);

    try {
      const uploadRes = await fetch(`${SUPABASE_URL}/storage/v1/object/recipe-images/${filename}`, {
        method: 'POST',
        headers: {
          'apikey': ANON_KEY,
          'Authorization': `Bearer ${ANON_KEY}`,
          'Content-Type': 'image/jpeg',
          'x-upsert': 'true'
        },
        body: fileBuffer
      });

      if (!uploadRes.ok) {
        const errorText = await uploadRes.text();
        console.warn(`  Failed ${filename}: ${uploadRes.status} ${errorText}`);
        failCount++;
        continue;
      }

      const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/recipe-images/${filename}`;
      urlMap[slug] = publicUrl;
      console.log(`  Uploaded! Public URL: ${publicUrl}`);
      successCount++;
    } catch (err) {
      console.error(`  Error uploading ${filename}:`, err.message);
      failCount++;
    }
  }

  console.log('\n=======================================');
  console.log(`UPLOAD FINISHED: ${successCount} succeeded, ${failCount} failed.`);

  // Now update public.recipes table image_url
  if (successCount > 0) {
    console.log('\nUpdating public.recipes table image_url to Supabase Storage CDN URLs...');
    const statements = [];
    for (const [slug, storageUrl] of Object.entries(urlMap)) {
      statements.push(`UPDATE public.recipes SET image_url = '${storageUrl}' WHERE slug = '${slug}';`);
    }

    const updateSql = statements.join('\n');
    const updateRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`
      },
      body: JSON.stringify({ query: updateSql })
    });

    if (!updateRes.ok) {
      const err = await updateRes.text();
      console.error('Failed to update recipes image_url:', err);
    } else {
      console.log('Successfully updated image_url for all recipes in Supabase!');
    }

    // Also update local master json
    const masterPath = 'd:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json';
    const master = JSON.parse(fs.readFileSync(masterPath, 'utf8'));
    master.forEach(r => {
      if (urlMap[r.slug]) {
        r.image_url = urlMap[r.slug];
      }
    });
    fs.writeFileSync(masterPath, JSON.stringify(master, null, 2), 'utf8');
    console.log('Updated image_url in local master dataset as well.');
  }
}

uploadImages().catch(console.error);
