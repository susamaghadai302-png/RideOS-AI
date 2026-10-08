# OBD Validation Report

## Current Status: UNVERIFIED

Physical testing of OBD-II adapters over RFCOMM Bluetooth Classic is currently blocked because no physical adapter is connected to the testing environment. 

### Architecture Completed
- ELM327 initialization (`ATZ`, `ATE0`, `ATL0`, `ATS0`, `ATSP0`) is implemented in `ObdTransport`.
- Capability discovery logic uses Mode 01 PID 00.
- State machines are explicitly built for retries, querying, and errors.
- Test suites explicitly verify that the absence of hardware results in a direct error, not a mock state.

### Next Steps
1. Procure physical OBD-II adapter (e.g. OBDLink MX+ or generic ELM327).
2. Pair via Bluetooth settings on physical Android test device.
3. Observe raw byte decoding into `PidSupport` registry.
