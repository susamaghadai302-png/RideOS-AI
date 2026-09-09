/**
 * RideOS Pro — Login Scene Manager
 * Controls the cinematic 3D environment state for the welcome/login screen.
 *
 * Behaviour:
 *  - Loads the default BMW S1000RR as the showcase model before user logs in
 *  - Switches camera to the 'login' preset
 *  - Enables slow auto-rotate breathing motion
 *  - On login success, triggers a cinematic camera fly-to 'home'
 *  - On screen transitions (any nav item clicked), transitions camera to
 *    the matching preset name
 */
export class LoginSceneManager {
  constructor(cameraManager, modelLoader, lightingManager) {
    this.cameraManager   = cameraManager;
    this.modelLoader     = modelLoader;
    this.lightingManager = lightingManager;
    this._active           = false;
    this._time             = 0;
    this._loginModelLoaded = false;
  }

  async activateLoginScene() {
    this._active = true;
    this._time   = 0;

    // Move to login camera preset (wider, cinematic angle)
    this.cameraManager.transitionToView('login', 1.8);

    // Apply studio lighting
    this.lightingManager.setLightingMode('studio');

    // Stable camera view without auto-rotation
    if (this.cameraManager.controls) {
      this.cameraManager.controls.autoRotate      = false;
      this.cameraManager.controls.autoRotateSpeed = 0;
    }

    // Load default showcase vehicle (BMW S1000RR — 3.9 MB)
    if (!this._loginModelLoaded) {
      try {
        await this.modelLoader.loadProfile({
          id:             'default-login-showcase',
          manufacturer:   'BMW',
          model:          'S 1000 RR',
          variant:        'M Package',
          model3DUrl:     'assets/models/bmw_s1000rr.glb',
          category:       'superbike',
          specifications: { engine: '999cc', power: '210 HP' },
        });
        this._loginModelLoaded = true;
        console.log('[LoginSceneManager] Default showcase model loaded.');
      } catch (e) {
        console.warn('[LoginSceneManager] Could not load default model, hologram stage will show.', e);
      }
    }
  }

  onLoginSuccess() {
    this._active = false;
    if (this.cameraManager.controls) {
      this.cameraManager.controls.autoRotate = false;
    }
    // Cinematic fly-in to home command center over 2 s
    this.cameraManager.transitionToView('home', 2.0);
  }

  onScreenChange(screenName) {
    if (this.cameraManager.controls) {
      this.cameraManager.controls.autoRotate = false;
    }
    const duration = this._getTransitionDuration(screenName);
    this.cameraManager.transitionToView(screenName, duration);
  }

  update(delta) {
    if (!this._active) return;
    this._time += delta;
  }

  _getTransitionDuration(screenName) {
    const quickScreens = ['dashboard', 'dashboard-hud', 'connect', 'cockpit'];
    const slowScreens  = ['navigation', 'navigation-3d', 'profile', 'settings', 'ai'];
    if (quickScreens.includes(screenName)) return 1.0;
    if (slowScreens.includes(screenName))  return 1.6;
    return 1.2;
  }
}
