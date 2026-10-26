async function inspectOlderPost() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?slug=cach-nau-canh-chua-ca-dieu-hong-ngot-thanh-dam-da";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  if (posts.length > 0) {
    const p = posts[0];
    console.log("=== Title:", p.title.rendered);
    console.log("=== Content ===");
    console.log(p.content.rendered.substring(0, 3000));
  } else {
    console.log("Not found by slug");
  }
}
inspectOlderPost();
