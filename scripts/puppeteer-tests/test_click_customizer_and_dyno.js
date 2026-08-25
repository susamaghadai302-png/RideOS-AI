const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 CLICK-VERIFYING CUSTOMIZER MODAL & DYNO BENCH');
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

  // 1. Click Customizer Palette Icon in Right Dock (1248, 323)
  console.log('6. Clicking Customizer Palette Icon (1248, 323)...');
  await page.mouse.click(1248, 323);
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_drawer_open.png') });
  console.log('✓ Saved customizer_drawer_open.png');

  // 2. Click Wheel / Brakes Tab inside Customizer (950, 490)
  console.log('7. Switching to Wheels & Brakes Tab...');
  await page.mouse.click(950, 490);
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_wheels_tab.png') });
  console.log('✓ Saved customizer_wheels_tab.png');

  // 3. Click Exhaust Tab inside Customizer (1030, 490)
  console.log('8. Switching to Exhaust Tab...');
  await page.mouse.click(1030, 490);
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_exhaust_tab.png') });
  console.log('✓ Saved customizer_exhaust_tab.png');

  // 4. Close Customizer (click 1248, 323 again) and Open Telemetry (1248, 277)
  console.log('9. Opening Telemetry & Dyno Bench (1248, 277)...');
  await page.mouse.click(1248, 323);
  await sleep(1000);
  await page.mouse.click(1248, 277);
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'telemetry_gauges_open.png') });
  console.log('✓ Saved telemetry_gauges_open.png');

  // 5. Toggle Dyno Bench Mode (1120, 520)
  console.log('10. Toggling Dyno Bench Mode...');
  await page.mouse.click(1120, 520);
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'dyno_studio_live_curve.png') });
  console.log('✓ Saved dyno_studio_live_curve.png');

  await browser.close();
  console.log('Done verifying customizer tabs!');
})();
