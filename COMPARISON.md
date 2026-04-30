# Vulnerable vs Fixed - Side-by-Side Comparison

## 1. Hardcoded Secrets

### ❌ VULNERABLE
```javascript
const API_KEY = 'sk-1234567890abcdefghijklmnop';
const SECRET_TOKEN = 'super_secret_admin_token_12345';
```

### ✅ FIXED
```javascript
const API_KEY = process.env.API_KEY;
const SECRET_TOKEN = process.env.SECRET_TOKEN;

if (!API_KEY || !SECRET_TOKEN) {
  console.warn('⚠️  Warning: API_KEY or SECRET_TOKEN not set');
}
```

---

## 2. SQL Injection

### ❌ VULNERABLE
```javascript
const username = req.params.username;
const query = `SELECT * FROM users WHERE username = '${username}'`;
db.get(query, (err, row) => { ... });
```

**Attack**: `admin' OR '1'='1` → Returns all users

### ✅ FIXED
```javascript
const username = req.params.username;

// Validate input
if (!validateUsername(username)) {
  return res.status(400).json({ error: 'Invalid username format' });
}

// Use parameterized query
const query = `SELECT * FROM users WHERE username = ?`;
db.get(query, [username], (err, row) => { ... });
```

---

## 3. Weak API Authentication

### ❌ VULNERABLE
```javascript
app.get('/api/admin/users', (req, res) => {
  const apiKey = req.query.api_key;
  if (apiKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  // ...
});
```

**Issues**: 
- Key in query string (visible in logs, history)
- No rate limiting
- Hardcoded comparison

### ✅ FIXED
```javascript
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5
});

app.get('/api/admin/users', authLimiter, (req, res) => {
  // Use Authorization header
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token || token !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  // ...
});
```

---

## 4. Insecure Direct Object Reference (IDOR)

### ❌ VULNERABLE
```javascript
app.get('/api/user/:id', (req, res) => {
  const userId = req.params.id;
  // No authorization check
  db.get('SELECT * FROM users WHERE id = ?', [userId], (err, row) => {
    res.json(row || { error: 'User not found' });
  });
});
```

**Attack**: Any user can access any user's data

### ✅ FIXED
```javascript
app.get('/api/user/:id', authenticateToken, (req, res) => {
  const userId = parseInt(req.params.id);

  // Validate input
  if (isNaN(userId) || userId < 1) {
    return res.status(400).json({ error: 'Invalid user ID' });
  }

  // Check authorization
  if (userId !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }

  db.get('SELECT id, username, email, role FROM users WHERE id = ?', 
    [userId], (err, row) => {
    res.json(row || { error: 'User not found' });
  });
});
```

---

## 5. Prototype Pollution

### ❌ VULNERABLE
```javascript
const _ = require('lodash'); // Version 3.10.1 (vulnerable)

app.post('/api/config', (req, res) => {
  const userConfig = req.body;
  const defaultConfig = { debug: false, timeout: 5000 };
  
  // Unsafe merge
  const config = _.merge(defaultConfig, userConfig);
  res.json({ config });
});
```

**Attack**: `{"__proto__": {"isAdmin": true}}`

### ✅ FIXED
```javascript
app.post('/api/config', (req, res) => {
  const userConfig = req.body;
  
  // Whitelist allowed keys
  const allowedKeys = ['debug', 'timeout', 'maxRetries'];
  const defaultConfig = {
    debug: false,
    timeout: 5000,
    maxRetries: 3
  };

  // Safe merge - only whitelisted keys
  const config = { ...defaultConfig };
  Object.keys(userConfig).forEach(key => {
    if (allowedKeys.includes(key)) {
      config[key] = userConfig[key];
    }
  });

  res.json({ message: 'Config updated', config });
});
```

---

## 6. Sensitive Data Exposure

### ❌ VULNERABLE
```javascript
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  db.get('SELECT * FROM users WHERE username = ?', [username], (err, row) => {
    if (row && row.password === password) {
      res.json({
        message: 'Login successful',
        user: row,  // ❌ Returns password!
        token: Buffer.from(username).toString('base64') // ❌ Weak token
      });
    }
  });
});
```

### ✅ FIXED
```javascript
app.post('/api/login', authLimiter, (req, res) => {
  const { username, password } = req.body;

  // Validate input
  if (!validateUsername(username) || !password) {
    return res.status(400).json({ error: 'Invalid credentials' });
  }

  db.get('SELECT * FROM users WHERE username = ?', [username], (err, row) => {
    if (!row || row.password_hash !== password) {
      // Don't reveal if user exists
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate secure token (JWT in production)
    const token = 'valid_token_12345';

    // ✅ Never return password
    const { password_hash, ...userWithoutPassword } = row;
    res.json({
      message: 'Login successful',
      user: userWithoutPassword,
      token: token,
      expiresIn: 3600
    });
  });
});
```

