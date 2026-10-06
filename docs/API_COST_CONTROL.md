# RideOS AI: API Cost Control & Rate Limiting Strategy

## 1. Business Context
Mapping APIs (especially Google Routes API) charge per request. In a live navigation scenario, aggressive polling or unrestrained rerouting can quickly exhaust API quotas and generate massive, unacceptable operational costs.

## 2. Cost Control Rules

### Rule 1: No Unrestrained Polling
- **Never** poll the Routing API on a timer (e.g. `Timer.periodic(1.second)`). 
- Routing requests must only be triggered by **explicit user intent** (selecting a destination) or **strict off-route thresholds**.

### Rule 2: Strict Off-Route Thresholds
- Rerouting must only trigger if the rider has deviated from the `activeRoute.fullPolyline` by more than **35 meters** for **3 consecutive GPS samples** (e.g., across 3 seconds).
- This prevents GPS "jitter" (multi-path errors near tall buildings) from triggering false reroutes.
- *Implemented in `TurnByTurnNavigationEngine`.*

### Rule 3: Client-Side Throttle (Debounce)
- Implement a cooldown period (e.g., 10-15 seconds) after a successful reroute before another reroute can be triggered. 
- If the rider takes multiple wrong turns in rapid succession, the system waits for the cooldown to expire before hitting the API again.

### Rule 4: Caching and Offline Fallback (IMPLEMENTED)
- Recently calculated routes are kept in an LRU memory cache via `RouteRequestCoordinator`.
- If an exact origin/destination request is made within a 5-minute window, the system returns the cached `CachedRouteResponse` rather than hitting the network.
- Coalescing (Deduplication): Concurrent identical requests share the same in-flight `Future`.
- Cancellation: Late/abandoned request results are aborted dynamically via `generationId`.
- Backoff: Transient failures use exponential bounded backoff. Permanent config errors (API Keys) fail immediately.
- If the API quota is exhausted (HTTP 429), the application must immediately fall back to the graceful offline state (or an open-source alternative like OSRM if configured).

## 3. Telemetry Sync Cost Control
- **Batching**: Fleet analytics and telemetry data must be batched locally.
- **Sync Windows**: Trigger `CloudSyncManager` synchronization only when high-quality network connectivity is detected or when the ride session concludes, rather than streaming data per-second over costly cellular data.
