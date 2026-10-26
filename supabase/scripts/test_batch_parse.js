function cleanHtml(s) {
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/&nbsp;/g, ' ')
    .trim();
}

function parseRecipe(html, rawTitle) {
  // 1. Clean Title
  const cleanTitle = rawTitle
    .replace(/&#8211;/g, '–')
    .replace(/&#8217;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/[\u{1F300}-\u{1F9FF}]/gu, '')
    .replace(/[\u{2600}-\u{26FF}]/gu, '')
    .replace(/[\u{2700}-\u{27BF}]/gu, '')
    .replace(/–\s*Món Cơm Nhà.*/i, '')
    .replace(/–\s*Ăn Cơm Hay Bánh Mì.*/i, '')
    .replace(/–\s*Công Thức Đơn Giản.*/i, '')
    .replace(/–\s*Đậm Đà Như Ngoài Tiệm.*/i, '')
    .replace(/–\s*Chuẩn Vị.*/i, '')
    .replace(/–\s*Thơm Ngon.*/i, '')
    .replace(/^Cách (?:Làm|Nấu)\s+/i, '')
    .trim();

  // 2. Ingredients
  const ingrSectionMatch = html.match(/<h2[^>]*>(?:🛒\s*)?Nguyên Liệu[\s\S]*?<\/h2>([\s\S]*?)(?=<h2[^>]*>(?:👩‍🍳\s*)?Cách Làm|$)/i);
  let ingredients = [];
  if (ingrSectionMatch) {
    const listItems = [...ingrSectionMatch[1].matchAll(/<li[^>]*>(.*?)<\/li>/gi)].map(m => cleanHtml(m[1]));
    for (const item of listItems) {
      if (item.length > 2 && !item.toLowerCase().startsWith('phần ') && !item.toLowerCase().endsWith(':')) {
        ingredients.push(item);
      }
    }
  }

  // 3. Instructions / Steps
  const stepsSectionMatch = html.match(/<h2[^>]*>(?:👩‍🍳\s*)?Cách Làm[\s\S]*?<\/h2>([\s\S]*?)(?=<h2[^>]*>(?:Bí Quyết|Thành Phẩm|Mẹo|Lưu Ý|Lời Kết)|$)/i);
  let steps = [];
  if (stepsSectionMatch) {
    const sHtml = stepsSectionMatch[1];
    
    // Check format A: <h3>Bước X...</h3><p>...</p>
    const h3Matches = [...sHtml.matchAll(/<h3[^>]*>(Bước \d+[^<]*)<\/h3>([\s\S]*?)(?=<h3|$)/gi)];
    if (h3Matches.length > 0) {
      for (const m of h3Matches) {
        steps.push({
          title: cleanHtml(m[1]),
          description: cleanHtml(m[2])
        });
      }
    } else {
      // Check format B: <p><strong>Bước X...</strong>...</p>
      const pMatches = [...sHtml.matchAll(/<p[^>]*><strong>(Bước \d+[^<:]*)[–:](.*?)<\/strong>([\s\S]*?)<\/p>/gi)];
      if (pMatches.length > 0) {
        for (const m of pMatches) {
          const stepTitle = cleanHtml(m[1]) + ": " + cleanHtml(m[2]);
          const stepDesc = cleanHtml(m[3]);
          steps.push({
            title: stepTitle,
            description: stepDesc
          });
        }
      } else {
        // Fallback: any <p><strong>Bước \d+...</strong>
        const fallbackMatches = [...sHtml.matchAll(/<p[^>]*><strong>(Bước \d+[^<]*)<\/strong>([\s\S]*?)<\/p>/gi)];
        for (const m of fallbackMatches) {
          steps.push({
            title: cleanHtml(m[1]),
            description: cleanHtml(m[2])
          });
        }
      }
    }
  }

  return { cleanTitle, ingredients, steps };
}

async function testBatch() {
  const url = "https://bepxua.vn/wp-json/wp/v2/posts?per_page=10&_embed=1";
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const posts = await res.json();
  
  for (let i = 0; i < posts.length; i++) {
    const p = posts[i];
    const { cleanTitle, ingredients, steps } = parseRecipe(p.content.rendered, p.title.rendered);
    console.log(`[${i+1}] ${cleanTitle} | Ingredients: ${ingredients.length} | Steps: ${steps.length}`);
  }
}

testBatch();
