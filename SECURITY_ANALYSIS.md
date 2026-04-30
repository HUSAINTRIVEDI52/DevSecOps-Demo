# Security Analysis & Remediation Guide

## Executive Summary

This vulnerable app demonstrates 10 critical security flaws commonly found in production systems. All vulnerabilities have been successfully exploited in testing.

---

## Vulnerability Details & Fixes

### 1. Hardcoded API Key

**Severity**: 🔴 CRITICAL

**Location**: `server.js:8-9`

**Problem**:
```javascript
const API_KEY = 'sk-1234567890abcdefghijklmnop';
const SECRET_TOKEN = 'super_secret_admin_token_12345';
```

**Risks**:
- Exposed in version control history
- Visible in source code repositories
- Logged in error messages and monitoring systems
- Accessible to anyone with code access

**Exploitation**:
```bash
curl "http://localhost:3000/api/admin/users?api_key=sk-1234567890abcdefghijklmnop"
```

**Fix**:
```javascript
// Use environment variables
const API_KEY = process.env.API_KEY;
const SECRET_TOKEN = process.env.SECRET_TOKEN;

if (!API_KEY || !SECRET_TOKEN) {
  throw new Error('Missing required environment variables');
}
```

**Best Practices**:
- Use environment variables or secret management systems (AWS Secrets Manager, HashiCorp Vault)
- Never commit secrets to version control
- Rotate secrets regularly
- Use different keys for different environments
- Implement secret scanning in CI/CD pipelines

---

### 2. SQL Injection

**Severity**: 🔴 CRITICAL

**Location**: `server.js:56-62`

**Problem**:
```javascript
const query = `SELECT * FROM users WHERE username = '${username}'`;
db.get(query, (err, row) => { ... });
```

**Risks**:
- Complete database compromise
- Unauthorized data access
- Data manipulation or deletion
- Privilege escalation

**Exploitation**:
```bash
curl "http://localhost:3000/api/users/admin' OR '1'='1"
# Returns all users instead of just admin
```

**Fix**:
```javascript
// Use parameterized queries
const query = `SELECT * FROM users WHERE username = ?`;
db.get(query, [username], (err, row) => { ... });
```

**Best Practices**:
- Always use parameterized queries/prepared statements
- Never concatenate user input into SQL
- Use ORM frameworks (Sequelize, TypeORM)
- Implement input validation as defense-in-depth
- Use least privilege database accounts

---

### 3. Weak API Authentication

**Severity**: 🔴 CRITICAL

**Location**: `server.js:65-75`

**Problem**:
```javascript
const apiKey = req.query.api_key;
if (apiKey !== API_KEY) {
  return res.status(401).json({ error: 'Unauthorized' });
}
```

**Risks**:
- API key exposed in browser history
- Visible in server logs and referrer headers
- No rate limiting on authentication attempts
- Hardcoded comparison is predictable

**Exploitation**:
```bash
# Key visible in URL and logs
curl "http://localhost:3000/api/admin/users?api_key=sk-1234567890abcdefghijklmnop"
```

**Fix**:
```javascript
// Use Authorization header with Bearer token
const authHeader = req.headers.authorization;
const token = authHeader?.split(' ')[1];

if (!token || !verifyToken(token)) {
  return res.status(401).json({ error: 'Unauthorized' });
}

// Implement rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/admin/', limiter);
```

**Best Practices**:
- Use Authorization header (Bearer tokens, OAuth 2.0)
- Implement rate limiting on authentication endpoints
- Use strong, randomly generated tokens
- Implement token expiration
- Use HTTPS only
- Implement API key rotation

---

### 4. Insecure Direct Object Reference (IDOR)

**Severity**: 🟠 HIGH

**Location**: `server.js:78-87`

**Problem**:
```javascript
app.get('/api/user/:id', (req, res) => {
  const userId = req.params.id;
  // No authorization check
  db.get('SELECT * FROM users WHERE id = ?', [userId], (err, row) => {
    res.json(row || { error: 'User not found' });
  });
});
```

**Risks**:
- Any user can access any other user's data
- Privacy violation
- Unauthorized information disclosure

**Exploitation**:
```bash
curl http://localhost:3000/api/user/1  # Get admin data
curl http://localhost:3000/api/user/2  # Get other user data
```

**Fix**:
```javascript
app.get('/api/user/:id', (req, res) => {
  const userId = req.params.id;
  const requestingUserId = req.user.id; // From authentication
  
  // Verify user owns the resource
  if (userId !== requestingUserId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }
  
  db.get('SELECT * FROM users WHERE id = ?', [userId], (err, row) => {
    res.json(row || { error: 'User not found' });
  });
});
```

**Best Practices**:
- Always verify user authorization before returning data
- Use consistent authorization checks across all endpoints
- Implement role-based access control (RBAC)
- Log authorization failures
- Use UUIDs instead of sequential IDs when possible

---

### 5. Prototype Pollution

**Severity**: 🟠 HIGH

**Location**: `server.js:90-103`

**Problem**:
```javascript
const lodash = require('lodash'); // Version 3.10.1 (vulnerable)
const config = _.merge(defaultConfig, userConfig);
```

