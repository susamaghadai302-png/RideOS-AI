/**
 * RideOS Pro — Realistic Physically Based Automotive Lighting Engine
 * Provides multiple cinematic showroom lighting rigs with soft shadows,
 * realistic light falloff, and dynamic ambient lighting.
 */

export class LightingManager {
  constructor(scene) {
    this.scene = scene;
    this.lightsGroup = new THREE.Group();
    this.scene.add(this.lightsGroup);
    this.lights = [];
    this.currentMode = 'studio';
    this.setupShowroom();
  }

  setLightingMode(mode) {
    this.currentMode = mode;
    this.clearLights();

    switch (mode) {
      case 'dark':
      case 'cyberpunk':
        this._setupCyberpunkMode();
        break;
      case 'performance':
        this._setupPerformanceMode();
        break;
      case 'cinematic':
      case 'sunset':
        this._setupCinematicMode();
        break;
      case 'studio':
      default:
        this._setupStudioMode();
        break;
    }
  }

  _setupStudioMode() {
    // 1. Soft Ambient Fill
    const ambient = new THREE.AmbientLight(0xddeeff, 0.45);
    this.lightsGroup.add(ambient);
    this.lights.push(ambient);

    // 2. Main Key SpotLight (Bright white with soft penumbra & shadows)
    const keyLight = new THREE.SpotLight(0xffffff, 3.2);
    keyLight.position.set(3.2, 5.0, 3.2);
    keyLight.angle = Math.PI / 5;
    keyLight.penumbra = 0.5;
    keyLight.decay = 2;
    keyLight.castShadow = true;
    keyLight.shadow.mapSize.width = 2048;
    keyLight.shadow.mapSize.height = 2048;
    keyLight.shadow.bias = -0.0001;
    keyLight.shadow.camera.near = 0.5;
    keyLight.shadow.camera.far = 15;
    this.lightsGroup.add(keyLight);
    this.lights.push(keyLight);

    // 3. Cool Skylight Fill Light (Directional)
    const fillLight = new THREE.DirectionalLight(0x00d2ff, 1.2);
    fillLight.position.set(-4, 3.5, -2.5);
    this.lightsGroup.add(fillLight);
    this.lights.push(fillLight);

    // 4. Warm Rim / Edge Light (Behind motorcycle to highlight silhouette)
    const rimLight = new THREE.SpotLight(0x7928ca, 2.4);
    rimLight.position.set(0, 3.8, -4.5);
    rimLight.angle = Math.PI / 3.5;
    rimLight.penumbra = 0.8;
    this.lightsGroup.add(rimLight);
    this.lights.push(rimLight);

    // 5. Floor Bounce Up-Light (Soft ground glow)
    const floorBounce = new THREE.PointLight(0x00E5FF, 1.0, 6);
    floorBounce.position.set(0, 0.2, 0);
    this.lightsGroup.add(floorBounce);
    this.lights.push(floorBounce);
  }

  _setupCyberpunkMode() {
    // Cyberpunk Dark: High contrast neon cyan, deep magenta & violet
    const ambient = new THREE.AmbientLight(0x0a1020, 0.3);
    this.lightsGroup.add(ambient);
    this.lights.push(ambient);

    // Intense Cyan Key Spot
    const cyanKey = new THREE.SpotLight(0x00F0FF, 4.0);
    cyanKey.position.set(-3.5, 4.0, 3.0);
    cyanKey.angle = Math.PI / 4.5;
    cyanKey.penumbra = 0.6;
    cyanKey.castShadow = true;
    this.lightsGroup.add(cyanKey);
    this.lights.push(cyanKey);

    // Vivid Magenta Rim / Accent Light
    const magentaRim = new THREE.SpotLight(0xFF007A, 3.8);
    magentaRim.position.set(3.5, 3.0, -3.0);
    magentaRim.angle = Math.PI / 4;
    magentaRim.penumbra = 0.7;
    this.lightsGroup.add(magentaRim);
    this.lights.push(magentaRim);

    // Violet Ground Fill
    const violetFill = new THREE.DirectionalLight(0x7928CA, 1.5);
    violetFill.position.set(0, 2.0, 4.0);
    this.lightsGroup.add(violetFill);
    this.lights.push(violetFill);
  }

  _setupPerformanceMode() {
    // Low overhead: 2 simple directional lights, no heavy shadow mapping
    const dir1 = new THREE.DirectionalLight(0xffffff, 1.8);
    dir1.position.set(3, 4, 3);
    this.lightsGroup.add(dir1);
    this.lights.push(dir1);

    const dir2 = new THREE.DirectionalLight(0x00d2ff, 1.0);
    dir2.position.set(-3, 2, -2);
    this.lightsGroup.add(dir2);
    this.lights.push(dir2);
  }

  _setupCinematicMode() {
    const ambient = new THREE.AmbientLight(0x1a2638, 0.4);
    this.lightsGroup.add(ambient);
    this.lights.push(ambient);

    // Warm golden sunlight
    const sunLight = new THREE.DirectionalLight(0xffaa44, 3.0);
    sunLight.position.set(5, 4.5, -3.5);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 1024;
    sunLight.shadow.mapSize.height = 1024;
    this.lightsGroup.add(sunLight);
    this.lights.push(sunLight);

    // Cool skylight fill
    const skyFill = new THREE.DirectionalLight(0x00c6ff, 1.4);
    skyFill.position.set(-4, 3.5, 3.5);
    this.lightsGroup.add(skyFill);
    this.lights.push(skyFill);

    // Amber rim light
    const amberRim = new THREE.SpotLight(0xff5500, 2.5);
    amberRim.position.set(0, 2.5, -4);
    amberRim.angle = Math.PI / 3;
    amberRim.penumbra = 0.8;
    this.lightsGroup.add(amberRim);
    this.lights.push(amberRim);
  }

  setupShowroom() {
    this.setLightingMode(this.currentMode);
  }

  clearLights() {
    this.lights.forEach(light => {
      this.lightsGroup.remove(light);
      if (light.dispose) light.dispose();
    });
    this.lights = [];
  }

  dispose() {
    this.clearLights();
    this.scene.remove(this.lightsGroup);
  }
}
