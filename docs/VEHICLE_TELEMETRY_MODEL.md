# Canonical Vehicle Telemetry Model

## Core Philosophy
The core principle of `VehicleTelemetry` is **Explicit Quality Constraints**. 

If a value is not derived from verified hardware packets, it does not exist. The system does not default to `0` or `false` when a sensor is missing; it defaults to `null` with a `TelemetryQuality` of `unavailable` or `unverified`.

## `TelemetryQuality` Enumeration
- **`verified`**: Arrived over a cryptographic or strictly parsed hardware interface within the validity window (usually < 2000ms).
- **`stale`**: Was `verified`, but the latest polling interval timed out or was dropped. Good for historical logs, invalid for real-time safety.
- **`estimated`**: Derived from secondary sources (e.g., GPS speed instead of OBD-II wheel speed).
- **`unavailable`**: Hard evidence that the capability is not supported by the current adapter.

## Missing Data Handling
AI inference, crash detection, and smart displays rely heavily on `isValid` checks. If `isValid == false`, the downstream system must cleanly fallback or gracefully degrade its display elements rather than processing a synthetic value.
