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

const config = {
  containerName: 'sonarqube-vulnerable-app',
  port: 9000,
  dbPort: 5432,
  version: 'latest',
  projectKey: 'vulnerable-app',
  projectName: 'Vulnerable App',
  user: 'admin',
  pass: 'admin'
};

async function checkDocker() {
  try {
    execSync('docker --version', { stdio: 'pipe' });
    log.success('Docker is installed');
    return true;
  } catch (e) {
    log.error('Docker is not installed. Please install Docker first.');
    return false;
  }
}

function containerExists() {
  try {
    const output = execSync(`docker ps -a --format "{{.Names}}"`, { encoding: 'utf8' });
    return output.includes(config.containerName);
  } catch (e) {
    return false;
  }
}

function containerRunning() {
  try {
    const output = execSync(`docker ps --format "{{.Names}}"`, { encoding: 'utf8' });
    return output.includes(config.containerName);
  } catch (e) {
    return false;
  }
}

function startContainer() {
  log.info('Starting SonarQube container...');

  try {
    execSync(`docker run -d \\
      --name ${config.containerName} \\
      -p ${config.port}:9000 \\
      -p ${config.dbPort}:5432 \\
      -e SONAR_JDBC_URL=jdbc:postgresql://localhost:5432/sonarqube \\
      -e SONAR_JDBC_USERNAME=sonar \\
      -e SONAR_JDBC_PASSWORD=sonar \\
      -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLED=true \\
      -v sonarqube_data:/opt/sonarqube/data \\
      -v sonarqube_extensions:/opt/sonarqube/extensions \\
      -v sonarqube_logs:/opt/sonarqube/logs \\
      sonarqube:${config.version}`, { stdio: 'pipe' });

    log.success('SonarQube container started');
    return true;
  } catch (e) {
    log.error(`Failed to start container: ${e.message}`);
    return false;
  }
}

async function waitForSonarQube() {
  log.info('Waiting for SonarQube to be ready...');

  const maxAttempts = 60;
  let attempt = 0;

  while (attempt < maxAttempts) {
    try {
      const response = execSync(`curl -s http://localhost:${config.port}/api/system/health`, { encoding: 'utf8' });
      if (response.includes('"status":"UP"')) {
        log.success('SonarQube is ready');
        return true;
      }
    } catch (e) {
      // Still waiting
    }

    attempt++;
    console.log(`Attempt ${attempt}/${maxAttempts}...`);
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  log.error('SonarQube failed to start');
  return false;
}

function createProject() {
  log.info('Creating SonarQube project...');

  try {
    execSync(`curl -X POST "http://localhost:${config.port}/api/projects/create" \\
      -u ${config.user}:${config.pass} \\
      -d "project=${config.projectKey}&name=${config.projectName}"`, { stdio: 'pipe' });

    log.success('Project created');
    return true;
  } catch (e) {
    log.warn('Project may already exist');
    return true;
  }
}

function displayInfo() {
  console.log('\n');
  console.log(`${colors.green}✅ SonarQube Configuration Complete${colors.reset}`);
  console.log('\n');
  console.log(`${colors.blue}📊 SonarQube Dashboard:${colors.reset}`);
  console.log(`   URL: http://localhost:${config.port}`);
  console.log(`   Username: ${config.user}`);
  console.log(`   Password: ${config.pass}`);
  console.log('\n');
  console.log(`${colors.blue}🔑 Generate Authentication Token:${colors.reset}`);
  console.log(`   1. Go to http://localhost:${config.port}`);
  console.log(`   2. Login with ${config.user}/${config.pass}`);
  console.log(`   3. Click on your profile (top right)`);
  console.log(`   4. Select 'My Account' → 'Security'`);
  console.log(`   5. Generate a token`);
  console.log('\n');
  console.log(`${colors.blue}📝 Run SonarQube Scanner:${colors.reset}`);
  console.log(`   npm run sonar`);
  console.log('\n');
  console.log(`${colors.blue}🛑 Stop SonarQube:${colors.reset}`);
  console.log(`   docker stop ${config.containerName}`);
  console.log('\n');
  console.log(`${colors.blue}🗑️  Remove SonarQube:${colors.reset}`);
  console.log(`   docker rm ${config.containerName}`);
  console.log(`   docker volume rm sonarqube_data sonarqube_extensions sonarqube_logs`);
  console.log('\n');
}

async function main() {
  console.log('\n');
  console.log(`${colors.blue}🚀 SonarQube Local Setup${colors.reset}`);
  console.log(`${colors.blue}=======================${colors.reset}`);
  console.log('\n');

  // Check Docker
  if (!await checkDocker()) {
    process.exit(1);
  }

  // Check if container exists
  if (containerExists()) {
    log.warn('SonarQube container already exists');

    if (containerRunning()) {
      log.success(`SonarQube is running on http://localhost:${config.port}`);
      displayInfo();
      process.exit(0);
    } else {
      log.info('Starting existing container...');
      try {
        execSync(`docker start ${config.containerName}`, { stdio: 'pipe' });
        log.success('Container started');
      } catch (e) {
        log.error(`Failed to start container: ${e.message}`);
        process.exit(1);
      }
    }
  } else {
    // Start new container
    if (!startContainer()) {
      process.exit(1);
    }
  }

  // Wait for SonarQube
  if (!await waitForSonarQube()) {
    process.exit(1);
  }

  // Create project
  if (!createProject()) {
    process.exit(1);
  }

  // Display info
  displayInfo();
}

main().catch(err => {
  log.error(`Setup failed: ${err.message}`);
  process.exit(1);
});
