const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://iwmnkygicqfesvbilmrw.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml3bW5reWdpY3FmZXN2YmlsbXJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExNzE2OTAsImV4cCI6MjEwNjc0NzY5MH0.9jQ9PzlPLg0fH9MGj-vnkPf6qxRB9Ahp2Qw2aNsRrbQ';

async function applyMigration() {
  const sqlFile = path.join(__dirname, '../supabase/migrations/20261005000011_create_ingredient_management_functions.sql');
  const sql = fs.readFileSync(sqlFile, 'utf8');

  console.log('Applying migration 11 to Supabase...');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_seed_sql`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    },
    body: JSON.stringify({ query: sql })
  });

  if (!res.ok) {
    const err = await res.text();
    console.error('Migration failed:', res.status, err);
  } else {
    console.log('Migration 11 successfully applied!');
  }
}

applyMigration().catch(console.error);
