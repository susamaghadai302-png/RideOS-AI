const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 TESTING REAL-TIME 3D VEHICLE CUSTOMIZER & DYNO STUDIO');
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

  console.log('1. Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await sleep(6000);

  console.log('2. Clicking (640, 765)...');
  await page.mouse.click(640, 765);
  await sleep(2500);

  console.log('3. Entering credentials...');
  await page.mouse.click(500, 415);
  await sleep(300);
  await page.keyboard.type('demo@rideos.ai');
  await sleep(300);
  await page.mouse.click(500, 485);
  await sleep(300);
  await page.keyboard.type('Password123!');
  await sleep(300);

  console.log('4. Logging In (500, 570)...');
  await page.mouse.click(500, 570);
  await sleep(5500);

  console.log('5. Navigating to 3D Garage (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(7000);

  // 1. Open Vehicle Customizer (C key or click right dock at 1248, 555)
  console.log('6. Opening Vehicle Customizer (key C)...');
  await page.keyboard.press('KeyC');
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_paint_modal_open.png') });
  console.log('✓ Saved customizer_paint_modal_open.png');

  // 2. Select Matte Stealth or Solar Gold
  console.log('7. Selecting Custom Color / Finish in Customizer...');
  // Click Paint Preset Chip inside modal
  await page.mouse.click(950, 680);
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_paint_applied.png') });
  console.log('✓ Saved customizer_paint_applied.png');

  // 3. Close Customizer (key C) & Open Telemetry/Dyno Panel
  console.log('8. Closing Customizer and Starting Engine...');
  await page.keyboard.press('KeyC');
  await sleep(1000);

  // Start Engine (Key E)
  await page.keyboard.press('KeyE');
  await sleep(2500);

  // Open Dyno Bench
  console.log('9. Clicking Dyno Bench Toggle in Telemetry...');
  // Press W to rev up
  await page.keyboard.down('KeyW');
  await sleep(2000);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'dyno_studio_live_curve.png') });
  console.log('✓ Saved dyno_studio_live_curve.png');
  await page.keyboard.up('KeyW');
  await sleep(1500);

  await browser.close();
  console.log('Done verifying Real-Time Customizer & Dyno Studio!');
})();
