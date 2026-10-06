# Navigation Architecture Decision

## Context
RideOS AI requires a premium, distraction-minimized, two-wheeler-optimized navigation layer. We must decide whether to continue using the combination of `google_maps_flutter` with the standard **Google Routes API**, or migrate to the official **Google Navigation SDK for Flutter**.

## Comparison Matrix

| Feature | Google Maps + Routes API | Google Navigation SDK for Flutter |
| :--- | :--- | :--- |
| **Turn-by-Turn Capability** | Custom implementation required (maneuver logic, countdown). | Native out-of-the-box TBT UI and audio guidance. |
| **TWO_WHEELER Support** | Fully supported via API parameters. | Supported natively by the SDK routing engine. |
| **Custom UI / HUD** | **Maximum flexibility**. Total control over map styling, polyline drawing, and overlaying telematics/HUD elements. | **Limited/Opinionated**. Hard to deeply customize the UI for a specialized motorcycle Smart Display. |
| **Flutter Compatibility** | Highly stable (`google_maps_flutter`). | Requires heavy native integration; Flutter wrapper has limitations on deep customization. |
| **API / Billing Impact** | Pay-per-route calculation (Routes API) + dynamic map loads. Can be aggressively cached and throttled to control cost. | Tiered pricing based on Monthly Active Users (MAUs) or per-trip. SDK handles internal caching. |
| **Current RideOS Compatibility** | Already integrated (`RoadOsRoutingEngine`). Migration cost is ZERO. | Migration cost is HIGH. Requires ripping out existing routing architecture. |
| **Hardware Output (Smart Display/Helmet)**| Extremely easy to serialize route steps into custom bytes for ESP32/CCU integration. | Difficult to extract raw, low-level maneuver byte-streams out of the opaque SDK. |

## Decision
**Remain on Google Maps Flutter + Google Routes API.**

### Justification
RideOS is a custom operating system that demands total architectural control over the presentation layer to render specialized AI copilots, predictive maintenance widgets, and distraction-free motorcycle HUDs. The Navigation SDK is designed for standard ride-sharing/delivery apps and is too restrictive for our canonical `RideAIContext` and wearable output pipelines (e.g., transmitting next-turn telemetry bytes to a Bluetooth helmet). 

By staying with the Routes API, we retain absolute control to build `RideRouteRequest` parameters, extract `TWO_WHEELER` data, and decouple the routing data fabric from the presentation layer.
