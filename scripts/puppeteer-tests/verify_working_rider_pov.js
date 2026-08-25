const puppeteer = require('puppeteer-core');
const path = require('path');

const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

(async () => {
  console.log('================================================================');
  console.log('🚀 LIVE FIRST-PERSON RIDER POV & RIDE SIMULATOR VERIFICATION');
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

  console.log('Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 35000 });

  console.log('Waiting 5.5s for Welcome screen...');
  await new Promise((r) => setTimeout(r, 5500));

  console.log('Step 1: Clicking SIGN IN TO COCKPIT at (640, 765)...');
  await page.mouse.click(640, 765);
  await new Promise((r) => setTimeout(r, 2500));

  console.log('Step 2: Submitting Pre-filled Credentials with START ENGINE (LOGIN) at (640, 570)...');
  await page.mouse.click(640, 570);
  await new Promise((r) => setTimeout(r, 7000));

  console.log('Step 3: Clicking 3D Garage in Sidebar at (80, 265)...');
  await page.mouse.click(80, 265);
  await new Promise((r) => setTimeout(r, 7500));

  // 1. Activate Rider POV Mode (Key V) on Yamaha YZF-R1M
  console.log('Step 4: Activating First-Person Rider POV (Key V) on Yamaha YZF-R1M...');
  await page.keyboard.press('KeyV');
  await new Promise((r) => setTimeout(r, 2000));
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_cockpit_tft.png') });
  console.log('✓ Saved rider_pov_yamaha_cockpit_tft.png');

  // 2. Start Engine, Accelerate to 180+ KM/H, and Lean into Corner (W + A)
  console.log('Step 5: Starting Engine, Accelerating, and Leaning Left (W + A)...');
  await page.keyboard.press('KeyE');
  await new Promise((r) => setTimeout(r, 800));
  await page.keyboard.down('KeyW');
  await page.keyboard.down('KeyA');
  await new Promise((r) => setTimeout(r, 3500));
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_high_speed_lean_corner.png') });
  console.log('✓ Saved rider_pov_high_speed_lean_corner.png');
  await page.keyboard.up('KeyA');
  await page.keyboard.up('KeyW');
  await new Promise((r) => setTimeout(r, 1000));

  // 3. Select Ducati Panigale V4 S (485, 175)
  console.log('\nStep 6: Selecting Ducati Panigale V4 S at (485, 175)...');
  await page.mouse.click(485, 175);
  await new Promise((r) => setTimeout(r, 6000));
  await page.keyboard.press('KeyV');
  await new Promise((r) => setTimeout(r, 1500));
  await page.keyboard.press('KeyE');
  await new Promise((r) => setTimeout(r, 500));
  await page.keyboard.down('KeyW');
  await page.keyboard.down('KeyD');
  await new Promise((r) => setTimeout(r, 3000));
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_ducati_v4s_simulation.png') });
  console.log('✓ Saved rider_pov_ducati_v4s_simulation.png');
  await page.keyboard.up('KeyD');
  await page.keyboard.up('KeyW');
  await new Promise((r) => setTimeout(r, 1000));

  // 4. Select BMW S 1000 RR (690, 175)
  console.log('\nStep 7: Selecting BMW S 1000 RR at (690, 175)...');
  await page.mouse.click(690, 175);
  await new Promise((r) => setTimeout(r, 6000));
  await page.keyboard.press('KeyV');
  await new Promise((r) => setTimeout(r, 1500));
  await page.keyboard.press('KeyE');
  await new Promise((r) => setTimeout(r, 500));
  await page.keyboard.down('KeyW');
  await new Promise((r) => setTimeout(r, 3500));
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_bmw_s1000rr_shift_flash.png') });
  console.log('✓ Saved rider_pov_bmw_s1000rr_shift_flash.png');
  await page.keyboard.up('KeyW');

  await browser.close();
  console.log('\nDone verifying Rider POV across all 3 superbikes!');
})();
