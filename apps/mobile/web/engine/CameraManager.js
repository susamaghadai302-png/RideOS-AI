/**
 * RideOS Pro — Cinematic Camera Management Engine
 * Manages perspective camera, orbital damping, preset view transitions,
 * subtle idle breathing drift, and mouse parallax.
 */

export class CameraManager {
  constructor(renderer) {
    this.renderer = renderer;
    this.camera = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.1, 100);
    this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);

    // Initial configuration — 3/4 perspective
    this.camera.position.set(3.4, 1.4, 3.2);
    this.controls.target.set(0, 0.6, 0);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.minDistance = 1.2;
    this.controls.maxDistance = 9.0;
    this.controls.maxPolarAngle = Math.PI / 2 + 0.02; // Ground collision limit

    // Comprehensive automotive and screen preset views
    this.views = {
      // Main Page Presets
      'home': { pos: new THREE.Vector3(3.2, 1.35, 3.0), target: new THREE.Vector3(0, 0.6, 0) },
      'garage': { pos: new THREE.Vector3(2.8, 1.15, 2.6), target: new THREE.Vector3(0, 0.65, 0) },
      'vehicles': { pos: new THREE.Vector3(3.5, 1.0, 0.5), target: new THREE.Vector3(0, 0.6, 0) },
      'dashboard': { pos: new THREE.Vector3(2.4, 1.1, 2.2), target: new THREE.Vector3(0, 0.55, 0) },
      'navigation': { pos: new THREE.Vector3(0.5, 3.6, 1.2), target: new THREE.Vector3(0, 0.4, 0) },
      'cockpit': { pos: new THREE.Vector3(0, 1.22, -0.38), target: new THREE.Vector3(0, 1.05, 0.8) },

      // Inspection Presets
      'front': { pos: new THREE.Vector3(0, 0.95, 3.4), target: new THREE.Vector3(0, 0.65, 0) },
      'rear': { pos: new THREE.Vector3(0, 1.05, -3.4), target: new THREE.Vector3(0, 0.65, 0) },
      'left': { pos: new THREE.Vector3(-3.4, 0.85, 0), target: new THREE.Vector3(0, 0.55, 0) },
      'right': { pos: new THREE.Vector3(3.4, 0.85, 0), target: new THREE.Vector3(0, 0.55, 0) },
      'top': { pos: new THREE.Vector3(0, 4.2, 0.1), target: new THREE.Vector3(0, 0, 0) },
      'engine': { pos: new THREE.Vector3(1.3, 0.5, 0.1), target: new THREE.Vector3(0, 0.42, 0) },
      'wheels': { pos: new THREE.Vector3(-1.3, 0.38, 1.3), target: new THREE.Vector3(0, 0.35, 1.0) },
      'brakes': { pos: new THREE.Vector3(1.1, 0.38, 1.2), target: new THREE.Vector3(0.1, 0.35, 1.0) },
      'suspension': { pos: new THREE.Vector3(0.85, 0.85, 0.95), target: new THREE.Vector3(0, 0.75, 0.7) },
      'exhaust': { pos: new THREE.Vector3(1.4, 0.35, -1.1), target: new THREE.Vector3(0.15, 0.35, -0.6) },
    };

    // Interpolation state
    this.isInterpolating = false;
    this.interpDuration = 1.1;
    this.interpTime = 0;
    this.startPos = new THREE.Vector3();
    this.startTarget = new THREE.Vector3();
    this.endPos = new THREE.Vector3();
    this.endTarget = new THREE.Vector3();

    // Idle drift
    this.idleTime = 0;
    this.isUserInteracting = false;
    this.mouseParallax = new THREE.Vector2(0, 0);
    this.targetMouseParallax = new THREE.Vector2(0, 0);

    this._setupParallaxListener();
  }

  _setupParallaxListener() {
    this.controls.addEventListener('start', () => {
      this.isUserInteracting = true;
    });

    this.controls.addEventListener('end', () => {
      setTimeout(() => {
        this.isUserInteracting = false;
      }, 2000);
    });
  }

  transitionToView(viewName, duration = 1.1) {
    const view = this.views[viewName];
    if (!view) return;

    this.startPos.copy(this.camera.position);
    this.startTarget.copy(this.controls.target);
    this.endPos.copy(view.pos);
    this.endTarget.copy(view.target);

    this.interpDuration = duration;
    this.isInterpolating = true;
    this.interpTime = 0;
  }

  reset() {
    this.transitionToView('home');
  }

  _ease(t) {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }

  update(delta) {
    this.idleTime += delta;

    if (this.isInterpolating) {
      this.interpTime += delta;
      let t = this.interpTime / this.interpDuration;
      if (t >= 1.0) {
        t = 1.0;
        this.isInterpolating = false;
      }

      const easedT = this._ease(t);
      this.camera.position.lerpVectors(this.startPos, this.endPos, easedT);
      this.controls.target.lerpVectors(this.startTarget, this.endTarget, easedT);
    }

    this.controls.update();
  }

  resize(width, height) {
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }
}
