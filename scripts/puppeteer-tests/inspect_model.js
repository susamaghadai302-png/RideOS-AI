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

  const modelInfo = await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    const box = new THREE.Box3().setFromObject(sh.currentBikeGroup);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    return {
      size: { x: size.x, y: size.y, z: size.z },
      center: { x: center.x, y: center.y, z: center.z },
      bikePos: { x: sh.currentBikeGroup.position.x, y: sh.currentBikeGroup.position.y, z: sh.currentBikeGroup.position.z },
      bikeRot: { x: sh.currentBikeGroup.rotation.x, y: sh.currentBikeGroup.rotation.y, z: sh.currentBikeGroup.rotation.z },
      wheelCount: sh.wheelMeshes.length,
      wheels: sh.wheelMeshes.map(m => ({ name: m.name, pos: m.position })),
    };
  });

  console.log('MODEL INSPECTION:', JSON.stringify(modelInfo, null, 2));
  await browser.close();
})();
