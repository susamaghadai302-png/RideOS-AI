const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1280,950'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  console.log('Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  console.log('Waiting 5.5s for Flutter engine & Splash animation to complete...');
  await sleep(5500);

  console.log('Clicking (640, 765)...');
  await page.mouse.click(640, 765);
  await sleep(2000);

  console.log('Entering credentials...');
  await page.mouse.click(500, 415);
  await page.keyboard.type('demo@rideos.ai');
  await sleep(300);

  await page.mouse.click(500, 485);
  await page.keyboard.type('Password123!');
  await sleep(300);

  console.log('Clicking START ENGINE (LOGIN)...');
  await page.mouse.click(500, 570);
  await sleep(5000);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'debug_5_dashboard.png') });

  console.log('Clicking 3D Garage at (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(6500);

  // 1. Yamaha
  console.log('Selecting Yamaha YZF-R1M (Card 1 at 280, 165)...');
  await page.mouse.click(280, 165);
  await sleep(6500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'garage_master_yamaha_final.png') });
  console.log('✓ Saved Yamaha screenshot');

  // 2. Ducati
  console.log('Selecting Ducati Panigale V4 S (Card 2 at 440, 165)...');
  await page.mouse.click(440, 165);
  await sleep(7500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'garage_master_ducati_final.png') });
  console.log('✓ Saved Ducati screenshot');

  // 3. BMW
  console.log('Selecting BMW S 1000 RR (Card 3 at 600, 165)...');
  await page.mouse.click(600, 165);
  await sleep(7500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'garage_master_bmw_final.png') });
  console.log('✓ Saved BMW screenshot');

  await browser.close();
  console.log('Done!');
})();
