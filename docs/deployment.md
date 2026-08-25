# RideOS Production Deployment Guide

## 1. Backend Deployment (NestJS + Docker)

### Environment Variables
Configure `.env` with production values:
```env
NODE_ENV=production
PORT=3000
MONGO_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/rideos_prod
JWT_SECRET=YOUR_PRODUCTION_SECURE_JWT_SECRET_64_CHARS
JWT_EXPIRATION=7d
JWT_REFRESH_SECRET=YOUR_PRODUCTION_SECURE_REFRESH_SECRET_64_CHARS
GOOGLE_MAPS_API_KEY=AIzaSyProductionKey
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
Host the static bundle behind NGINX or Cloudflare CDN with appropriate caching headers.
