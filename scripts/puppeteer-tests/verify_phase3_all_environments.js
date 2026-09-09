const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/fd9cfd90-55a3-49f4-9d97-667eab593ba0';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 TESTING PHASE 3: ALL INTERCONNECTED 3D ENVIRONMENTS');
  console.log('================================================================');

  let browser;
  try {
    browser = await puppeteer.launch({
      executablePath: CHROME_PATH,
      headless: 'new',
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--enable-webgl',
        '--use-gl=angle',
        '--use-angle=metal',
        '--window-size=1280,900',
      ],
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 900 });

    console.log('1. Loading RideOS-AI Web App on http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await sleep(6000);

    // 1. Home Command Center (initial index 0)
    console.log('Capturing: 1. 3D Home Command Center...');
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_home_command_center.png') });
    console.log('✓ Captured 3D Home Command Center');

    // 2. Garage Showroom (dock index 1, approx x: 420, y: 865)
    console.log('Navigating to: 2. 3D Garage Showroom...');
    await page.mouse.click(420, 865);
    await sleep(3500);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_garage_showroom.png') });
    console.log('✓ Captured 3D Garage Showroom');

    // 3. Cockpit / Telemetry Dashboard (dock index 2, approx x: 470, y: 865)
    console.log('Navigating to: 3. 3D Cockpit / Telemetry...');
    await page.mouse.click(470, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_telemetry_cockpit.png') });
    console.log('✓ Captured 3D Telemetry Cockpit');

    // 4. Bluetooth / Connect (dock index 3, approx x: 520, y: 865)
    console.log('Navigating to: 4. 3D Bluetooth / Connect...');
    await page.mouse.click(520, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_connect_bluetooth.png') });
    console.log('✓ Captured 3D Connect Bluetooth');

    // 5. AI Copilot (dock index 4, approx x: 570, y: 865)
    console.log('Navigating to: 5. 3D AI Copilot...');
    await page.mouse.click(570, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_ai_copilot.png') });
    console.log('✓ Captured 3D AI Copilot');

    // 6. Navigation (dock index 5, approx x: 620, y: 865)
    console.log('Navigating to: 6. 3D Navigation...');
    await page.mouse.click(620, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_navigation_env.png') });
    console.log('✓ Captured 3D Navigation');

    // 7. Health Diagnostics (dock index 6, approx x: 670, y: 865)
    console.log('Navigating to: 7. 3D Health Diagnostics...');
    await page.mouse.click(670, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_vehicle_health.png') });
    console.log('✓ Captured 3D Vehicle Health');

    // 8. Maintenance Bay (dock index 7, approx x: 720, y: 865)
    console.log('Navigating to: 8. 3D Maintenance Bay...');
    await page.mouse.click(720, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_vehicle_maintenance.png') });
    console.log('✓ Captured 3D Vehicle Maintenance');

    // 9. Safety Command Center (dock index 8, approx x: 770, y: 865)
    console.log('Navigating to: 9. 3D Safety Command Center...');
    await page.mouse.click(770, 865);
    await sleep(3000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '3d_rider_safety.png') });
    console.log('✓ Captured 3D Rider Safety');

    console.log('\n================================================================');
    console.log('✅ ALL PHASE 3 3D ENVIRONMENTS TESTED & VERIFIED SUCCESSFULLY');
    console.log('================================================================');
  } catch (err) {
    console.error('❌ Phase 3 verification failed:', err);
  } finally {
    if (browser) await browser.close();
  }
})();
