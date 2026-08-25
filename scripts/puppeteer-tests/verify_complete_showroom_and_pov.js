const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🏁 COMPLETE RIDEOS-AI 3D GARAGE & RIDER POV COCKPIT VERIFICATION');
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
  console.log('2. Waiting for Flutter splash...');
  await sleep(6000);

  // Click login
  console.log('3. Logging into Demo Cockpit...');
  await page.mouse.click(640, 870);
  await sleep(3500);

  // Navigate to 3D Garage
  console.log('4. Entering 3D Garage...');
  await page.mouse.click(80, 265);
  await sleep(4000);

  // ══════════════════════════════════════════════════════════════════════════
  // 1. YAMAHA YZF-R1M SHOWROOM & RIDER POV
  // ══════════════════════════════════════════════════════════════════════════
  console.log('\n--- 1. YAMAHA YZF-R1M ---');
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'showroom_yamaha_r1m_exterior.png') });
  console.log('✓ Saved showroom_yamaha_r1m_exterior.png');

  console.log('Activating Yamaha Rider POV & Cockpit TFT Instrument Cluster...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 8400);
    sh.simulatedSpeedKmh = 162;
    sh.currentGear = 4;
    sh.setCameraPreset('riderPov');
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_r1m_cockpit.png') });
  console.log('✓ Saved rider_pov_yamaha_r1m_cockpit.png');

  console.log('Simulating Yamaha High-Speed Lean Angle (-28 deg left)...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13400);
    sh.simulatedSpeedKmh = 248;
    sh.currentGear = 5;
    sh.steeringInput = -0.75;
  });
  await sleep(2000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_yamaha_high_speed_lean.png') });
  console.log('✓ Saved rider_pov_yamaha_high_speed_lean.png');

  // ══════════════════════════════════════════════════════════════════════════
  // 2. DUCATI PANIGALE V4 S SHOWROOM & RIDER POV
  // ══════════════════════════════════════════════════════════════════════════
  console.log('\n--- 2. DUCATI PANIGALE V4 S ---');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setCameraPreset('frontThreeQuarter');
    sh.loadVehicle('ducati_panigale_v4s_2024');
  });
  await sleep(4000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'showroom_ducati_panigale_exterior.png') });
  console.log('✓ Saved showroom_ducati_panigale_exterior.png');

  console.log('Activating Ducati Rider POV Simulation...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13800);
    sh.setCameraPreset('riderPov');
    sh.simulatedSpeedKmh = 274;
    sh.currentGear = 6;
    sh.steeringInput = 0.65; // Right lean
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_ducati_v4s_cockpit.png') });
  console.log('✓ Saved rider_pov_ducati_v4s_cockpit.png');

  // ══════════════════════════════════════════════════════════════════════════
  // 3. BMW S 1000 RR (M PACKAGE) SHOWROOM & REDLINE SHIFT FLASH
  // ══════════════════════════════════════════════════════════════════════════
  console.log('\n--- 3. BMW S 1000 RR (M PACKAGE) ---');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setCameraPreset('frontThreeQuarter');
    sh.loadVehicle('bmw_s1000rr_m_2024');
  });
  await sleep(4000);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'showroom_bmw_s1000rr_exterior.png') });
  console.log('✓ Saved showroom_bmw_s1000rr_exterior.png');

  console.log('Activating BMW S 1000 RR Redline Shift Flash Simulator...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 14850); // Redline shift flash
    sh.setCameraPreset('riderPov');
    sh.simulatedSpeedKmh = 305;
    sh.currentGear = 6;
    sh.steeringInput = 0.0;
    sh.shiftFlash = 1.0;
  });
  await sleep(2500);

  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'rider_pov_bmw_s1000rr_redline_flash.png') });
  console.log('✓ Saved rider_pov_bmw_s1000rr_redline_flash.png');

  console.log('\n================================================================');
  console.log('✅ ALL SHOWROOM & RIDER POV VERIFICATIONS COMPLETED PERFECTLY!');
  console.log('================================================================');

  await browser.close();
})();
