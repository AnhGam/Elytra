async function testEmbed() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=3&_embed=1";
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    const posts = await res.json();
    for (const p of posts) {
      const img = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || null;
      console.log("Post:", p.title.rendered);
      console.log("Image:", img);
    }
  } catch (e) {
    console.error(e);
  }
}
testEmbed();
