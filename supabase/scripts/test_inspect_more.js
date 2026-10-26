async function inspectSteps5and8() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=10";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  const p5 = posts[4]; // Bo kho
  console.log("=== Post 5 Headings ===");
  console.log([...p5.content.rendered.matchAll(/<h[234][^>]*>(.*?)<\/h[234]>/gi)].map(m => m[1]));
  console.log("Sample content near 'Cách làm' or 'Bước':");
  const m = p5.content.rendered.match(/(?:Cách Làm|Cách làm|Hướng dẫn)[\s\S]{0,1000}/i);
  if (m) console.log(m[0]);
}
inspectSteps5and8();
