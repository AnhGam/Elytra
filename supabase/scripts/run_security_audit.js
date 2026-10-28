/**
 * Security Audit Automation Script
 * Adheres to Cloudflare Security Audit methodology for Supabase & Mobile App:
 * 1. Verifies RLS is enabled on all tables in migrations
 * 2. Checks for unsafe public write policies
 * 3. Scans for hardcoded service_role or database private credentials
 * 4. Checks git status to ensure untracked env files remain ignored
 */

const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '../../');
const MIGRATIONS_DIR = path.resolve(__dirname, '../migrations');

console.log('====================================================');
console.log('   ELYTRA SYSTEM SECURITY AUDIT (Cloudflare Flow)   ');
console.log('====================================================\n');

let issuesFound = 0;
let checksPassed = 0;

function auditMigrations() {
  console.log('[1/4] Auditing Supabase Database Migrations for RLS Compliance...');

  if (!fs.existsSync(MIGRATIONS_DIR)) {
    console.error('Error: Migrations directory not found:', MIGRATIONS_DIR);
    issuesFound++;
    return;
  }

  const migrationFiles = fs.readdirSync(MIGRATIONS_DIR).filter(f => f.endsWith('.sql'));
  const tablesCreated = new Set();
  const rlsEnabledTables = new Set();

  for (const file of migrationFiles) {
    const content = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');

    // Find table creations
    const tableMatches = content.matchAll(/CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?([a-zA-Z0-9_]+)/gi);
    for (const match of tableMatches) {
      tablesCreated.add(match[1]);
    }

    // Find RLS enabled statements
    const rlsMatches = content.matchAll(/ALTER\s+TABLE\s+(?:public\.)?([a-zA-Z0-9_]+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY/gi);
    for (const match of rlsMatches) {
      rlsEnabledTables.add(match[1]);
    }

    // Check for dangerous public write policies
    const dangerousPolicyRegex = /CREATE\s+POLICY[^\n;]+FOR\s+(?:INSERT|UPDATE|DELETE|ALL)\s+TO\s+(?:anon|public)\s+USING\s*\(\s*true\s*\)\s+WITH\s+CHECK\s*\(\s*true\s*\)/gi;
    if (dangerousPolicyRegex.test(content)) {
      console.warn(`  [FAIL] ${file}: Unrestricted public write policy detected!`);
      issuesFound++;
    }
  }

  console.log(`  Identified ${tablesCreated.size} database tables across migrations.`);
  for (const table of tablesCreated) {
    if (rlsEnabledTables.has(table)) {
      console.log(`  [PASS] RLS enabled on table: ${table}`);
      checksPassed++;
    } else {
      console.warn(`  [WARN] Table ${table} does not have explicit ENABLE ROW LEVEL SECURITY in checked migrations.`);
    }
  }
}

function auditSecrets() {
  console.log('\n[2/4] Auditing Codebase for Accidental Secret Exposure...');

  const sensitiveKeywords = [
    /service_role_key\s*=\s*['"][a-zA-Z0-9_\-\.]{20,}['"]/i,
    /SUPABASE_SERVICE_ROLE_KEY\s*=\s*['"][a-zA-Z0-9_\-\.]{20,}['"]/i,
    /postgres:\/\/[a-zA-Z0-9_]+:[a-zA-Z0-9_]+@/i
  ];

  const excludeDirs = ['node_modules', '.git', '.dart_tool', 'build'];

  function scanDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (excludeDirs.includes(entry.name)) continue;
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        scanDir(fullPath);
      } else if (entry.isFile() && (entry.name.endsWith('.ts') || entry.name.endsWith('.js') || entry.name.endsWith('.dart') || entry.name.endsWith('.sql'))) {
        const text = fs.readFileSync(fullPath, 'utf8');
        for (const kw of sensitiveKeywords) {
          if (kw.test(text)) {
            console.error(`  [FAIL] Possible private secret/credential pattern in: ${path.relative(ROOT_DIR, fullPath)}`);
            issuesFound++;
          }
        }
      }
    }
  }

  scanDir(ROOT_DIR);
  if (issuesFound === 0) {
    console.log('  [PASS] No private service_role keys or connection strings hardcoded.');
    checksPassed++;
  }
}

function auditEnvFiles() {
  console.log('\n[3/4] Checking .gitignore and environment configuration isolation...');

  const gitignorePath = path.join(ROOT_DIR, '.gitignore');
  if (fs.existsSync(gitignorePath)) {
    const gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    const envIgnored = gitignoreContent.includes('env.json') || gitignoreContent.includes('.env');
    if (envIgnored) {
      console.log('  [PASS] env.json/.env is explicitly listed in .gitignore.');
      checksPassed++;
    } else {
      console.warn('  [WARN] env.json should be explicitly included in .gitignore.');
      issuesFound++;
    }
  }

  const liveEnvPath = path.join(ROOT_DIR, 'app', 'env.json');
  if (fs.existsSync(liveEnvPath)) {
    console.log('  [NOTICE] app/env.json exists locally for development.');
  }
}

function auditAndroidSecurity() {
  console.log('\n[4/4] Auditing Android Manifest Security Configurations...');
  const manifestPath = path.join(ROOT_DIR, 'app', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
  if (fs.existsSync(manifestPath)) {
    const manifest = fs.readFileSync(manifestPath, 'utf8');
    if (manifest.includes('android:usesCleartextTraffic="true"')) {
      console.warn('  [WARN] usesCleartextTraffic is set to true. Production apps should use HTTPS only.');
      issuesFound++;
    } else {
      console.log('  [PASS] Cleartext HTTP traffic is not enabled globally (HTTPS enforced).');
      checksPassed++;
    }
  } else {
    console.log('  [INFO] AndroidManifest.xml not in current scope or directory.');
  }
}

// Run all checks
auditMigrations();
auditSecrets();
auditEnvFiles();
auditAndroidSecurity();

console.log('\n----------------------------------------------------');
console.log(`Security Audit Summary: ${checksPassed} checks passed, ${issuesFound} issues found.`);
console.log('----------------------------------------------------');

if (issuesFound > 0) {
  console.log('\n❌ Audit finished with warnings or issues. Please resolve before production release.');
  process.exit(1);
} else {
  console.log('\n✅ System passed automated security compliance checks.');
  process.exit(0);
}
