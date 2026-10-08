# Telemetry Quality Engine

## Objective
Enforce rigorous staleness checks on telemetry to prevent the app from displaying frozen values when a connection hangs or data is dropped.

## `TelemetryQualityEngine`
- `evaluateQuality`: Compares the timestamp of a data point against `_staleThreshold` (e.g., 10 seconds).
- Validates that the underlying `HardwareTransport` is actually connected.

## States
- `verified`: Data is fresh and hardware is active.
- `stale`: Data is older than the threshold, or the hardware disconnected but a last-known value exists.
- `unavailable`: No prior data exists, or the adapter is fully disconnected without cache.
