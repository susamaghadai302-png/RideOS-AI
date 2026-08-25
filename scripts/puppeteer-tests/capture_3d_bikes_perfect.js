const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

(async () => {
  console.log('================================================================');
  console.log('🚀 AUDITING ALL 3 MOTORCYCLES IN RIDEOS-AI 3D GARAGE');
  console.log('================================================================');

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--enable-webgl',
      '--use-gl=angle',
      '--use-angle=metal',
      '--window-size=1280,950',
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  page.on('console', (msg) => {
    const text = msg.text();
    if (!text.includes('geolocation') && !text.includes('Noto') && !text.includes('Multiple instances')) {
      console.log('[Browser Console]', msg.type(), text.substring(0, 120));
    }
  });

  console.log('1. Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 35000 });

  console.log('2. Waiting 6.0s for Flutter engine initialization...');
  await sleep(6000);

  console.log('3. Clicking SIGN IN TO COCKPIT...');
  await page.mouse.click(640, 785);
  await sleep(2500);

  console.log('4. Entering credentials...');
  await page.mouse.click(500, 415);
  await sleep(300);
  await page.keyboard.type('demo@rideos.ai');
  await sleep(300);

  await page.mouse.click(500, 485);
  await sleep(300);
  await page.keyboard.type('Password123!');
  await sleep(300);

  console.log('5. Clicking START ENGINE (LOGIN)...');
  await page.mouse.click(500, 570);
  await sleep(5500);

  console.log('6. Clicking 3D Garage in Sidebar...');
  await page.mouse.click(80, 265);
  await sleep(7000);

  // ──────────────────────────────────────────────────────────────────────────
  // VEHICLE 1: YAMAHA YZF-R1M
  // ──────────────────────────────────────────────────────────────────────────
  console.log('\n[1/3] Selecting Yamaha YZF-R1M (Card 1 at 280, 165)...');
  await page.mouse.click(280, 165);
  await sleep(6500);
  const yamahaPath = path.join(ARTIFACTS_DIR, 'yamaha_r1m_verified_3d.png');
  await page.screenshot({ path: yamahaPath });
  console.log(`✓ Saved: ${yamahaPath}`);

  // ──────────────────────────────────────────────────────────────────────────
  // VEHICLE 2: DUCATI PANIGALE V4 S
  // ──────────────────────────────────────────────────────────────────────────
  console.log('\n[2/3] Selecting Ducati Panigale V4 S (Card 2 at 440, 165)...');
  await page.mouse.click(440, 165);
  await sleep(7500);
  const ducatiPath = path.join(ARTIFACTS_DIR, 'ducati_panigale_verified_3d.png');
  await page.screenshot({ path: ducatiPath });
  console.log(`✓ Saved: ${ducatiPath}`);

  // ──────────────────────────────────────────────────────────────────────────
  // VEHICLE 3: BMW S 1000 RR (M PACKAGE)
  // ──────────────────────────────────────────────────────────────────────────
  console.log('\n[3/3] Selecting BMW S 1000 RR (Card 3 at 600, 165)...');
  await page.mouse.click(600, 165);
  await sleep(7500);
  const bmwPath = path.join(ARTIFACTS_DIR, 'bmw_s1000rr_verified_3d.png');
  await page.screenshot({ path: bmwPath });
  console.log(`✓ Saved: ${bmwPath}`);

  await browser.close();
  console.log('\n🎉 ALL 3 BIKES AUDITED SUCCESSFULLY!');
})();
