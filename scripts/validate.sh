#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================"
echo "RideOS AI — Full Repository Validation"
echo "========================================"

# 1. Packages Build Verification
echo "-> 1. Building monorepo packages..."
cd "$ROOT_DIR"
pnpm run build:packages

# 2. Backend API Verification
echo "-> 2. Verifying Backend API (lint, build & unit tests)..."
pnpm --filter backend run lint
pnpm --filter backend run build
pnpm --filter backend run test

# 3. Flutter Mobile Verification
echo "-> 3. Verifying Flutter Mobile App (analyze & tests)..."
cd "$ROOT_DIR/apps/mobile"
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test

echo "========================================"
echo "✅ ALL VALIDATION CHECKS PASSED!"
echo "========================================"

