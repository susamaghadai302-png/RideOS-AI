# Master Architecture

## Domain Driven Design

RideOS follows a strict Clean Architecture, decoupling the canonical domain layer from external provider implementations. 
This prevents the application from inheriting the constraints, terminology, or data gaps of any specific provider (e.g., Google Routes API, OSRM, AWS Location).

### Key Components

1. **Domain Models (`apps/mobile/lib/features/maps/domain/models/`)**
   - Canonical definitions representing the rider's universe (`RideRouteRequest`, `RideRouteResponse`, `VehicleTelemetry`).
   - Strict nullable semantics. Data is never hallucinated (e.g., if traffic data is absent, it is `null` or `UNAVAILABLE`, not `0` or `no traffic`).

2. **Core Services / Adapters (`apps/mobile/lib/features/maps/core/services/`)**
   - Classes like `RoadOsRoutingEngine` act as infrastructure adapters.
   - They consume `RideRouteRequest` and map the external provider's JSON back into the canonical `RideRouteResponse`.

3. **Application Services (`apps/mobile/lib/features/maps/services/`)**
   - `TurnByTurnNavigationEngine`: Consumes the canonical `RideRouteResponse` and orchestrates the state machine (e.g., tracking `ManeuverProximityState`).
   
4. **Presentation (`apps/mobile/lib/features/maps/presentation/`)**
   - `ProductionNavigationScreen`: Renders the UI exclusively based on the canonical state emitted by `TurnByTurnNavigationEngine`.

### Provider Abstraction
```
                    PROVIDERS
                       |
          +------------+------------+
          |                         |
   Google Routes API          OSRM Provider
          |                         |
          +------------+------------+
                       |
                ROUTE ADAPTER (RoadOsRoutingEngine)
                       |
                RideRouteResponse
                       |
             NavigationSession (TurnByTurnNavigationEngine)
                       |
          +------------+-------------+
          |            |             |
       Phone HUD   Smart Display   AI Context
```
