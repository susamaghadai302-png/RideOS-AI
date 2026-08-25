import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API key — read securely from Info.plist (injected from xcconfig / local.properties).
    // To set the key: add GOOGLE_MAPS_API_KEY=<your_key> in ios/Flutter/Debug.xcconfig (gitignored).
    let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String ?? ""
    if mapsApiKey.isEmpty {
      NSLog("[RideOS] WARNING: GOOGLE_MAPS_API_KEY is not set. Map tiles will not load.")
    }
    GMSServices.provideAPIKey(mapsApiKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

