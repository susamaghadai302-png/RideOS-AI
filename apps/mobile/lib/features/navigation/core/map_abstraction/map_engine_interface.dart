enum MapProviderType { googleMaps, mapbox, openStreetMap }

enum MapViewMode { normal, satellite, terrain, hybrid }

enum NavigationRouteType {
  fastest,
  safest,
  scenic,
  rainAvoidance,
  nightRide,
  highwayPreference,
  curvyRoad,
  fuelEfficient,
  avoidTraffic,
  avoidConstruction,
  avoidFlood,
  motorcycleSafe,
  rainSafe,
  nightSafe,
  eco,
}

enum PoiCategory {
  petrolPumps,
  evCharging,
  bikeService,
  tyreShop,
  hospitals,
  hotels,
  restaurants,
  parking,
}

class MapCoordinates {
  final double latitude;
  final double longitude;

  const MapCoordinates({required this.latitude, required this.longitude});
}

class MapMarker {
  final String id;
  final MapCoordinates position;
  final String title;
  final String? snippet;
  final PoiCategory? category;

  const MapMarker({
    required this.id,
    required this.position,
    required this.title,
    this.snippet,
    this.category,
  });
}

class SmartRidePrediction {
  final double estimatedEtaMinutes;
  final double fuelRemainingPct;
  final String weatherAlert;
  final String trafficCondition;
  final int breakRecommendationMinutes;
  final double nightVisibilityPct;
  final double roadRiskScore; // 0.0 to 10.0 scale

  const SmartRidePrediction({
    this.estimatedEtaMinutes = 32.0,
    this.fuelRemainingPct = 84.0,
    this.weatherAlert = 'Clear Sky',
    this.trafficCondition = 'Optimal Flow',
    this.breakRecommendationMinutes = 45,
    this.nightVisibilityPct = 94.0,
    this.roadRiskScore = 1.2,
  });
}

class NavigationRouteOptions {
  final NavigationRouteType routeType;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidBadRoads;
  final SmartRidePrediction prediction;

  const NavigationRouteOptions({
    this.routeType = NavigationRouteType.motorcycleSafe,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.avoidBadRoads = true,
    this.prediction = const SmartRidePrediction(),
  });
}

abstract class IMapEngineController {
  MapProviderType get providerType;

  Future<void> initializeMap();
  Future<void> setCameraPosition(MapCoordinates coordinates, {double zoom = 16.0, double bearing = 0.0, double tilt = 45.0});
  Future<void> drawRoutePolyline(List<MapCoordinates> coordinates, {NavigationRouteType routeType = NavigationRouteType.motorcycleSafe});
  Future<void> addMarker(MapMarker marker);
  Future<void> clearMarkers();
  Future<void> enableOfflineCaching(String regionName, MapCoordinates boundsMin, MapCoordinates boundsMax);
  Future<void> setTrafficEnabled(bool enabled);
  Future<void> setMapViewMode(MapViewMode mode);
}
