// Sample banking accounts API. Fake data only. This is the thing the
// infrastructure in infra/ hosts; the session is about the infra, not the app.
'use strict';

const http = require('node:http');

const TRANSFER_LIMIT = Number(process.env.TRANSFER_LIMIT ?? 10000);
const PORT = Number(process.env.PORT ?? 8080);

const accounts = new Map([
  ['CHK-1001', { id: 'CHK-1001', type: 'chequing', balance: 2450.75 }],
  ['SAV-2002', { id: 'SAV-2002', type: 'savings', balance: 18200.0 }],
]);

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');
  if (req.method === 'GET' && url.pathname === '/api/health') {
    return send(res, 200, { status: 'ok', transferLimit: TRANSFER_LIMIT });
  }
  const match = url.pathname.match(/^\/api\/accounts\/([\w-]+)$/);
  if (req.method === 'GET' && match) {
    const account = accounts.get(match[1]);
    return account ? send(res, 200, account) : send(res, 404, { error: 'account not found' });
  }
  return send(res, 404, { error: 'not found' });
});

server.listen(PORT, () => console.log(`accounts API listening on ${PORT}`));
