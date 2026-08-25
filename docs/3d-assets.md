# RideOS 3D Motorcycle Assets & Digital Twin

## 1. Asset Registry

| Vehicle Profile | 3D Asset Path | Polygon Count | Materials |
| :--- | :--- | :--- | :--- |
| **Yamaha YZF-R1M / MT-09** | `assets/models/yamaha_r1m.glb` | 85k Tris | PBR Carbon / Metallic Blue |
| **Ducati Panigale V4 S** | `assets/models/ducati_panigale.glb` | 92k Tris | Ducati Red / Titanium Exhaust |
| **BMW M 1000 RR** | `assets/models/bmw_m1000rr.glb` | 88k Tris | Motorsport Tri-Color / Carbon |

---

## 2. Rendering Optimization
- **Graphics Quality Levels**:
  - `Auto`: Scales dynamic resolution based on device frame times.
  - `High`: Full PBR shaders, dynamic shadow mapping, 60 FPS target.
  - `Performance`: Baked shadows, simplified shaders for low-power mobile devices.
- **Resource Disposal**: WebGL / Canvas contexts are explicitly disposed on route exit to prevent memory leaks.
