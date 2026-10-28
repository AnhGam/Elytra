const fs = require('fs');
const path = require('path');

async function downloadImages() {
  const master = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', 'utf8'));
  const targetDir = 'd:/Antigravity/DA1/Elytra/data/recipe_images';

  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  console.log(`Starting download of ${master.length} recipe images to ${targetDir}...`);

  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < master.length; i++) {
    const r = master[i];
    const ext = path.extname(new URL(r.image_url).pathname) || '.jpg';
    const filename = `${r.slug}${ext}`;
    const filePath = path.join(targetDir, filename);

    if (fs.existsSync(filePath) && fs.statSync(filePath).size > 1000) {
      console.log(`[${i + 1}/${master.length}] Exists: ${filename}`);
      successCount++;
      continue;
    }

    try {
      console.log(`[${i + 1}/${master.length}] Downloading: ${r.title} (${r.image_url})...`);
      const res = await fetch(r.image_url, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });

      if (!res.ok) {
        console.warn(`  Failed HTTP ${res.status} for ${r.slug}`);
        failCount++;
        continue;
      }

      const buffer = await res.arrayBuffer();
      fs.writeFileSync(filePath, Buffer.from(buffer));
      console.log(`  Saved: ${filename} (${(buffer.byteLength / 1024).toFixed(1)} KB)`);
      successCount++;
    } catch (err) {
      console.error(`  Error downloading ${r.slug}:`, err.message);
      failCount++;
    }
  }

  console.log('\n=======================================');
  console.log(`DOWNLOAD COMPLETE: ${successCount} succeeded, ${failCount} failed.`);
}

downloadImages().catch(console.error);
