const fs = require('fs');

function cleanTitle(raw) {
  return raw
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/[\u{1F300}-\u{1F9FF}]/gu, '') // strip emojis
    .replace(/[\u{2600}-\u{26FF}]/gu, '')
    .replace(/[\u{2700}-\u{27BF}]/gu, '')
    .replace(/–\s*Món Cơm Nhà.*/i, '')
    .replace(/–\s*Ăn Cơm Hay Bánh Mì.*/i, '')
    .replace(/–\s*Công Thức Đơn Giản.*/i, '')
    .replace(/–\s*Đậm Đà Như Ngoài Tiệm.*/i, '')
    .replace(/–\s*Chuẩn Vị.*/i, '')
    .replace(/–\s*Thơm Ngon.*/i, '')
    .trim();
}

function parseRecipeHtml(html, title) {
  // 1. Extract ingredients section
  // Usually between "Nguyên liệu" and "Cách làm"
  const ingrRegex = /(?:🛒|Nguyên Liệu|Nguyên liệu)[\s\S]*?(?:👩‍🍳|Cách Làm|Cách làm|Hướng dẫn thực hiện)/i;
  const ingrMatch = html.match(ingrRegex);
  
  let rawIngredients = [];
  if (ingrMatch) {
    const listItems = [...ingrMatch[0].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => m[1]);
    for (let item of listItems) {
      // strip html tags and decode entities
      let text = item.replace(/<[^>]+>/g, '').replace(/&#8211;/g, '-').replace(/&nbsp;/g, ' ').trim();
      if (text.length > 0) {
        rawIngredients.push(text);
      }
    }
  }

  // 2. Extract steps / instructions
  const stepsRegex = /<h3[^>]*>(Bước \d+[^<]*)<\/h3>([\s\S]*?)(?=<h3|<h2|$)/gi;
  let steps = [];
  let stepMatch;
  while ((stepMatch = stepsRegex.exec(html)) !== null) {
    const stepTitle = stepMatch[1].replace(/<[^>]+>/g, '').trim();
    const stepBody = stepMatch[2]
      .replace(/<p[^>]*>/gi, '')
      .replace(/<\/p>/gi, '\n')
      .replace(/<[^>]+>/g, '')
      .replace(/&#8211;/g, '-')
      .replace(/&nbsp;/g, ' ')
      .trim();
    if (stepBody) {
      steps.push({
        title: stepTitle,
        description: stepBody
      });
    }
  }

  return {
    rawIngredients,
    steps
  };
}

async function run() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=5&_embed=1";
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' }
  });
  const posts = await res.json();
  
  for (const p of posts) {
    const title = cleanTitle(p.title.rendered);
    const parsed = parseRecipeHtml(p.content.rendered, title);
    const img = p._embedded?.['wp:featuredmedia']?.[0]?.source_url || null;
    
    console.log(`\n========================================`);
    console.log(`TITLE: ${title}`);
    console.log(`SLUG: ${p.slug}`);
    console.log(`IMAGE: ${img}`);
    console.log(`INGREDIENTS (${parsed.rawIngredients.length}):`, parsed.rawIngredients.slice(0, 5));
    console.log(`STEPS COUNT: ${parsed.steps.length}`);
    if (parsed.steps.length > 0) {
      console.log(`Step 1: ${parsed.steps[0].title} -> ${parsed.steps[0].description.substring(0, 80)}...`);
    }
  }
}

run().catch(console.error);
