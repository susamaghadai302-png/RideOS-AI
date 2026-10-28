# RideOS AI — Android QA APK Release Notes

**Build Version**: `1.0.0+1` (RideOS Pro)
**Target Architecture**: Universal Android APK (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
**Package Identifier**: `ai.rideos.app`
**Minimum Android SDK**: API 29 (Android 10)
**Target Android SDK**: API 35 / compileSdk 37 (Android 15/16)
**Target Commit**: `89671b229af3040776e4da72719fff64fd0c2297`
**Branch**: `automation/android-emulator-apk-delivery`

---

## 1. Binary Manifest & Verification Details

| Attribute | Specification |
| :--- | :--- |
| **Filename** | `app-release.apk` |
| **Output Path** | `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` |
| **Binary Size** | ~108.6 MB (`108,570,960 bytes`) |
| **SHA-256 Checksum** | `44f8f9713d0b66682d7433044fe4eb79a65730abed040796d3ba68a517bb7b61` |
| **Checksum Provenance** | Verified independently via direct byte-stream `shasum -a 256` and GitHub API release digest |
| **Signing Classification** | **QA / Testing Build (Debug-signed fallback)** |
| **Play Store Readiness** | **Non-Production** (QA testing only; not for Google Play Store upload) |
| **Verified Process ID** | `PID 4621` on Android API 35 Emulator (`emulator-5554`) |
| **GitHub Release Tag** | `ci-apk-40559158294` |
| **Workflow Run** | [Run 40559158294](https://github.com/susamaghadai302-png/RideOS-AI/actions/runs/40559158294) (Status: `success`) |

> [!NOTE]
> **APK Size Breakdown**: The universal APK includes compiled `.so` native libraries for three CPU architectures (ARM64, ARMv7, and x86_64), five multi-dex files, and high-fidelity 3D motorcycle models (`assets/models/*.glb`). When distributed through Google Play as an `.aab` (Android App Bundle), device-specific splits automatically reduce the user download footprint to ~35–40 MB.

---

## 2. Signing Classification & Security Policy

1. **QA / Emulator Testing APK**:
   - The APK compiled in the CI pipeline falls back to debug signing when no production keystore is provided in CI secrets.
   - This binary is intended for internal developer verification, emulator testing, and physical device sideloading.
   - It is explicitly **not** signed for Google Play Store release distribution.
2. **Production Release Keystore**:
   - For Google Play production distribution, an enterprise upload keystore (`upload-keystore.jks`) with Google Play App Signing is required.
   - Google Play Integrity Attestation operates in `AndroidDebugProvider` mode for this QA build and switches to `AndroidPlayIntegrityProvider` in Google-signed production builds.

---

## 3. How to Download the APK

The verified release APK is published through GitHub Releases:

1. **Direct GitHub Release Page**:
   ```
   https://github.com/susamaghadai302-png/RideOS-AI/releases/tag/ci-apk-40559158294
   ```
2. **Direct Asset Download Link**:
   ```
   https://github.com/susamaghadai302-png/RideOS-AI/releases/download/ci-apk-40559158294/app-release.apk
   ```
3. **Release Tag**: `ci-apk-40559158294`
4. **Asset Name**: `app-release.apk`
5. **Download via GitHub CLI**:
   ```bash
   gh release download ci-apk-40559158294 -p "app-release.apk" --repo susamaghadai302-png/RideOS-AI
   ```

---

## 4. Installation & Verification Instructions

### Method A: Sideload via Android Debug Bridge (ADB)
Connect your physical phone or start an Android Emulator, then run:

```bash
# 1. Check connected device
adb devices

# 2. Uninstall any previous debug build or test runner
adb uninstall ai.rideos.app.test || true
adb uninstall ai.rideos.app || true

# 3. Install the QA Release APK
adb install -r app-release.apk

# 4. Launch RideOS AI
adb shell am start -n ai.rideos.app/.MainActivity

# 5. Check runtime logs
adb logcat -s "flutter" "RideOS" "AndroidRuntime"
```

### Method B: Direct Phone Sideloading
1. Download `app-release.apk` to your Android device (Android 10+).
2. Open your device's **Files** or **Downloads** app.
3. Tap `app-release.apk`.
4. If prompted, enable **"Install unknown apps"** for your file manager or browser.
5. Tap **Install** and then **Open**.

---

## 5. Verified App Behaviors & Expected States

When opening this QA build on your device or emulator:
1. **Splash Screen**: The dark-mode RideOS Pro splash screen renders with high-contrast amber/cyan branding.
2. **Authentication Gate**: Renders Email/Password login. Note: unconfigured third-party OAuth and Phone OTP throw configuration notices rather than faking demo sessions.
3. **Navigation & Maps**: Centered on Bhubaneswar, Odisha (`20.2961° N, 85.8245° E`) with live vector tiles and turn-by-turn guidance.
4. **Telemetry & Dashboard**: When no physical motorcycle is connected via BLE, the cluster gauges truthfully show `-- KM/H`, `-- RPM`, and Gear `N`. Zero synthetic mock data is displayed.
