# RideOS Complete System Architecture

## 1. Global End-to-End Architecture

```mermaid
graph TD
    subgraph "Hardware & Sensors"
        BLE_Device[Motorcycle ECU / OBD-II / Sensor Hub]
        GNSS_Hardware[High-Precision GNSS Receiver]
    end

    subgraph "Mobile Client — Context & Telemetry Engine"
        Scanner[DeviceScanner — RSSI & Service Filter]
        ProtoDetector[ProtocolDetector — GATT UUIDs & Mfg Data]
        CompatEngine[VehicleCompatibilityEngine — Verification & Matrix]
        ActiveContext[ActiveVehicleContext — Single Authoritative State]
        ModelResolver[VehicleModelResolver — Exact 3D GLB vs Fallback]
        FreshnessPolicy[DataFreshnessPolicy — Live vs Stale Timeout]
        StatusEngine[VehicleStatusEngine — 0% Synthetic Data]
    end

    subgraph "Mobile Client — Core Features"
        HomeUI[Home Dashboard — Active Vehicle Card & Live Telemetry]
        GarageUI[3D Virtual Garage — Photorealistic Digital Twin]
        NavEngine[Navigation & Maps — Real-Time HUD & Deadband Filter]
        TripEngine[TripManager — Offline Queue & Elevation Profile]
        HealthEngine[Vehicle Health & DTC Scanner — 11 Categories]
        MaintMgr[Maintenance Manager — Odometer Service Countdown]
        NotifCenter[Notification Hub — Deep Links & Alert Priority]
    end

    subgraph "Backend & Cloud Services (NestJS)"
        AuthGuard[JwtAuthGuard — Strict Rider Scoping]
        HealthService[VehicleHealthService — DTCs & Logs]
        TripsService[TripsService — Spatial Compression & Sync]
        Deleter[AccountDeletionService — Cascading Erasure]
    end

    subgraph "Storage & Cloud Persistence"
        MongoDB[(MongoDB — Riders, Profiles, Maintenance, Documents)]
        TimescaleDB[(TimescaleDB — High-Frequency Telemetry Streams)]
        LocalCache[(SQLite / SecureStorage — Local Offline Buffer)]
    end

    BLE_Device --> Scanner
    Scanner --> ProtoDetector
    ProtoDetector --> CompatEngine
    CompatEngine --> ActiveContext
    ActiveContext --> ModelResolver
    ActiveContext --> FreshnessPolicy
    ActiveContext --> StatusEngine
    
    ActiveContext --> HomeUI
    ActiveContext --> GarageUI
    ActiveContext --> HealthEngine
    ActiveContext --> TripEngine
    
    GNSS_Hardware --> NavEngine
    TripEngine --> LocalCache
    LocalCache --> TripsService
    TripsService --> TimescaleDB
```

---

## 2. Active Vehicle Context Synchronization

Every screen in RideOS Pro observes a single unified `ActiveVehicleContext` instance:

```dart
class ActiveVehicleContext {
  final String vehicleId;
  final VehicleProfile? profile;
  final VehicleConnectionStatus connectionStatus;
  final VehicleModelStatus modelStatus;
  final String model3DPath;
  final List<String> supportedCapabilities;
  final NormalizedTelemetry telemetry;
  final TelemetryQuality telemetryQuality;
  final List<String> activeDtcCodes;
  final String? activeTripId;
  final DateTime lastUpdated;
}
```

### Data Freshness Policy
- **`LIVE`**: Telemetry packet received $\le$ 3.5 seconds ago.
- **`STALE`**: No update in $>$ 3.5 seconds (displays informative stale warning).
- **`UNAVAILABLE`**: Sensor unmapped or Bluetooth connection inactive (displays explicit `Unavailable` badge).
- **`INVALID`**: Range check or checksum validation failed.

---

## 3. Vehicle Switching & Multi-Vehicle Isolation
- Switching from Vehicle A to Vehicle B atomically unloads active 3D WebGL meshes, resets live telemetry, clears DTC caches, and associates trips and maintenance strictly with the new vehicle ID.
