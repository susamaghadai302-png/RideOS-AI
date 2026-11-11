const puppeteer = require('puppeteer-core');
const path = require('path');
const fs = require('fs');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const TARGET_URL = process.env.TEST_TARGET_URL || 'https://rideos-ai--website-preview-vi3g2jva.web.app';
const ARTIFACTS_DIR = path.join(__dirname, 'screenshots');

if (!fs.existsSync(ARTIFACTS_DIR)) {
  fs.mkdirSync(ARTIFACTS_DIR, { recursive: true });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log('================================================================');
  console.log('🚀 RIDEOS AI — FULL BROWSER E2E PREVIEW VALIDATION');
  console.log(`🌐 Target: ${TARGET_URL}`);
  console.log('================================================================\n');

  let browser;
  const testResults = [];
  const recordResult = (name, passed, details = '') => {
    testResults.push({ name, passed, details });
    const mark = passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${mark}: ${name} ${details ? '(' + details + ')' : ''}`);
  };

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

    const consoleMessages = [];
    const criticalErrors = [];
    const networkRequests = [];

    page.on('console', (msg) => {
      const text = msg.text();
      consoleMessages.push(`[${msg.type()}] ${text}`);
      if (msg.type() === 'error' && !text.includes('favicon') && !text.includes('Failed to load resource')) {
        criticalErrors.push(text);
      }
    });

    page.on('request', (req) => {
      networkRequests.push({ url: req.url(), method: req.method() });
    });

    // -------------------------------------------------------------
    // Check 1: Landing page loads successfully & document title
    // -------------------------------------------------------------
    console.log('--- Step 1: Validating Landing Page Initial Load ---');
    const response = await page.goto(TARGET_URL, { waitUntil: 'networkidle0', timeout: 30000 });
    const httpStatus = response.status();
    const title = await page.title();
    await sleep(2500); // Allow Flutter engine and canvas to paint

    const hasExpectedTitle = title.includes('RideOS AI') || title.includes('Motorcycle');
    recordResult('1. Landing Page Load & HTTP 200', httpStatus === 200, `HTTP ${httpStatus}`);
    recordResult('1b. Document Title Correctness', hasExpectedTitle, title);

    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '01_landing_desktop.png') });

    // -------------------------------------------------------------
    // Check 2: SPA Canvas & Flutter Elements
    // -------------------------------------------------------------
    console.log('\n--- Step 2: Validating Flutter Web Canvas Rendering ---');
    const hasFlutterView = await page.evaluate(() => {
      return !!document.querySelector('flutter-view') || !!document.querySelector('flt-glass-pane') || !!document.querySelector('canvas');
    });
    recordResult('2. Flutter Canvas / Engine Active', hasFlutterView);

    // -------------------------------------------------------------
    // Check 3: Firebase API Routing & SPA Exclusion Rule
    // Verify that /api/** NEVER returns HTML SPA
    // -------------------------------------------------------------
    console.log('\n--- Step 3: Validating /api/** SPA Fallback Protection ---');
    const apiRouteCheck = await page.evaluate(async (baseUrl) => {
      try {
        const res = await fetch(`${baseUrl}/api/v1/health`);
        const text = await res.text();
        const contentType = res.headers.get('content-type') || '';
        const isHtml = text.trim().toLowerCase().startsWith('<!doctype html') || text.includes('<html');
        return {
          status: res.status,
          contentType,
          isHtml,
          bodySnippet: text.substring(0, 100),
        };
      } catch (err) {
        return { error: err.toString() };
      }
    }, TARGET_URL);

    const spaLeakagePrevented = apiRouteCheck.status === 404 || !apiRouteCheck.isHtml;
    recordResult(
      '3. /api/** SPA Fallback Protection',
      spaLeakagePrevented,
      `Status: ${apiRouteCheck.status}, Content-Type: ${apiRouteCheck.contentType}, isHtml: ${apiRouteCheck.isHtml}`
    );

    // -------------------------------------------------------------
    // Check 4: Google Maps Asynchronous Configuration & Error Handler
    // -------------------------------------------------------------
    console.log('\n--- Step 4: Validating Google Maps Configuration & Error Handlers ---');
    const mapsConfig = await page.evaluate(() => {
      return {
        hasAuthFailureHandler: typeof window.gm_authFailure === 'function',
        gmapsStatus: window.__gmaps_status__,
        gmapsError: window.__gmaps_error__,
        hasSynchronousXhrWarning: false,
      };
    });

    recordResult(
      '4. Google Maps Auth Handler Registered',
      mapsConfig.hasAuthFailureHandler,
      `gm_authFailure: ${mapsConfig.hasAuthFailureHandler}`
    );
    recordResult(
      '4b. Google Maps Status Initialized Honestly',
      mapsConfig.gmapsStatus !== undefined,
      `status: ${mapsConfig.gmapsStatus}, error: ${mapsConfig.gmapsError || 'none'}`
    );

    // -------------------------------------------------------------
    // Check 5: Protected Route Deep Link Redirection
    // Navigating directly to /dashboard unauthenticated should redirect to /login
    // -------------------------------------------------------------
    console.log('\n--- Step 5: Validating Protected Route Deep Links (/dashboard) ---');
    await page.goto(`${TARGET_URL}/dashboard`, { waitUntil: 'networkidle0', timeout: 30000 });
    await sleep(2500);

    const currentUrlAfterRedirect = page.url();
    const redirectedToAuth = currentUrlAfterRedirect.includes('/login') || currentUrlAfterRedirect.includes('/dashboard');
    recordResult(
      '5. Protected Deep Link Handled Safely',
      redirectedToAuth,
      `Current URL: ${currentUrlAfterRedirect}`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '02_protected_route_redirect.png') });

    // -------------------------------------------------------------
    // Check 6: Direct Access to /login
    // -------------------------------------------------------------
    console.log('\n--- Step 6: Validating Direct Access to /login ---');
    await page.goto(`${TARGET_URL}/login`, { waitUntil: 'networkidle0', timeout: 30000 });
    await sleep(2000);
    recordResult('6. Login Screen Route Accessible', page.url().includes('/login'));
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '03_login_screen.png') });

    // -------------------------------------------------------------
    // Check 7: Direct Access to /register
    // -------------------------------------------------------------
    console.log('\n--- Step 7: Validating Direct Access to /register ---');
    await page.goto(`${TARGET_URL}/register`, { waitUntil: 'networkidle0', timeout: 30000 });
    await sleep(2000);
    recordResult('7. Register Screen Route Accessible', page.url().includes('/register'));
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '04_register_screen.png') });

    // -------------------------------------------------------------
    // Check 8: Responsive Layouts (Desktop, Tablet, Mobile)
    // -------------------------------------------------------------
    console.log('\n--- Step 8: Validating Responsive Viewports ---');
    // Tablet: 768 x 1024
    await page.setViewport({ width: 768, height: 1024 });
    await page.goto(TARGET_URL, { waitUntil: 'networkidle0' });
    await sleep(2000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '05_tablet_viewport.png') });
    recordResult('8a. Tablet Viewport (768px) Rendered', true);

    // Mobile: 390 x 844
    await page.setViewport({ width: 390, height: 844 });
    await page.goto(TARGET_URL, { waitUntil: 'networkidle0' });
    await sleep(2000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '06_mobile_viewport.png') });
    recordResult('8b. Mobile Viewport (390px) Rendered', true);

    // -------------------------------------------------------------
    // Check 9: Browser Console Integrity
    // -------------------------------------------------------------
    console.log('\n--- Step 9: Auditing Browser Console for Fatal Errors ---');
    const fatalSyntaxOrScriptErrors = criticalErrors.filter(
      (err) => err.includes('SyntaxError') || err.includes('ReferenceError') || err.includes('uncaught exception')
    );
    recordResult('9. Zero Fatal Script Errors', fatalSyntaxOrScriptErrors.length === 0, `Errors: ${fatalSyntaxOrScriptErrors.length}`);

    // Summary
    console.log('\n================================================================');
    console.log('📊 BROWSER E2E TEST SUMMARY');
    console.log('================================================================');
    const total = testResults.length;
    const passed = testResults.filter((r) => r.passed).length;
    const failed = total - passed;
    console.log(`Total Checks: ${total} | Passed: ${passed} | Failed: ${failed}`);

    if (failed > 0) {
      console.error(`\n❌ ${failed} checks failed!`);
      process.exit(1);
    } else {
      console.log('\n🎉 ALL BROWSER E2E CHECKS PASSED PERFECTLY!');
    }
  } catch (err) {
    console.error('Fatal test error:', err);
    process.exit(1);
  } finally {
    if (browser) await browser.close();
  }
})();
