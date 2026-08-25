# RoadOS AI — Global Commercial Launch Requirements & External Dependency Roadmap

> **Separating Pure Software Implementation from External Accounts, Regulatory Approvals, and Physical Hardware**

---

## 1. Summary of Completed Software Implementations (Active Today)

| Component | Software Status | Notes |
| :--- | :--- | :--- |
| **Flutter Mobile Client (`apps/mobile`)** | Production Release Ready | 10 navigation destinations, 3D Superbike digital twin, spatial HUD navigation, Voice AI copilot, Profile Vault. |
| **NestJS Backend (`apps/backend`)** | Hardened & Active | Global ValidationPipe, security headers, CORS allow-list, live Google Gemini streaming endpoint. |
| **Multi-Region Map Abstraction** | Complete | `MapEngineFactory` with Google Maps, MapLibre OSM, and Mapbox support with auto failover. |
| **Internationalization & Unit Conversion** | Complete | 8 languages (`AppLocalizations`) and dynamic metric/imperial/pressure/temperature conversion (`RegionConfig`). |
| **Offline-First Resilience** | Complete | `OfflineSyncEngine` with Last-Write-Wins (LWW) conflict resolution and offline visual status banners. |

---

## 2. External Dependencies Required for Global Commercial Operations

### 2.1 Category 2: Third-Party Accounts & API Credentials
The following environment variables can be provided in `.env` to enable live cloud capabilities:

1. **Google Gemini API Key (`GOOGLE_GEMINI_API_KEY`)**:
   - *Purpose*: Live conversational LLM reasoning in the Voice AI copilot.
   - *Provider*: Google AI Studio / Google Cloud Vertex AI.
2. **Google Maps API Key / Mapbox Access Token (`GOOGLE_MAPS_API_KEY`, `MAPBOX_ACCESS_TOKEN`)**:
   - *Purpose*: Live vector map tiles and routing directions.
   - *Note*: OpenStreetMap (MapLibre) operates 100% free with zero API key required.
3. **SMS / OTP Provider (`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`)**:
   - *Purpose*: Worldwide SMS verification for rider telephone authentication.

---

### 2.2 Category 3: Hardware & Regulatory Prerequisites

1. **Physical OBD-II Bluetooth LE Dongle**:
   - Standard ELM327 or STN1110 BLE OBD-II adapter connected to motorcycle CAN-BUS port (currently simulated in `simulationMode = true`).
2. **PSAP / E911 / E112 Emergency Dispatch Agreement**:
   - Formal telematics carrier partnership required for automated cellular dispatch to public safety answering points.
3. **Regional Privacy & Data Protection Compliance**:
   - Formal DPO filings in EU (GDPR) and India (DPDP Act) prior to commercial marketing.
