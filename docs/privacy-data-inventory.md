# RoadOS AI — Global Privacy & Data Protection Inventory

> **Comprehensive Telemetry, Biometrics, and Document Vault Privacy Architecture**

---

## 1. Data Classification Inventory

| Data Category | Specific Elements Collected | Storage Location | Retention / Lifecycle | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Location & Spatial Telemetry** | GPS Coordinates, Elevation, Speed, Lean Angle, Heading | Local Cache & NestJS Telematics API | Session duration / Trip archive | Real-time 3D Navigation, post-ride analytics, Squad radar mesh. |
| **Vehicle CAN-BUS / OBD-II** | Engine RPM, Coolant Temp, Throttle %, Gear, TPMS PSI & °C | Local memory & Encrypted Telemetry Log | Active ride duration | Live instrument cluster, maintenance diagnostics, fault alerts. |
| **Safety & Incident Data** | 6-Axis IMU Acceleration, Gyro Tilt Rate, Impact Timestamp | Local device memory | 90 days following crash event | Emergency SOS automated impact evaluation and dispatch. |
| **Profile & Vehicle Documents** | Driver License #, Insurance Policy, RC Book, PUC Emission Scan | Local AES-256 Vault / Secure Cloud Vault | Until user deletion | Digital glovebox vault, expiry alert reminders. |
| **AI Voice & Interaction Data** | Rider voice queries, transcript logs, intent action routes | Ephemeral in-memory stream | Session memory (cleared on app restart) | Copilot navigation commands, hands-free vehicle controls. |

---

## 2. Software-Implemented Privacy Controls (Active Today)

1. **Client-Side Document Vault Encryption**: All stored vehicle and driver documents in `Profile Vault` use `flutter_secure_storage` with hardware-backed keystore/keychain encryption.
2. **Offline-First Telemetry Scoping**: GPS and sensor streams can operate 100% locally without uploading location data when offline mode is selected.
3. **Session Cleansing**: Multi-turn Voice AI conversation memory is strictly ephemeral and scoped to the active riding session.
4. **Explicit Simulation Mode**: When physical hardware is absent, telemetry simulation runs 100% within local device memory without calling external services.

---

## 3. Future Regulatory & Legal Requirements (Category 3 / Post-Software)

The following items are outside pure software engineering and require official legal counsel and regulatory filings prior to international public commercialization:
1. **GDPR / CCPA / DPDP Compliance Filings**: Formal Data Protection Officer (DPO) registration and regional representative appointments in the EU, UK, and India.
2. **Emergency Dispatch (E911 / E112) Carrier Integration**: Formal telematics emergency service provider certification for direct PSAP cellular dispatch.
3. **Insurance Telematics Partner Agreements**: Formal OEM data-sharing agreements if riders choose to share ride scores for insurance premium discounts.
