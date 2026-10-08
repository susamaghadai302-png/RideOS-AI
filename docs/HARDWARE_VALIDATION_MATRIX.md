# Hardware Validation Matrix

This matrix tracks the genuine physical validation states of all hardware subsystems. 

## Truth States Definitions
- **IMPLEMENTED**: Software architecture is built and isolated unit tests pass.
- **SOFTWARE_VERIFIED**: End-to-end integration tests pass using strictly isolated test-doubles.
- **PHYSICAL_DEVICE_VERIFIED**: Successfully connected and validated using real physical hardware via ADB or local network.
- **UNVERIFIED**: Implementation exists but has not been tested with the actual target hardware.
- **CONFIGURATION_REQUIRED**: Dependent on API keys, secrets, or deployment configs.
- **UNAVAILABLE**: Feature or capability is missing or not supported.
- **BLOCKED**: Verification cannot proceed due to missing dependencies.

## Matrix

| Subsystem | Truth State | Date | Evidence / Notes |
| :--- | :--- | :--- | :--- |
| **Android Physical Device** | PHYSICAL_DEVICE_VERIFIED | 2026-10-06 | Realme 14x 5G successfully paired and active via ADB wireless. |
| **BLE Vehicle Discovery** | UNVERIFIED | 2026-10-06 | Hardware architecture (BleTransport) IMPLEMENTED. No physical motorcycle BLE beacon present. |
| **Bluetooth Classic** | UNVERIFIED | 2026-10-06 | Hardware architecture (BluetoothClassicTransport) IMPLEMENTED. No physical RFCOMM target present. |
| **OBD-II (ELM327)** | UNVERIFIED | 2026-10-06 | Hardware architecture (ObdTransport, PidRegistry) IMPLEMENTED. No physical OBD adapter plugged in. |
| **Vehicle ECU** | UNVERIFIED | 2026-10-06 | - |
| **TPMS Sensor** | UNVERIFIED | 2026-10-06 | - |
| **Telemetry Parsing** | SOFTWARE_VERIFIED | 2026-10-06 | Raw bytes converted to `VehicleTelemetry` tested in isolation. |
| **Crash Detection** | SOFTWARE_VERIFIED | 2026-10-06 | Mathematical pipeline verified, physical drop testing UNVERIFIED. |
