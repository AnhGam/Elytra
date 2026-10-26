async function inspectPage2() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=10&page=2";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  for (const p of posts) {
    const hasIngr = /nguyên liệu/i.test(p.content.rendered);
    const hasCachLam = /cách làm|hướng dẫn|thực hiện/i.test(p.content.rendered);
    const headings = [...p.content.rendered.matchAll(/<h[234][^>]*>(.*?)<\/h[234]>/gi)].map(m => m[1].replace(/<[^>]+>/g, '').trim());
    console.log(`- [${p.title.rendered}] | hasIngr: ${hasIngr} | hasCachLam: ${hasCachLam} | Headings (${headings.length}):`, headings.slice(0, 4));
  }
}
inspectPage2();
