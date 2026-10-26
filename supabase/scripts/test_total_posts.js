async function checkTotal() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=10";
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    console.log("X-WP-Total:", res.headers.get("x-wp-total"));
    console.log("X-WP-TotalPages:", res.headers.get("x-wp-totalpages"));
  } catch (e) {
    console.error(e);
  }
}
checkTotal();
