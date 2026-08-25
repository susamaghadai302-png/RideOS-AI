export class PerformanceManager {
  constructor(renderer, scene) {
    this.renderer = renderer;
    this.scene = scene;
    this.frameCount = 0;
    this.lastTime = performance.now();
    this.currentQuality = 'high'; // high, medium, low
  }

  update() {
    this.frameCount++;
    const now = performance.now();
    const elapsed = now - this.lastTime;
    
    // Evaluate every 1 second
    if (elapsed >= 1000) {
      const fps = (this.frameCount * 1000) / elapsed;
      this._evaluatePerformance(fps);
      this.frameCount = 0;
      this.lastTime = now;
    }
  }

  _evaluatePerformance(fps) {
    if (fps < 20 && this.currentQuality !== 'low') {
      this._setLowQuality();
    } else if (fps >= 45 && this.currentQuality === 'low') {
      // Maybe scale back up to medium slowly if it stabilized
      this._setMediumQuality();
    }
  }

  _setLowQuality() {
    console.warn('FPS dropped below 20. Engaging Low Quality mode.');
    this.currentQuality = 'low';
    this.renderer.setPixelRatio(1);
    this.renderer.shadowMap.enabled = false;
    
    // Disable shadows on all meshes
    this.scene.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = false;
        child.receiveShadow = false;
      }
    });
  }

  _setMediumQuality() {
    this.currentQuality = 'medium';
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.BasicShadowMap; // cheaper than PCFSoft
    
    this.scene.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = true;
        child.receiveShadow = true;
      }
    });
  }
}
