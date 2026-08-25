const puppeteer = require('puppeteer-core');
const path = require('path');

async function verifyFullRedesign() {
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
  
  page.on('console', msg => console.log(`[Browser Console]: ${msg.text()}`));
  page.on('pageerror', err => console.error(`[Browser PageError]: ${err.toString()}`));

  console.log('Navigating to http://localhost:8080 ...');
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded', timeout: 15000 });
  await new Promise(r => setTimeout(r, 3500));

  const artifactDir = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/342e4fb3-fbfa-49f9-b38f-fcc690406762';

  // 1. Screenshot My Vehicles (Reference Flagship Screen)
  const myVehiclesPath = path.join(artifactDir, 'redesign_01_my_vehicles.png');
  await page.screenshot({ path: myVehiclesPath, fullPage: false });
  console.log(`✅ Saved My Vehicles screenshot to: ${myVehiclesPath}`);

  // 2. Click Home nav item in sidebar (approx coordinates on 1440x900)
  // Left sidebar nav items:
  // Home is the first item under MAIN
  console.log('Navigating to Home (3D Command Center)...');
  await page.mouse.click(100, 115); // Click Home in sidebar
  await new Promise(r => setTimeout(r, 2000));
  const homePath = path.join(artifactDir, 'redesign_02_home_command_center.png');
  await page.screenshot({ path: homePath, fullPage: false });
  console.log(`✅ Saved Home 3D Command Center screenshot to: ${homePath}`);

  // 3. Click 3D Garage in sidebar
  console.log('Navigating to 3D Garage Showroom...');
  await page.mouse.click(100, 275); // Click 3D Garage
  await new Promise(r => setTimeout(r, 2000));
  const garagePath = path.join(artifactDir, 'redesign_03_3d_garage.png');
  await page.screenshot({ path: garagePath, fullPage: false });
  console.log(`✅ Saved 3D Garage screenshot to: ${garagePath}`);

  // 4. Click Live Dashboard in sidebar
  console.log('Navigating to Live Digital Cockpit...');
  await page.mouse.click(100, 320); // Click Live Dashboard
  await new Promise(r => setTimeout(r, 2000));
  const cockpitPath = path.join(artifactDir, 'redesign_04_live_cockpit.png');
  await page.screenshot({ path: cockpitPath, fullPage: false });
  console.log(`✅ Saved Live Cockpit screenshot to: ${cockpitPath}`);

  // 5. Click Trips in sidebar
  console.log('Navigating to Trips & Route Telemetry...');
  await page.mouse.click(100, 395); // Click Trips
  await new Promise(r => setTimeout(r, 2000));
  const tripsPath = path.join(artifactDir, 'redesign_05_trips_telemetry.png');
  await page.screenshot({ path: tripsPath, fullPage: false });
  console.log(`✅ Saved Trips screenshot to: ${tripsPath}`);

  // 6. Click Health in sidebar
  console.log('Navigating to 3D Health Diagnostics...');
  await page.mouse.click(100, 515); // Click Health
  await new Promise(r => setTimeout(r, 2000));
  const healthPath = path.join(artifactDir, 'redesign_06_health_diagnostics.png');
  await page.screenshot({ path: healthPath, fullPage: false });
  console.log(`✅ Saved Health Diagnostics screenshot to: ${healthPath}`);

  // 7. Click Maintenance in sidebar
  console.log('Navigating to 3D Maintenance Service Bay...');
  await page.mouse.click(100, 560); // Click Maintenance
  await new Promise(r => setTimeout(r, 2000));
  const maintenancePath = path.join(artifactDir, 'redesign_07_maintenance_bay.png');
  await page.screenshot({ path: maintenancePath, fullPage: false });
  console.log(`✅ Saved Maintenance Service Bay screenshot to: ${maintenancePath}`);

  // 8. Click Safety in sidebar
  console.log('Navigating to Safety Command Center...');
  await page.mouse.click(100, 640); // Click Safety
  await new Promise(r => setTimeout(r, 2000));
  const safetyPath = path.join(artifactDir, 'redesign_08_safety_center.png');
  await page.screenshot({ path: safetyPath, fullPage: false });
  console.log(`✅ Saved Safety Command Center screenshot to: ${safetyPath}`);

  await browser.close();
  console.log('🎉 Full application redesign screenshot verification complete!');
}

verifyFullRedesign().catch(console.error);
