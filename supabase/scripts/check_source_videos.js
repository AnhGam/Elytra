const fs = require('fs');

async function checkRecipeVideos() {
  const master = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', 'utf8'));
  console.log(`Checking ${master.length} recipes for video links...`);

  const results = [];

  for (let i = 0; i < Math.min(10, master.length); i++) {
    const r = master[i];
    console.log(`[${i + 1}/${master.length}] Checking: ${r.title} (${r.source_url})`);
    try {
      const res = await fetch(r.source_url, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });
      if (!res.ok) {
        console.log(`  Failed HTTP ${res.status}`);
        continue;
      }
      const html = await res.text();
      
      // Look for youtube, tiktok, facebook video, or native video
      const ytMatches = [...html.matchAll(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/gi)];
      const iframes = [...html.matchAll(/<iframe[^>]+src=["']([^"']+)["']/gi)];
      const videos = [...html.matchAll(/<video[^>]*>([\s\S]*?)<\/video>/gi)];
      const mp4s = [...html.matchAll(/https?:\/\/[^\s"'<>]+\.mp4/gi)];

      const foundYt = ytMatches.map(m => m[1]);
      const foundIframes = iframes.map(m => m[1]);
      const foundMp4 = mp4s.map(m => m[0]);

      console.log(`  YouTube IDs:`, foundYt);
      console.log(`  Iframes:`, foundIframes);
      console.log(`  MP4s:`, foundMp4);

      results.push({
        title: r.title,
        slug: r.slug,
        source_url: r.source_url,
        youtube: foundYt,
        iframes: foundIframes,
        mp4: foundMp4
      });
    } catch (err) {
      console.error(`  Error:`, err.message);
    }
  }

  console.log('\n=== Summary of first 10 recipes ===');
  console.log(JSON.stringify(results, null, 2));
}

checkRecipeVideos().catch(console.error);
