# Sensor Fusion Foundation

## Objective
Provide a unified structure for hardware physics sensors (accelerometer, gyroscope, GPS) to detect severe events.

## Components
- `SensorSample`: Wraps 3D vectors (x, y, z) and timestamps.
- `SensorFusionState`: `normal`, `degraded` (missing GPS or sensors), `candidateEvent` (unusual spikes requiring validation), and `insufficientData` (hardware absent).

## Logic Rule
"A single accelerometer spike must NEVER become CRASH DETECTED." Multi-sensor correlation over time is explicitly required by the architecture before escalating to `SosState.candidate`.
