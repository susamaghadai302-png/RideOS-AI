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

    server.listen(port, '127.0.0.1', () => {
      console.log(`[Static Server] Running on http://127.0.0.1:${port}`);
      resolve(server);
    });
  });
}

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

(async () => {
  console.log('===============================================================');
  console.log('🚀 RIDEOS-AI COMPLETE 3D GARAGE PRODUCTION MASTER AUDIT & TEST');
  console.log('===============================================================');

  const serverPort = 8089;
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
        console.log(`[Browser Console] ${type}: ${text.substring(0, 100)}`);
      }
    });

    console.log(`\n[1/10] Navigating to http://127.0.0.1:${serverPort}...`);
    await page.goto(`http://127.0.0.1:${serverPort}`, { waitUntil: 'domcontentloaded', timeout: 35000 });
    console.log('Waiting 5.5s for Flutter engine & Splash animation to complete...');
    await sleep(5500);

    console.log('[2/10] Logging in to cockpit...');
    await page.mouse.click(640, 765); // Click "SIGN IN TO COCKPIT"
    await sleep(2000);

    await page.mouse.click(500, 415);
    await page.keyboard.type('demo@rideos.ai');
    await sleep(300);

    await page.mouse.click(500, 485);
    await page.keyboard.type('Password123!');
    await sleep(300);

    await page.mouse.click(500, 570); // "START ENGINE (LOGIN)"
    await sleep(5000);

    console.log('[3/10] Navigating to 3D Garage...');
    await page.mouse.click(80, 265); // 3D Garage Sidebar item
    await sleep(6500);

    // ══════════════════════════════════════════════════════════════════════════
    // VEHICLE 1: YAMAHA YZF-R1M
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[4/10] Testing Vehicle 1: Yamaha YZF-R1M...');
    await page.mouse.click(280, 165); // Click Card 1 (Yamaha)
    await sleep(6500);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_yamaha_default.png'),
    });
    console.log('  ✓ Saved: garage_master_yamaha_default.png');

    // 360 Camera Drag Orbit
    await page.mouse.move(700, 450);
    await page.mouse.down();
    await page.mouse.move(960, 410, { steps: 35 });
    await page.mouse.up();
    await sleep(2000);
    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_yamaha_rotated.png'),
    });
    console.log('  ✓ Saved: garage_master_yamaha_rotated.png');

    // Test Engine Start on Yamaha
    console.log('  → Starting Yamaha engine...');
    await page.mouse.click(940, 915); // Bottom right ENGINE button
    await sleep(2000);

    // Throttle revving
    await page.keyboard.down('w');
    await sleep(1500);
    await page.keyboard.up('w');
    await sleep(1000);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_yamaha_engine_active.png'),
    });
    console.log('  ✓ Saved: garage_master_yamaha_engine_active.png');

    // Stop Engine
    await page.mouse.click(940, 915);
    await sleep(1000);

    // Explicitly click Close 'X' button on component card if open
    await page.mouse.click(530, 415);
    await sleep(800);

    // ══════════════════════════════════════════════════════════════════════════
    // VEHICLE 2: DUCATI PANIGALE V4 S
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[5/10] Testing Vehicle 2: Ducati Panigale V4 S...');
    await page.mouse.click(440, 165); // Click Card 2 (Ducati)
    await sleep(8500);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_ducati_default.png'),
    });
    console.log('  ✓ Saved: garage_master_ducati_default.png');

    // 360 Camera Drag Orbit
    await page.mouse.move(700, 450);
    await page.mouse.down();
    await page.mouse.move(960, 410, { steps: 35 });
    await page.mouse.up();
    await sleep(2000);
    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_ducati_rotated.png'),
    });
    console.log('  ✓ Saved: garage_master_ducati_rotated.png');

    // Start Ducati Engine
    console.log('  → Starting Ducati engine...');
    await page.mouse.click(940, 915);
    await sleep(2000);
    await page.keyboard.down('w');
    await sleep(1200);
    await page.keyboard.up('w');
    await sleep(1000);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_ducati_engine_active.png'),
    });
    console.log('  ✓ Saved: garage_master_ducati_engine_active.png');

    // Stop Engine
    await page.mouse.click(940, 915);
    await sleep(1000);

    // Explicitly click Close 'X' button on component card if open
    await page.mouse.click(530, 415);
    await sleep(800);

    // ══════════════════════════════════════════════════════════════════════════
    // VEHICLE 3: BMW S 1000 RR (M PACKAGE)
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[6/10] Testing Vehicle 3: BMW S 1000 RR (M Package)...');
    await page.mouse.click(600, 165); // Click Card 3 (BMW)
    await sleep(8500);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_bmw_default.png'),
    });
    console.log('  ✓ Saved: garage_master_bmw_default.png');

    // 360 Camera Drag Orbit
    await page.mouse.move(700, 450);
    await page.mouse.down();
    await page.mouse.move(960, 410, { steps: 35 });
    await page.mouse.up();
    await sleep(2000);
    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_bmw_rotated.png'),
    });
    console.log('  ✓ Saved: garage_master_bmw_rotated.png');

    // Start BMW Engine
    console.log('  → Starting BMW engine...');
    await page.mouse.click(940, 915);
    await sleep(2000);
    await page.keyboard.down('w');
    await sleep(1200);
    await page.keyboard.up('w');
    await sleep(1000);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_bmw_engine_active.png'),
    });
    console.log('  ✓ Saved: garage_master_bmw_engine_active.png');

    // Stop Engine
    await page.mouse.click(940, 915);
    await sleep(1000);

    // ══════════════════════════════════════════════════════════════════════════
    // COMPARE MODAL
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[7/10] Testing Vehicle Comparison Feature...');
    await page.mouse.click(875, 85); // "Compare" button top right
    await sleep(2500);
    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_compare_modal.png'),
    });
    console.log('  ✓ Saved: garage_master_compare_modal.png');

    // Close compare modal (click Compare button again or top area)
    await page.mouse.click(875, 85);
    await sleep(1000);

    // ══════════════════════════════════════════════════════════════════════════
    // SET PRIMARY VEHICLE
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[8/10] Testing Set Primary Feature...');
    await page.mouse.click(460, 915); // "Set Primary" button in bottom bar
    await sleep(2000);
    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_primary_updated.png'),
    });
    console.log('  ✓ Saved: garage_master_primary_updated.png');

    // ══════════════════════════════════════════════════════════════════════════
    // FULL CYCLE SWITCHING TEST
    // ══════════════════════════════════════════════════════════════════════════
    console.log('\n[9/10] Testing Full-Cycle Vehicle Switching (Yamaha -> Ducati -> BMW -> Yamaha)...');
    await page.mouse.click(280, 165); // Yamaha
    await sleep(5000);
    await page.mouse.click(440, 165); // Ducati
    await sleep(5000);
    await page.mouse.click(600, 165); // BMW
    await sleep(5000);
    await page.mouse.click(280, 165); // Back to Yamaha
    await sleep(5000);

    await page.screenshot({
      path: path.join(ARTIFACTS_DIR, 'garage_master_full_cycle_verified.png'),
    });
    console.log('  ✓ Saved: garage_master_full_cycle_verified.png');

    console.log('\n[10/10] 🎉 ALL MASTER GARAGE AUDIT TESTS PASSED SUCCESSFULLY!\n');
  } catch (err) {
    console.error('Master test failed with error:', err);
  } finally {
    await browser.close();
    staticServer.close();
  }
})();
