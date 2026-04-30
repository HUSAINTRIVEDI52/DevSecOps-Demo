#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m'
};

const log = {
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  warn: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`)
};

async function runDependencyCheck() {
  console.log('\n');
  console.log(`${colors.blue}🔍 OWASP Dependency Check${colors.reset}`);
  console.log(`${colors.blue}===========================${colors.reset}`);
  console.log('\n');

  // Check if Docker is available
  try {
    execSync('docker --version', { stdio: 'pipe' });
    log.success('Docker is available');
  } catch (e) {
    log.error('Docker is not installed');
    log.info('Install Docker or use: npm audit');
    process.exit(1);
  }

  // Create reports directory
  const reportsDir = path.join(process.cwd(), 'reports');
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
    log.success('Created reports directory');
  }

  // Run Dependency Check
  log.info('Running OWASP Dependency Check...');
  console.log('');

  try {
    const cmd = `docker run --rm \\
      -v ${process.cwd()}:/src \\
      -v ${reportsDir}:/reports \\
      owasp/dependency-check:latest \\
      --scan /src \\
      --format JSON \\
      --format HTML \\
      --project "Vulnerable App" \\
      --out /reports \\
      --exclude node_modules \\
      --exclude .git \\
      --exclude .github \\
      --enableExperimental \\
      --enableRetired`;

    execSync(cmd, { stdio: 'inherit' });
    log.success('Dependency Check completed');
  } catch (e) {
    log.error(`Dependency Check failed: ${e.message}`);
    process.exit(1);
  }

  // Parse results
  const reportPath = path.join(reportsDir, 'dependency-check-report.json');
  if (fs.existsSync(reportPath)) {
    try {
      const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
      const dependencies = report.reportSchema?.dependencies || [];

      let criticalCount = 0;
      let highCount = 0;
      let mediumCount = 0;

      dependencies.forEach(dep => {
        if (dep.vulnerabilities) {
          dep.vulnerabilities.forEach(vuln => {
            if (vuln.severity === 'CRITICAL') criticalCount++;
            if (vuln.severity === 'HIGH') highCount++;
            if (vuln.severity === 'MEDIUM') mediumCount++;
          });
        }
      });

      console.log('\n');
      console.log(`${colors.blue}📊 Vulnerability Summary:${colors.reset}`);
      console.log(`   Critical: ${criticalCount}`);
      console.log(`   High: ${highCount}`);
      console.log(`   Medium: ${mediumCount}`);
      console.log(`   Total Dependencies: ${dependencies.length}`);
      console.log('\n');

      if (criticalCount > 0) {
        log.error(`Found ${criticalCount} critical vulnerabilities!`);
        process.exit(1);
      }

      if (highCount > 0) {
        log.warn(`Found ${highCount} high severity vulnerabilities`);
      }

      log.success('Dependency Check completed successfully');
      console.log(`\n📄 Reports generated in: ${reportsDir}`);
      console.log(`   - dependency-check-report.json`);
      console.log(`   - dependency-check-report.html\n`);
    } catch (e) {
      log.error(`Failed to parse report: ${e.message}`);
      process.exit(1);
    }
  } else {
    log.warn('Report file not found');
  }
}

runDependencyCheck().catch(err => {
  log.error(`Setup failed: ${err.message}`);
  process.exit(1);
});
