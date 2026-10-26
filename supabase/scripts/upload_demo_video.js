const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function uploadDemoVideo() {
  const sampleVideoUrl = 'https://www.w3schools.com/html/mov_bbb.mp4';
  const targetDir = 'd:/Antigravity/DA1/Elytra/data/recipe_videos';

  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const localFile = path.join(targetDir, 'demo_recipe_guide.mp4');
  console.log(`Downloading sample MP4 from ${sampleVideoUrl}...`);

  const res = await fetch(sampleVideoUrl);
  if (!res.ok) {
    throw new Error(`Failed to download sample video: HTTP ${res.status}`);
  }

  const buffer = await res.arrayBuffer();
  fs.writeFileSync(localFile, Buffer.from(buffer));
  console.log(`Saved local video: ${localFile} (${(buffer.byteLength / (1024 * 1024)).toFixed(2)} MB)`);

  // Upload to Supabase Storage bucket 'recipe-videos'
  console.log('Uploading demo video to Supabase Storage bucket "recipe-videos"...');
  const uploadRes = await fetch(`${SUPABASE_URL}/storage/v1/object/recipe-videos/demo_recipe_guide.mp4`, {
    method: 'POST',
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
      'Content-Type': 'video/mp4',
      'x-upsert': 'true'
    },
    body: Buffer.from(buffer)
  });

  if (!uploadRes.ok) {
    const errText = await uploadRes.text();
    throw new Error(`Upload failed: ${uploadRes.status} ${errText}`);
  }

  const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/recipe-videos/demo_recipe_guide.mp4`;
  console.log(`Upload successful! Public Video CDN URL: ${publicUrl}`);

  // Test video head request to verify direct playback support
  const headRes = await fetch(publicUrl, { method: 'HEAD' });
  console.log('Video CDN HEAD status:', headRes.status);
  console.log('Content-Type:', headRes.headers.get('content-type'));
  console.log('Content-Length:', headRes.headers.get('content-length'), 'bytes');
}

uploadDemoVideo().catch(console.error);
