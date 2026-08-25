const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ARTIFACTS_DIR = '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf';

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

  const testCameras = [
    { name: 'cam1_high_saddle', pos: [0.08, 1.35, 0.02], look: [2.5, 0.85, 0.02], fov: 65 },
    { name: 'cam2_mid_saddle', pos: [0.08, 1.22, 0.02], look: [2.5, 0.80, 0.02], fov: 70 },
    { name: 'cam3_over_shoulder', pos: [-0.45, 1.38, 0.25], look: [1.8, 0.85, 0.02], fov: 60 },
    { name: 'cam4_cockpit_view', pos: [0.20, 1.18, 0.02], look: [2.5, 0.80, 0.02], fov: 75 },
    { name: 'cam5_front_three_quarter', pos: [2.0, 1.10, 1.8], look: [0.15, 0.60, 0.02], fov: 45 },
  ];

  for (const c of testCameras) {
    await page.evaluate((cam) => {
      const sh = window.RideOS3D.showroom;
      sh.isRiderPov = false; // disable animate override
      if (sh.controls) sh.controls.enabled = false;
      sh.camera.fov = cam.fov;
      sh.camera.updateProjectionMatrix();
      sh.camera.position.set(cam.pos[0], cam.pos[1], cam.pos[2]);
      sh.camera.lookAt(cam.look[0], cam.look[1], cam.look[2]);
    }, c);
    await sleep(1000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, `${c.name}.png`) });
    console.log(`✓ Saved ${c.name}.png`);
  }

  await browser.close();
})();
