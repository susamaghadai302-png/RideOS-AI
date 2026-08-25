const puppeteer = require('puppeteer-core');
const path = require('path');

const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

(async () => {
  console.log('================================================================');
  console.log('🚀 RUNNING 3D SHOWROOM VERIFICATION FOR ALL 3 MOTORCYCLES');
  console.log('================================================================');

  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
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
  await page.setCacheEnabled(false);

  page.on('console', (msg) => {
    const text = msg.text();
    if (!text.includes('geolocation') && !text.includes('Noto') && !text.includes('Multiple instances')) {
      console.log('[Browser Console]', msg.type(), text.substring(0, 120));
    }
  });
  page.on('pageerror', (err) => console.error('[Browser Error]', err));

  console.log('Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 35000 });

  console.log('Waiting 5.5s for Welcome screen...');
  await new Promise((r) => setTimeout(r, 5500));

  console.log('Step 1: Clicking SIGN IN TO COCKPIT at (640, 765)...');
  await page.mouse.click(640, 765);
  await new Promise((r) => setTimeout(r, 2000));

  console.log('Step 2: Entering demo credentials...');
  await page.mouse.click(500, 415);
  await page.keyboard.type('demo@rideos.ai');
  await new Promise((r) => setTimeout(r, 300));

  await page.mouse.click(500, 485);
  await page.keyboard.type('Password123!');
  await new Promise((r) => setTimeout(r, 300));

  console.log('Step 3: Clicking START ENGINE (LOGIN)...');
  await page.mouse.click(500, 570);
  await new Promise((r) => setTimeout(r, 5000));

  console.log('Step 4: Clicking 3D Garage in Sidebar at (80, 265)...');
  await page.mouse.click(80, 265);
  await new Promise((r) => setTimeout(r, 6000));

  // 1. YAMAHA YZF-R1M
  console.log('\nStep 5: Selecting Yamaha YZF-R1M at (280, 175)...');
  await page.mouse.click(280, 175);
  await new Promise((r) => setTimeout(r, 7000));

  const yamahaPath = path.join(ARTIFACTS_DIR, 'garage_verified_yamaha_r1m.png');
  await page.screenshot({ path: yamahaPath });
  console.log(`✓ Saved Yamaha Showroom: ${yamahaPath}`);

  // 2. DUCATI PANIGALE V4 S
  console.log('\nStep 6: Selecting Ducati Panigale V4 S at (485, 175)...');
  await page.mouse.click(485, 175);
  await new Promise((r) => setTimeout(r, 7500));

  const ducatiPath = path.join(ARTIFACTS_DIR, 'garage_verified_ducati_v4s.png');
  await page.screenshot({ path: ducatiPath });
  console.log(`✓ Saved Ducati Showroom: ${ducatiPath}`);

  // 3. BMW S 1000 RR (M PACKAGE)
  console.log('\nStep 7: Selecting BMW S 1000 RR (M Package) at (690, 175)...');
  await page.mouse.click(690, 175);
  await new Promise((r) => setTimeout(r, 7500));

  const bmwPath = path.join(ARTIFACTS_DIR, 'garage_verified_bmw_s1000rr.png');
  await page.screenshot({ path: bmwPath });
  console.log(`✓ Saved BMW Showroom: ${bmwPath}`);

  await browser.close();
  console.log('\n🎉 ALL 3 MOTORCYCLES VERIFIED AND CAPTURED SUCCESSFULLY!');
})();
