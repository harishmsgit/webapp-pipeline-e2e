const http = require('http');
const net = require('net');
const { spawn } = require('child_process');

const startupTimeoutMs = 20000;
const pollIntervalMs = 500;

let server;
let targetUrl;

function cleanup() {
  if (server && !server.killed) {
    server.kill();
  }
}

process.on('exit', cleanup);
process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));

function fail(message) {
  console.error(message);
  cleanup();
  process.exit(1);
}

function pass() {
  console.log('Smoke test passed');
  cleanup();
  process.exit(0);
}

function findFreePort() {
  return new Promise((resolve, reject) => {
    const probe = net.createServer();
    probe.listen(0, '127.0.0.1', () => {
      const address = probe.address();
      const port = address && address.port;
      probe.close(() => resolve(port));
    });
    probe.on('error', reject);
  });
}

function checkHealth() {
  return new Promise((resolve, reject) => {
    const req = http.get(targetUrl, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        if (res.statusCode === 200 && body.includes('Sprint 1 Web Application - CI/CD Pipeline Ready')) {
          resolve(true);
        } else {
          reject(new Error(`Unexpected response: ${res.statusCode} ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(2000, () => {
      req.destroy(new Error('Request timeout'));
    });
  });
}

async function waitForHealthyServer() {
  const deadline = Date.now() + startupTimeoutMs;
  let lastError = null;

  while (Date.now() < deadline) {
    try {
      await checkHealth();
      return;
    } catch (err) {
      lastError = err;
      await new Promise((resolve) => setTimeout(resolve, pollIntervalMs));
    }
  }

  throw new Error(`Server did not become healthy within ${startupTimeoutMs} ms. Last error: ${lastError ? lastError.message : 'unknown'}`);
}

async function run() {
  const port = await findFreePort();
  targetUrl = `http://127.0.0.1:${port}`;

  server = spawn('node', ['server.js'], { env: { ...process.env, PORT: String(port) } });
  server.stdout.on('data', (data) => process.stdout.write(data));
  server.stderr.on('data', (data) => process.stderr.write(data));
  server.on('exit', (code, signal) => {
    if (code !== 0) {
      fail(`Server exited before smoke test completed (code=${code}, signal=${signal || 'none'})`);
    }
  });

  try {
    await waitForHealthyServer();
    pass();
  } catch (err) {
    fail(`Smoke test failed: ${err.message}`);
  }
}

run().catch((err) => fail(`Smoke test bootstrap failed: ${err.message}`));
