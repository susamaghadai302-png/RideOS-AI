# RideOS Testing & QA Matrix

## 1. Automated Test Suites

### Mobile Unit & Golden Tests (Flutter)
```bash
cd apps/mobile
flutter test
```
- **63 Unit & Widget Tests**:
  - `vehicle_command_pipeline_test.dart` (Protocol discovery, safety rules, command validation)
  - `vehicle_health_diagnostics_test.dart` (11 health categories, SAE DTC dictionary, clear gates)
  - `app_shell_and_settings_test.dart` (Unit conversions, notification priority, settings persistence)
  - `navigation_bloc_test.dart` (Turn-by-turn routing, voice guidance)
  - `auth_bloc_test.dart` (Login, OAuth, logout, session restoration)
  - `motorcycle_3d_assets_test.dart` (GLB asset verification)
  - `enterprise_services_test.dart` (SecurityService, crash detection, sync engine)

### Backend Unit & Integration Tests (NestJS / Jest)
```bash
pnpm --filter backend test
```
- **39 Integration Tests**:
  - `vehicle_health.service.spec.ts` (Diagnostics, maintenance, alerts, documents)
  - `trips.service.spec.ts` (Trip slices, spatial geojson, aggregation)
  - `auth.service.spec.ts` (JWT issuance, refresh, password hashing)
  - `obd_diagnostics.service.spec.ts` (OBD-II PID decoding, DTC parsing)
  - `navigation.service.spec.ts` (Route planning, curvature matrix)

---

## 2. Real Device Testing Checklist (Hardware-Dependent)

| Test Flow | Requirements | Verification Criteria |
| :--- | :--- | :--- |
| **BLE ECU Connection** | Physical Motorcycle (Yamaha/Ducati/OBD-II) | Discovers GATT services, streams RPM & speed, handles disconnect gracefully |
| **Active Ride Recording** | Real Road Test | Background foreground service keeps GPS active with screen locked |
| **DTC Fault Scanning** | Vehicle ECU with fault triggered | Reads DTC code, displays severity badge, requires stationary state to clear |
