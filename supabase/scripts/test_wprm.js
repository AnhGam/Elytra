async function inspectWprm() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?search=suon+non+rim+sa+ot";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  const p = posts[0];
  const wprmMatch = p.content.rendered.match(/<div[^>]+class="[^"]*wprm-recipe-container[^"]*"[\s\S]*?(?=<div class="wprm-recipe-template|$)/i);
  
  // Find all ingredients inside wprm
  const ingrs = [...p.content.rendered.matchAll(/<li[^>]+class="[^"]*wprm-recipe-ingredient[^"]*"[^>]*>([\s\S]*?)<\/li>/gi)];
  console.log(`Found ${ingrs.length} WPRM ingredients:`);
  for (let i = 0; i < ingrs.length; i++) {
    const raw = ingrs[i][1];
    const amount = raw.match(/wprm-recipe-ingredient-amount[^>]*>(.*?)<\/span>/i)?.[1] || "";
    const unit = raw.match(/wprm-recipe-ingredient-unit[^>]*>(.*?)<\/span>/i)?.[1] || "";
    const name = raw.match(/wprm-recipe-ingredient-name[^>]*>(.*?)<\/(?:span|a)>/i)?.[1] || "";
    const notes = raw.match(/wprm-recipe-ingredient-notes[^>]*>(.*?)<\/span>/i)?.[1] || "";
    console.log(`  [${i+1}] Amount: "${amount}", Unit: "${unit}", Name: "${name}", Notes: "${notes}"`);
  }

  // Find all instructions inside wprm
  const steps = [...p.content.rendered.matchAll(/<div[^>]+class="[^"]*wprm-recipe-instruction-text[^"]*"[^>]*>([\s\S]*?)<\/div>/gi)];
  console.log(`Found ${steps.length} WPRM instructions:`);
  steps.slice(0, 3).forEach((s, idx) => console.log(`  Step ${idx+1}: ${s[1].replace(/<[^>]+>/g, '').trim().substring(0, 80)}...`));
}
inspectWprm();
