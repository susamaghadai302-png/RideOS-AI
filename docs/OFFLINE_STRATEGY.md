# RideOS AI: Offline & Degraded Mode Strategy

## 1. Core Philosophy
The motorcycle environment is inherently unpredictable. Network connectivity will drop in rural areas, tunnels, and deep canyons. The rider intelligence platform must gracefully degrade rather than fail catastrophically. 

**Rule: Never stall the rider's primary UI due to a background network failure.**

## 2. Navigation Degradation Matrix

| Capability | Online (4G/5G) | Degraded (2G/Edge) | Offline (No Network) |
| :--- | :--- | :--- | :--- |
| **Route Calculation** | Primary API (Google Routes) | Primary API (Google Routes) | Local Cache / Unavailable Error |
| **Active Navigation** | Full Telemetry & Rerouting | Minimal GPS Tracking | GPS Tracking Only (No Rerouting) |
| **Traffic Data** | Live Colors on Polyline | Cached/Historical only | Unavailable |
| **ETA Accuracy** | Live Dynamic ETA | Static (Distance / Avg Speed) | Static (Distance / Avg Speed) |
| **Map Tiles** | Vector/Satellite Streaming | Low-Res Caching | Pre-downloaded Regions only |

## 3. Graceful Failure Implementation
1. **API Timeout Hierarchy**: All routing requests must enforce a strict `connectTimeout` and `receiveTimeout` (e.g., 6000ms).
2. **StateError Propagation**: As implemented in `GoogleRouteAdapter` and `OsrmRouteAdapter`, network failures must be caught and re-thrown as specific domain exceptions (e.g., `StateError('Routing providers unavailable')`).
3. **UI Reflection**: The `ProductionNavigationScreen` must catch these exceptions and display clear, non-intrusive HUD warnings (e.g., "Offline: Routing Unavailable") instead of infinite loading spinners.
4. **GPS Resilience**: The `TurnByTurnNavigationEngine` must continue to track the rider's physical GPS coordinate against the last known polyline even if rerouting fails. 

## 4. Hardware Independence
While the system is offline, it must continue to operate based entirely on local hardware (GPS chip, Bluetooth LE to vehicle) without requiring a cloud-sync heartbeat to remain functional.
