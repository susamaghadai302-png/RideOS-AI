#!/usr/bin/env bash
set -Eeuo pipefail

device="${ANDROID_SERIAL:-emulator-5554}"
cd "${GITHUB_WORKSPACE:-$(pwd)}/apps/mobile"

echo "Waiting for Flutter integration launch test on ${device}..."
if ! flutter test integration_test/integration_setup_test.dart -d "${device}" --reporter expanded; then
  echo "::error::RideOS integration launch test failed on the Android emulator."
  adb -s "${device}" logcat -d -t 600 | tail -n 160 || true
  exit 1
fi

apk="build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -s "$apk" ]]; then
  echo "::error::Release APK is missing or empty: $apk"
  exit 1
fi

adb -s "${device}" uninstall ai.rideos.app >/dev/null 2>&1 || true
adb -s "${device}" install -r "$apk"
adb -s "${device}" logcat -c
adb -s "${device}" shell monkey -p ai.rideos.app -c android.intent.category.LAUNCHER 1
sleep 15

pid="$(adb -s "${device}" shell pidof ai.rideos.app 2>/dev/null || true)"
if [[ -z "$pid" ]]; then
  echo "::error::Release APK did not remain running on the Android emulator."
  adb -s "${device}" logcat -d -t 800 | tail -n 200 || true
  exit 1
fi

fatal_log="$(adb -s "${device}" logcat -d -t 800 | grep -E 'Process: ai[.]rideos[.]app|Fatal signal.*ai[.]rideos[.]app' || true)"
if [[ -n "$fatal_log" ]]; then
  echo "$fatal_log"
  echo "::error::Fatal Android runtime failure detected during the release APK smoke test."
  exit 1
fi

echo "::notice title=Android emulator smoke test::Integration test passed; release APK installed and remained running on Android API 35."
