const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const _ = require('lodash');
const path = require('path');

const app = express();
const PORT = 3000;

// VULNERABILITY 1: Hardcoded API key
const API_KEY = 'sk-1234567890abcdefghijklmnop';
const SECRET_TOKEN = 'super_secret_admin_token_12345';

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Initialize SQLite database
const db = new sqlite3.Database(':memory:');

db.serialize(() => {
  db.run(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY,
      username TEXT,
      email TEXT,
      password TEXT,
      role TEXT
    )
  `);

  db.run(`
    CREATE TABLE products (
      id INTEGER PRIMARY KEY,
      name TEXT,
      price REAL,
      description TEXT
    )
  `);

  // Insert sample data
  db.run("INSERT INTO users VALUES (1, 'admin', 'admin@example.com', 'password123', 'admin')");
  db.run("INSERT INTO users VALUES (2, 'user', 'user@example.com', 'userpass', 'user')");
  db.run("INSERT INTO products VALUES (1, 'Laptop', 999.99, 'High-end laptop')");
  db.run("INSERT INTO products VALUES (2, 'Mouse', 29.99, 'Wireless mouse')");
});

// VULNERABILITY 2: No input validation - SQL Injection risk
app.get('/api/users/:username', (req, res) => {
  const username = req.params.username;

  // Direct string concatenation - SQL injection vulnerability
  const query = `SELECT * FROM users WHERE username = '${username}'`;

  db.get(query, (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(row || { error: 'User not found' });
  });
});

// VULNERABILITY 3: Weak authentication - API key in query string
app.get('/api/admin/users', (req, res) => {
  const apiKey = req.query.api_key;

  // Hardcoded key comparison - no rate limiting, exposed in logs
  if (apiKey !== API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  db.all('SELECT * FROM users', (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(rows);
  });
});

// VULNERABILITY 4: Insecure direct object reference (IDOR)
app.get('/api/user/:id', (req, res) => {
  const userId = req.params.id;

  // No authorization check - any user can access any user's data
  db.get('SELECT * FROM users WHERE id = ?', [userId], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(row || { error: 'User not found' });
  });
});

// VULNERABILITY 5: Unsafe use of lodash merge with user input
app.post('/api/config', (req, res) => {
  const userConfig = req.body;

  // Prototype pollution vulnerability - lodash 3.10.1 is vulnerable
  const defaultConfig = {
    debug: false,
    timeout: 5000,
    maxRetries: 3
  };

  // Unsafe merge with user input
  const config = _.merge(defaultConfig, userConfig);

  res.json({
    message: 'Config updated',
    config: config
  });
});

// VULNERABILITY 6: No CSRF protection
app.post('/api/transfer', (req, res) => {
  const { fromUser, toUser, amount } = req.body;

  // No CSRF token validation, no origin check
  // Direct state-changing operation
  res.json({
    message: `Transferred $${amount} from ${fromUser} to ${toUser}`,
    status: 'success'
  });
});

// VULNERABILITY 7: Sensitive data exposure - passwords in response
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;

  db.get('SELECT * FROM users WHERE username = ?', [username], (err, row) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (row && row.password === password) {
      // Returning sensitive data including password
      res.json({
        message: 'Login successful',
        user: row,
        token: Buffer.from(username).toString('base64') // Weak token
      });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  });
});

// VULNERABILITY 8: Path traversal risk
app.get('/api/file/:filename', (req, res) => {
  const filename = req.params.filename;

  // No path validation - could access files outside intended directory
  const filepath = path.join(__dirname, 'uploads', filename);

  res.json({
    message: `Would serve file: ${filepath}`,
    warning: 'Path traversal vulnerability - ../../../etc/passwd would work'
  });
});

// VULNERABILITY 9: Exposed debug endpoint
app.get('/api/debug', (req, res) => {
  res.json({
    apiKey: API_KEY,
    secretToken: SECRET_TOKEN,
    environment: process.env,
    nodeVersion: process.version,
    uptime: process.uptime()
  });
});

// VULNERABILITY 10: No rate limiting
app.post('/api/password-reset', (req, res) => {
  const { email } = req.body;

  // No rate limiting - brute force attack possible
  // No email validation
  res.json({
    message: `Password reset link sent to ${email}`,
    resetToken: Math.random().toString(36).substring(7) // Weak token
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Vulnerable app running on http://localhost:${PORT}`);
  console.log('⚠️  WARNING: This app contains intentional security vulnerabilities for educational purposes only');
});
