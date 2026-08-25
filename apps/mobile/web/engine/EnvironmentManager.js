/**
 * RideOS Pro — 3D Showroom Environment & Architectural Staging Engine
 * Builds a realistic, physically lit automotive command-center showroom
 * with reflective floor, curved architectural arches, neon light fins,
 * atmospheric dust particles, and holographic scanner for pending models.
 */

export class EnvironmentManager {
  constructor(scene) {
    this.scene = scene;
    this.environmentGroup = new THREE.Group();
    this.scene.add(this.environmentGroup);

    this.particles = null;
    this.particleVelocities = [];
    this.hologramGroup = new THREE.Group();
    this.environmentGroup.add(this.hologramGroup);
    this.hologramGroup.visible = false;

    this.turntable = null;
    this.neonRings = [];
    this.time = 0;

    this._buildAtmosphere();
    this._buildShowroomFloor();
    this._buildArchitecturalElements();
    this._buildAtmosphericParticles();
    this._buildHologramStage();
  }

  _buildAtmosphere() {
    // Soft cybernetic depth fog
    this.scene.fog = new THREE.FogExp2(0x030611, 0.032);
  }

  _buildShowroomFloor() {
    // 1. Base expansive floor (very dark metallic, high roughness)
    const floorGeo = new THREE.PlaneGeometry(80, 80, 32, 32);
    const floorMat = new THREE.MeshStandardMaterial({
      color: 0x040711,
      roughness: 0.28,
      metalness: 0.85,
      side: THREE.DoubleSide,
    });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -0.01;
    floor.receiveShadow = true;
    this.environmentGroup.add(floor);

    // 2. Center Circular Turntable Podium
    const turntableGeo = new THREE.CylinderGeometry(2.4, 2.5, 0.08, 64);
    const turntableMat = new THREE.MeshStandardMaterial({
      color: 0x080d1a,
      roughness: 0.15,
      metalness: 0.92,
    });
    this.turntable = new THREE.Mesh(turntableGeo, turntableMat);
    this.turntable.position.y = -0.04;
    this.turntable.receiveShadow = true;
    this.environmentGroup.add(this.turntable);

    // 3. Glowing Cyber Turntable Rim Ring
    const rimGeo = new THREE.RingGeometry(2.38, 2.45, 64);
    const rimMat = new THREE.MeshBasicMaterial({
      color: 0x00E5FF,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.85,
    });
    const rimRing = new THREE.Mesh(rimGeo, rimMat);
    rimRing.rotation.x = -Math.PI / 2;
    rimRing.position.y = 0.002;
    this.environmentGroup.add(rimRing);
    this.neonRings.push({ mesh: rimRing, baseOpacity: 0.85, speed: 1.2, color: 0x00E5FF });

    // 4. Secondary Outer Accent Ring (Violet)
    const outerRingGeo = new THREE.RingGeometry(3.6, 3.65, 64);
    const outerRingMat = new THREE.MeshBasicMaterial({
      color: 0x8A2BE2,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.45,
    });
    const outerRing = new THREE.Mesh(outerRingGeo, outerRingMat);
    outerRing.rotation.x = -Math.PI / 2;
    outerRing.position.y = 0.001;
    this.environmentGroup.add(outerRing);
    this.neonRings.push({ mesh: outerRing, baseOpacity: 0.45, speed: 0.8, color: 0x8A2BE2 });

    // 5. Grid Lines on floor around showroom
    const gridHelper = new THREE.GridHelper(24, 24, 0x00E5FF, 0x111c33);
    gridHelper.position.y = 0.001;
    gridHelper.material.opacity = 0.18;
    gridHelper.material.transparent = true;
    this.environmentGroup.add(gridHelper);

    // 6. Contact shadow disc underneath vehicle
    const shadowGeo = new THREE.PlaneGeometry(3.4, 1.6);
    const shadowCanvas = document.createElement('canvas');
    shadowCanvas.width = 256;
    shadowCanvas.height = 128;
    const ctx = shadowCanvas.getContext('2d');
    const gradient = ctx.createRadialGradient(128, 64, 10, 128, 64, 120);
    gradient.addColorStop(0, 'rgba(0,0,0,0.85)');
    gradient.addColorStop(0.5, 'rgba(0,0,0,0.4)');
    gradient.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 256, 128);

