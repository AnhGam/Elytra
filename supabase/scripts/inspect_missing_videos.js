const fs = require('fs');

const master = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', 'utf8'));
const audit = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/recipes_video_audit.json', 'utf8'));

console.log('--- 8 RECIPES WITHOUT EMBEDDED VIDEO ---');
audit.withoutVideo.forEach(item => {
  const r = master.find(m => m.slug === item.slug);
  if (r) {
    console.log(`\n[ID ${item.idx}] "${r.title}" (slug: ${r.slug})`);
    console.log('Ingredients count:', r.ingredients.length);
    console.log('Steps count:', r.instructions.length);
    console.log('Steps:');
    r.instructions.forEach(s => console.log(`   - ${s.title || 'Bước ' + s.step_number}: ${s.description ? s.description.substring(0, 100) + '...' : ''}`));
  }
});
