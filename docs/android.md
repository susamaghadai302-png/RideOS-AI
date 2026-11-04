# RideOS Android Build & Release Engineering

## 1. Toolchain & SDK Prerequisites
- **JDK**: Java 17 LTS (configured in Android Studio / CI)
- **Flutter SDK**: `3.47.5` / Dart `3.13.x`
- **Android Gradle Plugin (AGP)**: `8.x`
- **Kotlin Gradle Plugin**: `2.x`
- **Android SDK Specifications**:
  - `compileSdk = 37`
  - `minSdk = 29` (Android 10.0+ / Q, supporting modern Bluetooth LE and high-precision GNSS APIs)
  - `targetSdk = flutter.targetSdkVersion` (API 34 / 35 compliant)
  - `ndkVersion = "28.2.13676358"`
- **Java Desugaring**: Enabled (`isCoreLibraryDesugaringEnabled = true`) for Java 8+ API backporting.

---

## 2. Secure Maps Credential Configuration
The Android build reads `ANDROID_GOOGLE_MAPS_API_KEY` (with legacy fallback to `GOOGLE_MAPS_API_KEY`) across multiple layered sources:
1. `apps/mobile/android/local.properties` (local developer machine)
2. Monorepo root `.env` / subfolder `.env`
3. CI/CD environment variable `ANDROID_GOOGLE_MAPS_API_KEY`

Example `apps/mobile/android/local.properties`:
```properties
ANDROID_GOOGLE_MAPS_API_KEY=AIzaSyYourAndroidClientKeyHere
```

The key is bound to `ai.rideos.app` with SHA-1 fingerprint restriction in Google Cloud Console and injected into `AndroidManifest.xml` via `manifestPlaceholders["GOOGLE_MAPS_API_KEY"]`.

---

## 3. Release Keystore Setup
1. Generate an upload keystore (if not already provisioned):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rideos_key
   ```
2. Configure `apps/mobile/android/key.properties` (gitignored):
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=rideos_key
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

---

## 4. Building Android Artifacts
- **Debug APK** (for emulator testing & CI smoke tests):
  ```bash
  cd apps/mobile
  flutter build apk --debug
  ```
- **Release APK** (for real device side-loading & field testing):
  ```bash
  cd apps/mobile
  flutter build apk --release
  ```
- **Android App Bundle (.aab)** (for Google Play Console distribution):
  ```bash
  cd apps/mobile
  flutter build appbundle --release
  ```
