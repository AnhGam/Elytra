const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function listFuncs() {
  const query = `
    SELECT routine_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    ORDER BY routine_name;
  `;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query })
  });

  const text = await res.text();
  console.log('Result:', text);
}

listFuncs().catch(console.error);