**Risks**:
- Arbitrary property injection
- Privilege escalation
- Application behavior manipulation
- Remote code execution in some contexts

**Exploitation**:
```bash
curl -X POST http://localhost:3000/api/config \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"isAdmin": true}}'
```

**Fix**:
```javascript
// Update lodash to latest version
// package.json: "lodash": "^4.17.21"

// Use safe merge operations
const config = Object.assign({}, defaultConfig, userConfig);

// Or use a whitelist approach
const allowedKeys = ['debug', 'timeout', 'maxRetries'];
const config = { ...defaultConfig };
Object.keys(userConfig).forEach(key => {
  if (allowedKeys.includes(key)) {
    config[key] = userConfig[key];
  }
});
```

**Best Practices**:
- Keep dependencies updated
- Use `npm audit` regularly
- Avoid merging untrusted objects into prototypes
- Use Object.create(null) for safe objects
- Implement dependency scanning in CI/CD

---

### 6. Sensitive Data Exposure

**Severity**: 🟠 HIGH

**Location**: `server.js:106-122`

**Problem**:
```javascript
app.post('/api/login', (req, res) => {
  // ...
  if (row && row.password === password) {
    res.json({
      message: 'Login successful',
      user: row,  // Returns password!
      token: Buffer.from(username).toString('base64') // Weak token
    });
  }
});
```

**Risks**:
- Passwords exposed in responses
- Weak token generation (base64 is not encryption)
- Credentials visible in logs and transit
- Token easily reversible

**Exploitation**:
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "password123"}'
# Response includes password and weak token
```

**Fix**:
```javascript
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  db.get('SELECT * FROM users WHERE username = ?', [username], async (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    
    if (!row) return res.status(401).json({ error: 'Invalid credentials' });
    
    // Compare hashed passwords
    const validPassword = await bcrypt.compare(password, row.password_hash);
    if (!validPassword) return res.status(401).json({ error: 'Invalid credentials' });
    
    // Generate secure JWT token
    const token = jwt.sign(
      { id: row.id, username: row.username },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    // Never return password
    const { password_hash, ...userWithoutPassword } = row;
    res.json({
      message: 'Login successful',
      user: userWithoutPassword,
      token: token
    });
  });
});
```

**Best Practices**:
- Hash passwords with bcrypt, scrypt, or Argon2
- Never return passwords in responses
- Use JWT or session tokens
- Implement token expiration
- Use HTTPS for all authentication
- Implement secure password reset flows

---

### 7. Path Traversal

**Severity**: 🟡 MEDIUM

**Location**: `server.js:125-133`

**Problem**:
```javascript
app.get('/api/file/:filename', (req, res) => {
  const filename = req.params.filename;
  const filepath = path.join(__dirname, 'uploads', filename);
  // No validation - ../../../etc/passwd would work
});
```

**Risks**:
- Access to files outside intended directory
- Information disclosure
- Potential code execution
- Configuration file exposure

**Exploitation**:
```bash
curl "http://localhost:3000/api/file/../../../etc/passwd"
```

**Fix**:
```javascript
const path = require('path');
const fs = require('fs');

app.get('/api/file/:filename', (req, res) => {
  const filename = req.params.filename;
  
  // Validate filename - no path separators
  if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
    return res.status(400).json({ error: 'Invalid filename' });
  }
  
  const filepath = path.join(__dirname, 'uploads', filename);
  const realpath = fs.realpathSync(filepath);
  const uploadsDir = fs.realpathSync(path.join(__dirname, 'uploads'));
  
  // Verify file is within uploads directory
  if (!realpath.startsWith(uploadsDir)) {
    return res.status(403).json({ error: 'Access denied' });
  }
  
  res.sendFile(filepath);
});
```

**Best Practices**:
- Validate and sanitize file paths
- Use whitelists for allowed files
- Verify resolved path is within intended directory
- Use fs.realpathSync() to resolve symlinks
- Implement proper file permissions
- Never serve files from user input directly

---

### 8. Exposed Debug Endpoint

**Severity**: 🔴 CRITICAL

**Location**: `server.js:136-145`

**Problem**:
```javascript
app.get('/api/debug', (req, res) => {
  res.json({
    apiKey: API_KEY,
    secretToken: SECRET_TOKEN,
    environment: process.env,
    nodeVersion: process.version,
    uptime: process.uptime()
  });
});
```

**Risks**:
- Complete system compromise
- All secrets exposed
- Environment variables leaked
- System information disclosed

**Exploitation**:
```bash
curl http://localhost:3000/api/debug
# Returns all secrets and environment variables
```

**Fix**:
```javascript
// Remove debug endpoint entirely in production
if (process.env.NODE_ENV !== 'production') {
  app.get('/api/debug', (req, res) => {
    // Only expose non-sensitive debug info
    res.json({
      nodeVersion: process.version,
      uptime: process.uptime(),
      memory: process.memoryUsage()
    });
  });
}
```

**Best Practices**:
- Never expose debug endpoints in production
- Use environment-based feature flags
- Implement proper logging instead
- Use monitoring tools (DataDog, New Relic)
- Implement access controls on debug endpoints
- Never log sensitive information

---

### 9. Missing CSRF Protection

**Severity**: 🟡 MEDIUM

**Location**: `server.js:148-157`

**Problem**:
```javascript
app.post('/api/transfer', (req, res) => {
  const { fromUser, toUser, amount } = req.body;
  // No CSRF token validation
  res.json({
    message: `Transferred $${amount} from ${fromUser} to ${toUser}`,
    status: 'success'
  });
});
```

**Risks**:
- Attacker can trick user into performing unwanted actions
- State-changing operations without verification
- Cross-site request forgery attacks

**Exploitation**:
```bash
# Attacker creates malicious website that makes this request
curl -X POST http://localhost:3000/api/transfer \
  -H "Content-Type: application/json" \
  -d '{"fromUser": "admin", "toUser": "attacker", "amount": 1000}'
