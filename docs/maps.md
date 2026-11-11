# RideOS Maps, Navigation & GPS Subsystem

## 1. Architecture Overview
The navigation subsystem is built on a clean provider architecture designed specifically for two-wheelers (motorcycles and scooters):

```
                       ┌──────────────────────────────┐
                       │      Navigation UI Layer     │
                       │ (ThreeDNavigation / BikeHUD) │
                       └──────────────┬───────────────┘
                                      │
                       ┌──────────────▼───────────────┐
                       │        NavigationBloc        │
                       └──────────────┬───────────────┘
                                      │
            ┌─────────────────────────┴─────────────────────────┐
            │                                                   │
 ┌──────────▼──────────┐                             ┌──────────▼──────────┐
 │   LocationManager   │                             │  NavigationService  │
 │ (GNSS + IMU Kalman) │                             │   (Backend Client)  │
 └─────────────────────┘                             └──────────┬──────────┘
                                                                │
                                                     ┌──────────▼──────────┐
                                                     │   Google Routes v2  │
                                                     │ (TWO_WHEELER Mode)  │
                                                     └─────────────────────┘
```

---

## 2. Google Routes API v2 Integration (`TWO_WHEELER`)
RideOS uses **Google Routes API v2 (`computeRoutes`)** with `travelMode: TWO_WHEELER`:
- **Server-Side Routing**: The backend `NavigationService` communicates with `https://routes.googleapis.com/directions/v2:computeRoutes`.
- **Motorcycle Optimization**: Routes account for motorcycle-accessible narrow roads, bypass toll gates/highways where restricted, and calculate lean angles and road curvature profiles for riders.
- **Unified Route Data Model**: Both the 2D Bike Mode HUD and the 3D Navigation Screen consume the unified `NavigationRoute` model containing polyline points, turn-by-turn guidance steps, maneuver icons, and elevation profiles.

---

## 3. Strict Credential Separation
To prevent credential leaks and restrict API quota usage according to Google Cloud best practices, RideOS enforces strict key separation:

| Key Variable | Usage Context | Security Restriction | Location |
| :--- | :--- | :--- | :--- |
| **`GOOGLE_ROUTES_API_KEY`** | Backend Only (`apps/backend`) | IP-restricted or Server-restricted to backend hosts; used for Routes API v2 `computeRoutes` | Backend `.env` |
| **`ANDROID_GOOGLE_MAPS_API_KEY`** | Android Client Only (`apps/mobile/android`) | SHA-1 Certificate Fingerprint + Android Package Name restricted (`ai.rideos.app`); used for Maps SDK for Android | `local.properties` / root `.env` / CI secret |

> [!IMPORTANT]
> The Android application NEVER directly accesses or holds the server-side `GOOGLE_ROUTES_API_KEY`. All route calculation requests are routed through the RideOS NestJS backend API.

---

## 4. Android Configuration
1. Add the restricted client Maps SDK key to `apps/mobile/android/local.properties`:
   ```properties
   ANDROID_GOOGLE_MAPS_API_KEY=AIzaSyYourAndroidClientRestrictedKeyHere
   ```
2. The Kotlin DSL build configuration in `apps/mobile/android/app/build.gradle.kts` resolves `ANDROID_GOOGLE_MAPS_API_KEY` with multi-layer fallback to root `.env` or system environment, injecting it into `AndroidManifest.xml` via `manifestPlaceholders["GOOGLE_MAPS_API_KEY"]`.

---

## 5. GNSS & Dead Reckoning Sensor Fusion
When riding through tunnels, urban canyons, or dense tree cover where GNSS signal degrades:
- `LocationManager` fuses high-rate IMU accelerometer and gyroscope data with GPS coordinates using an internal Kalman filter.
- Odometer and vehicle speed telemetry from the Bluetooth ECU/OBD-II adapter provide dead reckoning speed input to prevent navigation freeze.
