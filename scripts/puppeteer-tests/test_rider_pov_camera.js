const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 TESTING DIRECT RIDER POV COCKPIT & TFT INSTRUMENT CLUSTER');
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

  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await sleep(6000);

  // Click login
  console.log('1. Logging in via One-Tap Demo Cockpit...');
  await page.mouse.click(640, 870);
  await sleep(4000);

  // Navigate to 3D Garage
  console.log('2. Navigating to 3D Garage in Sidebar...');
  await page.mouse.click(80, 265);
  await sleep(4500);

  // Wait for RideOS3D showroom to be ready
  console.log('3. Waiting for 3D Showroom & Model to mount...');
  await page.waitForFunction(
    () => window.RideOS3D && window.RideOS3D.showroom && window.RideOS3D.showroom.currentBikeGroup,
    { timeout: 20000 }
  );

  // Set Rider POV directly on the active bike
  console.log('4. Activating Rider POV on active superbike...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 8500);
    sh.simulatedSpeedKmh = 168;
    sh.currentGear = 4;
    sh.setCameraPreset('riderPov');
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_cockpit_tft_active.png') });
  console.log('✓ Saved rider_pov_cockpit_tft_active.png');

  // Test Lean into corner
  console.log('5. Simulating High-Speed Lean Angle (Left 28 deg)...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13200);
    sh.simulatedSpeedKmh = 245;
    sh.currentGear = 5;
    sh.steeringInput = -0.75;
  });
  await sleep(2000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_cockpit_lean_active.png') });
  console.log('✓ Saved rider_pov_cockpit_lean_active.png');

  // Test Redline Shift Flash
  console.log('6. Simulating Redline Shift Flash at 14,800 RPM & 298 KM/H...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 14800);
    sh.simulatedSpeedKmh = 298;
    sh.currentGear = 6;
    sh.steeringInput = 0.0;
  });
  await sleep(2000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_cockpit_redline_shift_flash.png') });
  console.log('✓ Saved rider_pov_cockpit_redline_shift_flash.png');

  console.log('\nAll Rider POV Cockpit screenshots successfully captured!');
  await browser.close();
})();
