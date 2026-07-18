const http = require('http');
const client = require('prom-client');

const port = process.env.PORT || 3000;

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'webapp_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
  registers: [register],
});

const httpRequestsTotal = new client.Counter({
  name: 'webapp_http_requests_total',
  help: 'Total HTTP requests processed by the webapp',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

const routeLabel = (url) => {
  if (url === '/metrics') {
    return '/metrics';
  }
  if (url === '/healthz') {
    return '/healthz';
  }
  return '/';
};

const server = http.createServer(async (req, res) => {
  const end = httpRequestDuration.startTimer();
  const route = routeLabel(req.url);

  if (req.url === '/metrics') {
    try {
      const metrics = await register.metrics();
      res.writeHead(200, { 'Content-Type': register.contentType });
      res.end(metrics);
      httpRequestsTotal.inc({ method: req.method, route, status_code: '200' });
      end({ method: req.method, route, status_code: '200' });
      return;
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('metrics unavailable\n');
      httpRequestsTotal.inc({ method: req.method, route, status_code: '500' });
      end({ method: req.method, route, status_code: '500' });
      return;
    }
  }

  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    httpRequestsTotal.inc({ method: req.method, route, status_code: '200' });
    end({ method: req.method, route, status_code: '200' });
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Sprint 1 Web Application - CI/CD Pipeline Ready\n');
  httpRequestsTotal.inc({ method: req.method, route, status_code: '200' });
  end({ method: req.method, route, status_code: '200' });
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
