async function inspectRawR16() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?search=suon+non+kho+tieu";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  const p = posts[0];
  console.log("=== Title:", p.title.rendered);
  console.log("=== Content Headings ===");
  console.log([...p.content.rendered.matchAll(/<h[234][^>]*>(.*?)<\/h[234]>/gi)].map(m => m[1]));
  console.log("=== Sample under Nguyên liệu ===");
  const m = p.content.rendered.match(/(?:nguyên liệu|gia vị)[\s\S]{0,1000}/i);
  if (m) console.log(m[0]);
}
inspectRawR16();
