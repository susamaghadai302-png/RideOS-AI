import 'map_provider.dart';
import 'google_maps_provider.dart';

enum MapEngineType {
  googleMaps,
}

class MapProviderFactory {
  static final MapProviderFactory _instance = MapProviderFactory._internal();
  factory MapProviderFactory() => _instance;

  final GoogleMapsProvider _googleMapsProvider = GoogleMapsProvider();

  MapEngineType _currentEngine = MapEngineType.googleMaps;

  MapProviderFactory._internal();

  MapEngineType get currentEngine => _currentEngine;

  MapProvider get activeProvider {
    return _googleMapsProvider;
  }

  void setEngine(MapEngineType type) {
    _currentEngine = type;
  }

  void useGoogleMaps() => setEngine(MapEngineType.googleMaps);
}
