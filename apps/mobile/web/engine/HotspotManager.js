export class HotspotManager {
  constructor(scene, camera) {
    this.scene = scene;
    this.camera = camera;
    this.hotspots = [];
    
    // We will use CSS2DRenderer for 2D DOM overlays in a full implementation,
    // but for now, we'll use simple Sprite objects in WebGL to act as markers
    this.markerMaterial = new THREE.SpriteMaterial({
      color: 0x00ffff,
      transparent: true,
      opacity: 0.8,
    });
  }

  createHotspots(vehicleProfile) {
    this.clear();

    if (!vehicleProfile || !vehicleProfile.specifications || !vehicleProfile.specifications.hotspots) {
      return;
    }

    const spots = vehicleProfile.specifications.hotspots;
    
    spots.forEach(spot => {
      const sprite = new THREE.Sprite(this.markerMaterial);
      sprite.scale.set(0.1, 0.1, 0.1);
      
      // Parse coordinates (e.g., { x, y, z })
      if (spot.position) {
        sprite.position.set(spot.position.x, spot.position.y, spot.position.z);
      }
      
      sprite.userData = { componentName: spot.name };
      this.hotspots.push(sprite);
      this.scene.add(sprite);
    });
  }

  update() {
    // Optional: make sprites pulsate or scale based on distance to camera
    const time = performance.now() * 0.005;
    this.hotspots.forEach(sprite => {
      const scale = 0.1 + Math.sin(time) * 0.02;
      sprite.scale.set(scale, scale, scale);
    });
  }

  clear() {
    this.hotspots.forEach(h => this.scene.remove(h));
    this.hotspots = [];
  }
}
