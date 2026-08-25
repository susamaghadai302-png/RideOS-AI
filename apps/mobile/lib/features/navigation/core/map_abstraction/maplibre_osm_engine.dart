import 'map_engine_interface.dart';

class MapLibreOsmEngine implements IMapEngineController {
  @override
  MapProviderType get providerType => MapProviderType.openStreetMap;

  @override
  Future<void> initializeMap() async {}

  @override
  Future<void> setCameraPosition(
    MapCoordinates coordinates, {
    double zoom = 16.0,
    double bearing = 0.0,
    double tilt = 45.0,
  }) async {}

  @override
  Future<void> drawRoutePolyline(
    List<MapCoordinates> coordinates, {
    NavigationRouteType routeType = NavigationRouteType.fastest,
  }) async {}

  @override
  Future<void> addMarker(MapMarker marker) async {}

  @override
  Future<void> clearMarkers() async {}

  @override
  Future<void> enableOfflineCaching(String regionName, MapCoordinates boundsMin, MapCoordinates boundsMax) async {}

  @override
  Future<void> setTrafficEnabled(bool enabled) async {}

  @override
  Future<void> setMapViewMode(MapViewMode mode) async {}
}
