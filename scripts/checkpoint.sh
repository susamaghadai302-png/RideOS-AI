#!/usr/bin/env bash
set -e

echo "========================================"
echo "Phase Checkpoint & Automation Setup"
echo "========================================"

# 1. Unstage everything to start clean
git reset HEAD >/dev/null 2>&1 || true

# 2. Stage legitimate changes (respects .gitignore)
git add .

# 3. Filter out unwanted artifacts dynamically
# (Secrets/envs are ideally in .gitignore, but we double-check)
git reset HEAD -- .env .env.* credentials* tokens* keys* *.patch *.log *.txt scripts/validate.sh >/dev/null 2>&1 || true
git add .env*.example apps/*/.env*.example >/dev/null 2>&1 || true

# 4. Check if we actually have changes
if git diff --cached --quiet; then
  echo "No legitimate changes to commit after filtering. Exiting safely without empty commit."
  exit 0
fi

echo "Verifying staged changes..."

# 5. git diff --check (fails on whitespace errors/conflict markers)
git diff --cached --check || {
  echo "ERROR: Trailing whitespace or conflict markers found in staged files."
  exit 1
}

# Determine impacted scopes
RUN_FLUTTER=false
RUN_BACKEND=false

if git diff --cached --name-only | grep -q "^apps/mobile/"; then
  RUN_FLUTTER=true
fi
if git diff --cached --name-only | grep -q "^apps/backend/"; then
  RUN_BACKEND=true
fi

# 6. Flutter Verification
if [ "$RUN_FLUTTER" = true ]; then
  echo "-> Flutter files changed. Running static analysis and tests..."
  cd apps/mobile

  echo "Running flutter analyze..."
  # Use --no-fatal-warnings to not block commits on infos/warnings, but catch real errors
  flutter analyze --no-fatal-infos --no-fatal-warnings || {
    echo "ERROR: Flutter analyze failed with errors."
    exit 1
  }

  echo "Running flutter test..."
  flutter test || {
    echo "ERROR: Flutter tests failed."
    exit 1
  }
  cd ../..
fi

# 7. Backend Verification
if [ "$RUN_BACKEND" = true ]; then
  echo "-> Backend files changed. Running backend tests..."
  pnpm --filter backend run test || {
    echo "ERROR: Backend tests failed."
    exit 1
  }
fi

# 8. Checkpoint Commit
echo "Verification passed. Creating checkpoint commit..."
git commit -m "chore: automatic phase checkpoint completion"

# 9. Push to GitHub
echo "Pushing to remote..."
current_branch=$(git rev-parse --abbrev-ref HEAD)
if ! git push origin "$current_branch"; then
  echo "ERROR: Push failed! Preserving local commit."
  echo "DO NOT force push. Resolve remote conflicts manually."
  exit 1
fi

echo "========================================"
echo "Checkpoint and push successful."
echo "========================================"
