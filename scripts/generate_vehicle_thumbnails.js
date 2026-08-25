const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const GARAGE_DIR = path.join(__dirname, '../apps/mobile/assets/garage');

(async () => {
  console.log('================================================================');
  console.log('📸 GENERATING DEDICATED 3D VEHICLE STUDIO THUMBNAILS');
  console.log('================================================================');

  const browser = await puppeteer.launch({
    executablePath: CHROME_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--enable-webgl', '--window-size=800,600'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 800, height: 600 });

  await page.setContent(`
    <!DOCTYPE html>
    <html>
      <head>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/DRACOLoader.js"></script>
        <style>
          body { margin: 0; overflow: hidden; background: transparent; }
          canvas { width: 800px; height: 600px; }
        </style>
      </head>
      <body>
        <div id="container"></div>
      </body>
    </html>
  `);

  const vehicles = [
    {
      id: 'yamaha_mt09_sp',
      modelFile: 'yamaha_mt09_sp.glb',
      outFile: 'yamaha_mt09_sp.png',
      camPos: [2.2, 1.1, 2.6],
    },
    {
      id: 'suzuki_burgman',
      modelFile: 'suzuki_burgman.glb',
      outFile: 'suzuki_burgman.png',
      camPos: [2.0, 1.0, 2.4],
    },
    {
      id: 'bmw_m1000rr',
      modelFile: 'bmw_m1000rr.glb',
      outFile: 'bmw_m1000rr.png',
      camPos: [2.4, 1.2, 2.8],
    },
    {
      id: 'generic_obd',
      outFile: 'generic_obd.png',
      isObd: true,
    }
  ];

  for (const v of vehicles) {
    if (v.isObd) {
      // Generate clean OBD-II telematics badge icon
      const obdPngBase64 = await page.evaluate(() => {
        const canvas = document.createElement('canvas');
        canvas.width = 800;
        canvas.height = 600;
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, 800, 600);

        // Gradient rounded badge
        const grad = ctx.createLinearGradient(150, 100, 650, 500);
        grad.addColorStop(0, '#0f172a');
        grad.addColorStop(1, '#020617');
        ctx.fillStyle = grad;
        ctx.strokeStyle = '#00f0ff';
        ctx.lineWidth = 4;
        
        ctx.beginPath();
        ctx.roundRect(200, 120, 400, 360, 32);
        ctx.fill();
        ctx.stroke();

        // Glowing text & OBD Icon
        ctx.fillStyle = '#00f0ff';
        ctx.font = 'bold 36px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('UNIVERSAL OBD-II', 400, 240);

        ctx.fillStyle = '#94a3b8';
        ctx.font = '500 20px sans-serif';
        ctx.fillText('CAN-BUS Telemetry Dongle', 400, 290);
        ctx.fillText('ISO 15765-4 / SAE J1939', 400, 330);

        ctx.fillStyle = '#10b981';
        ctx.font = 'bold 18px sans-serif';
        ctx.fillText('● COMPATIBLE INTERFACE', 400, 400);

        return canvas.toDataURL('image/png').split(',')[1];
      });

      const outPath = path.join(GARAGE_DIR, v.outFile);
      fs.writeFileSync(outPath, Buffer.from(obdPngBase64, 'base64'));
      console.log(`✓ Generated Universal OBD-II Thumbnail: ${outPath}`);
      continue;
    }

    const modelPath = path.join(__dirname, '../apps/mobile/assets/models', v.modelFile);
    if (!fs.existsSync(modelPath)) {
      console.warn(`Model not found for ${v.id}: ${modelPath}`);
      continue;
    }

    const modelBase64 = fs.readFileSync(modelPath).toString('base64');

    const pngBase64 = await page.evaluate(async (base64, camPos) => {
      const container = document.getElementById('container');
      container.innerHTML = '';

      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(40, 800 / 600, 0.1, 100);
      camera.position.set(camPos[0], camPos[1], camPos[2]);

      const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true, preserveDrawingBuffer: true });
      renderer.setSize(800, 600);
      renderer.setPixelRatio(2);
      renderer.toneMapping = THREE.ACESFilmicToneMapping;
      renderer.toneMappingExposure = 1.2;
      container.appendChild(renderer.domElement);

      // Studio Lighting
      const ambientLight = new THREE.AmbientLight(0xffffff, 1.2);
      scene.add(ambientLight);

      const keyLight = new THREE.DirectionalLight(0xffffff, 2.5);
      keyLight.position.set(5, 8, 5);
      scene.add(keyLight);

      const cyanRim = new THREE.DirectionalLight(0x00f0ff, 1.8);
      cyanRim.position.set(-5, 3, -5);
      scene.add(cyanRim);

      const loader = new THREE.GLTFLoader();
      const dracoLoader = new THREE.DRACOLoader();
      dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.6/');
      loader.setDRACOLoader(dracoLoader);

      const arrayBuffer = Uint8Array.from(atob(base64), c => c.charCodeAt(0)).buffer;

      return new Promise((resolve) => {
        loader.parse(arrayBuffer, '', (gltf) => {
          const model = gltf.scene;

          // Auto center & align
          const box = new THREE.Box3().setFromObject(model);
          const center = box.getCenter(new THREE.Vector3());
          model.position.x -= center.x;
          model.position.y -= box.min.y;
          model.position.z -= center.z;

          scene.add(model);

          camera.lookAt(0, (box.max.y - box.min.y) * 0.45, 0);
          renderer.render(scene, camera);

          resolve(renderer.domElement.toDataURL('image/png').split(',')[1]);
        });
      });
    }, modelBase64, v.camPos);

    const outPath = path.join(GARAGE_DIR, v.outFile);
    fs.writeFileSync(outPath, Buffer.from(pngBase64, 'base64'));
    console.log(`✓ Rendered studio thumbnail: ${outPath} (${(fs.statSync(outPath).size / 1024).toFixed(1)} KB)`);
  }

  await browser.close();
  console.log('\n================================================================');
  console.log('✅ ALL DEDICATED VEHICLE THUMBNAILS CREATED SUCCESSFULLY');
  console.log('================================================================');
})();
