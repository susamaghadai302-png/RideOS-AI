export class InteractionManager {
  constructor(camera, scene, canvas, onComponentClicked) {
    this.camera = camera;
    this.scene = scene;
    this.canvas = canvas;
    this.onComponentClicked = onComponentClicked;
    
    this.raycaster = new THREE.Raycaster();
    this.mouse = new THREE.Vector2();
    
    // Bind event listeners
    this.onClick = this.onClick.bind(this);
    this.canvas.addEventListener('click', this.onClick, false);
    
    // For visual feedback on hover/click
    this.outlineMaterial = new THREE.MeshBasicMaterial({ color: 0x00E5FF, wireframe: true, transparent: true, opacity: 0.5 });
    this.highlightedMesh = null;
    this.originalMaterial = null;
  }

  onClick(event) {
    // Calculate mouse position in normalized device coordinates (-1 to +1)
    const rect = this.canvas.getBoundingClientRect();
    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    this.raycaster.setFromCamera(this.mouse, this.camera);
    
    // Intersect all meshes in the scene
    const intersects = this.raycaster.intersectObjects(this.scene.children, true);
    
    if (intersects.length > 0) {
      // Find the first mesh that has a componentName assigned (either via hotspot or mesh data)
      for (let i = 0; i < intersects.length; i++) {
        const object = intersects[i].object;
        if (object.userData && object.userData.componentName) {
          this.highlightMesh(object);
          if (this.onComponentClicked) {
            this.onComponentClicked(object.userData.componentName);
          }
          break;
        }
      }
    } else {
      this.clearHighlight();
    }
  }

  highlightMesh(mesh) {
    this.clearHighlight();
    this.highlightedMesh = mesh;
    this.originalMaterial = mesh.material;
    
    // Swap material to outline for visual feedback
    mesh.material = this.outlineMaterial;
    
    // Revert after 500ms
    setTimeout(() => {
      if (this.highlightedMesh === mesh) {
        this.clearHighlight();
      }
    }, 500);
  }

  clearHighlight() {
    if (this.highlightedMesh && this.originalMaterial) {
      this.highlightedMesh.material = this.originalMaterial;
      this.highlightedMesh = null;
      this.originalMaterial = null;
    }
  }
}