```

**Fix**:
```javascript
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

app.use(cookieParser());
app.use(csrf({ cookie: true }));

// Generate CSRF token for forms
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Validate CSRF token on state-changing operations
app.post('/api/transfer', (req, res) => {
  // CSRF middleware validates token automatically
  const { fromUser, toUser, amount } = req.body;
  
  // Process transfer
  res.json({
    message: `Transferred $${amount} from ${fromUser} to ${toUser}`,
    status: 'success'
  });
});

// Also use SameSite cookies
app.use((req, res, next) => {
  res.setHeader('Set-Cookie', 'SameSite=Strict');
  next();
});
```

**Best Practices**:
- Implement CSRF tokens on all state-changing operations
- Use SameSite cookie attribute
- Validate origin and referer headers
- Use POST/PUT/DELETE for state changes (not GET)
- Implement double-submit cookie pattern

---

### 10. No Rate Limiting

**Severity**: 🟡 MEDIUM

**Location**: `server.js:160-169`

**Problem**:
```javascript
app.post('/api/password-reset', (req, res) => {
  const { email } = req.body;
  // No rate limiting - unlimited requests
  res.json({
    message: `Password reset link sent to ${email}`,
    resetToken: Math.random().toString(36).substring(7)
  });
});
```

**Risks**:
- Brute force attacks
- Account takeover
- Denial of service
- Weak token generation

**Exploitation**:
```bash
# Attacker can spam password reset requests
for i in {1..1000}; do
  curl -X POST http://localhost:3000/api/password-reset \
    -H "Content-Type: application/json" \
    -d '{"email": "victim@example.com"}'
done
```

**Fix**:
```javascript
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');

// Strict rate limiting for password reset
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // 3 requests per window
  message: 'Too many password reset attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req, res) => req.user?.role === 'admin' // Skip for admins
});

app.post('/api/password-reset', passwordResetLimiter, (req, res) => {
  const { email } = req.body;
  
  // Validate email
  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }
  
  // Generate secure token
  const resetToken = crypto.randomBytes(32).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
  
  // Store token hash with expiration (not plain token)
  storeResetToken(email, tokenHash, Date.now() + 3600000); // 1 hour
  
  res.json({
    message: 'Password reset link sent to email',
    // Don't return token to user
  });
});
```

**Best Practices**:
- Implement rate limiting on all sensitive endpoints
- Use exponential backoff for repeated failures
- Implement CAPTCHA for repeated attempts
- Log and monitor suspicious activity
- Use secure token generation (crypto.randomBytes)
- Implement token expiration

---

## Summary Table

| # | Vulnerability | CVSS | Fix Priority | Effort |
|---|---|---|---|---|
| 1 | Hardcoded Secrets | 9.8 | 1 | Low |
| 2 | SQL Injection | 9.9 | 1 | Medium |
| 3 | Weak Auth | 9.1 | 1 | Medium |
| 4 | IDOR | 7.5 | 2 | Low |
| 5 | Prototype Pollution | 8.1 | 2 | Low |
| 6 | Data Exposure | 7.5 | 2 | Medium |
| 7 | Path Traversal | 5.3 | 3 | Low |
| 8 | Debug Endpoint | 9.1 | 1 | Low |
| 9 | CSRF | 6.5 | 3 | Medium |
| 10 | No Rate Limit | 5.3 | 3 | Low |

---

## Remediation Roadmap

### Phase 1 (Critical - Week 1)
- [ ] Remove hardcoded secrets
- [ ] Fix SQL injection with parameterized queries
- [ ] Implement proper authentication
- [ ] Remove debug endpoint

### Phase 2 (High - Week 2)
- [ ] Add authorization checks (IDOR)
- [ ] Update vulnerable dependencies
- [ ] Implement secure password handling
- [ ] Add input validation

### Phase 3 (Medium - Week 3)
- [ ] Implement CSRF protection
- [ ] Add rate limiting
- [ ] Fix path traversal
- [ ] Add security headers

### Phase 4 (Ongoing)
- [ ] Security testing and code review
- [ ] Dependency updates and audits
- [ ] Incident response planning
- [ ] Security training

---

## References

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [CWE/SANS Top 25](https://cwe.mitre.org/top25/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
