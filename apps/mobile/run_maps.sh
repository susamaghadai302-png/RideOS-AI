#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# RideOS AI — Flutter Run with Google Maps API Key
# ─────────────────────────────────────────────────────────────────
# Usage:
#   ./run_maps.sh                  → runs on default connected device
#   ./run_maps.sh -d <device-id>   → runs on specific device
#
# Before running:
#   1. Edit .env in the repo root and set GOOGLE_MAPS_API_KEY=<your_key>
#   2. Also update ios/Flutter/GoogleMapsApiKey.xcconfig (for iOS builds)
#   3. Also update android/local.properties with GOOGLE_MAPS_API_KEY=<your_key>
# ─────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# Load GOOGLE_MAPS_API_KEY from root .env file
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | grep 'GOOGLE_MAPS_API_KEY' | xargs)
fi

if [ -z "$GOOGLE_MAPS_API_KEY" ] || [ "$GOOGLE_MAPS_API_KEY" = "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ]; then
  echo ""
  echo "⚠️  WARNING: GOOGLE_MAPS_API_KEY is not set or still has the placeholder value."
  echo ""
  echo "   To fix: edit /.env and set GOOGLE_MAPS_API_KEY=<your_actual_key>"
  echo "   Get your key from: https://console.cloud.google.com/apis/credentials"
  echo ""
  echo "   The app will run but Google Maps tiles will NOT load."
  echo ""
fi

echo "🗺️  Starting RideOS AI with Google Maps..."
echo "   Key: ${GOOGLE_MAPS_API_KEY:0:10}... (truncated for security)"
echo ""

flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
  "$@"
