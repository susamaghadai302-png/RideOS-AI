#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

GOOGLE_MAPS_KEY=""
if [ -f "$ROOT_DIR/.env" ]; then
  GOOGLE_MAPS_KEY=$(grep -v '^#' "$ROOT_DIR/.env" | grep 'GOOGLE_MAPS_API_KEY' | cut -d '=' -f2- | tr -d '"' | tr -d "'" | xargs 2>/dev/null) || true
fi

DART_DEFINES=""
if [ -n "$GOOGLE_MAPS_KEY" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
  echo "🗺️  Injecting GOOGLE_MAPS_API_KEY into Flutter Web release build..."
  DART_DEFINES="--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_KEY"
else
  echo "ℹ️  Building Flutter Web with local fallback routing configuration..."
fi

cd "$ROOT_DIR/apps/mobile"
flutter build web --release $DART_DEFINES

if [ -d "$ROOT_DIR/apps/mobile/assets" ]; then
  cp -rn "$ROOT_DIR/apps/mobile/assets/"* "$ROOT_DIR/apps/mobile/build/web/assets/" 2>/dev/null || true
  cp -rn "$ROOT_DIR/apps/mobile/assets" "$ROOT_DIR/apps/mobile/build/web/" 2>/dev/null || true
fi

if [ -n "$GOOGLE_MAPS_KEY" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ] && [ "$GOOGLE_MAPS_KEY" != "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
  if [ -f "$ROOT_DIR/apps/mobile/build/web/index.html" ]; then
    node -e "
      const fs = require('fs');
      const p = '$ROOT_DIR/apps/mobile/build/web/index.html';
      let html = fs.readFileSync(p, 'utf8');
      html = html.replace('<!-- GOOGLE_MAPS_CONFIG_INJECTION -->', '<script>window.__RIDEOS_GOOGLE_MAPS_API_KEY__ = \"$GOOGLE_MAPS_KEY\";</script>');
      fs.writeFileSync(p, html);
    "
    echo "✓ Injected Google Maps API Key into release web bundle."
  fi
fi
