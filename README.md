# Vulnerable App - Educational Security Testing

This is an intentionally vulnerable Node.js application designed for security testing and educational purposes.

## ⚠️ WARNING
**DO NOT use this in production or on any system you don't own.** This app contains multiple critical security vulnerabilities.

## Vulnerabilities Included

### 1. **Hardcoded API Key** (Secrets Management)
- **Location**: `server.js` line 8-9
- **Issue**: API keys and tokens hardcoded in source code
- **Risk**: Exposed in version control, logs, and error messages
- **Fix**: Use environment variables or secret management systems

### 2. **SQL Injection** (Input Validation)
- **Location**: `/api/users/:username` endpoint
- **Issue**: User input directly concatenated into SQL query
- **Payload**: `admin' OR '1'='1`
- **Risk**: Unauthorized data access, data manipulation, database compromise
- **Fix**: Use parameterized queries

### 3. **Weak API Authentication** (Authentication)
- **Location**: `/api/admin/users` endpoint
- **Issue**: API key passed in query string, hardcoded comparison
- **Risk**: Exposed in browser history, logs, referrer headers
- **Fix**: Use Authorization header, implement proper authentication

### 4. **Insecure Direct Object Reference (IDOR)** (Authorization)
- **Location**: `/api/user/:id` endpoint
- **Issue**: No authorization check on user data access
- **Risk**: Any user can access any other user's data
- **Fix**: Verify user owns the resource before returning data

### 5. **Prototype Pollution** (Vulnerable Dependency)
- **Location**: `/api/config` endpoint
- **Issue**: Using lodash 3.10.1 (vulnerable version) with unsafe merge
- **Payload**: `{"__proto__": {"isAdmin": true}}`
- **Risk**: Arbitrary property injection, privilege escalation
- **Fix**: Update lodash, use safe merge operations

### 6. **Missing CSRF Protection** (CSRF)
- **Location**: `/api/transfer` endpoint
- **Issue**: No CSRF token validation on state-changing operations
- **Risk**: Attacker can trick user into performing unwanted actions
- **Fix**: Implement CSRF tokens, SameSite cookies

### 7. **Sensitive Data Exposure** (Data Protection)
- **Location**: `/api/login` endpoint
- **Issue**: Passwords returned in response, weak token generation
- **Risk**: Credentials exposed in transit and logs
- **Fix**: Hash passwords, use secure token generation

### 8. **Path Traversal** (Input Validation)
- **Location**: `/api/file/:filename` endpoint
- **Issue**: No validation on file path, allows `../` sequences
- **Payload**: `../../../etc/passwd`
- **Risk**: Access to files outside intended directory
- **Fix**: Validate and sanitize file paths

### 9. **Exposed Debug Endpoint** (Information Disclosure)
- **Location**: `/api/debug` endpoint
- **Issue**: Exposes API keys, tokens, environment variables
- **Risk**: Complete system compromise
- **Fix**: Remove debug endpoints in production

### 10. **No Rate Limiting** (Brute Force)
- **Location**: `/api/password-reset` endpoint
- **Issue**: No rate limiting on password reset attempts
- **Risk**: Brute force attacks, account takeover
- **Fix**: Implement rate limiting, CAPTCHA

## Setup

```bash
npm install
npm start
```

Server runs on `http://localhost:3000`

## Testing Endpoints

### Health Check
```bash
curl http://localhost:3000/health
```

### SQL Injection Test
```bash
curl "http://localhost:3000/api/users/admin' OR '1'='1"
```

### Hardcoded API Key Exposure
```bash
curl "http://localhost:3000/api/admin/users?api_key=sk-1234567890abcdefghijklmnop"
```

### IDOR Test
```bash
curl http://localhost:3000/api/user/1
curl http://localhost:3000/api/user/2
```

### Prototype Pollution Test
```bash
curl -X POST http://localhost:3000/api/config \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"isAdmin": true}}'
```

### Debug Endpoint
```bash
curl http://localhost:3000/api/debug
```

### Weak Token Test
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password123"}'
```

## Learning Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)

## Disclaimer

This application is for **educational and authorized security testing only**. Unauthorized access to computer systems is illegal.
