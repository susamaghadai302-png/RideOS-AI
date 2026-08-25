const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 TESTING EXACT BUTTON COORDINATES (640, 790)');
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
    console.log(`[BROWSER CONSOLE] ${msg.type()}: ${msg.text()}`);
  });

  console.log('1. Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  console.log('2. Waiting 6.0s for Flutter splash...');
  await sleep(6000);

  console.log('3. Clicking SIGN IN TO COCKPIT at (640, 790)...');
  await page.mouse.click(640, 790);
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step3_login_screen.png') });
  console.log('✓ Saved step3_login_screen.png');

  console.log('4. Entering credentials...');
  await page.mouse.click(500, 415);
  await sleep(300);
  await page.keyboard.type('demo@rideos.ai');
  await sleep(300);

  await page.mouse.click(500, 485);
  await sleep(300);
  await page.keyboard.type('Password123!');
  await sleep(300);

  console.log('5. Clicking START ENGINE (LOGIN) at (640, 570)...');
  await page.mouse.click(640, 570);
  await sleep(5500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step5_after_login.png') });
  console.log('✓ Saved step5_after_login.png');

  console.log('6. Clicking 3D Garage in Sidebar at (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(7500);

  // 1. Yamaha YZF-R1M
  console.log('\n7. Selecting Yamaha YZF-R1M at (280, 165)...');
  await page.mouse.click(280, 165);
  await sleep(6500);
  console.log('8. Activating First-Person Rider POV (Key V)...');
  await page.keyboard.press('KeyV');
  await sleep(2500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_cockpit_tft.png') });
  console.log('✓ Saved rider_pov_yamaha_cockpit_tft.png');

  // 2. Accelerate to 180+ KM/H & Lean Left (W + A)
  console.log('9. Accelerating to 180+ KM/H and Leaning into Corner (W + A)...');
  await page.keyboard.press('KeyE');
  await sleep(800);
  await page.keyboard.down('KeyW');
  await page.keyboard.down('KeyA');
  await sleep(3500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_high_speed_lean_corner.png') });
  console.log('✓ Saved rider_pov_high_speed_lean_corner.png');
  await page.keyboard.up('KeyA');
  await page.keyboard.up('KeyW');
  await sleep(1000);

  // 3. Ducati Panigale V4 S
  console.log('\n10. Selecting Ducati Panigale V4 S at (440, 165)...');
  await page.mouse.click(440, 165);
  await sleep(7500);
  await page.keyboard.press('KeyV');
  await sleep(1500);
  await page.keyboard.press('KeyE');
  await sleep(500);
  await page.keyboard.down('KeyW');
  await page.keyboard.down('KeyD');
  await sleep(3000);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_ducati_v4s_simulation.png') });
  console.log('✓ Saved rider_pov_ducati_v4s_simulation.png');
  await page.keyboard.up('KeyD');
  await page.keyboard.up('KeyW');
  await sleep(1000);

  // 4. BMW S 1000 RR
  console.log('\n11. Selecting BMW S 1000 RR at (600, 165)...');
  await page.mouse.click(600, 165);
  await sleep(7500);
  await page.keyboard.press('KeyV');
  await sleep(1500);
  await page.keyboard.press('KeyE');
  await sleep(500);
  await page.keyboard.down('KeyW');
  await sleep(3500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_bmw_s1000rr_shift_flash.png') });
  console.log('✓ Saved rider_pov_bmw_s1000rr_shift_flash.png');
  await page.keyboard.up('KeyW');

  await browser.close();
  console.log('\nDone verifying Rider POV across all 3 superbikes!');
})();
