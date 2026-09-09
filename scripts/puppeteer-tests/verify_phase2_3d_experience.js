const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/fd9cfd90-55a3-49f4-9d97-667eab593ba0';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 TESTING SPATIAL 3D AUTOMOTIVE OPERATING SYSTEM');
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

    console.log('1. Loading RideOS Web App on http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await sleep(6000);

    // 1. Capture 3D Home Command Center (initial screen)
    const homeShot = path.join(ARTIFACTS_DIR, '3d_home_command_center.png');
    await page.screenshot({ path: homeShot });
    console.log('✓ Captured 3D Home Command Center Screenshot to:', homeShot);

    // 2. Click "3D Garage" in the floating bottom spatial dock (approx x: 440, y: 865)
    console.log('2. Navigating to 3D Garage Showroom...');
    await page.mouse.click(440, 865);
    await sleep(3500);

    const garageShot = path.join(ARTIFACTS_DIR, '3d_garage_showroom.png');
    await page.screenshot({ path: garageShot });
    console.log('✓ Captured 3D Garage Showroom Screenshot to:', garageShot);

    // 3. Click "Cockpit" in the floating bottom spatial dock (approx x: 530, y: 865)
    console.log('3. Navigating to 3D Cockpit / Telemetry Dashboard...');
    await page.mouse.click(530, 865);
    await sleep(3000);

    const telemetryShot = path.join(ARTIFACTS_DIR, '3d_telemetry_cockpit.png');
    await page.screenshot({ path: telemetryShot });
    console.log('✓ Captured 3D Telemetry Cockpit Screenshot to:', telemetryShot);

    // 4. Click "Connect" in the floating bottom spatial dock (approx x: 610, y: 865)
    console.log('4. Navigating to 3D Connect / Scanner...');
    await page.mouse.click(610, 865);
    await sleep(3000);

    const connectShot = path.join(ARTIFACTS_DIR, '3d_connect_bluetooth.png');
    await page.screenshot({ path: connectShot });
    console.log('✓ Captured 3D Connect Bluetooth Screenshot to:', connectShot);

    console.log('\n================================================================');
    console.log('✅ ALL SPATIAL 3D SCREENS CAPTURED SUCCESSFULLY');
    console.log('================================================================');
  } catch (err) {
    console.error('❌ Verification failed:', err);
  } finally {
    if (browser) await browser.close();
  }
})();
