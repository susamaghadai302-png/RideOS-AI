const http = require('http');

function get(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    }).on('error', reject);
  });
}

function post(url, payload) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(payload);
    const u = new URL(url);
    const options = {
      hostname: u.hostname,
      port: u.port,
      path: u.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: data }));
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

(async () => {
  console.log('================================================================');
  console.log('🧪 RIDEOS-AI: END-TO-END DYNAMIC 3D DIGITAL TWIN SYSTEM TEST');
  console.log('================================================================\n');

  // Test 1: Verify all 5 3D GLBs and Thumbnails on web server
  const assets = [
    'assets/models/yamaha_mt09_sp.glb',
    'assets/garage/yamaha_mt09_sp.png',
    'assets/models/yamaha_r1m.glb',
    'assets/garage/yamaha_r1m.png',
    'assets/models/ducati_panigale.glb',
    'assets/garage/ducati_panigale.png',
    'assets/models/bmw_m1000rr.glb',
    'assets/garage/bmw_m1000rr.png',
    'assets/models/suzuki_burgman.glb',
    'assets/garage/suzuki_burgman.png',
    'assets/garage/generic_obd.png',
  ];

  console.log('1. Verifying Static 3D GLB Models and Studio Thumbnails:');
  for (const asset of assets) {
    const res = await get(`http://localhost:8080/${asset}`);
    if (res.statusCode === 200) {
      console.log(`  ✓ [200 OK] http://localhost:8080/${asset} (${res.headers['content-length']} bytes)`);
    } else {
      console.error(`  ✗ [FAILED ${res.statusCode}] http://localhost:8080/${asset}`);
      process.exit(1);
    }
  }

  // Test 2: Pre-seeded system digital twin retrieval
  console.log('\n2. Testing Pre-seeded Digital Twin Endpoint (GET /api/v1/digital-twin/:id):');
  const getRes = await get('http://localhost:3000/api/v1/digital-twin/vt_mt09sp_system');
  console.log(`  HTTP ${getRes.statusCode}:`, getRes.body);
  if (getRes.statusCode !== 200) {
    console.error('  ✗ Failed to retrieve pre-seeded twin!');
    process.exit(1);
  }

  // Test 3: On-demand dynamic digital twin reconstruction for unlisted vehicle
  console.log('\n3. Testing Dynamic 3D Digital Twin Reconstruction (POST /api/v1/digital-twin/reconstruct):');
  const customVehiclePayload = {
    vehicleId: 'v_custom_tvs_apache_310',
    manufacturer: 'TVS',
    model: 'Apache RTR 310',
    variant: 'Dynamic Twin',
    year: 2024,
    category: 'Motorcycle',
    targetQuality: 'ULTRA',
    frameCount: 36,
  };

  const reconRes = await post('http://localhost:3000/api/v1/digital-twin/reconstruct', customVehiclePayload);
  console.log(`  HTTP ${reconRes.statusCode}:`, reconRes.body);
  const twin = JSON.parse(reconRes.body);
  if (reconRes.statusCode !== 201 && reconRes.statusCode !== 200 || !twin.twinId) {
    console.error('  ✗ Failed to reconstruct digital twin!');
    process.exit(1);
  }
  console.log(`  ✓ Reconstructed Twin ID: ${twin.twinId}, Quality: ${twin.quality}, Polygon Count: ${twin.meshStats.polygonCount}`);

  // Test 4: Privacy Photo Purge
  console.log('\n4. Testing Privacy Photo Purge (POST /api/v1/digital-twin/privacy/purge-photos/:twinId):');
  const purgeRes = await post(`http://localhost:3000/api/v1/digital-twin/privacy/purge-photos/${twin.twinId}`, {});
  console.log(`  HTTP ${purgeRes.statusCode}:`, purgeRes.body);
  const purgeData = JSON.parse(purgeRes.body);
  if (!purgeData.success) {
    console.error('  ✗ Failed to purge source photos!');
    process.exit(1);
  }
  console.log('  ✓ Privacy photo purge successfully verified!');

  console.log('\n================================================================');
  console.log('🎉 ALL DYNAMIC 3D DIGITAL TWIN SYSTEM TESTS PASSED WITH 100% SUCCESS!');
  console.log('================================================================');
})();
