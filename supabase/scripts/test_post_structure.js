async function inspectPostSteps() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=1";
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    const posts = await res.json();
    const p = posts[0];
    console.log("Full Content length:", p.content.rendered.length);
    console.log("--- Headings ---");
    const headings = [...p.content.rendered.matchAll(/<h[23][^>]*>(.*?)<\/h[23]>/g)].map(m => m[1]);
    console.log(headings);
    console.log("--- Sections ---");
    // print middle and end
    console.log(p.content.rendered.substring(1000, 3000));
  } catch (e) {
    console.error(e);
  }
}
inspectPostSteps();
