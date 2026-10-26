const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function createVideoBucket() {
  const sql = `
    INSERT INTO storage.buckets (id, name, public) 
    VALUES ('recipe-videos', 'recipe-videos', true)
    ON CONFLICT (id) DO UPDATE SET public = true;

    DROP POLICY IF EXISTS "Public Access Videos" ON storage.objects;
    CREATE POLICY "Public Access Videos" ON storage.objects FOR SELECT USING (bucket_id = 'recipe-videos');

    DROP POLICY IF EXISTS "Allow anon upload videos" ON storage.objects;
    CREATE POLICY "Allow anon upload videos" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'recipe-videos');

    DROP POLICY IF EXISTS "Allow anon update videos" ON storage.objects;
    CREATE POLICY "Allow anon update videos" ON storage.objects FOR UPDATE USING (bucket_id = 'recipe-videos');
  `;

  console.log('Creating recipe-videos bucket on Supabase...');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query: sql })
  });

  console.log('SQL Status:', res.status);

  // Verify
  const checkRes = await fetch(`${SUPABASE_URL}/storage/v1/bucket`, {
    headers: { 'apikey': ANON_KEY, 'Authorization': `Bearer ${ANON_KEY}` }
  });
  const buckets = await checkRes.json();
  console.log('Current buckets in Supabase Storage:', buckets);
}

createVideoBucket().catch(console.error);
