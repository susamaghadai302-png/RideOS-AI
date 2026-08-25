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

  const bikeGeometryInfo = await page.evaluate(() => {
    const sh = window.RideOS3D.showroom;
    const meshes = [];
    sh.currentBikeGroup.traverse((child) => {
      if (child.isMesh) {
        const box = new THREE.Box3().setFromObject(child);
        const center = box.getCenter(new THREE.Vector3());
        const size = box.getSize(new THREE.Vector3());
        meshes.push({
          name: child.name,
          center: { x: center.x.toFixed(3), y: center.y.toFixed(3), z: center.z.toFixed(3) },
          size: { x: size.x.toFixed(3), y: size.y.toFixed(3), z: size.z.toFixed(3) },
        });
      }
    });

    const entireBox = new THREE.Box3().setFromObject(sh.currentBikeGroup);
    return {
      totalMeshes: meshes.length,
      entireBounds: {
        min: entireBox.min,
        max: entireBox.max,
        center: entireBox.getCenter(new THREE.Vector3()),
        size: entireBox.getSize(new THREE.Vector3()),
      },
      top10Meshes: meshes.slice(0, 15),
    };
  });

  console.log('BIKE GEOMETRY BOUNDS:', JSON.stringify(bikeGeometryInfo, null, 2));
  await browser.close();
})();
