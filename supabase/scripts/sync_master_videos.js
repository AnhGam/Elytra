const fs = require('fs');

const master = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', 'utf8'));
const audit = JSON.parse(fs.readFileSync('d:/Antigravity/DA1/Elytra/data/recipes_video_audit.json', 'utf8'));

const videoMap = {};
audit.withVideo.forEach(item => {
  videoMap[item.slug] = item.video_url;
});

const fallbackMap = {
  'dau-hu-nhoi-thit-sot-ca-chua': 'https://www.youtube.com/watch?v=sI9fF7v1R_E',
  'ca-nuc-kho-nuoc-mia-dam-da-ngot-thanh-an-com-hay-banh-mi-deu-cuon': 'https://www.youtube.com/watch?v=ZfH2N0x7a30',
  'cach-lam-mi-xao-bo-dam-da-soi-mi-dai-thit-bo-gion-beo': 'https://www.youtube.com/watch?v=8I_9K0f8d1c',
  'com-chien-thap-cam-toi-ngon-nhu-ngoai-tiem-cong-thuc-don-gian-ai-lam-cung-duoc': 'https://www.youtube.com/watch?v=2XVE_Snq8No',
  'cach-lam-ca-chim-kho-thom-dam-da-ca-mem-khong-tanh-hao-com-cuc': 'https://www.youtube.com/watch?v=wX-yQ8u_Z68',
  'ga-rang-muoi-gion-rum-thom-lung-cong-thuc-don-gian-ai-cung-lam-duoc': 'https://www.youtube.com/watch?v=kY0hE7kX_Z8',
  'cach-lam-muoi-tom-kho-campuchia-tai-nha-an-la-ghien-cham-gi-cung-cuon': 'https://www.youtube.com/watch?v=akcrTz2AJpk',
  'cach-xao-mien-mem-toi-ngon-dam-bao-khong-dinh': 'https://www.youtube.com/watch?v=A8-5L1sP-jI'
};

Object.assign(videoMap, fallbackMap);

let updated = 0;
master.forEach(r => {
  if (videoMap[r.slug]) {
    r.video_url = videoMap[r.slug];
    updated++;
  }
});

console.log(`Updated video_url in master JSON for ${updated}/${master.length} recipes.`);
fs.writeFileSync('d:/Antigravity/DA1/Elytra/data/vietnamese_recipes_master.json', JSON.stringify(master, null, 2), 'utf8');
console.log('Saved updated master dataset.');
