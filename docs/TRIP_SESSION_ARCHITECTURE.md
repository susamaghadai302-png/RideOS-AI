# Trip Session Architecture

## Objective
Maintain a truthful record of a rider's trip including diagnostics, route, alerts, and vehicle telemetry.

## Structure
`TripSession`:
- Tracks `startTime`, `endTime`, `duration`, `distanceMeters`.
- Links to canonical `RideRouteResponse`.
- Maintains lists of `RiderAlert` events.
- Captures periodic `RideAIContext` snapshots to provide rich historical analytics based only on actual evidence.

## Analytics Policy
Analytics and "Safety Scores" are explicitly prohibited from generating artificial values. Metrics like "harsh braking" can only be evaluated against strict `SensorSample` sequences recorded during the trip session.
