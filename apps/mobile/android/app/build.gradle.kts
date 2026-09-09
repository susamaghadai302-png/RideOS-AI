import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read Google Maps API Key securely from local.properties, root .env, or system environment
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

var resolvedMapsKey = (localProperties.getProperty("ANDROID_GOOGLE_MAPS_API_KEY")
    ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY", "")).trim()

// Multi-layer fallback to reading root .env file if local.properties does not contain it
if (resolvedMapsKey.isEmpty()) {
    val envFiles = listOf(
        rootProject.file("../../../.env"),
        rootProject.file("../../.env"),
        rootProject.file("../.env"),
        rootProject.file(".env")
    )
    val envFile = envFiles.firstOrNull { it.exists() }
    if (envFile != null) {
        val envProperties = Properties()
        envFile.inputStream().use { envProperties.load(it) }
        resolvedMapsKey = (envProperties.getProperty("ANDROID_GOOGLE_MAPS_API_KEY")
            ?: envProperties.getProperty("GOOGLE_MAPS_API_KEY", "")).trim()
    }
}

val googleMapsApiKey: String = resolvedMapsKey

// Read release signing credentials securely from key.properties (gitignored file)
val keystoreProperties = Properties()
val keystorePropertiesFile = listOf(
    rootProject.file("key.properties"),
    file("key.properties"),
    file("../key.properties"),
    file("../../key.properties")
).firstOrNull { it.exists() }
val hasKeystore = keystorePropertiesFile != null
if (hasKeystore) {
    keystorePropertiesFile!!.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.rideos_mobile"
    compileSdk = 37
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ai.rideos.app"
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inject Google Maps API key as a manifest placeholder
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}



flutter {
    source = "../.."
}

dependencies {
    // Android Auto / Car App Library — required for CarAppService
    // Navigation category (androidx.car.app.navigation) requires minSdk 23+
    implementation("androidx.car.app:app:1.7.0")
    implementation("androidx.car.app:app-projected:1.7.0")
    implementation("androidx.car.app:app-automotive:1.7.0")
    
    // Official Google Navigation SDK (includes MapView and NavigationViewForAuto)
    // Used specifically to provide a real geographic map surface on the vehicle DHU
    implementation("com.google.android.libraries.navigation:navigation:5.5.0")
}

configurations.all {
    // Navigation SDK internally bundles maps. Exclude standalone play-services-maps
    // to prevent Duplicate Class errors with google_maps_flutter.
    exclude(group = "com.google.android.gms", module = "play-services-maps")
    
    // Fix AGP 8+ namespace collision between cronet-api and cronet-fallback
    exclude(group = "org.chromium.net", module = "cronet-fallback")
}
