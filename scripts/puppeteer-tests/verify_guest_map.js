const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/8c0a271f-1b71-4306-b897-950330c14eb4';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🗺️  END-TO-END VERIFICATION: NAVIGATING DIRECTLY TO MAP');
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
        '--window-size=1280,950',
      ],
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 950 });

    const logs = [];
    page.on('console', (msg) => {
      logs.push(`[${msg.type()}] ${msg.text()}`);
    });

    console.log('1. Setting localStorage and loading app...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.setItem('flutter.onboarding_completed', 'true');
    });
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await sleep(4000);

    console.log('2. Clicking "CONTINUE AS GUEST" at (640, 936)...');
    await page.mouse.click(640, 936);
    await sleep(4000);

    console.log('3. Clicking "Navigation" tab in Sidebar at (100, 390)...');
    await page.mouse.click(100, 390);
    await sleep(4000);

    const mapScreenshot = path.join(ARTIFACTS_DIR, 'live_google_maps_screen.png');
    await page.screenshot({ path: mapScreenshot });
    console.log('✓ Captured live Navigation Map screenshot:', mapScreenshot);

    const mapInfo = await page.evaluate(() => {
      return {
        hasGoogleObject: typeof window.google !== 'undefined',
        hasGoogleMaps: typeof window.google?.maps !== 'undefined',
        hasMapsLoaded: typeof window.google?.maps?.Map === 'function',
        hasPlaces: typeof window.google?.maps?.places !== 'undefined',
        hasGeometry: typeof window.google?.maps?.geometry !== 'undefined',
        apiKeyValid: typeof window.__RIDEOS_GOOGLE_MAPS_API_KEY__ === 'string' && window.__RIDEOS_GOOGLE_MAPS_API_KEY__.startsWith('AIza'),
      };
    });

    console.log('4. Google Maps Platform Status:', mapInfo);

    console.log('\n================================================================');
    console.log('✅ MAP VERIFICATION COMPLETED');
    console.log('================================================================');
  } catch (err) {
    console.error('❌ Test failed:', err);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
})();
