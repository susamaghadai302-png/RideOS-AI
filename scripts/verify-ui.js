const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

async function main() {
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--use-gl=angle',
      '--use-angle=metal',
      '--enable-webgl',
      '--enable-features=WebGL2ComputeContext',
      '--window-size=1440,900'
    ],
    defaultViewport: { width: 1440, height: 900 }
  });

  const page = await browser.newPage();

  const consoleLogs = [];
  page.on('console', msg => {
    consoleLogs.push(`[${msg.type()}] ${msg.text()}`);
  });

  page.on('pageerror', err => {
    consoleLogs.push(`[PAGE ERROR] ${err.toString()}`);
  });

  console.log('Navigating to http://localhost:8080 ...');
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle2', timeout: 30000 });

  console.log('Waiting 3s for Flutter rendering...');
  await new Promise(r => setTimeout(r, 3000));

  // Click SKIP if onboarding screen is present (top right corner ~ 1380, 40)
  console.log('Clicking SKIP on onboarding...');
  await page.mouse.click(1380, 40);
  await new Promise(r => setTimeout(r, 2000));

  // If still on auth / welcome, click login or guest / skip
  // Or evaluate Flutter click / keyboard enter
  await page.keyboard.press('Enter');
  await new Promise(r => setTimeout(r, 3000));

  const artifactDir = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/342e4fb3-fbfa-49f9-b38f-fcc690406762';
  const screenshotMainPath = path.join(artifactDir, 'rideos_pro_dashboard_view.png');
  await page.screenshot({ path: screenshotMainPath, fullPage: false });
  console.log(`Saved main dashboard view to: ${screenshotMainPath}`);

  // Switch to My Vehicles (sidebar tile 2 ~ x: 60, y: 155)
  console.log('Navigating to My Vehicles...');
  await page.mouse.click(80, 155);
  await new Promise(r => setTimeout(r, 2500));

  const screenshotVehiclesPath = path.join(artifactDir, 'rideos_pro_my_vehicles_view.png');
  await page.screenshot({ path: screenshotVehiclesPath, fullPage: false });
  console.log(`Saved My Vehicles view to: ${screenshotVehiclesPath}`);

  // Switch to 3D Garage (sidebar tile 4 ~ x: 60, y: 260)
  console.log('Navigating to 3D Garage...');
  await page.mouse.click(80, 260);
  await new Promise(r => setTimeout(r, 3000));

  const screenshotGaragePath = path.join(artifactDir, 'rideos_pro_3d_garage_view.png');
  await page.screenshot({ path: screenshotGaragePath, fullPage: false });
  console.log(`Saved 3D Garage view to: ${screenshotGaragePath}`);

  console.log('\n--- BROWSER CONSOLE LOGS ---');
  consoleLogs.slice(-25).forEach(log => console.log(log));

  await browser.close();
}

main().catch(err => {
  console.error('Puppeteer verification failed:', err);
  process.exit(1);
});
