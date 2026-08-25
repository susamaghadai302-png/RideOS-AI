const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/8c0a271f-1b71-4306-b897-950330c14eb4';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🗺️  TESTING GOOGLE MAPS RENDERING IN RIDEOS AI APP');
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

    const errors = [];
    const logs = [];

    page.on('console', (msg) => {
      const text = msg.text();
      logs.push(`[${msg.type()}] ${text}`);
      if (msg.type() === 'error') {
        errors.push(text);
      }
    });

    console.log('1. Navigating to http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    
    console.log('2. Waiting 5s for Flutter Engine initialization...');
    await sleep(5000);

    // Check window.google and window.google.maps
    const mapsStatus = await page.evaluate(() => {
      return {
        hasGoogle: typeof window.google !== 'undefined',
        hasGoogleMaps: typeof window.google !== 'undefined' && typeof window.google.maps !== 'undefined',
        hasMapsLoaded: typeof window.google !== 'undefined' && typeof window.google.maps?.Map === 'function',
      };
    });

    console.log('3. Window Google Maps Object status:', mapsStatus);

    console.log('4. Performing Quick Login to Cockpit...');
    // Click Sign In
    await page.mouse.click(640, 790);
    await sleep(2000);

    // Fill credentials
    await page.mouse.click(500, 415);
    await sleep(200);
    await page.keyboard.type('demo@rideos.ai');
    await sleep(200);

    await page.mouse.click(500, 485);
    await sleep(200);
    await page.keyboard.type('Password123!');
    await sleep(200);

    // Submit
    await page.mouse.click(640, 570);
    await sleep(4000);

    console.log('5. Clicking on Navigation Tab in Sidebar...');
    // In RoadOSAppShell, the sidebar has Navigation item around y=390
    await page.mouse.click(100, 390);
    await sleep(4000);

    // Check if DOM contains map elements or flutter canvas
    const domInfo = await page.evaluate(() => {
      const fltElements = document.querySelectorAll('flt-scene, flt-glass-pane, canvas, iframe');
      return {
        elementCount: fltElements.length,
        hasCanvas: document.querySelectorAll('canvas').length > 0,
        title: document.title,
      };
    });

    console.log('6. DOM Inspection Result:', domInfo);

    const screenshotPath = path.join(ARTIFACTS_DIR, 'maps_verification_result.png');
    await page.screenshot({ path: screenshotPath });
    console.log('✓ Screenshot saved to:', screenshotPath);

    console.log('7. Console Log Summary:');
    logs.slice(-15).forEach((l) => console.log('  ', l));

    console.log('\n================================================================');
    console.log('✅ GOOGLE MAPS INTEGRATION TEST COMPLETE');
    console.log('================================================================');
  } catch (err) {
    console.error('❌ Test failed with exception:', err);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
})();
