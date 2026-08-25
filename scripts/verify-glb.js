const puppeteer = require('puppeteer-core');
const path = require('path');

async function testGlbModel() {
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--use-gl=angle',
      '--use-angle=metal',
      '--enable-webgl',
      '--window-size=1440,900'
    ],
    defaultViewport: { width: 1440, height: 900 }
  });

  const page = await browser.newPage();
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle2' });
  await new Promise(r => setTimeout(r, 3000));

  // Directly tell Three.js to load the verified BMW M1000RR / S1000RR GLB model
  console.log('Invoking window.RideOS3D.loadVehicleProfile with BMW S 1000 RR...');
  const loadResult = await page.evaluate(() => {
    if (window.RideOS3D) {
      window.RideOS3D.loadVehicleProfile({
        id: 'v_bmw_s1000rr_2024',
        model3DUrl: 'assets/models/bmw_s1000rr.glb',
        manufacturer: 'BMW Motorrad',
        model: 'S 1000 RR'
      });
      window.RideOS3D.setCameraPreset('garage');
      window.RideOS3D.setLightingMode('cyberpunk');
      return { success: true, activePreset: 'garage' };
    }
    return { success: false };
  });

  console.log('Load Result:', loadResult);
  await new Promise(r => setTimeout(r, 4000));

  const artifactDir = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/342e4fb3-fbfa-49f9-b38f-fcc690406762';
  const screenshotModelPath = path.join(artifactDir, 'rideos_pro_bmw_s1000rr_loaded.png');
  await page.screenshot({ path: screenshotModelPath, fullPage: false });
  console.log(`Saved BMW model screenshot to: ${screenshotModelPath}`);

  // Test Camera Cockpit & Engine Presets
  await page.evaluate(() => {
    if (window.RideOS3D) {
      window.RideOS3D.setCameraPreset('cockpit');
    }
  });
  await new Promise(r => setTimeout(r, 2000));
  const screenshotCockpitPath = path.join(artifactDir, 'rideos_pro_cockpit_view.png');
  await page.screenshot({ path: screenshotCockpitPath, fullPage: false });
  console.log(`Saved cockpit view screenshot to: ${screenshotCockpitPath}`);

  await browser.close();
}

testGlbModel().catch(console.error);
