async function inspect() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=5";
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    console.log("Status:", res.status);
    if (res.status === 200) {
      const posts = await res.json();
      console.log("Posts count:", posts.length);
      for (const p of posts) {
        console.log("Title:", p.title.rendered);
        console.log("Link:", p.link);
      }
    }
  } catch (e) {
    console.error(e);
  }
}
inspect();
