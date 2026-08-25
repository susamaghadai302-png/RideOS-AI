const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/8c0a271f-1b71-4306-b897-950330c14eb4';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🗺️  END-TO-END VERIFICATION: NAVIGATING DIRECTLY TO MAP SCREEN');
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

    console.log('1. Setting localStorage and loading app...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.setItem('flutter.onboarding_completed', 'true');
    });
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await sleep(4000);

    console.log('2. Clicking "Sign In to Cockpit" at (640, 755)...');
    await page.mouse.click(640, 755);
    await sleep(2500);

    await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step2_login_screen.png') });
    console.log('✓ Captured step2_login_screen.png');

    console.log('3. Clicking Google Sign-in on Login Screen at (540, 680)...');
    await page.mouse.click(540, 680);
    await sleep(4000);

    await page.screenshot({ path: path.join(ARTIFACTS_DIR, 'step3_after_login.png') });
    console.log('✓ Captured step3_after_login.png');

    console.log('4. Clicking "Navigation" in sidebar at (100, 390)...');
    await page.mouse.click(100, 390);
    await sleep(4000);

    const mapScreenshot = path.join(ARTIFACTS_DIR, 'google_maps_active_tiles.png');
    await page.screenshot({ path: mapScreenshot });
    console.log('✓ Captured Navigation Screen screenshot:', mapScreenshot);

    const verificationResults = await page.evaluate(() => {
      return {
        hasGoogle: typeof window.google !== 'undefined',
        hasGoogleMaps: typeof window.google?.maps !== 'undefined',
        hasPlacesApi: typeof window.google?.maps?.places !== 'undefined',
        hasGeometryApi: typeof window.google?.maps?.geometry !== 'undefined',
        hasGeocodingApi: typeof window.google?.maps?.Geocoder === 'function',
        hasDirectionsApi: typeof window.google?.maps?.DirectionsService === 'function',
        hasMapConstructor: typeof window.google?.maps?.Map === 'function',
        apiKeyPrefix: typeof window.__RIDEOS_GOOGLE_MAPS_API_KEY__ === 'string' 
          ? window.__RIDEOS_GOOGLE_MAPS_API_KEY__.slice(0, 4) + '...' 
          : 'None',
      };
    });

    console.log('5. Google Maps Platform Verification Results:', verificationResults);
  } catch (err) {
    console.error('❌ Verification failed:', err);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
})();
