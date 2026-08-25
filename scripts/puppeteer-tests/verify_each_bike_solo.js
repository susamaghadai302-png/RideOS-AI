const http = require('http');
const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

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

function createStaticServer(port) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      let reqPath = decodeURI(req.url.split('?')[0]);
      if (reqPath === '/' || reqPath === '') reqPath = '/index.html';
      const filePath = path.join(__dirname, 'apps/mobile/build/web', reqPath);

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
        });
        fs.createReadStream(filePath).pipe(res);
      });
    });

    server.listen(port, '0.0.0.0', () => {
      console.log(`[Static Server] Running on http://localhost:${port}`);
      resolve(server);
    });
  });
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

(async () => {
  console.log('================================================================');
  console.log('🔍 AUDITING 3 DISTINCT MOTORCYCLES IN RIDEOS-AI 3D GARAGE');
  console.log('================================================================');

  const serverPort = 8092;
  const staticServer = await createStaticServer(serverPort);

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--use-gl=angle',
      '--use-angle=metal',
      '--enable-webgl',
      '--window-size=1280,950',
    ],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 950 });
    await page.setCacheEnabled(false);

    page.on('console', (msg) => {
      const type = msg.type();
      const text = msg.text();
      if (!text.includes('geolocation') && !text.includes('Noto') && !text.includes('Multiple instances')) {
        console.log(`[Console] ${type}: ${text.substring(0, 100)}`);
      }
    });

    console.log(`Navigating to http://localhost:${serverPort}...`);
    await page.goto(`http://localhost:${serverPort}`, { waitUntil: 'domcontentloaded', timeout: 35000 });
    await sleep(5500);

    console.log('Logging in to cockpit...');
    await page.mouse.click(640, 765);
    await sleep(2000);

    await page.mouse.click(500, 415);
    await page.keyboard.type('demo@rideos.ai');
    await sleep(300);

    await page.mouse.click(500, 485);
    await page.keyboard.type('Password123!');
    await sleep(300);

    await page.mouse.click(500, 570);
    await sleep(5000);

    console.log('Navigating to 3D Garage...');
    await page.mouse.click(80, 265);
    await sleep(6500);

    // ──────────────────────────────────────────────────────────────────────────
    // 1. YAMAHA YZF-R1M
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n[1/3] Selecting Yamaha YZF-R1M (Card 1 at 280, 175)...');
    await page.mouse.click(280, 175);
    await sleep(6500);

    const yamahaPath = path.join(ARTIFACTS_DIR, 'garage_production_yamaha_r1m.png');
    await page.screenshot({ path: yamahaPath });
    console.log(`  ✓ Saved: ${yamahaPath}`);

    // ──────────────────────────────────────────────────────────────────────────
    // 2. DUCATI PANIGALE V4 S
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n[2/3] Selecting Ducati Panigale V4 S (Card 2 at 485, 175)...');
    await page.mouse.click(485, 175);
    await sleep(7500);

    const ducatiPath = path.join(ARTIFACTS_DIR, 'garage_production_ducati_v4s.png');
    await page.screenshot({ path: ducatiPath });
    console.log(`  ✓ Saved: ${ducatiPath}`);

    // ──────────────────────────────────────────────────────────────────────────
    // 3. BMW S 1000 RR (M PACKAGE)
    // ──────────────────────────────────────────────────────────────────────────
    console.log('\n[3/3] Selecting BMW S 1000 RR (Card 3 at 690, 175)...');
    await page.mouse.click(690, 175);
    await sleep(7500);

    const bmwPath = path.join(ARTIFACTS_DIR, 'garage_production_bmw_s1000rr.png');
    await page.screenshot({ path: bmwPath });
    console.log(`  ✓ Saved: ${bmwPath}`);

    console.log('\n🎉 ALL 3 BIKES SUCCESSFULLY AUDITED AND CAPTURED!');
  } catch (err) {
    console.error('Audit failed:', err);
  } finally {
    await browser.close();
    staticServer.close();
  }
})();
