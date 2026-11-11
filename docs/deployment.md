# RideOS Production Deployment Guide

## 1. Backend Deployment (NestJS + Docker)

### Environment Variables
Configure `.env` with production credentials:
```env
# Application
NODE_ENV=production
PORT=3000

# Persistence
MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/rideos_prod
REDIS_HOST=localhost
REDIS_PORT=6379

# Authentication & Security
JWT_SECRET=YOUR_PRODUCTION_SECURE_JWT_SECRET_64_CHARS
JWT_EXPIRATION=7d
JWT_REFRESH_SECRET=YOUR_PRODUCTION_SECURE_REFRESH_SECRET_64_CHARS
JWT_REFRESH_EXPIRATION=30d

# Google Cloud APIs (Strict Credential Separation)
GOOGLE_ROUTES_API_KEY=AIzaSyProductionServerRoutesApiKey
ANDROID_GOOGLE_MAPS_API_KEY=AIzaSyProductionAndroidClientApiKey

# Telemetry & Storage
TIMESCALE_URI=postgres://<user>:<password>@timescale.internal:5432/rideos_telematics
AWS_S3_BUCKET=rideos-diagnostics-prod

# SMS Carrier Gateway (Optional for Phone OTP in Production)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
TWILIO_PHONE_NUMBER=+1234567890
```

### Docker Compose
```bash
docker compose -f docker-compose.prod.yml up -d --build
```

---

## 2. Web Client Deployment
```bash
cd apps/mobile
flutter build web --release --no-tree-shake-icons
# Output artifacts located in apps/mobile/build/web
```
Host the static bundle behind NGINX or Cloudflare CDN with appropriate HTTP security headers (`Content-Security-Policy`, `X-Content-Type-Options`, `Strict-Transport-Security`).

---

## 3. Continuous Verification Gate
Prior to deploying any release candidate, run the full monorepo validation pipeline:
```bash
./scripts/validate.sh
```
This ensures:
1. All 16 monorepo TypeScript packages build cleanly.
2. Backend static type analysis (`tsc --noEmit`) passes with 0 errors.
3. Backend integration & unit tests (120 tests across 23 test suites) pass.
4. Mobile Flutter static analyzer reports zero issues.
5. Mobile test suite (878 tests) passes.

---

## 4. Production Android Release Preparation (Play Console)

### Artifact Verification
The production Android App Bundle (AAB) is generated via:
```bash
cd apps/mobile
flutter build appbundle --release
# Output: apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

- **Application ID**: `ai.rideos.app`
- **Version**: `2.4.0` (VersionCode: `2400`)
- **Compile SDK**: API 37 | **Target SDK**: API 35 | **Min SDK**: API 29
- **Verified Keystore Alias**: `rideos-upload-key`
- **Signing Validity**: Through January 1, 2054 (`SHA384withRSA`, 2048-bit RSA)
- **SHA-1 Fingerprint**: `EE:BE:ED:61:4E:5A:AF:61:D0:A3:5D:5A:01:C1:75:17:39:39:80:F0` (registered for Google Cloud Maps SDK for Android)
- **SHA-256 Fingerprint**: `6B:A5:26:1D:3C:C6:CE:43:20:92:FA:75:8D:24:13:2E:C2:E8:0F:CA:35:CF:15:91:78:48:F9:2C:A2:4B:56:16`

### Play Console Deployment Steps
1. Navigate to Google Play Console -> `ai.rideos.app` -> Testing -> **Internal testing**.
2. Create a new release and upload `app-release.aab`.
3. Provide release notes highlighting motorcycle navigation, OBD-II ECU telemetry, and enterprise AI assistant features.
4. Distribute to internal tester group for real-world motorcycle bench and road validation.

---

## 5. Privacy, Permission Disclosures & Safety Declarations
- **High-Precision & Background Location (`ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`)**: Required solely for turn-by-turn motorcycle navigation, spatial trip breadcrumbs, and live crash detection standstill verification. Location data is never sold or shared with third parties.
- **Bluetooth Low Energy (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`)**: Required strictly for vehicle ECU telemetry (OBD-II / ELM327) and Smart Helmet HUD connectivity. Uses `neverForLocation` flag.
- **Foreground Service (`FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_CONNECTED_DEVICE`)**: Maintains continuous navigation guidance and emergency crash monitoring while the screen is locked or during helmet HUD streaming.
- **AI Co-Pilot Memory & Conversations**: User-controlled and account-isolated. Riders can inspect, export, or permanently delete all conversational memories at any time under GDPR / CCPA right-to-be-forgotten compliance.

---

## 6. Rollback & Emergency Degradation Procedure
1. **Backend Rollback**:
   - If an unexpected backend regression occurs in production, revert the container image to the prior stable tag (`main` baseline `ef29060f4c9aa2194f380a309ead604fa1e4c526`).
   - MongoDB collections and Timescale tables use non-destructive append/upsert schemas, ensuring seamless backward schema compatibility.
2. **Mobile App Rollback**:
   - In Google Play Console, halt staged rollout or promote the previous internal track build if critical field issues are reported.
   - On-device AI assistant and OBD-II telemetry automatically degrade to honest `DATA_UNAVAILABLE` states when remote services or hardware dongles are disconnected, preventing application crashes.
