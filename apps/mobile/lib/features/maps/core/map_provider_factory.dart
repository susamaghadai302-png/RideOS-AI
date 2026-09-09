import 'map_provider.dart';
import 'google_maps_provider.dart';
import 'local_graph_map_provider.dart';

enum MapEngineType {
  googleMaps,
  localGraph,
}

class MapProviderFactory {
  static final MapProviderFactory _instance = MapProviderFactory._internal();
  factory MapProviderFactory() => _instance;

  final GoogleMapsProvider _googleMapsProvider = GoogleMapsProvider();
  final LocalGraphMapProvider _localGraphProvider = LocalGraphMapProvider();

  MapEngineType _currentEngine = MapEngineType.googleMaps;

  MapProviderFactory._internal();

  MapEngineType get currentEngine => _currentEngine;

  MapProvider get activeProvider {
    switch (_currentEngine) {
      case MapEngineType.googleMaps:
        return _googleMapsProvider;
      case MapEngineType.localGraph:
        return _localGraphProvider;
    }
  }

  void setEngine(MapEngineType type) {
    _currentEngine = type;
  }

  void useGoogleMaps() => setEngine(MapEngineType.googleMaps);
  void useLocalGraph() => setEngine(MapEngineType.localGraph);
}