    const shadowTex = new THREE.CanvasTexture(shadowCanvas);
    const shadowMat = new THREE.MeshBasicMaterial({
      map: shadowTex,
      transparent: true,
      opacity: 0.75,
      depthWrite: false,
    });
    const shadowMesh = new THREE.Mesh(shadowGeo, shadowMat);
    shadowMesh.rotation.x = -Math.PI / 2;
    shadowMesh.position.y = 0.003;
    this.environmentGroup.add(shadowMesh);
  }

  _buildArchitecturalElements() {
    // 1. Curved Rear Architectural Rib Arches
    const archGroup = new THREE.Group();
    const archMaterial = new THREE.MeshStandardMaterial({
      color: 0x091224,
      roughness: 0.25,
      metalness: 0.88,
    });

    const neonArchMaterial = new THREE.MeshBasicMaterial({
      color: 0x00E5FF,
      transparent: true,
      opacity: 0.7,
    });

    const violetArchMaterial = new THREE.MeshBasicMaterial({
      color: 0x7928CA,
      transparent: true,
      opacity: 0.6,
    });

    // 3 Curved structural rib arches in background
    for (let i = 0; i < 3; i++) {
      const zOffset = -3.8 - i * 1.6;
      const radius = 4.8 + i * 0.8;
      const tubeGeo = new THREE.TorusGeometry(radius, 0.06, 16, 64, Math.PI);
      const arch = new THREE.Mesh(tubeGeo, archMaterial);
      arch.position.set(0, 0, zOffset);
      archGroup.add(arch);

      // Emissive strip on the arch
      const stripGeo = new THREE.TorusGeometry(radius + 0.08, 0.02, 8, 64, Math.PI);
      const strip = new THREE.Mesh(stripGeo, i % 2 === 0 ? neonArchMaterial : violetArchMaterial);
      strip.position.set(0, 0, zOffset);
      archGroup.add(strip);
    }
    this.environmentGroup.add(archGroup);

    // 2. Vertical Futuristic Light Columns in distance
    const colGeo = new THREE.CylinderGeometry(0.04, 0.04, 6, 16);
    const colMatCyan = new THREE.MeshBasicMaterial({
      color: 0x00F0FF,
      transparent: true,
      opacity: 0.35,
    });
    const colMatViolet = new THREE.MeshBasicMaterial({
      color: 0x9D00FF,
      transparent: true,
      opacity: 0.35,
    });

    const colPositions = [
      [-6, 3, -4],
      [6, 3, -4],
      [-9, 3, -7],
      [9, 3, -7],
      [-12, 3, -10],
      [12, 3, -10],
    ];

    colPositions.forEach((pos, idx) => {
      const col = new THREE.Mesh(colGeo, idx % 2 === 0 ? colMatCyan : colMatViolet);
      col.position.set(pos[0], pos[1], pos[2]);
      this.environmentGroup.add(col);
    });
  }

  _buildAtmosphericParticles() {
    const particleCount = 220;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(particleCount * 3);
    const colors = new Float32Array(particleCount * 3);

    const color1 = new THREE.Color(0x00F0FF); // Cyan
    const color2 = new THREE.Color(0x7928CA); // Violet
    const color3 = new THREE.Color(0xFF007A); // Pink

    for (let i = 0; i < particleCount; i++) {
      const i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 16;
      positions[i3 + 1] = Math.random() * 5 + 0.1;
      positions[i3 + 2] = (Math.random() - 0.5) * 16;

      this.particleVelocities.push({
        x: (Math.random() - 0.5) * 0.004,
        y: Math.random() * 0.003 + 0.001,
        z: (Math.random() - 0.5) * 0.004,
      });

      const choice = Math.random();
      const pColor = choice < 0.5 ? color1 : choice < 0.8 ? color2 : color3;
      colors[i3] = pColor.r;
      colors[i3 + 1] = pColor.g;
      colors[i3 + 2] = pColor.b;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    // Particle texture
    const pCanvas = document.createElement('canvas');
    pCanvas.width = 64;
    pCanvas.height = 64;
    const pCtx = pCanvas.getContext('2d');
    const pGrad = pCtx.createRadialGradient(32, 32, 0, 32, 32, 30);
    pGrad.addColorStop(0, 'rgba(255,255,255,1)');
    pGrad.addColorStop(0.3, 'rgba(255,255,255,0.8)');
    pGrad.addColorStop(0.7, 'rgba(255,255,255,0.2)');
    pGrad.addColorStop(1, 'rgba(255,255,255,0)');
    pCtx.fillStyle = pGrad;
    pCtx.fillRect(0, 0, 64, 64);
    const pTexture = new THREE.CanvasTexture(pCanvas);

    const material = new THREE.PointsMaterial({
      size: 0.09,
      map: pTexture,
      vertexColors: true,
      transparent: true,
      opacity: 0.75,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
    });

    this.particles = new THREE.Points(geometry, material);
    this.environmentGroup.add(this.particles);
  }

  _buildHologramStage() {
    // Holographic Scanner Pedestal for pending models
    // 1. Rotating concentric hologram rings
    const ring1Geo = new THREE.RingGeometry(1.2, 1.25, 48);
    const ring1Mat = new THREE.MeshBasicMaterial({
      color: 0x00E5FF,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.7,
    });
    this.holoRing1 = new THREE.Mesh(ring1Geo, ring1Mat);
    this.holoRing1.rotation.x = -Math.PI / 2;
    this.holoRing1.position.y = 0.05;
    this.hologramGroup.add(this.holoRing1);

    const ring2Geo = new THREE.RingGeometry(0.8, 0.84, 48);
    const ring2Mat = new THREE.MeshBasicMaterial({
      color: 0x7928CA,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.6,
    });
    this.holoRing2 = new THREE.Mesh(ring2Geo, ring2Mat);
    this.holoRing2.rotation.x = -Math.PI / 2;
    this.holoRing2.position.y = 0.12;
    this.hologramGroup.add(this.holoRing2);

    // 2. Hologram Scanner Cone / Cylinder
    const coneGeo = new THREE.CylinderGeometry(0.2, 1.4, 1.8, 32, 1, true);
    const coneMat = new THREE.MeshBasicMaterial({
      color: 0x00F0FF,
      transparent: true,
      opacity: 0.12,
      side: THREE.DoubleSide,
      wireframe: true,
    });
    this.holoCone = new THREE.Mesh(coneGeo, coneMat);
    this.holoCone.position.y = 0.95;
    this.hologramGroup.add(this.holoCone);

    // 3. Hologram Floating Motorcycle Silhouette (Wireframe Node Structure)
    const bikeWireGroup = new THREE.Group();

    // Wheel wireframes
    const wheelTorusGeo = new THREE.TorusGeometry(0.35, 0.04, 8, 24);
    const wireMatCyan = new THREE.MeshBasicMaterial({ color: 0x00E5FF, wireframe: true, transparent: true, opacity: 0.6 });
    const wireMatViolet = new THREE.MeshBasicMaterial({ color: 0x9D00FF, wireframe: true, transparent: true, opacity: 0.6 });

    const frontWheel = new THREE.Mesh(wheelTorusGeo, wireMatCyan);
    frontWheel.position.set(0, 0.35, 0.85);
    bikeWireGroup.add(frontWheel);

    const rearWheel = new THREE.Mesh(wheelTorusGeo, wireMatCyan);
    rearWheel.position.set(0, 0.35, -0.85);
    bikeWireGroup.add(rearWheel);

    // Chassis frame box
    const frameGeo = new THREE.BoxGeometry(0.35, 0.45, 1.1);
    const frameMesh = new THREE.Mesh(frameGeo, wireMatViolet);
    frameMesh.position.set(0, 0.65, 0);
    bikeWireGroup.add(frameMesh);

    // Tank / Handlebar wire
    const tankGeo = new THREE.ConeGeometry(0.25, 0.6, 6);
    const tankMesh = new THREE.Mesh(tankGeo, wireMatCyan);
    tankMesh.rotation.x = Math.PI / 4;
    tankMesh.position.set(0, 0.85, 0.35);
    bikeWireGroup.add(tankMesh);

    this.holoBike = bikeWireGroup;
    this.hologramGroup.add(this.holoBike);

    // 4. Scanning laser plane
    const scanPlaneGeo = new THREE.PlaneGeometry(2.4, 0.02);
    const scanPlaneMat = new THREE.MeshBasicMaterial({
      color: 0x00FFFF,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.8,
    });
    this.scanPlane = new THREE.Mesh(scanPlaneGeo, scanPlaneMat);
    this.scanPlane.rotation.x = -Math.PI / 2;
    this.scanPlane.position.y = 0.5;
    this.hologramGroup.add(this.scanPlane);
  }

  showHologramPlaceholder(show = true) {
    this.hologramGroup.visible = show;
  }

  update(delta) {
    this.time += delta;

    // Pulse neon rings
    this.neonRings.forEach(ring => {
      const pulse = Math.sin(this.time * ring.speed) * 0.2;
      ring.mesh.material.opacity = Math.max(0.2, ring.baseOpacity + pulse);
    });

    // Animate atmospheric particles
    if (this.particles) {
      const positions = this.particles.geometry.attributes.position.array;
      const count = positions.length / 3;

      for (let i = 0; i < count; i++) {
        const i3 = i * 3;
        const vel = this.particleVelocities[i];

        positions[i3] += vel.x;
        positions[i3 + 1] += vel.y;
        positions[i3 + 2] += vel.z;

        // Wrap around boundaries
        if (positions[i3 + 1] > 5.5) positions[i3 + 1] = 0.1;
        if (positions[i3] > 8) positions[i3] = -8;
        if (positions[i3] < -8) positions[i3] = 8;
        if (positions[i3 + 2] > 8) positions[i3 + 2] = -8;
        if (positions[i3 + 2] < -8) positions[i3 + 2] = 8;
      }
      this.particles.geometry.attributes.position.needsUpdate = true;
    }

    // Animate hologram elements if active
    if (this.hologramGroup.visible) {
      if (this.holoRing1) this.holoRing1.rotation.z += delta * 0.8;
      if (this.holoRing2) this.holoRing2.rotation.z -= delta * 1.1;
      if (this.holoCone) this.holoCone.rotation.y += delta * 0.4;
      if (this.holoBike) {
        this.holoBike.position.y = 0.05 + Math.sin(this.time * 2.0) * 0.04;
        this.holoBike.rotation.y += delta * 0.5;
      }
      if (this.scanPlane) {
        this.scanPlane.position.y = 0.2 + Math.abs(Math.sin(this.time * 2.5)) * 1.1;
      }
    }
  }

  dispose() {
    this.scene.remove(this.environmentGroup);
  }
}
