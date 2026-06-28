const http = require('http');
const { spawn } = require('child_process');

const server = spawn('node', ['server.js'], { env: { ...process.env, PORT: '3001' } });

server.stdout.on('data', (data) => process.stdout.write(data));
server.stderr.on('data', (data) => process.stderr.write(data));

function cleanup() {
  server.kill();
}

process.on('exit', cleanup);
process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));

setTimeout(() => {
  http.get('http://127.0.0.1:3001', (res) => {
    let body = '';
    res.on('data', (chunk) => (body += chunk));
    res.on('end', () => {
      if (res.statusCode === 200 && body.includes('Sprint 1 Web Application - CI/CD Pipeline Ready')) {
        console.log('Smoke test passed');
        cleanup();
        process.exit(0);
      } else {
        console.error('Smoke test failed:', res.statusCode, body);
        cleanup();
        process.exit(1);
      }
    });
  }).on('error', (err) => {
    console.error('Smoke test request failed:', err.message);
    cleanup();
    process.exit(1);
  });
}, 1000);
