#!/bin/bash
set -e

echo "🚀 Building RideOS-AI monorepo..."
pnpm build

# Check if backend is running, if not start it
if ! curl -s http://localhost:3000/api/v1/health >/dev/null 2>&1; then
  echo "⚡ Starting NestJS Backend API..."
  pnpm --filter backend run start:prod &
  BACKEND_PID=$!
  sleep 2
fi

echo "📱 Launching Android Emulator & Flutter Mobile App..."
(
  cd apps/mobile
  flutter emulators --launch Medium_Phone 2>/dev/null || true
  sleep 4
  flutter run -d emulator-5554 2>/dev/null || flutter run
) &
MOBILE_PID=$!

if [ -n "$BACKEND_PID" ]; then
  trap "kill $BACKEND_PID $MOBILE_PID 2>/dev/null || true" EXIT INT TERM
fi

echo "✅ RideOS-AI Android service launching!"
wait
