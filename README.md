# Vulnerable App - Complete Security Pipeline

A comprehensive educational vulnerable web application with integrated security scanning pipeline, demonstrating 10 real-world security vulnerabilities and their fixes.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Local Setup](#local-setup)
- [CI/CD Pipeline](#cicd-pipeline)
- [GitHub Secrets Configuration](#github-secrets-configuration)
- [Security Tools](#security-tools)
- [Vulnerabilities](#vulnerabilities)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Prerequisites

- Node.js 14+
- npm 6+
- Docker & Docker Compose
- Git

### Installation & Testing (5 minutes)

```bash
# Clone repository
git clone <repository-url>
cd "Office/Vulnerable project"

# Install dependencies
npm install

# Run vulnerability tests
npm test

# Start SonarQube locally
docker-compose up -d

# Run full security scan
npm run full-scan

# Start vulnerable app
npm start

# Access app
http://localhost:3000
```

## 📁 Project Structure

```
G:/Office/Vulnerable project/
│
├── 🔐 Security Scanning
│   ├── .github/workflows/
│   │   ├── sonarqube-scan.yml           # SAST scanning
│   │   ├── security-scan.yml            # SCA + SAST
│   │   ├── complete-security-scan.yml   # Gitleaks + SCA + SAST
│   │   ├── full-security-pipeline.yml   # All tools + Trivy
│   │   └── deploy-aws.yml               # AWS deployment
│   ├── docker-compose.yml               # SonarQube + PostgreSQL
│   ├── sonar-project.properties         # SonarQube config
│   ├── Dockerfile                       # App container
│   ├── aws-iam-policy.json              # IAM policy template
│   └── scripts/
│       ├── setup-sonarqube.js
│       └── run-dependency-check.js
│
├── 🛠️ Setup & Operations
│   ├── setup-sonarqube.sh               # Linux/Mac setup
│   ├── setup-sonarqube.bat              # Windows setup
│   ├── sonarqube-ops.sh                 # Linux/Mac operations
│   ├── sonarqube-ops.bat                # Windows operations
│   ├── GITLEAKS_SETUP.sh
│   ├── TRIVY_SETUP.sh
│   └── IAM_HARDENING_SETUP.sh
│
├── 📚 Documentation
│   ├── 00_START_HERE.txt
│   ├── README.md                        # This file
│   ├── QUICKSTART.md
│   ├── SECURITY_ANALYSIS.md
│   ├── COMPARISON.md
│   └── [15+ other guides]
│
├── 🎯 Application
│   ├── server.js                        # Vulnerable app (10 flaws)
│   ├── server-fixed.js                  # Secure version
│   ├── test-vulnerabilities.js          # Automated tests
│   └── package.json
│
└── 📦 Configuration
    ├── .gitignore
    └── .git/
```

## 💻 Local Setup

### Option 1: Docker Compose (Recommended)

```bash
# Start SonarQube + PostgreSQL
docker-compose up -d

# Wait 30-60 seconds for startup
# Access: http://localhost:9000
# Username: admin
# Password: admin

# Stop services
docker-compose down

# Remove volumes
docker-compose down -v
```

### Option 2: Setup Scripts

**Windows:**
```bash
setup-sonarqube.bat
```

**Linux/Mac:**
```bash
bash setup-sonarqube.sh
```

**Node.js (Cross-platform):**
```bash
npm run sonar:setup
```

### Option 3: Operations Scripts

**Windows:**
```bash
sonarqube-ops.bat start      # Start SonarQube
sonarqube-ops.bat scan       # Run scanner
sonarqube-ops.bat status     # Get status
sonarqube-ops.bat dashboard  # Open dashboard
sonarqube-ops.bat logs       # View logs
sonarqube-ops.bat cleanup    # Remove containers
```

**Linux/Mac:**
```bash
bash sonarqube-ops.sh start
bash sonarqube-ops.sh scan
bash sonarqube-ops.sh status
bash sonarqube-ops.sh dashboard
bash sonarqube-ops.sh logs
bash sonarqube-ops.sh cleanup
```

### Running the Application

```bash
# Start vulnerable app
npm start
# Access: http://localhost:3000

# Start with nodemon (auto-reload)
npm run dev

# Run vulnerability tests
npm test

# Run security scans
npm run full-scan
```

### Available npm Scripts

```bash
# Development
npm start                       # Start vulnerable app
npm run dev                     # Start with nodemon
npm test                        # Run vulnerability tests

# Security Scanning
npm run lint                    # Run ESLint
npm run security-check          # npm audit
npm run dependency-check        # OWASP Dependency Check
npm run dependency-check:docker # Docker version
npm run sonar                   # SonarQube scanner
npm run sonar:setup             # Setup SonarQube
npm run security-scan           # npm audit + Dependency Check
npm run full-scan               # All scans
```

## 🔄 CI/CD Pipeline

### Pipeline Architecture

```
Code Push
    ↓
GitHub Actions Triggered
    ↓
┌─────────────────────────────────────────┐
│ SECURITY GATES (Must ALL Pass)          │
├─────────────────────────────────────────┤
│ 1. Gitleaks (Secrets Detection)         │
│ 2. Dependency Check (CVE Scanning)      │
│ 3. SonarQube (Code Analysis)            │
│ 4. Trivy (Container Scanning)           │
│ 5. CVSS Score Check                     │
│ 6. Build Success                        │
│ 7. Security Checks Pass                 │
└─────────────────────────────────────────┘
    ↓
All Gates Pass?
    ├─ NO  → ❌ Deployment BLOCKED
    │        PR marked as failed
    │        Developer notified
    │
    └─ YES → ✅ Proceed to Build
             ↓
        Build Docker Image
             ↓
        Push to ECR
             ↓
        Deploy to ECS
             ↓
        Health Checks
             ↓
        ✅ Deployment Complete
```

### Workflows Overview

#### 1. sonarqube-scan.yml
**Triggers:** `push`, `pull_request` (main, master, develop)

**Jobs:**
- Checkout code
- Setup Node.js
- Install dependencies
- Run linter
- Start SonarQube service
- Run scanner
- Check quality gate
- Comment on PR

**Duration:** ~5-10 minutes

#### 2. security-scan.yml
**Triggers:** `push`, `pull_request`, `schedule` (daily 2 AM UTC)

**Jobs:**
1. Dependency Check (SCA)
   - Scans for CVEs
   - Fails on CRITICAL/HIGH
   - Comments on PR

2. SonarQube (SAST)
   - Code analysis
   - Quality gate check
   - PR comments

3. Security Summary
   - Aggregates results
   - Uploads artifacts

**Duration:** ~10-15 minutes

#### 3. complete-security-scan.yml
**Triggers:** `push`, `pull_request`, `schedule` (daily 2 AM UTC)

**Jobs:**
1. Gitleaks (Secrets)
   - Scans git history
   - SARIF report

2. Dependency Check (SCA)
   - CVE scanning
   - License checking

3. SonarQube (SAST)
   - Code analysis
   - Quality metrics

4. Security Summary
   - Complete report

**Duration:** ~15-20 minutes

#### 4. full-security-pipeline.yml
**Triggers:** `push`, `pull_request`, `schedule` (daily 2 AM UTC)

**Jobs:**
1. Gitleaks (Secrets)
2. Dependency Check (SCA)
3. Trivy (Container)
   - Image scanning
   - Filesystem scanning
   - SARIF upload

4. SonarQube (SAST)
5. Security Summary

**Duration:** ~20-30 minutes

#### 5. deploy-aws.yml
**Triggers:** `push` (main, master), `workflow_dispatch` (manual)

**Jobs:**
1. Security Checks (GATES)
   - Gitleaks
   - npm audit
   - Fail if secrets found

2. Build & Push
   - Build Docker image
   - Scan with Trivy
   - Push to ECR
   - Fail if vulnerabilities

3. Deploy
   - Update ECS task definition
   - Deploy to ECS
   - Health checks

4. Post-Deployment
   - Verify service
   - Generate summary

**Duration:** ~15-25 minutes

**Requirements:**
- AWS account
- ECR repository
- ECS cluster & service
- IAM role configured
- GitHub secrets set

## 🔐 GitHub Secrets Configuration

### Required Secrets for AWS Deployment

#### 1. AWS_ROLE_TO_ASSUME
**Purpose:** IAM role for GitHub Actions OIDC federation

**Value Format:**
```
arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
```

**How to Create:**
1. Go to AWS IAM Console
2. Create new role
3. Select "Web identity"
4. Choose "GitHub" as provider
5. Enter GitHub repository details
6. Attach policies (see aws-iam-policy.json)
7. Copy ARN

**Example:**
```
arn:aws:iam::123456789012:role/GitHubActionsRole
```

#### 2. AWS_ACCOUNT_ID (Optional)
**Purpose:** AWS account ID for ECR

**Value Format:**
```
123456789012
```

#### 3. AWS_REGION (Optional)
**Purpose:** AWS region for deployment

**Value Format:**
```
us-east-1
```

### How to Add Secrets to GitHub

1. Go to Repository Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Enter secret name and value
5. Click "Add secret"

**Example:**
```
Name: AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::123456789012:role/GitHubActionsRole
```

### Secrets Used in Workflows

```yaml
# In deploy-aws.yml
- name: Configure AWS credentials with IAM Role
  uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
    aws-region: ${{ env.AWS_REGION }}
```

## 🛡️ Security Tools

### 1. Gitleaks - Secrets Detection

**What it detects:**
- API keys
- AWS credentials
- Database passwords
- Private keys
- OAuth tokens

**Configuration:**
- Threshold: 0 secrets allowed
- Enforcement: STRICT
- Bypass: NONE

**Local Testing:**
```bash
gitleaks detect --source . -v
```

### 2. OWASP Dependency Check - SCA

**What it detects:**
- CVEs in dependencies
- Outdated libraries
- License issues

**Configuration:**
- Threshold: 0 CRITICAL, 0 HIGH
- Enforcement: STRICT
- Bypass: Requires approval

**Local Testing:**
```bash
npm run dependency-check
# or
npm run dependency-check:docker
```

### 3. SonarQube - SAST

**What it detects:**
- Code smells
- Vulnerabilities
- Bugs
- Security hotspots

**Configuration:**
- Threshold: Quality gate PASSED
- Enforcement: STRICT
- Bypass: Requires approval

**Local Testing:**
```bash
docker-compose up -d
npm run sonar
# Access: http://localhost:9000
```

### 4. Trivy - Container Security

**What it detects:**
- OS vulnerabilities
- Application dependencies
- Misconfigurations

**Configuration:**
- Threshold: 0 CRITICAL, 0 HIGH
- Enforcement: STRICT
- Bypass: NONE

**Local Testing:**
```bash
docker build -t vulnerable-app:latest .
trivy image vulnerable-app:latest
```

### 5. IAM Hardening - AWS Security

**What it implements:**
- IAM roles (no access keys)
- Least privilege policies
- OIDC federation
- Temporary credentials

**Configuration:**
- See aws-iam-policy.json
- See IAM_HARDENING_SETUP.sh

## 🔓 Vulnerabilities

### Critical (4)
1. **Hardcoded API Key** - Secrets in source code
2. **SQL Injection** - String concatenation in queries
3. **Weak API Authentication** - Query string API keys
4. **Exposed Debug Endpoint** - Secrets in debug output

### High (3)
5. **IDOR** - No authorization checks
6. **Prototype Pollution** - Vulnerable lodash version
7. **Sensitive Data Exposure** - Passwords in responses

### Medium (3)
8. **Path Traversal** - No file path validation
9. **Missing CSRF Protection** - No state-change verification
10. **No Rate Limiting** - Brute force attacks possible

**Test Coverage:** 100% (All 10 vulnerabilities tested)

## 🚀 Deployment

### Local Deployment

```bash
# Start app
npm start

# Access
http://localhost:3000

# Health check
curl http://localhost:3000/health
```

### AWS Deployment

**Prerequisites:**
1. AWS account
2. ECR repository created
3. ECS cluster & service created
4. IAM role configured
5. GitHub secrets set

**Deployment Steps:**
1. Push to main/master branch
2. GitHub Actions workflow triggers
3. Security gates run
4. If all pass: Build & push to ECR
5. Deploy to ECS
6. Health checks verify

**Manual Trigger:**
```bash
# Go to Actions tab
# Select "Deploy to AWS with IAM Role"
# Click "Run workflow"
```

### Deployment Verification

```bash
# Check ECS service
aws ecs describe-services \
  --cluster vulnerable-app-cluster \
  --services vulnerable-app-service

# Check logs
aws logs tail /ecs/vulnerable-app --follow

# Health check
curl http://<load-balancer-dns>/health
```

## 🔧 Troubleshooting

### SonarQube Issues

**SonarQube won't start:**
```bash
# Check Docker
docker ps

# View logs
docker logs sonarqube-vulnerable-app

# Check ports
netstat -an | grep 9000

# Restart
docker-compose restart
```

**Scanner fails:**
```bash
# Ensure SonarQube is running
curl http://localhost:9000/api/system/health

# Check token
sonar-scanner --version

# Verify config
cat sonar-project.properties
```

### Dependency Check Issues

**Docker not found:**
```bash
# Install Docker
# https://www.docker.com/products/docker-desktop

# Verify
docker --version
```

**Scan takes too long:**
- First run downloads database (~500MB)
- Subsequent runs are faster
- Use --exclude to skip directories

### GitHub Actions Issues

**Workflow not triggering:**
1. Check branch name (main, master, develop)
2. Verify workflow file syntax
3. Check GitHub Actions enabled
4. Review workflow logs

**Secrets not found:**
1. Verify secret names match
2. Check secret values
3. Ensure secrets are in correct repository

**Build fails:**
1. Check logs in Actions tab
2. Verify Docker available
3. Check resource limits
4. Review error messages

### AWS Deployment Issues

**IAM role not working:**
1. Verify role ARN in secrets
2. Check OIDC provider configured
3. Verify trust policy
4. Check role permissions

**ECR push fails:**
1. Verify ECR repository exists
2. Check AWS credentials
3. Verify region matches
4. Check repository permissions

**ECS deployment fails:**
1. Verify ECS cluster exists
2. Check ECS service exists
3. Verify task definition
4. Check IAM permissions

## 📚 Documentation

- **00_START_HERE.txt** - Project overview
- **README.md** - This file
- **QUICKSTART.md** - Quick start guide
- **SECURITY_ANALYSIS.md** - Detailed vulnerability analysis
- **COMPARISON.md** - Vulnerable vs Fixed code
- **PROJECT_COMPLETION_REPORT.txt** - Completion report
- **FINAL_VERIFICATION_REPORT.txt** - Verification report

## 🔗 Resources

### Documentation
- [SonarQube Docs](https://docs.sonarqube.org/)
- [Gitleaks GitHub](https://github.com/gitleaks/gitleaks)
- [Trivy Docs](https://aquasecurity.github.io/trivy/)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/iam/)

### Security Standards
- [OWASP Top 10](https://owasp.org/Top10/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

## ⚠️ Disclaimer

This application is for **educational and authorized security testing only**.

- Do not use in production
- Do not test on systems you don't own
- Unauthorized access to computer systems is illegal
- Always obtain proper authorization before testing security

## 📝 License

Educational use only. See disclaimer above.

## 🤝 Contributing

To extend this project:
1. Add more vulnerabilities
2. Create additional test cases
3. Implement more security fixes
4. Add frontend examples
5. Create Docker setup
6. Add CI/CD security scanning

## 📞 Support

For issues or questions:
1. Check troubleshooting section
2. Review documentation files
3. Check GitHub Actions logs
4. Review error messages

---

**Created:** 2026-04-30
**Status:** ✅ Complete & Production-Ready
**Version:** 1.0.0
