# RideOS Android Build & Release Engineering

## 1. Prerequisites
- **JDK**: Java 17 LTS
- **Android SDK**: `compileSdk = 34`, `minSdk = 24`, `targetSdk = 34`
- **NDK**: `28.2.13676358`
- **Flutter**: 3.29.x / Dart 3.7.x

---

## 2. Release Keystore Setup
1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rideos_key
   ```
2. Create `apps/mobile/android/key.properties`:
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=rideos_key
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Set your Google Maps API key in `apps/mobile/android/local.properties`:
   ```properties
   GOOGLE_MAPS_API_KEY=AIzaSyYourKeyHere
   ```

---

## 3. Building Release Artifacts
- **Android App Bundle (.aab)** for Google Play:
  ```bash
  cd apps/mobile
  flutter build appbundle --release
  ```
- **Android APK (.apk)** for direct testing:
  ```bash
  cd apps/mobile
  flutter build apk --release
  ```
