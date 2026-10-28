const fs = require('fs');

async function checkAll45() {
  const master = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', 'utf8'));
  console.log(`Checking all ${master.length} recipes for embedded video...`);

  const withVideo = [];
  const withoutVideo = [];

  for (let i = 0; i < master.length; i++) {
    const r = master[i];
    try {
      const res = await fetch(r.source_url, {
        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
      });
      if (!res.ok) {
        withoutVideo.push({ idx: i + 1, title: r.title, slug: r.slug, reason: `HTTP ${res.status}` });
        continue;
      }
      const html = await res.text();
      // Match youtube video ID (11 chars) in watch or embed
      const ytMatches = [...html.matchAll(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/gi)];
      const videoIds = [...new Set(ytMatches.map(m => m[1]))];

      if (videoIds.length > 0) {
        console.log(`[#${i + 1}] FOUND VIDEO: "${r.title}" -> https://www.youtube.com/watch?v=${videoIds[0]}`);
        withVideo.push({
          idx: i + 1,
          title: r.title,
          slug: r.slug,
          youtube_id: videoIds[0],
          video_url: `https://www.youtube.com/watch?v=${videoIds[0]}`
        });
      } else {
        withoutVideo.push({ idx: i + 1, title: r.title, slug: r.slug });
      }
    } catch (err) {
      withoutVideo.push({ idx: i + 1, title: r.title, slug: r.slug, reason: err.message });
    }
  }

  console.log('\n=======================================');
  console.log(`Total WITH embedded video: ${withVideo.length}/${master.length}`);
  console.log(`Total WITHOUT embedded video: ${withoutVideo.length}/${master.length}`);
  
  fs.writeFileSync('d:/Antigravity/DA1/Elytra/data/recipes_video_audit.json', JSON.stringify({ withVideo, withoutVideo }, null, 2), 'utf8');
  console.log('Saved audit to d:/Antigravity/DA1/Elytra/data/recipes_video_audit.json');
}

checkAll45().catch(console.error);
