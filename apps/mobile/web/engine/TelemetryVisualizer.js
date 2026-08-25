export class TelemetryVisualizer {
  constructor() {
    this.model = null;
    this.headlightMaterials = [];
    this.taillightMaterials = [];
    this.dashboardMaterials = [];
    this.indicatorMaterials = [];
  }

  bindModel(model) {
    this.model = model;
    this.headlightMaterials = [];
    this.taillightMaterials = [];
    this.dashboardMaterials = [];
    this.indicatorMaterials = [];

    if (!model) return;

    model.traverse((child) => {
      if (child.isMesh && child.material) {
        const matName = child.material.name.toLowerCase();
        const meshName = child.name.toLowerCase();
        
        // Find headlights
        if (matName.includes('headlight') || matName.includes('glass') || meshName.includes('headlight')) {
          // Clone material to avoid affecting other shared materials
          child.material = child.material.clone();
          this.headlightMaterials.push(child.material);
        }
        
        // Find taillights
        if (matName.includes('taillight') || matName.includes('brake_light') || meshName.includes('tail')) {
          child.material = child.material.clone();
          this.taillightMaterials.push(child.material);
        }

        // Find dashboard screen
        if (matName.includes('screen') || matName.includes('display') || matName.includes('dash')) {
          child.material = child.material.clone();
          this.dashboardMaterials.push(child.material);
        }
      }
    });
  }

  setTelemetry(telemetryData) {
    if (!this.model) return;
    
    // Ignition state drives the dashboard and base lighting
    // Handle both old flat format (fallback) and new NormalizedTelemetry
    const rpmVal = telemetryData.rpm?.value ?? telemetryData.rpm ?? 0;
    const ignitionVal = telemetryData.ignitionState?.value ?? 'OFF';
    const brakeVal = telemetryData.brakeState?.value ?? false;
    const headlightVal = telemetryData.headlight?.value ?? true;

    const isIgnitionOn = ignitionVal !== 'OFF' || rpmVal > 0;
    
    // Update Dashboard (Emissive intensity)
    this.dashboardMaterials.forEach(mat => {
      if (mat.emissive) {
        mat.emissive = new THREE.Color(0xffffff);
        mat.emissiveIntensity = isIgnitionOn ? 1.0 : 0.0;
      }
    });

    // Update Headlight
    const isHeadlightOn = isIgnitionOn && (headlightVal !== false);
    this.headlightMaterials.forEach(mat => {
      if (mat.emissive) {
        mat.emissive = new THREE.Color(0xffffff);
        mat.emissiveIntensity = isHeadlightOn ? 2.0 : 0.0;
      }
    });

    // Update Taillight / Brakelight
    const isBraking = brakeVal;
    this.taillightMaterials.forEach(mat => {
      if (mat.emissive) {
        mat.emissive = new THREE.Color(0xff0000);
        mat.emissiveIntensity = isBraking ? 2.5 : (isIgnitionOn ? 0.5 : 0.0);
      }
    });
  }
}
