# Vulnerable App - Project Summary

## 📋 Project Overview

This educational project demonstrates 10 critical security vulnerabilities commonly found in real-world applications. It includes:

- **Vulnerable App** (`server.js`) - Intentionally flawed implementation
- **Fixed App** (`server-fixed.js`) - Secure implementation with all fixes
- **Automated Tests** (`test-vulnerabilities.js`) - Demonstrates each vulnerability
- **Comprehensive Documentation** - Analysis, fixes, and best practices

## 🎯 Learning Objectives

After working through this project, you will understand:

1. **How vulnerabilities work** - Real exploitation techniques
2. **Why they're dangerous** - Business and security impact
3. **How to fix them** - Secure coding practices
4. **How to prevent them** - Defense-in-depth strategies
5. **How to test for them** - Security testing methodologies

## 📁 Project Structure

```
Vulnerable project/
├── package.json                 # Dependencies
├── server.js                    # Vulnerable app (10 flaws)
├── server-fixed.js              # Fixed/secure version
├── test-vulnerabilities.js      # Automated exploitation tests
├── README.md                    # Quick overview
├── QUICKSTART.md                # Getting started guide
├── SECURITY_ANALYSIS.md         # Detailed vulnerability analysis
├── COMPARISON.md                # Vulnerable vs Fixed comparison
└── .gitignore                   # Git ignore rules
```

## 🔓 Vulnerabilities Included

### Critical (CVSS 9+)
1. **Hardcoded API Key** - Secrets in source code
2. **SQL Injection** - String concatenation in queries
3. **Weak API Authentication** - Query string API keys
4. **Exposed Debug Endpoint** - Secrets in debug output

### High (CVSS 7-8)
5. **Insecure Direct Object Reference (IDOR)** - No authorization checks
6. **Prototype Pollution** - Vulnerable lodash version
7. **Sensitive Data Exposure** - Passwords in responses

### Medium (CVSS 5-6)
8. **Path Traversal** - No file path validation
9. **Missing CSRF Protection** - No state-change verification
10. **No Rate Limiting** - Brute force attacks possible

## 🚀 Quick Start

### Installation
```bash
cd "G:/Office/Vulnerable project"
npm install
```

### Run Vulnerable App
```bash
npm start
# Server runs on http://localhost:3000
```

### Run Tests
```bash
node test-vulnerabilities.js
```

### Run Fixed App
```bash
NODE_ENV=development API_KEY=test_key SECRET_TOKEN=test_secret node server-fixed.js
```

## 📊 Test Results

All 10 vulnerabilities have been successfully demonstrated:

```
✓ SQL Injection - Bypassed authentication
✓ Hardcoded API Key - Accessed admin endpoint
✓ IDOR - Accessed other user's data
✓ Prototype Pollution - Injected properties
✓ Weak Token - Generated predictable token
✓ Path Traversal - Accessed system files
✓ Debug Endpoint - Exposed all secrets
✓ No Rate Limiting - Unlimited requests
✓ Missing CSRF - Transferred money without token
✓ Sensitive Data - Password in response
```

## 📚 Documentation Files

### README.md
- Overview of all vulnerabilities
- Testing endpoints with curl examples
- Learning resources

### QUICKSTART.md
- Installation and setup instructions
- Manual testing guide
- Vulnerability severity table

### SECURITY_ANALYSIS.md
- Detailed analysis of each vulnerability
- Exploitation techniques
- Remediation code examples
- Best practices for each issue
- Remediation roadmap

### COMPARISON.md
- Side-by-side vulnerable vs fixed code
- Security improvements summary
- Production checklist

## 🔧 Key Features

### Vulnerable App (server.js)
- ❌ Hardcoded secrets
- ❌ No input validation
- ❌ String concatenation in SQL
- ❌ No authentication/authorization
- ❌ Sensitive data exposure
- ❌ No rate limiting
- ❌ Debug endpoints exposed
- ❌ Vulnerable dependencies

### Fixed App (server-fixed.js)
- ✅ Environment variables for secrets
- ✅ Comprehensive input validation
- ✅ Parameterized queries
- ✅ Authentication & authorization
- ✅ Secure password handling
- ✅ Rate limiting implemented
- ✅ Debug endpoints removed
- ✅ Security headers added
- ✅ Safe dependency usage
- ✅ CSRF protection

## 🧪 Testing Endpoints

### Vulnerable App
```bash
# SQL Injection
curl "http://localhost:3000/api/users/admin' OR '1'='1"

# Hardcoded API Key
curl "http://localhost:3000/api/admin/users?api_key=sk-1234567890abcdefghijklmnop"

# IDOR
curl http://localhost:3000/api/user/1

# Prototype Pollution
curl -X POST http://localhost:3000/api/config \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"isAdmin": true}}'

# Debug Endpoint
curl http://localhost:3000/api/debug

# No Rate Limiting
for i in {1..10}; do
  curl -X POST http://localhost:3000/api/password-reset \
    -H "Content-Type: application/json" \
    -d '{"email": "test@example.com"}'
done
```

## 🎓 Learning Path

### Beginner
1. Read README.md
2. Run the vulnerable app
3. Run automated tests
4. Observe the vulnerabilities

### Intermediate
1. Read SECURITY_ANALYSIS.md
2. Manually test each vulnerability
3. Understand the exploitation techniques
4. Review the fixes in COMPARISON.md

### Advanced
1. Study server-fixed.js implementation
2. Implement additional security measures
3. Add more test cases
4. Deploy to a test environment
5. Perform security testing

## 🛡️ Security Best Practices Demonstrated

### Authentication & Authorization
- Environment variables for secrets
- Authorization headers (not query strings)
- Role-based access control
- User ownership verification

### Input Validation
- Username format validation
- Email format validation
- Numeric input validation
- Filename path validation

### Data Protection
- Never expose passwords
- Secure token generation
- Password hashing (bcrypt)
- Sensitive data filtering

### API Security
- Rate limiting on sensitive endpoints
- CSRF protection
- Security headers
- Input sanitization

### Dependency Management
- Update vulnerable packages
- Use safe merge operations
- Audit dependencies regularly
- Pin exact versions

## 📖 References

### OWASP Resources
- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)

### Security Testing
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTheBox](https://www.hackthebox.com/)
- [TryHackMe](https://tryhackme.com/)

### Node.js Security
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [Express Security](https://expressjs.com/en/advanced/best-practice-security.html)
- [npm Security](https://docs.npmjs.com/cli/v8/commands/npm-audit)

## ⚠️ Disclaimer

**This application is for educational and authorized security testing only.**

- Do not use in production
- Do not test on systems you don't own
- Unauthorized access to computer systems is illegal
- Always obtain proper authorization before testing security

## 🤝 Contributing

To extend this project:

1. Add more vulnerabilities
2. Create additional test cases
3. Implement more security fixes
4. Add frontend examples
5. Create Docker setup
6. Add CI/CD security scanning

## 📝 License

Educational use only. See disclaimer above.

## 🎯 Next Steps

1. **Understand**: Read all documentation
2. **Explore**: Run tests and examine code
3. **Practice**: Manually exploit vulnerabilities
4. **Learn**: Study the fixes
5. **Apply**: Use these practices in your own code
6. **Share**: Teach others about security

---

**Created**: 2026-04-30
**Purpose**: Security Education & Awareness
**Status**: Complete with 10 vulnerabilities + fixes + tests + documentation
