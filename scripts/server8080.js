const http = require('http');
const fs = require('fs');
const path = require('path');

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.glb': 'model/gltf-binary',
  '.gltf': 'model/gltf+json',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
};

const server = http.createServer((req, res) => {
  let reqPath = decodeURI(req.url.split('?')[0]);
  if (reqPath === '/' || reqPath === '') reqPath = '/index.html';
  const filePath = path.join(__dirname, '../apps/mobile/build/web', reqPath);

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
      res.end('Not Found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    const contentType = mimeTypes[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
    });

    if (ext === '.html') {
      let html = fs.readFileSync(filePath, 'utf8');
      // Read GOOGLE_MAPS_API_KEY from .env
      const envPath = path.join(__dirname, '../.env');
      if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        const match = envContent.match(/^GOOGLE_MAPS_API_KEY=(.*)$/m);
        if (match && match[1] && !match[1].includes('YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE')) {
          const key = match[1].trim().replace(/^['"]|['"]$/g, '');
          const injection = `<script>window.__RIDEOS_GOOGLE_MAPS_API_KEY__ = "${key}";</script>`;
          if (html.includes('<!-- GOOGLE_MAPS_CONFIG_INJECTION -->')) {
            html = html.replace('<!-- GOOGLE_MAPS_CONFIG_INJECTION -->', injection);
          } else {
            html = html.replace('<head>', `<head>\n  ${injection}`);
          }
        }
      }
      res.end(html);
      return;
    }

    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Static web server running on http://localhost:8080');
});
