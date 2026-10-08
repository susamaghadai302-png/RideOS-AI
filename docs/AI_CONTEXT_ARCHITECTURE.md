# AI Context Architecture

## Objective
Provide the LLM with a strictly validated, immutable snapshot of the vehicle state. The AI must reason *only* over verified evidence and never access mutable hardware references or fabricate data.

## `RideAIContext`
The unified application context containing:
- **Telemetry:** `VehicleTelemetry` (RPM, speed, engine temps).
- **Navigation:** `RideRouteResponse` and GPS quality confidence.
- **Safety:** Current active `RiderAlert` list and `SensorFusionState`.
- **Weather:** A simple string (or specific model) representing verified weather.

Every data point encapsulates its timestamp, source, and quality confidence (e.g. `STALE`, `UNAVAILABLE`, `VERIFIED`).

## Usage Rules
- `RideAIContext` objects are generated dynamically when a prompt is issued.
- If data is missing or a hardware transport is disconnected, the context fields default to `UNAVAILABLE` or `insufficientData`.
- Artificial values (like default RPM 0) are strictly banned.
