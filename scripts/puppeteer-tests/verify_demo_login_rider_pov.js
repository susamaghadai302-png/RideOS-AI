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
  console.log('2. Waiting 6.0s for Flutter engine & Splash animation...');
  await sleep(6000);

  console.log('3. Clicking ENTER DEMO COCKPIT (ONE-TAP) at (640, 870)...');
  await page.mouse.click(640, 870);
  await sleep(4000);

  console.log('4. Navigating to 3D Garage at (80, 265)...');
  await page.mouse.click(80, 265);
  await sleep(4000);

  // ══════════════════════════════════════════════════════════════════════════
  // YAMAHA YZF-R1M RIDER POV & COCKPIT SIMULATION
  // ══════════════════════════════════════════════════════════════════════════
  console.log('5. Loading Yamaha YZF-R1M...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.loadVehicleFromUrl('yamaha_r1m_2024', 'assets/models/yamaha_r1m.glb');
    }
  });
  await sleep(3000);

  console.log('6. Activating Yamaha Rider POV & Instrument Cluster...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.setEngineState(true, 7200);
      window.RideOS3D.showroom.setCameraPreset('riderPov');
      window.RideOS3D.showroom.simulatedSpeedKmh = 142;
      window.RideOS3D.showroom.currentGear = 3;
      window.RideOS3D.showroom.steeringInput = -0.15;
    }
  });
  await sleep(1500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_cockpit_tft.png') });
  console.log('✓ Saved rider_pov_yamaha_cockpit_tft.png');

  console.log('7. Accelerating Yamaha YZF-R1M into High-Speed Left Corner...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.setEngineState(true, 13100);
      window.RideOS3D.showroom.simulatedSpeedKmh = 245;
      window.RideOS3D.showroom.currentGear = 5;
      window.RideOS3D.showroom.steeringInput = -0.85; // High left lean
    }
  });
  await sleep(1500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_high_speed_lean_corner.png') });
  console.log('✓ Saved rider_pov_high_speed_lean_corner.png');

  // ══════════════════════════════════════════════════════════════════════════
  // DUCATI PANIGALE V4 S RIDER POV & COCKPIT SIMULATION
  // ══════════════════════════════════════════════════════════════════════════
  console.log('8. Loading Ducati Panigale V4 S...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.loadVehicleFromUrl('ducati_panigale_v4s_2024', 'assets/models/ducati_panigale.glb');
    }
  });
  await sleep(3500);

  console.log('9. Activating Ducati Rider POV & High Speed Cornering...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.setEngineState(true, 13800);
      window.RideOS3D.showroom.setCameraPreset('riderPov');
      window.RideOS3D.showroom.simulatedSpeedKmh = 274;
      window.RideOS3D.showroom.currentGear = 6;
      window.RideOS3D.showroom.steeringInput = 0.72; // Right lean
    }
  });
  await sleep(1500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_ducati_v4s_simulation.png') });
  console.log('✓ Saved rider_pov_ducati_v4s_simulation.png');

  // ══════════════════════════════════════════════════════════════════════════
  // BMW M 1000 RR RIDER POV & REDLINE SHIFT FLASH
  // ══════════════════════════════════════════════════════════════════════════
  console.log('10. Loading BMW M 1000 RR...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.loadVehicleFromUrl('bmw_m1000rr_2024', 'assets/models/bmw_m1000rr.glb');
    }
  });
  await sleep(3000);

  console.log('11. Activating BMW S 1000 RR Redline Shift Flash Simulator...');
  await page.evaluate(() => {
    if (window.RideOS3D && window.RideOS3D.showroom) {
      window.RideOS3D.showroom.setEngineState(true, 14750); // Redline shift flash
      window.RideOS3D.showroom.setCameraPreset('riderPov');
      window.RideOS3D.showroom.simulatedSpeedKmh = 302;
      window.RideOS3D.showroom.currentGear = 6;
      window.RideOS3D.showroom.steeringInput = 0.05;
      window.RideOS3D.showroom.shiftFlash = 1.0;
    }
  });
  await sleep(1500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_bmw_s1000rr_shift_flash.png') });
  console.log('✓ Saved rider_pov_bmw_s1000rr_shift_flash.png');

  console.log('\nDone verifying Rider POV across all 3 superbikes!');
  await browser.close();
})();
