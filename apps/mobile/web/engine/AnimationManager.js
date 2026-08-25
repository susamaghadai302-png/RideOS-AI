export class AnimationManager {
  constructor() {
    this.model = null;
    this.mixer = null;
    this.wheelNodes = [];
    this.steeringNode = null;
    this.speedKmh = 0;
    this.steeringAngle = 0;
  }

  bindModel(model) {
    this.model = model;
    this.wheelNodes = [];
    this.steeringNode = null;

    if (!model) return;

    // Support rigged animations if they exist
    if (model.animations && model.animations.length > 0) {
      this.mixer = new THREE.AnimationMixer(model);
      // We could play idle animations here
    }

    // Attempt to find conventional node names for procedural animation
    model.traverse((child) => {
      const name = child.name.toLowerCase();
      if ((name.includes('wheel') || name.includes('tire') || name.includes('tyre')) && !name.includes('steering') && !name.includes('steer')) {
        this.wheelNodes.push(child);
      }
      if (name.includes('steering') || name.includes('steer') || name.includes('handle') || name.includes('fork') || name.includes('yoke') || name.includes('front')) {
        // Find the highest level node that represents steering to avoid separating the assembly
        if (!this.steeringNode && child.isMesh) {
           this.steeringNode = child.parent && (child.parent.name.toLowerCase().includes('steer') || child.parent.name.toLowerCase().includes('fork')) ? child.parent : child;
        } else if (!this.steeringNode) {
           this.steeringNode = child;
        }
      }
    });

    console.log(`AnimationManager bound. Found ${this.wheelNodes.length} wheels, steering node: ${!!this.steeringNode} (${this.steeringNode?.name || 'none'})`);
  }

  setTelemetry(telemetryData) {
    // Handle both old flat format (fallback) and new NormalizedTelemetry
    this.speedKmh = telemetryData.speed?.value ?? telemetryData.speedKmh ?? 0;
    this.steeringAngle = telemetryData.steering?.value ?? 0; // Steering angle might not be in the basic payload yet, default to 0
  }

  update(delta) {
    if (this.mixer) this.mixer.update(delta);

    // Procedural wheel rotation based on speed
    // rough approximation: RPM = speed (km/h) * constant (depends on wheel radius, assuming ~0.3m)
    // rev/sec = (speed * 1000 / 3600) / (2 * PI * 0.3)
    const metersPerSec = this.speedKmh / 3.6;
    const wheelRadius = 0.3; // fallback 
    const radiansPerSec = metersPerSec / wheelRadius;

    if (radiansPerSec > 0) {
      const rot = radiansPerSec * delta;
      this.wheelNodes.forEach(node => {
        // Rotate along the local X axis (assuming standard rigging, may need Y/Z depending on exporter)
        node.rotateX(rot);
      });
    }

    if (this.steeringNode) {
      // Clamp and lerp steering for smoothness
      const targetRad = THREE.MathUtils.degToRad(this.steeringAngle);
      // Assuming steering rotates around local Y axis
      this.steeringNode.rotation.y = THREE.MathUtils.lerp(this.steeringNode.rotation.y, targetRad, delta * 5.0);
    }
  }
}
