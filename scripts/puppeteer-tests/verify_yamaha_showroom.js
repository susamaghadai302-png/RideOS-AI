const puppeteer = require('puppeteer-core');

(async () => {
  console.log('Launching Chrome with WebGL support...');
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--enable-webgl',
      '--use-gl=angle',
      '--use-angle=metal',
      '--window-size=1280,950'
    ]
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  page.on('console', msg => console.log('[Browser Console]', msg.type(), msg.text()));
  page.on('pageerror', err => console.error('[Browser Error]', err));

  console.log('Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle0', timeout: 30000 });

  // Wait 3 seconds for Welcome screen
  await new Promise(r => setTimeout(r, 3000));

  // 1. Click "SIGN IN TO COCKPIT" at (640, 765)
  console.log('Clicking SIGN IN TO COCKPIT at (640, 765)...');
  await page.mouse.click(640, 765);
  await new Promise(r => setTimeout(r, 2000));

  // 2. Type email and password on Login Screen
  console.log('Typing email demo@rideos.ai...');
  await page.mouse.click(500, 415);
  await page.keyboard.type('demo@rideos.ai');
  await new Promise(r => setTimeout(r, 400));

  console.log('Typing password Password123!...');
  await page.mouse.click(500, 485);
  await page.keyboard.type('Password123!');
  await new Promise(r => setTimeout(r, 400));

  // Click "START ENGINE (LOGIN)" at (500, 570)
  console.log('Clicking START ENGINE (LOGIN)...');
  await page.mouse.click(500, 570);
  await new Promise(r => setTimeout(r, 4000));

  // 3. Click on "3D Garage" in sidebar at EXACT coordinate (80, 265)
  console.log('Clicking 3D Garage in Sidebar at (80, 265)...');
  await page.mouse.click(80, 265);
  await new Promise(r => setTimeout(r, 6000));

  // 4. Capture rendered Yamaha 3D Showroom
  const screenshotPath1 = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf/yamaha_r1m_showroom_final.png';
  await page.screenshot({ path: screenshotPath1 });
  console.log(`Saved showroom screenshot to ${screenshotPath1}`);

  // 5. Test 360° interactive rotation: Drag canvas
  console.log('Rotating 3D camera 360°...');
  await page.mouse.move(700, 450);
  await page.mouse.down();
  await page.mouse.move(960, 410, { steps: 35 });
  await page.mouse.up();
  await new Promise(r => setTimeout(r, 2000));

  const screenshotPath2 = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf/yamaha_r1m_showroom_rotated.png';
  await page.screenshot({ path: screenshotPath2 });
  console.log(`Saved rotated screenshot to ${screenshotPath2}`);

  await browser.close();
  console.log('Verification completed successfully.');
})();
