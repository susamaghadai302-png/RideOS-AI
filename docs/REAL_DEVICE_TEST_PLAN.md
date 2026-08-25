# RideOS Pro — Real Android Device Validation Plan

This document outlines the step-by-step manual test protocol to be executed on a physical Android smartphone connected to compatible motorcycle hardware.

---

## 1. Environment & Pre-requisites
- **Target Device**: Physical Android device running Android 10 (API 29) to Android 14 (API 34).
- **Target Hardware**: Motorcycle with Yamaha Y-Connect ECU, Ducati DMS, or standard OBDLink MX+ / ELM327 BLE adapter.
- **Location**: Road route with varied cellular reception and GPS visibility (including tunnel or overpass).

---

## 2. Test Execution Matrix

| Step | Flow / Feature | Action | Expected Behavior | Physical Pass/Fail |
| :--- | :--- | :--- | :--- | :--- |
| **01** | **Fresh Install & Splash** | Install release APK/AAB and launch app | App transitions from splash screen to Onboarding without crash or delay. | [ ] |
| **02** | **Onboarding & Auth** | Swipe 5 onboarding screens $\rightarrow$ Register/Login | Stores authentication token in native secure storage; opens Home screen. | [ ] |
| **03** | **BLE Permission Gate** | Tap "Connect Vehicle" | System prompts for `BLUETOOTH_SCAN` & `BLUETOOTH_CONNECT`. If denied, shows graceful error card. | [ ] |
| **04** | **BLE Discovery & Scan** | Scan with ignition ON | Discovers compatible motorcycle device by manufacturer UUID; filters out non-vehicle BLE devices. | [ ] |
| **05** | **GATT Connection** | Tap vehicle in scan list | Connects within 3.5s, discovers GATT services, selects matching protocol adapter (`YamahaProtocolAdapter`, etc.). | [ ] |
| **06** | **3D Digital Twin** | Navigate to 3D Garage | Loads exact model GLB (`yamaha_r1m.glb`). Touch rotation, pinch zoom, and camera reset operate at 60 FPS. | [ ] |
| **07** | **Live Telemetry Stream** | Start engine & rev throttle | Speed, RPM, battery voltage, and coolant temp update in real-time. Missing sensors display `Unavailable`. | [ ] |
| **08** | **Active Ride Recording** | Tap "Start Ride" on Map | High-precision GNSS speedometer matches vehicle instrument cluster. Route draws on map. | [ ] |
| **09** | **Background / Screen Lock** | Lock phone screen while riding | Android foreground service keeps tracking active. Notification shows live distance and speed. | [ ] |
| **10** | **GPS Signal Loss** | Ride through tunnel / garage | UI shows `GPS UNAVAILABLE` with last known position. No fake coordinates inserted. Resumes on exit. | [ ] |
| **11** | **BLE Disconnect Recovery** | Turn motorcycle ignition OFF | UI switches to `DISCONNECTED`. Metrics freeze to `Unavailable`. Active ride continues on phone GNSS. | [ ] |
| **12** | **Ride Completion** | Tap "End Ride" | Trip computes distance, duration, elevation profile, and saves locally to SQLite. | [ ] |
| **13** | **ECU Diagnostics** | Trigger / Read DTC | Displays SAE code (e.g. P0300) with description. Clear button is active only when speed is 0 km/h. | [ ] |
| **14** | **Maintenance Tracker** | Check Service Reminders | Service reminder matches current odometer vs target interval. Adding log updates next due date. | [ ] |
| **15** | **Notification Center** | Trigger DTC or Maint reminder | Notification appears in center with priority chip. Tapping notification deep-links to specific page. | [ ] |
| **16** | **Account Deletion** | Settings $\rightarrow$ Delete Account | Deletes user profile and cascades deletion across all vehicles and trips on MongoDB. Logs out cleanly. | [ ] |
