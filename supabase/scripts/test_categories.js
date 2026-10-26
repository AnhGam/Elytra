async function checkCategories() {
  const url = "https://bepxua.vn/wp-json/wp/v2/categories?per_page=100";
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    const cats = await res.json();
    console.log("Categories found:", cats.length);
    for (const c of cats) {
      console.log(`[${c.id}] ${c.name} (${c.slug}) - ${c.count} recipes`);
    }
  } catch (e) {
    console.error(e);
  }
}
checkCategories();
