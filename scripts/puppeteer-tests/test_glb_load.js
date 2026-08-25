const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 LIVE FIRST-PERSON RIDER POV & RIDE SIMULATOR VERIFICATION');
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

  // Click login
  console.log('3. Clicking ENTER DEMO COCKPIT at (640, 870)...');
  await page.mouse.click(640, 870);
  await sleep(3500);

  // Navigate to 3D Garage
  console.log('4. Navigating to 3D Garage at (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(4000);

  // ══════════════════════════════════════════════════════════════════════════
  // YAMAHA YZF-R1M RIDER POV COCKPIT & TFT CLUSTER
  // ══════════════════════════════════════════════════════════════════════════
  console.log('5. Activating Yamaha YZF-R1M Rider POV...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 8200);
    sh.simulatedSpeedKmh = 158;
    sh.currentGear = 4;
    sh.setCameraPreset('riderPov');
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_cockpit_tft.png') });
  console.log('✓ Saved rider_pov_yamaha_cockpit_tft.png');

  // ══════════════════════════════════════════════════════════════════════════
  // HIGH-SPEED CORNERING & LEAN ANGLE (28 deg left)
  // ══════════════════════════════════════════════════════════════════════════
  console.log('6. Simulating High-Speed Left Cornering (248 KM/H, ~28° Lean)...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13400);
    sh.simulatedSpeedKmh = 248;
    sh.currentGear = 5;
    sh.steeringInput = -0.78; // Left lean
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_high_speed_lean_corner.png') });
  console.log('✓ Saved rider_pov_high_speed_lean_corner.png');

  // ══════════════════════════════════════════════════════════════════════════
  // DUCATI PANIGALE V4 S RIDER POV SIMULATION
  // ══════════════════════════════════════════════════════════════════════════
  console.log('7. Switching to Ducati Panigale V4 S...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.loadVehicleFromUrl('ducati_panigale_v4s_2024', 'assets/models/ducati_panigale.glb');
  });
  await sleep(4000);

  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13800);
    sh.setCameraPreset('riderPov');
    sh.simulatedSpeedKmh = 272;
    sh.currentGear = 6;
    sh.steeringInput = 0.65; // Right lean
  });
  await sleep(2000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_ducati_v4s_simulation.png') });
  console.log('✓ Saved rider_pov_ducati_v4s_simulation.png');

  // ══════════════════════════════════════════════════════════════════════════
  // BMW M 1000 RR REDLINE SHIFT FLASH SIMULATION
  // ══════════════════════════════════════════════════════════════════════════
  console.log('8. Switching to BMW M 1000 RR...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.loadVehicleFromUrl('bmw_m1000rr_2024', 'assets/models/bmw_m1000rr.glb');
  });
  await sleep(4000);

  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 14850); // Redline shift flash
    sh.setCameraPreset('riderPov');
    sh.simulatedSpeedKmh = 305;
    sh.currentGear = 6;
    sh.steeringInput = 0.0;
    sh.shiftFlash = 1.0;
  });
  await sleep(2000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_bmw_s1000rr_shift_flash.png') });
  console.log('✓ Saved rider_pov_bmw_s1000rr_shift_flash.png');

  console.log('\nAll 4 Rider POV Cockpit simulations successfully captured!');
  await browser.close();
})();
