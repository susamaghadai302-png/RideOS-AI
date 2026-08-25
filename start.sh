#!/bin/bash
set -e

echo "🚀 Starting RideOS-AI Web Application..."

# Check if backend is already listening on port 3000
if curl -s http://localhost:3000/api/v1/health >/dev/null 2>&1; then
  echo "⚡ RideOS Backend is already running and healthy on http://localhost:3000"
else
  echo "⚡ Starting RideOS Backend API..."
  if [ ! -f "$ROOT_DIR/apps/backend/dist/apps/backend/src/main.js" ]; then
    echo "🔨 Building RideOS Backend..."
    pnpm --filter backend run build
  fi
  pnpm --filter backend run start:prod &
  BACKEND_PID=$!
  sleep 3
fi

# Ensure cleanup of backend on exit if started here
if [ -n "$BACKEND_PID" ]; then
  trap "kill $BACKEND_PID 2>/dev/null || true" EXIT INT TERM
fi

# Free port 8080 if an orphaned process is listening on it
if lsof -ti :8080 >/dev/null 2>&1; then
  echo "🧹 Freeing port 8080..."
  kill -9 $(lsof -ti :8080) 2>/dev/null || true
  sleep 1
fi

# Load environment variables from root .env if present
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$ROOT_DIR/.env" ]; then
  export $(grep -v '^#' "$ROOT_DIR/.env" | grep 'GOOGLE_MAPS_API_KEY' | xargs 2>/dev/null) || true
fi

DART_DEFINES=""
if [ -n "$GOOGLE_MAPS_API_KEY" ] && [ "$GOOGLE_MAPS_API_KEY" != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" ] && [ "$GOOGLE_MAPS_API_KEY" != "YOUR_GOOGLE_MAPS_API_KEY_HERE" ]; then
  echo "🗺️  Google Maps API Key detected and loaded."
  DART_DEFINES="--dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
  if [ -f "$ROOT_DIR/apps/mobile/web/index.html" ]; then
    node -e "
      const fs = require('fs');
      const p = '$ROOT_DIR/apps/mobile/web/index.html';
      let html = fs.readFileSync(p, 'utf8');
      if (html.includes('<!-- GOOGLE_MAPS_CONFIG_INJECTION -->')) {
        html = html.replace('<!-- GOOGLE_MAPS_CONFIG_INJECTION -->', '<script>window.__RIDEOS_GOOGLE_MAPS_API_KEY__ = \"$GOOGLE_MAPS_API_KEY\";</script>\n  <!-- GOOGLE_MAPS_CONFIG_INJECTION -->');
        fs.writeFileSync(p, html);
      }
    " 2>/dev/null || true
  fi
else
  echo "ℹ️  Running with local fallback maps (Google Maps API Key not set in .env)."
fi

echo "🌐 Launching RideOS-AI Web Application in Google Chrome (http://localhost:8080)..."
cd apps/mobile
exec flutter run -d chrome --web-port=8080 --web-hostname=localhost $DART_DEFINES
