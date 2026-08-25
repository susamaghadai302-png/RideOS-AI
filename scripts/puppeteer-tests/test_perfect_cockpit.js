const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--enable-webgl'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await sleep(6000);
  await page.mouse.click(640, 870);
  await sleep(3500);
  await page.mouse.click(80, 265);
  await sleep(4000);

  // 1. Yamaha R1M First-Person Rider Cockpit with Active Engine & Speed
  console.log('1. Capturing Yamaha YZF-R1M Cockpit POV...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.isRiderPov = false; // direct control
    if (sh.controls) sh.controls.enabled = false;
    sh.camera.fov = 74;
    sh.camera.updateProjectionMatrix();
    sh.camera.position.set(0.42, 1.08, 0.0);
    sh.camera.lookAt(-2.8, 0.82, 0.0);

    sh.setEngineState(true, 8400);
    sh.simulatedSpeedKmh = 162;
    sh.currentGear = 4;
    sh.steeringInput = 0.0;

    if (sh.tftMesh) {
      sh.tftMesh.position.set(-0.30, 0.94, 0.0);
      sh.tftMesh.rotation.set(0, Math.PI / 2, Math.PI / 4.8);
      sh.tftMesh.scale.set(1.4, 1.4, 1.4);
    }
  });
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'yamaha_r1m_first_person_cockpit.png') });
  console.log('✓ Saved yamaha_r1m_first_person_cockpit.png');

  // 2. High Speed Left Lean Cornering (248 km/h, 28 deg lean)
  console.log('2. Capturing High-Speed Left Corner Lean...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.setEngineState(true, 13400);
    sh.simulatedSpeedKmh = 248;
    sh.currentGear = 5;
    sh.steeringInput = -0.75;

    sh.leanAngle = 0.48; // ~28 deg roll
    sh.currentBikeGroup.rotation.x = -sh.leanAngle;
    sh.camera.position.set(0.42, 1.08, -0.05);
    sh.camera.lookAt(-2.8, 0.82, 0.65);
    sh.camera.rotation.z = sh.leanAngle * 0.45;
  });
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'yamaha_r1m_high_speed_lean_corner.png') });
  console.log('✓ Saved yamaha_r1m_high_speed_lean_corner.png');

  // 3. Ducati Panigale V4 S Cockpit
  console.log('3. Capturing Ducati Panigale V4 S Cockpit POV...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.loadVehicle('ducati_panigale_v4s_2024');
  });
  await sleep(4000);

  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.isRiderPov = false;
    if (sh.controls) sh.controls.enabled = false;
    sh.camera.fov = 74;
    sh.camera.updateProjectionMatrix();
    sh.camera.position.set(0.42, 1.08, 0.0);
    sh.camera.lookAt(-2.8, 0.82, 0.0);
    sh.currentBikeGroup.rotation.set(0, 0, 0);

    sh.setEngineState(true, 13800);
    sh.simulatedSpeedKmh = 274;
    sh.currentGear = 6;
    sh.steeringInput = 0.0;

    if (sh.tftMesh) {
      sh.tftMesh.position.set(-0.30, 0.94, 0.0);
      sh.tftMesh.rotation.set(0, Math.PI / 2, Math.PI / 4.8);
      sh.tftMesh.scale.set(1.4, 1.4, 1.4);
    }
  });
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'ducati_v4s_first_person_cockpit.png') });
  console.log('✓ Saved ducati_v4s_first_person_cockpit.png');

  // 4. BMW S 1000 RR (M Package) Redline Shift Flash
  console.log('4. Capturing BMW S 1000 RR Cockpit & Redline Shift Flash...');
  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.loadVehicle('bmw_s1000rr_m_2024');
  });
  await sleep(4000);

  await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    sh.isRiderPov = false;
    if (sh.controls) sh.controls.enabled = false;
    sh.camera.fov = 74;
    sh.camera.updateProjectionMatrix();
    sh.camera.position.set(0.42, 1.08, 0.0);
    sh.camera.lookAt(-2.8, 0.82, 0.0);
    sh.currentBikeGroup.rotation.set(0, 0, 0);

    sh.setEngineState(true, 14850);
    sh.simulatedSpeedKmh = 305;
    sh.currentGear = 6;
    sh.steeringInput = 0.0;
    sh.shiftFlash = 1.0;

    if (sh.tftMesh) {
      sh.tftMesh.position.set(-0.30, 0.94, 0.0);
      sh.tftMesh.rotation.set(0, Math.PI / 2, Math.PI / 4.8);
      sh.tftMesh.scale.set(1.4, 1.4, 1.4);
    }
  });
  await sleep(1500);
  await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'bmw_s1000rr_redline_shift_flash_cockpit.png') });
  console.log('✓ Saved bmw_s1000rr_redline_shift_flash_cockpit.png');

  await browser.close();
})();
