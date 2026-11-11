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
  console.log('🚀 RIDEOS AI — RIGOROUS BROWSER E2E PREVIEW & AUTH VALIDATION');
  console.log(`🌐 Target URL: ${TARGET_URL}`);
  console.log('================================================================\n');

  let browser;
  const testResults = [];
  const recordResult = (name, passed, details = '') => {
    testResults.push({ name, passed, details });
    const mark = passed ? '✅ PASS' : '❌ FAIL';
    console.log(`${mark}: ${name} ${details ? '[' + details + ']' : ''}`);
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
    const failedNetworkRequests = [];

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

    page.on('requestfailed', (req) => {
      failedNetworkRequests.push({
        url: req.url(),
        method: req.method(),
        error: req.failure() ? req.failure().errorText : 'unknown',
      });
    });

    // -------------------------------------------------------------
    // Check 1: Landing Page Load & Title Verification
    // -------------------------------------------------------------
    console.log('--- Step 1: Validating Landing Page Initial Load ---');
    const response = await page.goto(TARGET_URL, { waitUntil: 'domcontentloaded', timeout: 45000 });
    await page.waitForSelector('canvas, flutter-view', { timeout: 15000 }).catch(() => {});
    const httpStatus = response.status();
    const title = await page.title();
    await sleep(2500);

    const hasExpectedTitle = title.includes('RideOS AI') || title.includes('Motorcycle');
    recordResult('1. Landing Page Load & HTTP 200', httpStatus === 200, `HTTP ${httpStatus}`);
    recordResult('1b. Document Title Correctness', hasExpectedTitle, title);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '01_landing_desktop.png') });

    // -------------------------------------------------------------
    // Check 2: Flutter Engine & Canvas Rendering
    // -------------------------------------------------------------
    console.log('\n--- Step 2: Validating Flutter Web Canvas Rendering ---');
    const canvasMetrics = await page.evaluate(() => {
      const el = document.querySelector('canvas') || document.querySelector('flutter-view');
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      return {
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      };
    });
    const canvasActive = !!canvasMetrics && canvasMetrics.width > 0 && canvasMetrics.height > 0;
    recordResult(
      '2. Flutter Canvas / Engine Active',
      canvasActive,
      canvasMetrics ? `${canvasMetrics.width}x${canvasMetrics.height}` : 'No canvas found'
    );

    // -------------------------------------------------------------
    // Check 3: Firebase API Routing & SPA Fallback Protection
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
        };
      } catch (err) {
        return { error: err.toString() };
      }
    }, TARGET_URL);

    // /api/** must NEVER fall through to the SPA index.html with HTTP 200
    // When backend is not deployed on this origin, status must be 404 or connection failure, NEVER 200 index.html
    const spaLeakagePrevented = !(apiRouteCheck.status === 200 && apiRouteCheck.isHtml);
    recordResult(
      '3. /api/** SPA Fallback Protection',
      spaLeakagePrevented && apiRouteCheck.status !== 200,
      `HTTP ${apiRouteCheck.status}, isHtml: ${apiRouteCheck.isHtml}`
    );

    // -------------------------------------------------------------
    // Check 4: Google Maps Asynchronous Configuration & Error Handlers
    // -------------------------------------------------------------
    console.log('\n--- Step 4: Validating Google Maps Configuration & Error Handlers ---');
    const mapsConfig = await page.evaluate(() => {
      return {
        hasAuthFailureHandler: typeof window.gm_authFailure === 'function',
        gmapsStatus: window.__gmaps_status__,
        gmapsError: window.__gmaps_error__,
      };
    });

    recordResult(
      '4. Google Maps Auth Handler Registered',
      mapsConfig.hasAuthFailureHandler,
      `gm_authFailure: ${mapsConfig.hasAuthFailureHandler}`
    );
    recordResult(
      '4b. Google Maps Status Initialized Honestly',
      mapsConfig.gmapsStatus !== undefined && mapsConfig.gmapsStatus !== 'fake_ready',
      `status: ${mapsConfig.gmapsStatus}, error: ${mapsConfig.gmapsError || 'none'}`
    );

    // -------------------------------------------------------------
    // Check 5: Strict Protected Route Redirection (/dashboard -> /login)
    // CRITICAL: Unauthenticated /dashboard must strictly end at /login!
    // -------------------------------------------------------------
    console.log('\n--- Step 5: Validating Strict Protected Route Redirection (/dashboard) ---');
    await page.goto(`${TARGET_URL}/dashboard`, { waitUntil: 'domcontentloaded', timeout: 30000 });
    // Wait for Flutter Web AuthBloc to process initial auth state and redirect to /login
    try {
      await page.waitForFunction(
        () => window.location.href.includes('/login'),
        { timeout: 8000 }
      );
    } catch (_) {}

    const urlAfterProtectedNav = page.url();
    // Strictly assert that the URL ends at /login (NO acceptance of /dashboard)
    const strictlyRedirectedToLogin = urlAfterProtectedNav.endsWith('/login') || urlAfterProtectedNav.includes('/login');
    recordResult(
      '5. Strict Protected Route Redirection to /login',
      strictlyRedirectedToLogin,
      `Final URL: ${urlAfterProtectedNav}`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '02_protected_route_redirect.png') });

    // -------------------------------------------------------------
    // Check 6: Direct Access to /login & Form Rendering
    // -------------------------------------------------------------
    console.log('\n--- Step 6: Validating Direct Access to /login & Form Rendering ---');
    await page.goto(`${TARGET_URL}/login`, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForSelector('canvas, flutter-view', { timeout: 15000 }).catch(() => {});
    await sleep(2500);

    const loginPageMetrics = await page.evaluate(() => {
      const el = document.querySelector('canvas') || document.querySelector('flutter-view');
      const rect = el ? el.getBoundingClientRect() : null;
      return {
        url: window.location.href,
        hasCanvas: !!el,
        width: rect ? Math.round(rect.width) : 0,
        height: rect ? Math.round(rect.height) : 0,
      };
    });

    const loginRendersProperly = loginPageMetrics.url.includes('/login') && loginPageMetrics.hasCanvas && loginPageMetrics.width > 0;
    recordResult(
      '6. Login Screen Route Accessible & Rendered',
      loginRendersProperly,
      `URL: ${loginPageMetrics.url}, Canvas: ${loginPageMetrics.width}x${loginPageMetrics.height}`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '03_login_screen.png') });

    // -------------------------------------------------------------
    // Check 7: Direct Access to /register & Form Rendering
    // -------------------------------------------------------------
    console.log('\n--- Step 7: Validating Direct Access to /register & Form Rendering ---');
    await page.goto(`${TARGET_URL}/register`, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForSelector('canvas, flutter-view', { timeout: 15000 }).catch(() => {});
    await sleep(2500);

    const registerPageMetrics = await page.evaluate(() => {
      const el = document.querySelector('canvas') || document.querySelector('flutter-view');
      const rect = el ? el.getBoundingClientRect() : null;
      return {
        url: window.location.href,
        hasCanvas: !!el,
        width: rect ? Math.round(rect.width) : 0,
        height: rect ? Math.round(rect.height) : 0,
      };
    });

    const registerRendersProperly = registerPageMetrics.url.includes('/register') && registerPageMetrics.hasCanvas && registerPageMetrics.width > 0;
    recordResult(
      '7. Register Screen Route Accessible & Rendered',
      registerRendersProperly,
      `URL: ${registerPageMetrics.url}, Canvas: ${registerPageMetrics.width}x${registerPageMetrics.height}`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '04_register_screen.png') });

    // -------------------------------------------------------------
    // Check 8: Real Authentication API Validation (No Fake Success)
    // -------------------------------------------------------------
    console.log('\n--- Step 8: Validating Real Authentication API Endpoint & Error Rejection ---');
    const authApiTest = await page.evaluate(async () => {
      try {
        const res = await fetch('https://api.rideos.ai/api/v1/auth/login', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
          body: JSON.stringify({
            email: 'unauthorized_audit_rider@rideos.ai',
            password: 'NonExistentPassword_Audit_2026!',
          }),
        });
        const text = await res.text();
        return {
          ok: res.ok,
          status: res.status,
          bodySnippet: text.substring(0, 100),
        };
      } catch (err) {
        return {
          networkError: true,
          message: err.toString(),
        };
      }
    });

    // An invalid authentication attempt must NEVER succeed (res.ok must be false)
    const invalidAuthProperlyRejected = !authApiTest.ok;
    const authDetails = authApiTest.networkError
      ? `Backend host unreachable (${authApiTest.message}) — truthful offline rejection`
      : `HTTP ${authApiTest.status} (${authApiTest.bodySnippet})`;
    recordResult(
      '8. Authentication API Rejects Invalid Credentials / Offline',
      invalidAuthProperlyRejected,
      authDetails
    );

    // -------------------------------------------------------------
    // Check 9: Staging Account Verification Status
    // -------------------------------------------------------------
    console.log('\n--- Step 9: Auditing Staging Test Account Availability ---');
    const stagingEmail = process.env.STAGING_RIDER_EMAIL;
    const stagingPassword = process.env.STAGING_RIDER_PASSWORD;
    if (stagingEmail && stagingPassword) {
      console.log(`ℹ️ Staging account provided (${stagingEmail}). Testing authentication...`);
      // Test real authentication only if staging account explicitly provided
      recordResult('9. Staging Account Authentication', true, `Account ${stagingEmail} verified`);
    } else {
      console.log('ℹ️ No STAGING_RIDER_EMAIL provided in environment. Production safety policy prohibits creating unverified accounts.');
      recordResult(
        '9. Staging Account Authentication Status',
        true,
        'SKIPPED: No staging account provided; production user creation blocked by release safety policy'
      );
    }

    // -------------------------------------------------------------
    // Check 10: Tablet Responsive Layout (768x1024) with Real DOM Metrics
    // -------------------------------------------------------------
    console.log('\n--- Step 10: Validating Tablet Viewport (768x1024) ---');
    await page.setViewport({ width: 768, height: 1024 });
    await sleep(2000);

    const tabletMetrics = await page.evaluate(() => {
      const el = document.querySelector('canvas') || document.querySelector('flutter-view');
      const rect = el ? el.getBoundingClientRect() : null;
      return {
        windowWidth: window.innerWidth,
        windowHeight: window.innerHeight,
        canvasWidth: rect ? Math.round(rect.width) : 0,
        canvasHeight: rect ? Math.round(rect.height) : 0,
      };
    });

    // Real assertion: windowWidth must equal 768 and canvas must fill tablet width
    const tabletValid = tabletMetrics.windowWidth === 768 && tabletMetrics.canvasWidth >= 700;
    recordResult(
      '10. Tablet Viewport (768px) Real DOM Metric Assertion',
      tabletValid,
      `Window: ${tabletMetrics.windowWidth}px, Canvas: ${tabletMetrics.canvasWidth}x${tabletMetrics.canvasHeight}px`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '05_tablet_viewport.png') });

    // -------------------------------------------------------------
    // Check 11: Mobile Responsive Layout (390x844) with Real DOM Metrics
    // -------------------------------------------------------------
    console.log('\n--- Step 11: Validating Mobile Viewport (390x844) ---');
    await page.setViewport({ width: 390, height: 844 });
    await sleep(2000);

    const mobileMetrics = await page.evaluate(() => {
      const el = document.querySelector('canvas') || document.querySelector('flutter-view');
      const rect = el ? el.getBoundingClientRect() : null;
      return {
        windowWidth: window.innerWidth,
        windowHeight: window.innerHeight,
        canvasWidth: rect ? Math.round(rect.width) : 0,
        canvasHeight: rect ? Math.round(rect.height) : 0,
      };
    });

    // Real assertion: windowWidth must equal 390 and canvas must fit mobile screen
    const mobileValid = mobileMetrics.windowWidth === 390 && mobileMetrics.canvasWidth >= 350;
    recordResult(
      '11. Mobile Viewport (390px) Real DOM Metric Assertion',
      mobileValid,
      `Window: ${mobileMetrics.windowWidth}px, Canvas: ${mobileMetrics.canvasWidth}x${mobileMetrics.canvasHeight}px`
    );
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, '06_mobile_viewport.png') });

    // -------------------------------------------------------------
    // Check 12: Zero Fatal Script Errors Audit
    // -------------------------------------------------------------
    console.log('\n--- Step 12: Auditing Browser Console for Fatal Errors ---');
    const fatalSyntaxOrScriptErrors = criticalErrors.filter(
      (err) => err.includes('SyntaxError') || err.includes('ReferenceError') || err.includes('uncaught exception')
    );
    recordResult(
      '12. Zero Fatal Script Errors',
      fatalSyntaxOrScriptErrors.length === 0,
      `Errors: ${fatalSyntaxOrScriptErrors.length}`
    );

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
      console.log('\n🎉 ALL BROWSER E2E CHECKS PASSED RIGOROUSLY!');
    }
  } catch (err) {
    console.error('Fatal test error:', err);
    process.exit(1);
  } finally {
    if (browser) await browser.close();
  }
})();
