const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function createBucket() {
  const sql = `
    INSERT INTO storage.buckets (id, name, public) 
    VALUES ('recipe-images', 'recipe-images', true)
    ON CONFLICT (id) DO UPDATE SET public = true;

    DROP POLICY IF EXISTS "Allow public select buckets" ON storage.buckets;
    CREATE POLICY "Allow public select buckets" ON storage.buckets FOR SELECT USING (true);

    DROP POLICY IF EXISTS "Public Access" ON storage.objects;
    CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'recipe-images');

    DROP POLICY IF EXISTS "Allow anon upload" ON storage.objects;
    CREATE POLICY "Allow anon upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'recipe-images');

    DROP POLICY IF EXISTS "Allow anon update" ON storage.objects;
    CREATE POLICY "Allow anon update" ON storage.objects FOR UPDATE USING (bucket_id = 'recipe-images');
  `;

  console.log('Creating storage bucket and RLS policies on Supabase...');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query: sql })
  });

  console.log('Status:', res.status);
  const text = await res.text();
  console.log('Result:', text || 'Success (204 No Content)');

  // Verify via storage API
  const checkRes = await fetch(`${SUPABASE_URL}/storage/v1/bucket`, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    }
  });
  const buckets = await checkRes.json();
  console.log('\nCurrent buckets in Supabase Storage:', buckets);
}

createBucket().catch(console.error);
