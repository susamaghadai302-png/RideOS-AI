# Next-Generation Rider Intelligence Platform: Implementation Plan

## 1. CURRENT STATE
- **Truthful Baseline Established**: The repository is clean. Zero synthetic production values. `flutter analyze` and all 789 tests pass. Release build is functional.
- **Navigation**: Relies on a generic MapProvider interface leveraging standard Google Maps Flutter plugins and the Google Routes API. Two-wheeler route fallback is implemented but lacks robust integration with advanced metadata like India flyover info or offline caching.
- **Hardware/Telemetry**: Relies on BLE ELM327 parsing (`Obd2CommandBuilder`). Classic Bluetooth RFCOMM and advanced device discovery (Companion Device Manager) are stubbed or partially implemented. Hardware verification remains outstanding.
- **AI Context**: Purely relies on verified JSON schemas from Gemini. Fakes have been stripped, meaning UI components appropriately display `DATA_UNAVAILABLE` when physical systems are disconnected.
- **Safety & Maintenance**: Abstracted interfaces exist but need wiring into multi-sensor consensus loops (accelerometer, gyroscope, verified OBD drops).

## 2. TARGET STATE
- **Navigation Intelligence**: Robust two-wheeler routing, strict maneuver countdowns, offline-degraded mode handling, and cost-controlled API utilization.
- **Vehicle Data Fabric**: Canonical `VehicleTelemetry` models enforcing strong source/confidence guarantees for every parameter.
- **BLE + BT Classic Transports**: Clear separation of Bluetooth Low Energy (for modern sensors) and Bluetooth Classic/SPP (for traditional OBD-II and older CCUs) using Android's latest permissions and Companion Device APIs.
- **Evidence-Driven Subsystems**: Predictive Maintenance, Smart SOS, and AI Copilot will strictly depend on real temporal evidence streams and reject false positives via multi-signal consensus.

## 3. DEPENDENCIES & RESEARCH BASIS
- Google Maps Platform / Navigation SDK for Flutter (to be audited vs Routes API)
- Android Companion Device Manager (for Bluetooth)
- Zod JSON Schemas for AI structured outputs
- SQLite/Hive for offline routing/telemetry caching

## 4. RISKS
- **Migration Cost**: Switching from `google_maps_flutter` + Routes API to the Google Navigation SDK requires significant architecture rewrites and could impact existing marker/polyline state loops.
- **Platform Specifics**: Bluetooth Classic SPP lacks robust cross-platform Flutter plugins compared to BLE. Android-specific Kotlin bridges may be necessary.
- **API Cost Scaling**: Over-polling the Google Routes/Geocoding API will cause billing spikes. Cost control mechanisms (debounce/cache) are mandatory.

## 5. MILESTONES & ORDER OF IMPLEMENTATION

### Milestone 1: Navigation Intelligence & True Two-Wheeler Routing (Phases 1-3)
- Audit Navigation SDK vs Routes API (`docs/NAVIGATION_ARCHITECTURE_DECISION.md`).
- Implement canonical `RideRouteRequest/Response` models enforcing `TWO_WHEELER`.
- Create Rider Navigation UI with strict state management (countdown, ETA, GPS status).

### Milestone 2: Offline Resilience & Cost Control (Phases 4, 18)
- Define `docs/OFFLINE_STRATEGY.md` and `docs/API_COST_CONTROL.md`.
- Implement API coalescing, route caching, and graceful capability degradation.

### Milestone 3: Vehicle Data Fabric & Hardware Transports (Phases 5-7, 13)
- Finalize canonical `VehicleTelemetry` with timestamps and confidence flags.
- Separate `BleTransport` and `BluetoothClassicTransport`.
- Standardize the Smart Display/Helmet payload sync protocols.

### Milestone 4: Safety, SOS & Smart Maintenance (Phases 10-12, 17)
- Integrate accelerometer/gyro multi-signal crash candidate detection.
- Implement countdown-based false-positive protection for Smart SOS.
- Enforce evidence-driven maintenance observations (`INSUFFICIENT_DATA` handling).
- Audit Android permissions (foreground services, background location).

### Milestone 5: Rider Copilot & Trip Intelligence (Phases 8-9, 14-16)
- Wire verified `RideAIContext` into the AI Copilot.
- Implement strict intent parser and tool selection policy.
- Build canonical `TripSession` and digital twin fidelity layers.

## 6. TEST STRATEGY
- **Zero-Regression Mandate**: The existing 789 unit/widget tests must not drop.
- **Transport Tests**: Mock ELM327 streams and BT Classic socket drops.
- **AI Tests**: Verify Copilot refuses to hallucinate unsafe commands.
- **Safety Tests**: Inject noisy IMU profiles and verify the SOS system rejects false positives.

## 7. ROLLBACK STRATEGY
- Every milestone will be committed as a standalone feature branch (or isolated commit).
- If an architectural shift (e.g., migrating to Navigation SDK) introduces fatal regressions or excessive billing, `git reset --hard` to the truthful baseline checkpoint will be enforced.
