# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Google Maps SDK (when present)
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Keep Flutter Blue Plus (BLE GATT serialization)
-keep class com.boskokg.flutter_blue_plus.** { *; }
-dontwarn com.boskokg.flutter_blue_plus.**

# Keep WebGL / ModelViewer WebViews
-keepclassmembers class * extends android.webkit.WebViewClient {
   public void *(android.webkit.WebView, java.lang.String);
   public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
   public void *(android.webkit.WebView, java.lang.String);
}

# Keep RideOS Data Transfer Objects & Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
