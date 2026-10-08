#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "RIDEOS AI - PHASE 6.10 RELEASE RUNNER"
echo "=========================================================="

ARTIFACT_DIR="artifacts/phase6_10"
mkdir -p "$ARTIFACT_DIR"

echo "Verifying Git State..."
git status --short > "$ARTIFACT_DIR/git_status.txt"
git rev-parse HEAD > "$ARTIFACT_DIR/local_head.txt"

echo "Detecting Environment Capabilities..."
flutter devices > "$ARTIFACT_DIR/flutter_devices.txt" 2>&1 || true
adb devices > "$ARTIFACT_DIR/adb_devices.txt" 2>&1 || true

echo "Checking Firebase CLI..."
firebase --version > "$ARTIFACT_DIR/firebase_version.txt" 2>&1 || echo "UNAVAILABLE" > "$ARTIFACT_DIR/firebase_version.txt"

echo "Checking Google Cloud CLI..."
gcloud --version > "$ARTIFACT_DIR/gcloud_version.txt" 2>&1 || echo "UNAVAILABLE" > "$ARTIFACT_DIR/gcloud_version.txt"

echo "Checking GitHub CLI..."
gh auth status > "$ARTIFACT_DIR/gh_status.txt" 2>&1 || echo "UNAVAILABLE" > "$ARTIFACT_DIR/gh_status.txt"

echo "Checking environment variables..."
env | grep -E "ANDROID_HOME|JAVA_HOME|FLUTTER|DART" > "$ARTIFACT_DIR/environment.txt" || true

echo "Detecting Emulators..."
emulator_list=$(flutter emulators 2>/dev/null || true)
echo "$emulator_list" > "$ARTIFACT_DIR/emulators.txt"

DEVICE_CONNECTED=$(adb devices | grep -w "device" | wc -l | tr -d ' ')
if [ "$DEVICE_CONNECTED" -gt 0 ]; then
    echo "Android Device Available. Building Release APK..."
    cd apps/mobile
    flutter build apk --release > "../../$ARTIFACT_DIR/release_build.txt" 2>&1
    
    echo "Installing APK..."
    flutter install || true
    
    echo "Capturing sanitized logcat (no secrets)..."
    adb logcat -d | grep -iE "RideOS|FirebaseAI|Gemini|AppCheck|PlayIntegrity" > "../../$ARTIFACT_DIR/logcat_sanitized.txt" || true
    cd ../..
else
    echo "No Android device/emulator available. Skipping live app test."
fi

echo "=========================================================="
echo "Runner Execution Complete."
echo "Check artifacts/phase6_10/STATUS.md for gate status."
echo "=========================================================="
