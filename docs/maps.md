# RideOS Maps, Navigation & GPS Subsystem

## 1. Architecture
The navigation subsystem is built on a modular provider architecture:

```
NavigationUI (ThreeDNavigationScreen)
     ↓
MapProvider (Google Maps / OpenStreetMap / Mapbox interface)
     ↓
LocationManager (Geolocator + Dead Reckoning IMU Kalman Filter)
     ↓
RouteEngine (Directions API + Motorcycle Curvature Profiler)
     ↓
TripManager (Real-time Spatial Filtering & Odometer Integrator)
     ↓
Backend Sync / Offline Storage
```

---

## 2. API Credentials & Configuration
1. Obtain a **Google Maps Platform API Key**.
2. Enable:
   - Maps SDK for Android
   - Places API (New)
   - Directions API
   - Geocoding API
3. Add the key to `apps/mobile/android/local.properties`:
   ```properties
   GOOGLE_MAPS_API_KEY=AIzaSyYourProductionApiKeyHere
   ```
4. On web or development environments, provide the key in `.env`.
