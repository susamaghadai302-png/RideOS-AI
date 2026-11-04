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
1. All monorepo TypeScript packages build cleanly.
2. Backend static type analysis (`tsc --noEmit`) passes.
3. Backend integration & unit tests (102 tests) pass.
4. Mobile Flutter static analyzer reports zero issues.
5. Mobile test suite (871 tests) passes.
