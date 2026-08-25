import 'google_maps_provider.dart';
import 'map_engine_interface.dart';
import 'maplibre_osm_engine.dart';
import 'mapbox_engine.dart';

class MapEngineFactory {
  static IMapEngineController getEngine(MapProviderType providerType) {
    switch (providerType) {
      case MapProviderType.googleMaps:
        return GoogleMapsProvider();
      case MapProviderType.openStreetMap:
        return MapLibreOsmEngine();
      case MapProviderType.mapbox:
        return MapboxEngine();
    }
  }

  /// Get active engine with graceful regional fallback
  static Future<IMapEngineController> getEngineWithFallback({
    MapProviderType preferred = MapProviderType.googleMaps,
    bool isGoogleMapsAvailable = true,
  }) async {
    try {
      if (preferred == MapProviderType.googleMaps && !isGoogleMapsAvailable) {
        // Fallback to open source OpenStreetMap / MapLibre
        final fallbackEngine = MapLibreOsmEngine();
        await fallbackEngine.initializeMap();
        return fallbackEngine;
      }

      final engine = getEngine(preferred);
      await engine.initializeMap();
      return engine;
    } catch (_) {
      // Safe reliable fallback
      final osmFallback = MapLibreOsmEngine();
      await osmFallback.initializeMap();
      return osmFallback;
    }
  }
}
