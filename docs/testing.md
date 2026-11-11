# RideOS Testing & QA Matrix

## 1. Automated Test Suites

### Mobile Unit, Widget & Integration Tests (Flutter)
```bash
cd apps/mobile
flutter test
```
- **878 Automated Tests (100% Passing)** across 60+ test suites:
  - `ai_assistant_notifier_test.dart` (AI gateway delegation, honest offline state, zero fake strings)
  - `obd2_malformed_and_edge_cases_test.dart` (ELM327 malformed response rejection, Mode 01/03/04 parsing, noise filtering)
  - `audit_regression_fixes_test.dart` (Web safety guards, scooter fallback resolution, session purge, transport permission checks)
  - `vehicle_command_pipeline_test.dart` (Protocol discovery, safety rules, command validation)
  - `vehicle_health_diagnostics_test.dart` (11 health categories, SAE DTC dictionary, clear gates)
  - `app_shell_and_settings_test.dart` (Unit conversions, notification priority, settings persistence)
  - `navigation_bloc_test.dart` (Turn-by-turn routing, motorcycle Routes API integration, voice guidance)
  - `auth_bloc_test.dart` (Login, OAuth, phone OTP, logout, session restoration)
  - `motorcycle_3d_assets_test.dart` (GLB asset verification, model resolver, fallbacks)
  - `enterprise_services_test.dart` (SecurityService, crash detection, sync engine)
  - `vehicle_model_resolver_test.dart` (Motorcycle, scooter, ICE, EV, and generic fallback resolution)
  - Full BLoC, repository, transport, and widget interaction coverage.

### Backend Unit & Integration Tests (NestJS / Jest)
```bash
pnpm --filter backend test
```
- **114 Automated Tests (22 Suites, 100% Passing)**:
  - `ai_assistant.service.spec.ts` (Prompt injection, safety policies, user memory, knowledge RAG, tools, multi-language localization)
  - `jwt.strategy.spec.ts` (JWT validation, phone OTP riders without email, missing user ID rejection)
  - `auth.service.spec.ts` (JWT issuance, refresh token rotation, phone OTP, password hashing)
  - `vehicles.controller.spec.ts` (Ownership verification, vehicle profile CRUD)
  - `diagnostics.controller.spec.ts` (DTC retrieval, fault clearance safety gates)
  - `vehicle_health.service.spec.ts` (Diagnostics, maintenance, alerts, documents)
  - `trips.service.spec.ts` (Trip slices, spatial GeoJSON, aggregation)
  - `obd_diagnostics.service.spec.ts` (OBD-II PID decoding, DTC parsing)
  - `navigation.service.spec.ts` (Routes API v2 TWO_WHEELER client, route planning, curvature matrix)

### Monorepo Full Verification Script
```bash
./scripts/validate.sh
```
Executes complete monorepo compilation, TypeScript checks, backend linting, backend tests, Flutter static analysis (`flutter analyze`), and Flutter test suite.

---

## 2. Real Device Testing Checklist (Hardware-Dependent)

The following capabilities are unit-tested and mocked in software; physical on-vehicle verification requires real hardware in the field:

| Test Flow | Hardware Requirements | Verification Criteria | Status |
| :--- | :--- | :--- | :--- |
| **BLE ECU Connection** | Physical Motorcycle (Yamaha Y-Connect / Ducati Link / OBD-II BLE) | Discovers GATT services, handshakes protocol, streams live RPM & speed, handles disconnect/reconnect | `EXTERNAL_VALIDATION_REQUIRED` |
| **Active Ride Recording** | Real Road Test (Android 14/15 Device) | Foreground service keeps high-precision GNSS active with screen locked; dead reckoning IMU fusion | `EXTERNAL_VALIDATION_REQUIRED` |
| **DTC Fault Scanning & Clear** | Physical Vehicle ECU with active fault | Reads DTC codes via ELM327/CAN, displays severity badge; stationary safety gate blocks clearing while in motion | `EXTERNAL_VALIDATION_REQUIRED` |
| **SMS OTP Verification** | Live Carrier SIM / Twilio SMS Gateway | Delivers 6-digit OTP SMS within carrier timeout window | `EXTERNAL_VALIDATION_REQUIRED` |
| **Emergency SOS Dispatch** | Cellular voice/SMS carrier | Dispatches automated SOS payload with GPS coordinates to emergency contacts | `EXTERNAL_VALIDATION_REQUIRED` |
