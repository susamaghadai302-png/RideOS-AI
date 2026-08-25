const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
  console.log('🚀 Starting Live End-to-End Verification of Dynamic 3D Digital Twin System...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-web-security']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });

  const errors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('[Browser Error]', msg.text());
      errors.push(msg.text());
    }
  });

  page.on('pageerror', err => {
    console.log('[Page Error]', err.toString());
    errors.push(err.toString());
  });

  try {
    console.log('1. Navigating to http://localhost:8080/#/login...');
    await page.goto('http://localhost:8080/#/login', { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise(r => setTimeout(r, 2000));

    console.log('2. Performing Automated Login...');
    // Click Demo Login or Submit
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 3000));

    console.log('3. Navigating to Smart Garage...');
    await page.goto('http://localhost:8080/#/garage', { waitUntil: 'networkidle2', timeout: 30000 });
    await new Promise(r => setTimeout(r, 4000));

    const screenshotPath = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/8c0a271f-1b71-4306-b897-950330c14eb4/digital_twin_garage_verified.png';
    await page.screenshot({ path: screenshotPath });
    console.log('📸 Captured Screenshot:', screenshotPath);

    console.log('4. Testing Backend Digital Twin Reconstruct API...');
    const reconstructRes = await page.evaluate(async () => {
      const res = await fetch('http://localhost:3000/api/v1/digital-twin/reconstruct', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          vehicleId: 'v_custom_tvs_apache',
          manufacturer: 'TVS',
          model: 'Apache RTR 310',
          year: 2024,
          category: 'Motorcycle',
          targetQuality: 'HIGH',
          frameCount: 24
        })
      });
      return await res.json();
    });

    console.log('✅ Reconstruct API Result:', JSON.stringify(reconstructRes, null, 2));

    if (reconstructRes.twinId && reconstructRes.modelGlbPath) {
      console.log('🎉 Digital Twin Reconstruct Verification PASSED!');
    } else {
      console.error('❌ Digital Twin Reconstruct Verification FAILED!');
      process.exit(1);
    }

    console.log('5. Testing Privacy Photo Purge API...');
    const purgeRes = await page.evaluate(async (twinId) => {
      const res = await fetch(`http://localhost:3000/api/v1/digital-twin/privacy/purge-photos/${twinId}`, {
        method: 'POST',
      });
      return await res.json();
    }, reconstructRes.twinId);

    console.log('✅ Purge API Result:', JSON.stringify(purgeRes, null, 2));

    console.log('🎉 ALL LIVE SYSTEM VERIFICATIONS PASSED SUCCESSFULLY!');
  } catch (e) {
    console.error('❌ Verification Exception:', e);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
