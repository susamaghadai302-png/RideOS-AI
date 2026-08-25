/**
 * RideOS Pro — Universal 3D Motorcycle & Scooter Model Loader
 * Loads GLB/glTF assets, normalizes bounding box/scale, applies physically
 * based materials, manages paint colors, and activates the holographic pending
 * showroom stage when an OEM CAD asset is not yet available.
 */

const AssetCache = new Map();

export class ModelLoader {
  constructor(scene, environmentManager) {
    this.scene = scene;
    this.environmentManager = environmentManager;
    this.currentModel = null;
    this.paintMaterials = [];
    this.originalPositions = new Map();
    this.isExploded = false;

    this.loader = new THREE.GLTFLoader();
    const dracoLoader = new THREE.DRACOLoader();
    dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.6/');
    this.loader.setDRACOLoader(dracoLoader);
  }

  _resolveUrl(url) {
    if (!url) return '';
    // Normalize path for Flutter Web serving
    if (url.startsWith('assets/')) {
      return url;
    }
    if (url.startsWith('/assets/')) {
      return url.substring(1);
    }
    return url;
  }

  async loadProfile(vehicleProfile) {
    if (!vehicleProfile) return Promise.reject('No profile provided');

    const rawUrl = vehicleProfile.model3DUrl || '';
    const url = this._resolveUrl(rawUrl);

    // If no 3D asset exists for this vehicle model, activate elegant holographic showroom stage
    if (!url || url.trim() === '' || url.includes('unavailable')) {
      if (this.currentModel) {
        this.scene.remove(this.currentModel);
        this.currentModel = null;
      }
      if (this.environmentManager) {
        this.environmentManager.showHologramPlaceholder(true);
      }
      if (window.invokeFlutterMethod) {
        window.invokeFlutterMethod('onModelUnavailable', vehicleProfile.model || 'Unknown Model');
      }
      return null;
    }

    // Hide hologram placeholder if we have a real model
    if (this.environmentManager) {
      this.environmentManager.showHologramPlaceholder(false);
    }

    if (this.currentModel) {
      this.scene.remove(this.currentModel);
      this.currentModel = null;
    }

    if (AssetCache.has(url)) {
      const cachedScene = AssetCache.get(url).clone(true);
      return this._setupModel(cachedScene, vehicleProfile);
    }

    return new Promise((resolve) => {
      if (window.invokeFlutterMethod) {
        window.invokeFlutterMethod('onModelLoading', 0.1);
      }

      this.loader.load(
        url,
        (gltf) => {
          AssetCache.set(url, gltf.scene); // Cache the raw scene
          const sceneClone = gltf.scene.clone(true);

          if (window.invokeFlutterMethod) {
            window.invokeFlutterMethod('onModelLoading', 1.0);
            window.invokeFlutterMethod('onModelLoaded', vehicleProfile.model);
          }

          resolve(this._setupModel(sceneClone, vehicleProfile));
        },
        (xhr) => {
          if (window.invokeFlutterMethod && xhr.total > 0) {
            window.invokeFlutterMethod('onModelLoading', xhr.loaded / xhr.total);
          }
        },
        (error) => {
          console.warn(`3D asset not available for ${vehicleProfile.model} at path ${url}. Activating hologram showroom stage:`, error);
          if (this.environmentManager) {
            this.environmentManager.showHologramPlaceholder(true);
          }
          if (window.invokeFlutterMethod) {
            window.invokeFlutterMethod('onModelUnavailable', vehicleProfile.model);
          }
          resolve(null);
        }
      );
    });
  }

  _setupModel(modelScene, vehicleProfile) {
    this.currentModel = modelScene;
    this.paintMaterials = [];
    this.originalPositions.clear();

    let hasMeshes = false;

    this.currentModel.traverse((child) => {
      if (child.isMesh) {
        hasMeshes = true;
        child.castShadow = true;
        child.receiveShadow = true;

        this.originalPositions.set(child, child.position.clone());

        if (child.material) {
          // Enhance physical material properties
          child.material.envMapIntensity = 1.6;
          child.material.needsUpdate = true;

          const matName = (child.material.name || '').toLowerCase();
          const meshName = (child.name || '').toLowerCase();

          // Identify paint/fairing surfaces for customizer
          if (matName.includes('paint') || matName.includes('body') || matName.includes('fairing') ||
              matName.includes('tank') || meshName.includes('fairing') || meshName.includes('tank')) {
            child.material = child.material.clone();
            this.paintMaterials.push(child.material);
          }

          // Enhance metallic motorcycle parts (exhaust, frame, engine)
          if (matName.includes('metal') || matName.includes('chrome') || matName.includes('engine') ||
              matName.includes('exhaust') || matName.includes('frame') || matName.includes('rim')) {
            child.material.metalness = Math.max(0.75, child.material.metalness || 0.85);
            child.material.roughness = Math.min(0.35, child.material.roughness || 0.2);
          }
        }
      }
    });

    if (!hasMeshes) {
      console.warn('GLB contains no mesh geometry.');
      return null;
    }

    // Auto-center and normalize model scale to fit turntable
    const box = new THREE.Box3().setFromObject(this.currentModel);
    const size = box.getSize(new THREE.Vector3());
    const maxDim = Math.max(size.x, size.y, size.z);

    // Standard motorcycle target length is ~2.0 - 2.2 units
    if (maxDim > 0.001) {
      const targetScale = 2.1 / maxDim;
      this.currentModel.scale.setScalar(targetScale);
    }

    // Recalculate bounding box after scaling
    box.setFromObject(this.currentModel);
    const center = box.getCenter(new THREE.Vector3());

    // Center X & Z, align bottom of wheels to Y=0 (showroom floor)
    this.currentModel.position.x = -center.x;
    this.currentModel.position.z = -center.z;
    this.currentModel.position.y = -box.min.y;

    this.scene.add(this.currentModel);
    return this.currentModel;
  }

  setPaintColor(hexColor) {
    if (!this.paintMaterials || this.paintMaterials.length === 0) return;
    const color = new THREE.Color(hexColor);
    this.paintMaterials.forEach(mat => {
      mat.color.copy(color);
      mat.needsUpdate = true;
    });
  }

  setExplodedView(exploded = true) {
    this.isExploded = exploded;
    if (!this.currentModel) return;

    this.currentModel.traverse((child) => {
      if (child.isMesh && this.originalPositions.has(child)) {
        const orig = this.originalPositions.get(child);
        if (exploded) {
          const name = child.name.toLowerCase();
          let offset = new THREE.Vector3(0, 0, 0);

          if (name.includes('wheel') || name.includes('tire')) {
            offset.set(0, 0, orig.z > 0 ? 0.35 : -0.35);
          } else if (name.includes('tank') || name.includes('seat')) {
            offset.set(0, 0.45, 0);
          } else if (name.includes('fairing') || name.includes('body')) {
            offset.set(orig.x > 0 ? 0.4 : -0.4, 0.2, 0);
          } else if (name.includes('exhaust')) {
            offset.set(0.35, -0.1, -0.2);
          } else {
            offset.set(orig.x * 0.4, 0.15, orig.z * 0.4);
          }
          child.position.copy(orig).add(offset);
        } else {
          child.position.copy(orig);
        }
      }
    });
  }

  dispose() {
    if (this.currentModel) {
      this.scene.remove(this.currentModel);
      this.currentModel = null;
    }
  }
}
