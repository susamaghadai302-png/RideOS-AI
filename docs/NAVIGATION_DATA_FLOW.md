# Navigation Data Flow

## 1. Request Phase
1. User selects a destination via UI.
2. `ProductionNavigationScreen` pushes a `RideRouteRequest` to the `TurnByTurnNavigationEngine` or a `RouteRequestCoordinator` (Phase 9).
3. The engine passes the request to the `RoadOsRoutingEngine`.

## 2. Infrastructure/Adapter Phase
1. `RoadOsRoutingEngine` converts `RideRouteRequest` into a provider-specific payload (e.g., OSRM URL or Google Routes JSON).
2. HTTP call executes.
3. Response is parsed. Provider-specific anomalies are handled.
4. If a capability (like toll pricing or two-wheeler traffic) is absent in the response, it is mapped as `null` or `UNAVAILABLE` in the domain model.
5. Adapter returns a canonical `RideRouteResponse`.

## 3. Session Management Phase
1. `TurnByTurnNavigationEngine` receives `RideRouteResponse` and initializes the active navigation state.
2. The engine tracks current GPS position (`updateGpsLocation`).
3. GPS coordinates are projected onto the `fullPolyline`.
4. Progress is measured against `segments` and `maneuvers`.
5. Off-route detection heuristics evaluate divergence from the polyline to trigger reroutes.

## 4. UI/Consumer Phase
1. `TurnByTurnNavigationEngine` broadcasts the `NavigationSessionState` and specific metrics (`remainingDistanceKm`, `proximityState`).
2. `ProductionNavigationScreen` (HUD) binds to these streams and updates visual elements (instruction banner color, ETA).
3. (Future) `NavigationOutput` is dispatched via `BluetoothClassicTransport` to the Smart Display.
