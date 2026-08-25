#!/bin/bash
set -e

echo "=================================================================="
echo "🔌 RIDEOS-AI ADB REVERSE TUNNEL SETUP"
echo "=================================================================="

ADB_BIN="$(which adb 2>/dev/null || echo "$HOME/Library/Android/sdk/platform-tools/adb")"

if [ ! -f "$ADB_BIN" ] && ! command -v adb &> /dev/null; then
  echo "❌ Error: 'adb' command not found in PATH or Android SDK."
  echo "Please ensure Android Platform Tools are installed."
  exit 1
fi

echo "📱 Checking connected Android devices..."
DEVICES_OUTPUT=$("$ADB_BIN" devices -l)
echo "$DEVICES_OUTPUT"
echo ""

DEVICE_COUNT=$(echo "$DEVICES_OUTPUT" | grep -v "List of devices" | grep "device" | grep -v "offline" | grep -v "unauthorized" | wc -l | tr -d ' ')

if [ "$DEVICE_COUNT" -eq 0 ]; then
  echo "⚠️  NO AUTHORIZED PHYSICAL ANDROID DEVICE DETECTED VIA ADB."
  echo "To connect your physical phone:"
  echo "  1. Plug your Android phone into this Mac via USB cable."
  echo "  2. Go to phone Settings -> Developer Options -> Enable 'USB Debugging'."
  echo "  3. When prompted on the phone screen, check 'Always allow from this computer' and tap 'Allow'."
  echo "  4. Re-run this script: ./scripts/setup-usb-reverse.sh"
  exit 1
fi

echo "🔄 Establishing reverse port forwarding on port 3000..."
"$ADB_BIN" reverse tcp:3000 tcp:3000

echo ""
echo "🔍 Verifying active reverse tunnels..."
"$ADB_BIN" reverse --list

echo ""
echo "=================================================================="
echo "✅ ADB REVERSE TUNNEL ESTABLISHED & ACTIVE!"
echo "Your physical Android phone can now connect to the Mac backend at:"
echo "👉 http://127.0.0.1:3000/api/v1"
echo "(Works 100% reliably over USB cable even on 5G / Mobile Data)"
echo "=================================================================="
