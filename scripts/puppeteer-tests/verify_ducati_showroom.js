const puppeteer = require('puppeteer-core');

(async () => {
  console.log('Launching Chrome with WebGL support for Ducati verification...');
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
  await page.setCacheEnabled(false);

  page.on('console', msg => console.log('[Browser Console]', msg.type(), msg.text()));
  page.on('pageerror', err => console.error('[Browser Error]', err));

  console.log('Navigating to http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle0', timeout: 35000 });

  // 1. Wait 3s for compiled Welcome screen
  console.log('Waiting 3s for Welcome screen...');
  await new Promise(r => setTimeout(r, 3500));

  // 2. Click "SIGN IN TO COCKPIT" at (640, 765)
  console.log('Step 1: Clicking SIGN IN TO COCKPIT at (640, 765)...');
  await page.mouse.click(640, 765);
  await new Promise(r => setTimeout(r, 2000));

  // 3. Type credentials
  console.log('Step 2: Entering demo credentials...');
  await page.mouse.click(500, 415);
  await page.keyboard.type('demo@rideos.ai');
  await new Promise(r => setTimeout(r, 300));

  await page.mouse.click(500, 485);
  await page.keyboard.type('Password123!');
  await new Promise(r => setTimeout(r, 300));

  // 4. Click "START ENGINE (LOGIN)" at (500, 570)
  console.log('Step 3: Clicking START ENGINE (LOGIN)...');
  await page.mouse.click(500, 570);
  await new Promise(r => setTimeout(r, 5000));

  // 5. Click "3D Garage" in sidebar at (80, 265)
  console.log('Step 4: Clicking 3D Garage in Sidebar at (80, 265)...');
  await page.mouse.click(80, 265);
  await new Promise(r => setTimeout(r, 5000));

  // 6. Click Ducati Panigale V4 S card at (518, 175)
  console.log('Step 5: Selecting Ducati Panigale V4 S card at (518, 175)...');
  await page.mouse.click(518, 175);
  await new Promise(r => setTimeout(r, 7000));

  // 7. Capture rendered Ducati Panigale V4 S Showroom
  const screenshotPath1 = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf/ducati_panigale_showroom_final.png';
  await page.screenshot({ path: screenshotPath1 });
  console.log(`Saved Ducati showroom screenshot to ${screenshotPath1}`);

  // 8. Test 360° interactive rotation: Drag canvas
  console.log('Step 6: Rotating 3D camera 360° for Ducati inspection...');
  await page.mouse.move(700, 450);
  await page.mouse.down();
  await page.mouse.move(960, 410, { steps: 35 });
  await page.mouse.up();
  await new Promise(r => setTimeout(r, 2000));

  const screenshotPath2 = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf/ducati_panigale_showroom_rotated.png';
  await page.screenshot({ path: screenshotPath2 });
  console.log(`Saved Ducati rotated screenshot to ${screenshotPath2}`);

  await browser.close();
  console.log('Ducati verification completed successfully.');
})();
