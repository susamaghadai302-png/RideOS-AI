#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 1. Read Google Maps API Key securely from root .env
ANDROID_MAPS_KEY=""
if [ -f "$ROOT_DIR/.env" ]; then
  ANDROID_MAPS_KEY=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'ANDROID_GOOGLE_MAPS_API_KEY' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
  if [ -z "$ANDROID_MAPS_KEY" ]; then
    ANDROID_MAPS_KEY=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'GOOGLE_MAPS_API_KEY' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
  fi
fi

# 2. Detect / Read API_BASE_URL for Physical Device Network Connection
API_URL=""
if [ -f "$ROOT_DIR/.env" ]; then
  API_URL=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'API_BASE_URL' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
fi

if [ -z "$API_URL" ]; then
  LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1 || echo "10.131.15.222")
  API_URL="http://${LAN_IP}:3000/api/v1"
fi

cd "$ROOT_DIR/apps/mobile"

# Update local.properties with Android Google Maps API key
if [ -f "android/local.properties" ]; then
  if grep -q "ANDROID_GOOGLE_MAPS_API_KEY" android/local.properties; then
    sed -i '' "s|ANDROID_GOOGLE_MAPS_API_KEY=.*|ANDROID_GOOGLE_MAPS_API_KEY=$ANDROID_MAPS_KEY|g" android/local.properties
  else
    echo "ANDROID_GOOGLE_MAPS_API_KEY=$ANDROID_MAPS_KEY" >> android/local.properties
  fi
  if grep -q "GOOGLE_MAPS_API_KEY" android/local.properties; then
    sed -i '' "s|GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=$ANDROID_MAPS_KEY|g" android/local.properties
  else
    echo "GOOGLE_MAPS_API_KEY=$ANDROID_MAPS_KEY" >> android/local.properties
  fi
fi

DART_DEFINES="--dart-define=API_BASE_URL=$API_URL"
if [ -n "$ANDROID_MAPS_KEY" ] && [ "$ANDROID_MAPS_KEY" != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ] && [ "$ANDROID_MAPS_KEY" != "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
  echo "🗺️  Configured Android Google Maps Platform Key into build manifest..."
  DART_DEFINES="$DART_DEFINES --dart-define=GOOGLE_MAPS_API_KEY=$ANDROID_MAPS_KEY"
fi

echo "🌐 Backend Endpoint configured: $API_URL"
echo "🚀 Building DEBUG Android APK (applicationId: ai.rideos.app)..."
flutter build apk --debug $DART_DEFINES

APK_PATH="$ROOT_DIR/apps/mobile/build/app/outputs/flutter-apk/app-debug.apk"

if [ -f "$APK_PATH" ]; then
  SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
  echo "=================================================================="
  echo "✅ DEBUG APK COMPILED SUCCESSFULLY!"
  echo "📦 Output APK: $APK_PATH"
  echo "📊 File Size: $SIZE"
  echo "🏷️  Package: ai.rideos.app"
  echo "🌐 Backend Target URL: $API_URL"
  echo "=================================================================="
fi
