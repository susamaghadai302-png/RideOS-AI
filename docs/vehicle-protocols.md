# RideOS Vehicle Protocols, Compatibility Engine & Telemetry Normalization

## 1. Vehicle Compatibility Architecture

RideOS Pro uses a capability-driven pipeline that maps physical hardware BLE GATT services to normalized telematics, digital twin models, and safety-gated controls:

```
Bluetooth Device Advertisements
             ↓
ProtocolDetector (GATT Service UUIDs & Manufacturer Data)
             ↓
VehicleCompatibilityEngine (Status: Supported / Partially Supported / Unsupported)
             ↓
VehicleRegistry (Verified Profiles, Specs, Maintenance Intervals)
             ↓
VehicleModelRegistry (Exact 3D GLB Asset / Fallback Flag)
             ↓
Normalized Telemetry Stream (0% Synthetic Data)
```

---

## 2. Protocol Detection Matrix

| Protocol Adapter | Primary Service UUID | Matched Advertisements | Telemetry Fields | Write Controls |
| :--- | :--- | :--- | :--- | :--- |
| **Yamaha Y-Connect CCU** | `0000FEE0` | `CCU`, `Y-CONNECT`, `YAMAHA` | Speed, RPM, Coolant Temp, Battery V, Gear, Lean Angle | Riding Mode, Hazard Lights |
| **Ducati Multimedia (DMS)** | `000018F0` | `DMS`, `DUCATI` | Speed, RPM, Engine Temp, Battery V, Traction Control | Riding Mode, DQS |
| **SAE J1979 OBD-II (ELM327)**| `0000FFF0` / `0000FFE0` | `OBD`, `ELM327`, `VGATE`, `OBDLINK` | Speed, RPM, Coolant Temp, MAF, Throttle, Voltage | DTC Clear (Speed == 0) |
| **Generic BLE Battery Service** | `0000180F` | Any Battery GATT Profile | Battery Voltage / Level (12V) | Read-Only |

---

## 3. Centralized Vehicle Catalog (`VehicleRegistry`)

The `VehicleRegistry` provides typed metadata for verified motorcycles and vehicles:

- **Yamaha MT-09 SP** (`v_yamaha_mt09_sp`): 890cc CP3, Yamaha Y-Connect CCU, `yamaha_r1m.glb`.
- **Yamaha YZF-R1M** (`v_yamaha_r1m`): 998cc CP4, Yamaha Y-Connect CCU, `yamaha_r1m.glb`.
- **Ducati Panigale V4 S** (`v_ducati_v4s`): 1,103cc Stradale V4, Ducati DMS, `ducati_panigale.glb`.
- **BMW M 1000 RR** (`v_bmw_m1000rr`): 999cc ShiftCam, OBD-II CAN-BUS, `bmw_m1000rr.glb`.
- **Universal OBD-II Vehicle** (`v_generic_obd2`): Universal CAN-BUS, standard OBD-II PID stream, `modelAvailable = false` (explicitly rendered with placeholder fallback).

---

## 4. Vehicle 3D Model Registry (`VehicleModelRegistry`)

To ensure visual truthfulness, RideOS Pro strictly checks 3D asset availability. If an exact model is not available in the local bundle, `modelAvailable` is marked `false` and the 3D garage displays an informative fallback badge rather than showing an incorrect motorcycle model.

---

## 5. Normalized Telemetry Schema

```dart
class NormalizedTelemetry {
  final TelemetryValue<double?> speed;
  final TelemetryValue<double?> rpm;
  final TelemetryValue<double?> engineTemperature;
  final TelemetryValue<double?> batteryVoltage;
  final TelemetryValue<int?> batteryPercentage;
  final TelemetryValue<int?> fuelLevel;
  final TelemetryValue<double?> odometer;
  final TelemetryValue<double?> tripDistance;
  final TelemetryValue<int?> gear;
  final TelemetryValue<String?> ridingMode;
  final TelemetryValue<bool?> absActive;
  final TelemetryValue<bool?> tractionControl;
  final TelemetryValue<List<String>?> faultCodes;
  final DateTime timestamp;
}
```

```dart
class TelemetryValue<T> {
  final T? value;
  final String unit;
  final bool available;
  final String source; // "vehicle_ecu" | "gnss_receiver" | "sensor_hub"
  final DateTime timestamp;
}
```

If a sensor is missing from the ECU payload, `available` is set to `false`, and the UI displays `Unavailable` (not `0`).
