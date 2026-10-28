const fs = require('fs');

const data = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_crawled.json', 'utf8'));
console.log('Total crawled posts in file:', data.length);

let countWithVideo = 0;
data.forEach((p, idx) => {
  const content = (p.content && p.content.rendered) ? p.content.rendered : '';
  const ytMatch = content.match(/(?:youtube\.com\/(?:watch\?v=|embed\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/i);
  const iframeMatch = content.match(/<iframe[^>]+src=["']([^"']+)["']/i);
  const videoTagMatch = content.match(/<video[^>]*>([\s\S]*?)<\/video>/i);
  const mp4Match = content.match(/https?:\/\/[^\s"'<>]+\.mp4/i);

  if (ytMatch || iframeMatch || videoTagMatch || mp4Match) {
    countWithVideo++;
    console.log(`[${idx+1}] ${p.title ? p.title.rendered : p.slug}`);
    if (ytMatch) console.log('   -> YouTube:', ytMatch[0]);
    if (iframeMatch) console.log('   -> Iframe:', iframeMatch[1]);
    if (mp4Match) console.log('   -> MP4:', mp4Match[0]);
  }
});

console.log(`\n===> Total with video embeds detected: ${countWithVideo}/${data.length}`);
