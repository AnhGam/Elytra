async function test() {
  const urls = [
    "https://vnexpress.net/du-lich/am-thuc",
    "https://bepxua.vn/",
    "https://monngonmoingay.com/",
    "https://cookpad.com/vn"
  ];
  for (const url of urls) {
    try {
      const res = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7'
        }
      });
      console.log(url, "=> Status:", res.status);
    } catch (e) {
      console.log(url, "=> Error:", e.message);
    }
  }
}
test();
