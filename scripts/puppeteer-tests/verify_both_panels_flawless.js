const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 LIVE RECORDING OF CUSTOMIZER & DYNO STUDIO');
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

  // 1. Open Telemetry & Dyno Bench at (1245, 332)
  console.log('6. Opening Telemetry Panel at (1245, 332)...');
  await page.mouse.click(1245, 332);
  await sleep(2000);

  // 2. Click GAUGES / DYNO toggle chip at (1120, 545)
  console.log('7. Switching Telemetry to Dyno Bench Curve (1120, 545)...');
  await page.mouse.click(1120, 545);
  await sleep(1500);

  // 3. Start Engine inside Dyno Bench (1000, 875)
  console.log('8. Starting Engine in Dyno Bench...');
  await page.mouse.click(1000, 875);
  await sleep(2000);

  // 4. Rev up engine using W key
  console.log('9. Revving on Dyno Roller (holding W)...');
  await page.keyboard.down('KeyW');
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'live_dyno_roller_power_curve.png') });
  console.log('✓ Saved live_dyno_roller_power_curve.png');
  await page.keyboard.up('KeyW');
  await sleep(1500);

  // 5. Close Telemetry (1245, 332) and Open Customizer Palette at (1245, 455)
  console.log('10. Opening Vehicle Customizer at (1245, 455)...');
  await page.mouse.click(1245, 332);
  await sleep(1000);
  await page.mouse.click(1245, 455);
  await sleep(2000);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'customizer_paint_panel_verified.png') });
  console.log('✓ Saved customizer_paint_panel_verified.png');

  await browser.close();
  console.log('Done recording customizer and dyno studio!');
})();
