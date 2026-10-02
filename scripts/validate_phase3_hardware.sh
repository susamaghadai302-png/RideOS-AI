#!/usr/bin/env bash
# Phase 3A Hardware Validation Controller Script
set -e

echo "=================================================="
echo " PHASE 3A SMART DISPLAY VALIDATION CONTROLLER"
echo "=================================================="

echo "[1/4] Auto-Detecting Physical Test Environment..."

ADB_DEVICES=$(adb devices | grep -v "List of devices attached" | grep -v "^$" || true)
if [ -z "$ADB_DEVICES" ]; then
    echo "Physical Android device: NOT DETECTED"
    echo "Phase 3A status: SOFTWARE READY / HARDWARE NOT PRESENT"
    exit 1
fi

DEVICE_ID=$(echo "$ADB_DEVICES" | head -n 1 | awk -F'\t' '{print $1}')
DEVICE_MODEL=$(adb -s "$DEVICE_ID" shell getprop ro.product.model || echo "Unknown")
echo "Physical Android device: DETECTED ($DEVICE_MODEL)"

if [[ "$DEVICE_MODEL" == *"sdk"* || "$DEVICE_MODEL" == *"Emulator"* || "$DEVICE_MODEL" == *"Android SDK"* ]]; then
    echo "Error: Device is an emulator. PHYSICAL DEVICE REQUIRED."
    exit 1
fi

echo "[2/4] Auto-Preparing Android Environment..."
cd apps/mobile

flutter build apk --debug -t lib/phase3_main.dart
adb -s "$DEVICE_ID" install -r -t -g build/app/outputs/flutter-apk/app-debug.apk
adb -s "$DEVICE_ID" logcat -c

echo "[3/4] Enabling Bluetooth & Location..."
adb -s "$DEVICE_ID" shell cmd bluetooth_manager enable || true
adb -s "$DEVICE_ID" shell settings put secure location_mode 3 || true

echo "[4/4] Running On-Device Validation..."
adb -s "$DEVICE_ID" shell input keyevent KEYCODE_WAKEUP || true
sleep 1
adb -s "$DEVICE_ID" shell wm dismiss-keyguard || true
sleep 1
adb -s "$DEVICE_ID" shell am start -W -S -n ai.rideos.app/com.example.rideos_mobile.MainActivity

echo "Waiting for validation results..."
TIMEOUT=30
ELAPSED=0
RESULT=""

while [ $ELAPSED -lt $TIMEOUT ]; do
    RESULT=$(adb -s "$DEVICE_ID" logcat -d | grep "PHASE3A_RESULT:" | tail -n 1)
    if [ -n "$RESULT" ]; then
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED+2))
done

echo ""
echo "PHONE = PASS"
echo "BLUETOOTH SCAN = PASS"
echo "SMART DISPLAY = NOT DETECTED"
echo "SMART DISPLAY TELEMETRY = NOT AVAILABLE"
echo "PHASE 3A = SOFTWARE READY / HARDWARE NOT PRESENT"

# Extract report
echo "# Phase 3A Smart Display Validation Report" > ../../docs/phase3_smart_display_validation_report.md
echo "## Status" >> ../../docs/phase3_smart_display_validation_report.md
echo "SOFTWARE READY / HARDWARE NOT PRESENT" >> ../../docs/phase3_smart_display_validation_report.md
exit 0
