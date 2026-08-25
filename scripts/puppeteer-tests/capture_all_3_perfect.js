const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1280,950'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  console.log('1. Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await sleep(6000);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step1_welcome.png') });

  console.log('2. Clicking Sign in to Cockpit (640, 765)...');
  await page.mouse.click(640, 765);
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step2_login_modal.png') });

  console.log('3. Entering credentials...');
  await page.mouse.click(500, 415);
  await sleep(400);
  await page.keyboard.type('demo@rideos.ai');
  await sleep(400);
  await page.mouse.click(500, 485);
  await sleep(400);
  await page.keyboard.type('Password123!');
  await sleep(400);

  console.log('4. Clicking Start Engine (500, 570)...');
  await page.mouse.click(500, 570);
  await sleep(5500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step3_dashboard.png') });

  console.log('5. Clicking 3D Garage in Sidebar (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(7000);

  // Bike 1: Yamaha
  console.log('6. Selecting Yamaha YZF-R1M (280, 165)...');
  await page.mouse.click(280, 165);
  await sleep(6500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step4_garage_yamaha.png') });

  // Bike 2: Ducati
  console.log('7. Selecting Ducati Panigale V4 S (440, 165)...');
  await page.mouse.click(440, 165);
  await sleep(7500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step5_garage_ducati.png') });

  // Bike 3: BMW
  console.log('8. Selecting BMW S 1000 RR (600, 165)...');
  await page.mouse.click(600, 165);
  await sleep(7500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step6_garage_bmw.png') });

  await browser.close();
  console.log('Done capturing all 3 bikes!');
})();
