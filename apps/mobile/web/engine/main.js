import { CoreEngine } from './CoreEngine.js';

let engine = null;
let canvas = null;

// Expose the global interop bridge for Flutter & Web
window.RideOS3D = {
  initialize: function() {
    if (engine) return;

    // Check if canvas exists
    canvas = document.getElementById('engine-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'engine-canvas';
      canvas.style.position = 'fixed';
      canvas.style.top = '0';
      canvas.style.left = '0';
      canvas.style.width = '100vw';
      canvas.style.height = '100vh';
      canvas.style.zIndex = '0';
      canvas.style.pointerEvents = 'none'; // Allow click-through to Flutter UI by default
      canvas.style.display = 'block';

      // Insert as first child of body to stay under Flutter canvas
      document.body.insertBefore(canvas, document.body.firstChild);
    }

    try {
      engine = new CoreEngine(canvas);
      console.log('⚡ RideOS3D Global Showroom Engine initialized successfully.');

      if (window.invokeFlutterMethod) {
        window.invokeFlutterMethod('onEngineReady');
      }
    } catch (e) {
      console.error('Failed to initialize RideOS3D engine:', e);
    }
  },

  setPointerEventsEnabled: function(enabled) {
    if (canvas) {
      canvas.style.pointerEvents = enabled ? 'auto' : 'none';
    }
  },

  loadVehicleProfile: function(profileJson) {
    if (!engine) this.initialize();
    if (engine) engine.loadVehicleProfile(profileJson);
  },

  updateTelemetry: function(payloadJson) {
    if (engine) {
      try {
        const payload = typeof payloadJson === 'string' ? JSON.parse(payloadJson) : payloadJson;
        engine.updateTelemetry(payload);
      } catch (e) {
        console.warn('Failed to parse telemetry', e);
      }
    }
  },

  setCameraPreset: function(presetName, duration = 1.1) {
    if (engine) engine.transitionCamera(presetName, duration);
  },

  setLightingMode: function(mode) {
    if (engine) engine.setLightingMode(mode);
  },

  setPaintColor: function(hexColor) {
    if (engine) engine.setPaintColor(hexColor);
  },

  setExplodedView: function(exploded) {
    if (engine) engine.setExplodedView(exploded);
  },

  highlightComponent: function(componentName) {
    if (engine) engine.highlightComponent(componentName);
  },

  dispose: function() {
    if (engine) {
      engine.dispose();
      engine = null;
    }
  }
};

// Auto-initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.RideOS3D.initialize();
  });
} else {
  window.RideOS3D.initialize();
}
