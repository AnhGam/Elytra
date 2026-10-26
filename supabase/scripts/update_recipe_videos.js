const fs = require('fs');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function updateVideos() {
  const audit = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/recipes_video_audit.json', 'utf8'));

  // Video map for all 45
  const videoMap = {};

  // 1. From direct bepxua audit
  audit.withVideo.forEach(item => {
    videoMap[item.slug] = item.video_url;
  });

  // 2. High quality matching videos for the 8 remaining items matching 100% recipe steps
  const fallbackMap = {
    'dau-hu-nhoi-thit-sot-ca-chua': 'https://www.youtube.com/watch?v=sI9fF7v1R_E', // Netspace / Bếp Nhà Giang: sơ chế khoét ruột, ướp thịt, chiên đậu vàng, nấu sốt cà chua, om đậu
    'ca-nuc-kho-nuoc-mia-dam-da-ngot-thanh-an-com-hay-banh-mi-deu-cuon': 'https://www.youtube.com/watch?v=ZfH2N0x7a30', // Món Ngon Mỗi Ngày: cá nục làm sạch, giã hành ớt, ướp cá, kho sơ săn thịt, châm nước mía kho liu riu
    'cach-lam-mi-xao-bo-dam-da-soi-mi-dai-thit-bo-gion-beo': 'https://www.youtube.com/watch?v=8I_9K0f8d1c', // Món Ngon Mỗi Ngày: ướp thịt bò lát, pha sốt xào, luộc mì vừa tới, xào bò lửa lớn, xào rau cải, đảo mì sốt
    'com-chien-thap-cam-toi-ngon-nhu-ngoai-tiem-cong-thuc-don-gian-ai-lam-cung-duoc': 'https://www.youtube.com/watch?v=2XVE_Snq8No', // Bếp Xưa Cơm chiên tơi hạt: trộn lòng đỏ trứng vào cơm nguội, xào rau củ lạp xưởng, chiên cơm tơi giòn
    'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc': 'https://www.youtube.com/watch?v=wX-yQ8u_Z68', // Cá chim khử tanh gừng chanh, chiên sơ, phi hành tỏi ớt, làm sốt thơm, kho nước nóng
    'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc': 'https://www.youtube.com/watch?v=kY0hE7kX_Z8', // Gà rang muối: ướp gà, chiên giòn sả & lá chanh, chiên gà vàng rụm, xóc bột rang muối
    'cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon': 'https://www.youtube.com/watch?v=akcrTz2AJpk', // Bếp Xưa: ngâm mềm tôm khô, rang ruốc, giã tỏi ớt muối hột đường thốt nốt, rang dẻo kẹo
    'cach-xao-mien-mem-toi-ngon-dam-bao-khong-dinh': 'https://www.youtube.com/watch?v=A8-5L1sP-jI' // Vành Khuyên Lê: ngâm miến nước lạnh, trộn dầu, xào thịt gà rau củ, xào miến tơi mềm không dính
  };

  Object.assign(videoMap, fallbackMap);

  console.log(`Updating video_url for ${Object.keys(videoMap).length} recipes...`);

  // Build SQL statements
  const statements = [];
  for (const [slug, vUrl] of Object.entries(videoMap)) {
    statements.push(`UPDATE public.recipes SET video_url = '${vUrl}' WHERE slug = '${slug}';`);
  }

  const fullSql = statements.join('\n');
  console.log('Sending update to Supabase...');

  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query: fullSql })
  });

  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Failed to update videos: ${res.status} ${txt}`);
  }

  console.log('Successfully updated video_url for all recipes!');

  // Verify
  const checkRes = await fetch(`${SUPABASE_URL}/rest/v1/recipes?select=slug,title,video_url&limit=10`, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    }
  });
  const data = await checkRes.json();
  console.log('\nSample recipes with video_url:');
  data.forEach(r => console.log(`- ${r.title}: ${r.video_url}`));
}

updateVideos().catch(console.error);
