const puppeteer = require('puppeteer-core');
const path = require('path');

async function captureRemainingScreens() {
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
  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await new Promise(r => setTimeout(r, 4000));

  const artifactDir = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/342e4fb3-fbfa-49f9-b38f-fcc690406762';

  // 1. Click Trips in sidebar (Y: ~365)
  console.log('Navigating to Trips...');
  await page.mouse.click(100, 365);
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({ path: path.join(artifactDir, 'screen_trips_exact.png') });

  // 2. Click Health in sidebar (Y: ~480)
  console.log('Navigating to Health...');
  await page.mouse.click(100, 480);
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({ path: path.join(artifactDir, 'screen_health_exact.png') });

  // 3. Click Safety in sidebar (Y: ~600)
  console.log('Navigating to Safety...');
  await page.mouse.click(100, 600);
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({ path: path.join(artifactDir, 'screen_safety_exact.png') });

  await browser.close();
  console.log('✅ Exact remaining screenshots captured!');
}

captureRemainingScreens().catch(console.error);
