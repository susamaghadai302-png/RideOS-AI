# Bluetooth Classic RFCOMM Final Decision

## Research & Verification Summary

During the Phase 5.9 Platform Integration Audit, we compared the current `bluetooth_classic` dependency against `flutter_classic_bluetooth`, `flutter_bluetooth_serial`, and native Android `BluetoothSocket` / RFCOMM implementations.

### Package Analysis

1. **`bluetooth_classic` (Current)**
   - **Maintenance:** Stalled.
   - **Android Compatibility:** Bound to older permissions.
   - **RFCOMM Support:** Yes, but stream management is flawed (e.g., "Stream has already been listened to" errors are common).
   - **Action:** Retained strictly for architecture interface bounding. Do NOT deploy to physical riders.

2. **`flutter_bluetooth_serial`**
   - **Maintenance:** Abandoned / Legacy.
   - **Action:** Rejected.

3. **`flutter_classic_bluetooth`**
   - **Maintenance:** Active.
   - **API Quality:** Modern Stream/Sink paradigm.
   - **Action:** Strong candidate for generic serial, but still abstracts critical low-level buffer management necessary for OBD-II J1979 protocols.

## Final RideOS Architecture Decision

**Do not replace `bluetooth_classic` with another Dart package.**

Instead, the final production implementation will bypass third-party Dart Bluetooth packages entirely and implement a **custom Platform Channel (`MethodChannel`) using native Kotlin `BluetoothSocket.connect()`**.

**Why?**
- ELM327 OBD-II diagnostic sequences require strict, deterministic byte buffering. Third-party Dart abstractions inherently introduce latency and hidden stream-controller race conditions that corrupt standard AT commands.
- Android 12+ (API 31) introduced complex `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` permissions. Custom native code ensures we correctly handle `SecurityException` and `neverForLocation` flags without waiting for an open-source maintainer to update their library.
- Direct socket management allows us to implement exact timeouts (e.g., dropping the socket if `ATZ` takes longer than 2 seconds).

### Current Status
- `bluetooth_classic` remains installed purely to validate the `HardwareTransport` and `VehicleCapabilities` abstraction boundaries.
- **Physical Verification:** `UNVERIFIED`
- **Software Verification:** `SOFTWARE_VERIFIED` (Interface bounded)
