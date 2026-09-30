/// Centralized configuration and credentials for Google Maps Platform APIs & SDKs.
///
/// To configure your production Google Maps API Key:
/// 1. Create a project on Google Cloud Console: https://console.cloud.google.com/
/// 2. Enable the following Google Maps Platform APIs:
///    - Places API (New) / Places API
///    - Directions API
///    - Geocoding API
///    - Maps SDK for Android
///    - Maps SDK for iOS
///    - Maps JavaScript API
/// 3. Create an API Key under APIs & Services > Credentials
/// 4. Pass the key at build/run time:
///    `flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY`
///    or set [overrideApiKey] programmatically.
class GoogleMapsConfig {
  /// Compile-time environment variables with optional runtime override
  static const String _envAndroidApiKey = String.fromEnvironment(
    'ANDROID_GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String _envApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Optional runtime override
  static String? overrideApiKey;

  /// Active Google Maps API Key
  static String get apiKey {
    if (overrideApiKey != null && overrideApiKey!.isNotEmpty) {
      return overrideApiKey!;
    }
    if (_envAndroidApiKey.isNotEmpty) {
      return _envAndroidApiKey;
    }
    if (_envApiKey.isNotEmpty) {
      return _envApiKey;
    }
    return '';
  }

  /// Whether a valid Google Maps API Key is configured
  static bool get hasValidApiKey => apiKey.isNotEmpty && apiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Official Google Maps Platform HTTP Endpoints
  static const String placesAutocompleteUrl = 'https://places.googleapis.com/v1/places:autocomplete';
  static const String placesTextSearchUrl = 'https://places.googleapis.com/v1/places:searchText';
  static const String placeDetailsUrlBase = 'https://places.googleapis.com/v1/places/';
  static const String placesNearbySearchUrl = 'https://places.googleapis.com/v1/places:searchNearby';
  static const String directionsUrl = 'https://routes.googleapis.com/directions/v2:computeRoutes';
  static const String geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
}
