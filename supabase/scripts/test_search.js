async function testSearch() {
  const query = "thịt kho";
  const url = `https://bepxua.vn/wp-json/wp/v2/posts?search=${encodeURIComponent(query)}&per_page=5&_embed=1`;
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  console.log(`Results for "${query}": ${posts.length}`);
  for (const p of posts) {
    console.log(`- ${p.title.rendered} (${p.slug})`);
  }
}
testSearch();
