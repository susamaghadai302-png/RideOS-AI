const puppeteer = require('puppeteer-core');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--enable-webgl'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  await page.goto('http://localhost:8080', { waitUntil: 'domcontentloaded' });
  await sleep(6000);
  await page.mouse.click(640, 870);
  await sleep(3500);
  await page.mouse.click(80, 265);
  await sleep(4000);

  const beforePreset = await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    return {
      camPos: sh.camera.position,
      camRot: sh.camera.rotation,
      fov: sh.camera.fov,
      isRiderPov: sh.isRiderPov,
      bikePos: sh.currentBikeGroup ? sh.currentBikeGroup.position : null,
    };
  });
  console.log('BEFORE PRESET:', JSON.stringify(beforePreset, null, 2));

  await page.evaluate(() => {
    window.RideOS3D.showroom.setCameraPreset('riderPov');
  });
  await sleep(1000);

  const afterPreset = await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    return {
      camPos: sh.camera.position,
      camRot: sh.camera.rotation,
      fov: sh.camera.fov,
      isRiderPov: sh.isRiderPov,
      bikePos: sh.currentBikeGroup ? sh.currentBikeGroup.position : null,
    };
  });
  console.log('AFTER PRESET:', JSON.stringify(afterPreset, null, 2));

  await browser.close();
})();
