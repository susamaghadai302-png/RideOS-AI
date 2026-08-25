/**
 * RideOS Pro — Core Real-Time 3D WebGL Command Center Engine
 * Integrates Three.js WebGLRenderer, EnvironmentManager, LightingManager,
 * CameraManager, ModelLoader, AnimationManager, and TelemetryVisualizer.
 */

import { CameraManager } from './CameraManager.js';
import { LightingManager } from './LightingManager.js';
import { EnvironmentManager } from './EnvironmentManager.js';
import { ModelLoader } from './ModelLoader.js';
import { InteractionManager } from './InteractionManager.js';
import { PerformanceManager } from './PerformanceManager.js';
import { HotspotManager } from './HotspotManager.js';
import { AnimationManager } from './AnimationManager.js';
import { TelemetryVisualizer } from './TelemetryVisualizer.js';

export class CoreEngine {
  constructor(canvasElement) {
    this.canvas = canvasElement;
    this.scene = new THREE.Scene();

    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: true,
      alpha: true,
      powerPreference: "high-performance",
    });

    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.15;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    this.clock = new THREE.Clock();
    this.animationFrameId = null;

    // Sub-managers
    this.cameraManager = new CameraManager(this.renderer);
    this.lightingManager = new LightingManager(this.scene);
    this.environmentManager = new EnvironmentManager(this.scene);
    this.modelLoader = new ModelLoader(this.scene, this.environmentManager);
    this.performanceManager = new PerformanceManager(this.renderer, this.scene);

    this.interactionManager = new InteractionManager(
      this.cameraManager.camera,
      this.scene,
      this.canvas,
      this.handleComponentClick.bind(this)
    );

    this.hotspotManager = new HotspotManager(this.scene, this.cameraManager.camera);
    this.animationManager = new AnimationManager();
    this.telemetryVisualizer = new TelemetryVisualizer();

    this.onWindowResize = this.onWindowResize.bind(this);
    window.addEventListener('resize', this.onWindowResize, false);

    // Start rendering loop immediately for persistent showroom
    this.startLoop();
  }

  async loadVehicleProfile(profileJson) {
    try {
      const profile = typeof profileJson === 'string' ? JSON.parse(profileJson) : profileJson;
      this.lightingManager.setupShowroom();

      const model = await this.modelLoader.loadProfile(profile);

      if (model) {
        this.animationManager.bindModel(model);
        this.telemetryVisualizer.bindModel(model);
        this.hotspotManager.createHotspots(profile);
      }

      this.startLoop();
    } catch (e) {
      console.error('Failed to load vehicle profile into 3D engine:', e);
    }
  }

  setLightingMode(mode) {
    if (this.lightingManager) {
      this.lightingManager.setLightingMode(mode);
    }
  }

  setPaintColor(hexColor) {
    if (this.modelLoader) {
      this.modelLoader.setPaintColor(hexColor);
    }
  }

  setExplodedView(exploded) {
    if (this.modelLoader) {
      this.modelLoader.setExplodedView(exploded);
    }
  }

  highlightComponent(componentName) {
    if (this.cameraManager) {
      const comp = (componentName || '').toLowerCase();
      if (comp.includes('engine') || comp.includes('oil') || comp.includes('spark')) {
        this.cameraManager.transitionToPreset('engine', 1.0);
      } else if (comp.includes('brake') || comp.includes('wheel') || comp.includes('tyre') || comp.includes('chain')) {
        this.cameraManager.transitionToPreset('wheels', 1.0);
      } else if (comp.includes('exhaust')) {
        this.cameraManager.transitionToPreset('exhaust', 1.0);
      } else if (comp.includes('battery') || comp.includes('cockpit') || comp.includes('abs') || comp.includes('hud')) {
        this.cameraManager.transitionToPreset('cockpit', 1.0);
      } else {
        this.cameraManager.transitionToPreset('garage', 1.0);
      }
    }
  }

  transitionCamera(viewName, duration = 1.1) {
    if (this.cameraManager) {
      this.cameraManager.transitionToView(viewName, duration);
    }
  }

  updateTelemetry(telemetryJson) {
    try {
      const data = typeof telemetryJson === 'string' ? JSON.parse(telemetryJson) : telemetryJson;
      if (this.animationManager) this.animationManager.setTelemetry(data);
      if (this.telemetryVisualizer) this.telemetryVisualizer.setTelemetry(data);
    } catch (e) {
      console.warn('Failed to parse incoming live telemetry in 3D engine:', e);
    }
  }

  handleComponentClick(componentName) {
    this.cameraManager.transitionToView(componentName);

    if (window.invokeFlutterMethod) {
      window.invokeFlutterMethod('onComponentClicked', componentName);
    }
  }

  startLoop() {
    if (!this.animationFrameId) {
      this.clock.start();
      this.animate();
    }
  }

  stopLoop() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  animate() {
    this.animationFrameId = requestAnimationFrame(this.animate.bind(this));

    const delta = this.clock.getDelta();
    this.performanceManager.update();
    this.cameraManager.update(delta);
    this.environmentManager.update(delta);
    this.animationManager.update(delta);
    this.hotspotManager.update();

    this.renderer.render(this.scene, this.cameraManager.camera);
  }

  onWindowResize() {
    this.cameraManager.resize(window.innerWidth, window.innerHeight);
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  dispose() {
    this.stopLoop();
    window.removeEventListener('resize', this.onWindowResize);
    this.modelLoader.dispose();
    this.environmentManager.dispose();
    this.lightingManager.dispose();
    this.renderer.dispose();
  }
}
