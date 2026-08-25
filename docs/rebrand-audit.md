# RIDEO ULTIMATE — Brand Transformation Audit & Touchpoint Checklist

> **Comprehensive Audit of Platform Identifiers, Native Metadata, and User-Facing Surfaces**

---

## 1. Native Platform Identity & Metadata Mapping

| Configuration Surface | Current Legacy Identifier | Target Brand Identifier | Status |
| :--- | :--- | :--- | :--- |
| **Android Manifest (`AndroidManifest.xml`)** | `android:label="rideos_mobile"` | `android:label="RIDEO ULTIMATE"` | Ready to update |
| **Android Gradle (`build.gradle.kts`)** | `applicationId = "ai.rideos.app"` | `applicationId = "ai.rideos.app"` *(Preserved per Rule 4)* | Kept Stable |
| **iOS Plist (`Info.plist`)** | `CFBundleDisplayName = "Rideos Mobile"` | `CFBundleDisplayName = "RIDEO ULTIMATE"` | Ready to update |
| **iOS Plist Bundle Name (`Info.plist`)** | `CFBundleName = "rideos_mobile"` | `CFBundleName = "RIDEO ULTIMATE"` | Ready to update |
| **Web Manifest (`web/manifest.json`)** | `"name": "rideos_mobile"` | `"name": "RIDEO ULTIMATE"` | Ready to update |
| **Flutter Root Entry (`lib/main.dart`)** | `title: 'RoadOS AI'` | `title: 'RIDEO ULTIMATE'` | Ready to update |
| **Pubspec Specification (`pubspec.yaml`)** | `description: "RideOS Mobile Flutter App"` | `description: "RIDEO ULTIMATE — Luxury Motorcycle Intelligence Platform"` | Ready to update |

---

## 2. In-App User-Visible Touchpoint Inventory

| Screen / Component | Touchpoint Element | New Luxury Brand String |
| :--- | :--- | :--- |
| **Splash Screen (`splash_screen.dart`)** | Wordmark & Tagline | **RIDEO ULTIMATE** • *"PREMIUM MOTORCYCLE INTELLIGENCE"* |
| **Splash Footer (`splash_screen.dart`)** | Engine Status Line | *"RIDEO ULTIMATE KERNEL v4.0 • SYSTEM ACTIVE"* |
| **Navigation Shell TopBar (`roados_app_shell.dart`)** | Sidebar Header & Brand Pill | **RIDEO ULTIMATE** with Luxury Apex Gold & Road Cyan Badging |
| **Brand Logo Component (`rideo_logo.dart`)** | Vector Brand Emblem | Precision Vector Aerodynamic "R" Apex Wing with Luxury Glow |
| **App Localizations (`app_localizations.dart`)** | `app_title` across 8 Locales | Translated "RIDEO ULTIMATE" / localized titles |
| **NestJS API Title (`main.ts`)** | Swagger & Service Log | **RIDEO ULTIMATE API** |
