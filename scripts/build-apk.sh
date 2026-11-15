#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Build profile selection: default to 'dev' unless '--prod' or '--production' is passed
BUILD_PROFILE="dev"
API_URL="${API_BASE_URL:-}"

for arg in "$@"; do
  case "$arg" in
    --prod|--production)
      BUILD_PROFILE="prod"
      ;;
    --dev|--development)
      BUILD_PROFILE="dev"
      ;;
    --api-base-url=*)
      API_URL="${arg#*=}"
      ;;
    --help|-h)
      echo "Usage: ./scripts/build-apk.sh [--prod|--dev] [--api-base-url=<URL>]"
      echo ""
      echo "Build Profiles:"
      echo "  --prod, --production   Production release build profile."
      echo "                         Sets API_BASE_URL to https://api.rideos.ai/api/v1."
      echo "                         Strictly rejects localhost and LAN IP fallbacks."
      echo "  --dev, --development   Development build profile (default)."
      echo "                         Uses .env configuration or auto-detected Mac LAN IP."
      echo "  --api-base-url=<URL>   Explicitly override API base URL."
      echo "  --help, -h             Show this help message."
      exit 0
      ;;
    *)
      ;;
  esac
done

# 1. Resolve and Validate API_BASE_URL per Build Profile
if [ "$BUILD_PROFILE" = "prod" ]; then
  if [ -z "$API_URL" ]; then
    API_URL="https://api.rideos.ai/api/v1"
  fi

  # Strict safety check: Never permit localhost or private LAN IP in production release builds
  if [[ "$API_URL" == *"127.0.0.1"* ]] || [[ "$API_URL" == *"localhost"* ]] || [[ "$API_URL" == *"10."* ]] || [[ "$API_URL" == *"192.168."* ]] || [[ "$API_URL" =~ 172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    echo "❌ CRITICAL SAFETY GATE: Production release APK must not use localhost or private LAN IP: ${API_URL}"
    echo "Provide a valid public production endpoint or use '--dev' for local testing."
    exit 1
  fi
  echo "🔒 Production Build Profile Active: API_BASE_URL=${API_URL}"
else
  # Development profile: read from .env if unset, or auto-detect host Mac LAN IP
  if [ -z "$API_URL" ] && [ -f "$ROOT_DIR/.env" ]; then
    API_URL=$(grep -v '^#' "$ROOT_DIR/.env" | grep '^API_BASE_URL=' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
  fi

  if [ -z "$API_URL" ]; then
    LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1 || echo "10.131.15.222")
    API_URL="http://${LAN_IP}:3000/api/v1"
  fi
  echo "🛠️  Development Build Profile Active: API_BASE_URL=${API_URL}"
fi

# 2. Read Google Maps API Key from root .env without printing secrets
GOOGLE_MAPS_KEY=""
if [ -f "$ROOT_DIR/.env" ]; then
  GOOGLE_MAPS_KEY=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'ANDROID_GOOGLE_MAPS_API_KEY' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
  if [ -z "$GOOGLE_MAPS_KEY" ]; then
    GOOGLE_MAPS_KEY=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'GOOGLE_MAPS_API_KEY' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
  fi
fi

cd "$ROOT_DIR/apps/mobile"

# Update local.properties with Google Maps API key
if [ -f "android/local.properties" ]; then
  if grep -q "GOOGLE_MAPS_API_KEY" android/local.properties; then
    sed -i '' "s|GOOGLE_MAPS_API_KEY=.*|GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_KEY|g" android/local.properties
  else
    echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_KEY" >> android/local.properties
  fi
fi

DART_DEFINES="--dart-define=API_BASE_URL=$API_URL"
if [ -n "$GOOGLE_MAPS_KEY" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
  echo "🗺️  Google Maps API Key: [CONFIGURED]"
  DART_DEFINES="$DART_DEFINES --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_KEY --dart-define=ANDROID_GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_KEY"
else
  echo "ℹ️  Google Maps API Key: [NOT CONFIGURED] (using vector fallback)"
fi

PROFILE_UPPER=$(echo "$BUILD_PROFILE" | tr '[:lower:]' '[:upper:]')
echo "=================================================================="
echo "🚀 Building Release APK (applicationId: ai.rideos.app)"
echo "Profile:         ${PROFILE_UPPER}"
echo "API Base URL:    ${API_URL}"
echo "=================================================================="

flutter build apk --release $DART_DEFINES

APK_PATH="$ROOT_DIR/apps/mobile/build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
  SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
  echo "=================================================================="
  echo "✅ RELEASE APK COMPILED SUCCESSFULLY!"
  echo "📦 Output APK:   $APK_PATH"
  echo "📊 File Size:    $SIZE"
  echo "🏷️  Package:      ai.rideos.app"
  echo "🌐 API Target:   $API_URL"
  echo "🛡️  Profile:      ${PROFILE_UPPER}"
  echo "=================================================================="
fi
