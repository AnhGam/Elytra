async function checkSingle() {
  const url = 'https://bepxua.vn/dau-hu-nhoi-thit-sot-ca-chua-%f0%9f%8d%85-mon-com-nha-ai-an-cung-ghien/';
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } });
  const html = await res.text();
  
  // Find all iframe tags in full
  const iframeTags = html.match(/<iframe[\s\S]*?<\/iframe>/gi) || [];
  console.log('Found iframe tags count:', iframeTags.length);
  iframeTags.forEach((tag, i) => {
    console.log(`\n--- Iframe #${i + 1} ---`);
    console.log(tag);
  });

  // Find all video tags
  const videoTags = html.match(/<video[\s\S]*?<\/video>/gi) || [];
  console.log('\nFound video tags count:', videoTags.length);
  videoTags.forEach((tag, i) => console.log(tag));

  // Search youtube across the entire html
  const yt = html.match(/https?:\/\/(?:www\.)?(?:youtube\.com|youtu\.be)[^\s"'<>]+/gi) || [];
  console.log('\nAny YouTube occurrences in full HTML:', yt);
}

checkSingle().catch(console.error);