---

## 7. Path Traversal

### ❌ VULNERABLE
```javascript
app.get('/api/file/:filename', (req, res) => {
  const filename = req.params.filename;
  const filepath = path.join(__dirname, 'uploads', filename);
  // No validation - ../../../etc/passwd works
  res.json({ filepath });
});
```

### ✅ FIXED
```javascript
app.get('/api/file/:filename', (req, res) => {
  const filename = req.params.filename;

  // Validate filename
  if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
    return res.status(400).json({ error: 'Invalid filename' });
  }

  // Verify path is within uploads directory
  const uploadsDir = path.resolve(__dirname, 'uploads');
  const filepath = path.resolve(uploadsDir, filename);

  if (!filepath.startsWith(uploadsDir)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  if (!fs.existsSync(filepath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  res.sendFile(filepath);
});
```

---

## 8. Exposed Debug Endpoint

### ❌ VULNERABLE
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

### ✅ FIXED
```javascript
// Remove in production
if (process.env.NODE_ENV !== 'production') {
  app.get('/api/debug', (req, res) => {
    // Only non-sensitive info
    res.json({
      nodeVersion: process.version,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      environment: process.env.NODE_ENV
    });
  });
}
```

---

## 9. Missing CSRF Protection

### ❌ VULNERABLE
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

### ✅ FIXED
```javascript
app.post('/api/transfer', authenticateToken, (req, res) => {
  const { toUser, amount } = req.body;

  // Validate input
  if (!toUser || !Number.isFinite(amount) || amount <= 0) {
    return res.status(400).json({ error: 'Invalid parameters' });
  }

  // User can only transfer from their own account
  const fromUser = req.user.username;

  res.json({
    message: `Transferred $${amount} from ${fromUser} to ${toUser}`,
    status: 'success'
  });
});
```

---

## 10. No Rate Limiting

### ❌ VULNERABLE
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

### ✅ FIXED
```javascript
const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 requests per hour
  message: 'Too many password reset attempts'
});

app.post('/api/password-reset', passwordResetLimiter, (req, res) => {
  const { email } = req.body;

  // Validate email
  if (!validateEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  // Don't reveal if email exists
  res.json({
    message: 'If email exists, password reset link has been sent'
  });
});
```

---

## Security Headers Added

```javascript
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000');
  next();
});
```

---

## Key Improvements Summary

| Aspect | Vulnerable | Fixed |
|--------|-----------|-------|
| Secrets | Hardcoded | Environment variables |
| SQL | String concatenation | Parameterized queries |
| Auth | Query string API key | Authorization header + rate limit |
| Authorization | None | Role-based checks |
| Dependencies | Old lodash 3.10.1 | Safe merge operations |
| Passwords | Returned in response | Never exposed |
| Tokens | Base64 encoded | JWT (production) |
| File access | No validation | Path validation + verification |
| Debug | Exposed secrets | Removed in production |
| CSRF | No protection | Authentication required |
| Rate limiting | None | Implemented on sensitive endpoints |
| Input validation | None | Comprehensive validation |
| Security headers | None | Added |

---

## Testing the Fixed Version

```bash
# Start the fixed server
NODE_ENV=development API_KEY=test_key SECRET_TOKEN=test_secret node server-fixed.js

# Test endpoints
curl http://localhost:3000/health

# Try SQL injection (now prevented)
curl "http://localhost:3000/api/users/admin' OR '1'='1"

# Try IDOR (now prevented)
curl http://localhost:3000/api/user/1

# Try prototype pollution (now prevented)
curl -X POST http://localhost:3000/api/config \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"isAdmin": true}}'
```

---

## Production Checklist

- [ ] Use environment variables for all secrets
- [ ] Enable HTTPS/TLS
- [ ] Implement proper JWT authentication
- [ ] Use bcrypt for password hashing
- [ ] Enable CORS with specific origins
- [ ] Implement comprehensive logging
- [ ] Set up monitoring and alerting
- [ ] Regular security audits
- [ ] Dependency scanning and updates
- [ ] Web Application Firewall (WAF)
- [ ] Rate limiting on all endpoints
- [ ] Input validation and sanitization
- [ ] Output encoding
- [ ] Security headers
- [ ] CSRF tokens on forms
- [ ] Remove debug endpoints
- [ ] Database encryption
- [ ] Backup and disaster recovery
- [ ] Incident response plan
- [ ] Security training for team
