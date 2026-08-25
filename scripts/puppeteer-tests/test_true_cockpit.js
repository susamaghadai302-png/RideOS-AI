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

  const testAngles = [
    { name: 'true_rider_pov_standard', pos: [0.18, 1.14, 0.02], look: [-2.5, 0.82, 0.02], fov: 68 },
    { name: 'true_rider_pov_tuck_in', pos: [0.08, 1.06, 0.02], look: [-2.5, 0.80, 0.02], fov: 72 },
    { name: 'true_rider_pov_high_chin', pos: [0.25, 1.22, 0.02], look: [-2.5, 0.85, 0.02], fov: 65 },
  ];

  for (const c of testAngles) {
    await page.evaluate((cam) => {
      const sh = window.RideOS3D.showroom;
      sh.isRiderPov = false;
      if (sh.controls) sh.controls.enabled = false;
      sh.camera.fov = cam.fov;
      sh.camera.updateProjectionMatrix();
      sh.camera.position.set(cam.pos[0], cam.pos[1], cam.pos[2]);
      sh.camera.lookAt(cam.look[0], cam.look[1], cam.look[2]);

      // Position TFT dashboard in front of handlebars
      if (sh.tftMesh) {
        sh.tftMesh.position.set(-0.48, 0.94, 0.02);
        sh.tftMesh.rotation.set(0, Math.PI / 2, Math.PI / 5.2);
        sh.tftMesh.scale.set(1.4, 1.4, 1.4);
      }
    }, c);
    await sleep(1000);
    await page.screenshot({ path: path.join(ARTIFACTS_DIR, `${c.name}.png`) });
    console.log(`✓ Saved ${c.name}.png`);
  }

  await browser.close();
})();
