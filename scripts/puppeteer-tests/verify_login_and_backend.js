const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/8c0a271f-1b71-4306-b897-950330c14eb4';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🔐 TESTING BACKEND CONNECTIVITY & LOGIN FLOW');
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

    const failedRequests = [];
    const consoleErrors = [];

    page.on('requestfailed', (req) => {
      failedRequests.push(`${req.method()} ${req.url()} - ${req.failure()?.errorText}`);
    });

    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    console.log('1. Loading http://localhost:8080...');
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await page.evaluate(() => {
      localStorage.setItem('flutter.onboarding_completed', 'true');
    });
    await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
    await sleep(4000);

    console.log('2. Testing in-browser API reachability to http://localhost:3000/api/v1/health...');
    const apiHealthCheck = await page.evaluate(async () => {
      try {
        const res = await fetch('http://localhost:3000/api/v1/health');
        const data = await res.json();
        return { ok: res.ok, status: res.status, data };
      } catch (err) {
        return { ok: false, error: err.toString() };
      }
    });
    console.log('   In-Browser Health Check Result:', apiHealthCheck);

    console.log('3. Testing in-browser Login API call to http://localhost:3000/api/v1/auth/login...');
    const apiLoginCheck = await page.evaluate(async () => {
      try {
        const res = await fetch('http://localhost:3000/api/v1/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: 'demo@rideos.ai', password: 'Password123!' }),
        });
        const data = await res.json();
        return { ok: res.ok, status: res.status, riderEmail: data?.rider?.email, hasTokens: !!data?.tokens };
      } catch (err) {
        return { ok: false, error: err.toString() };
      }
    });
    console.log('   In-Browser Login API Result:', apiLoginCheck);

    console.log('4. Checking for failed network requests or connection errors...');
    console.log('   Failed Requests:', failedRequests);
    console.log('   Console Errors:', consoleErrors);

    const screenshotPath = path.join(ARTIFACTS_DIR, 'backend_connectivity_verified.png');
    await page.screenshot({ path: screenshotPath });
    console.log('✓ Captured screenshot to:', screenshotPath);

    console.log('\n================================================================');
    console.log('✅ BACKEND CONNECTIVITY & LOGIN VERIFICATION COMPLETE');
    console.log('================================================================');
  } catch (err) {
    console.error('❌ Test failed:', err);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
})();
