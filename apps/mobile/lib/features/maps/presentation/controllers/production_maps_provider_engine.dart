import 'dart:developer' as developer;
import '../../domain/entities/poi_entity.dart';

enum MapProviderType {
  googleMaps,
  mapbox,
  openStreetMap,
  hereMaps,
  tomTom,
}

enum MotorcycleRouteMode {
  curvyBends,
  scenicHighway,
  fastestExpress,
  ecoElectric,
}

class MapGeoCoordinate {
  final double latitude;
  final double longitude;

  const MapGeoCoordinate({required this.latitude, required this.longitude});
}

class MapNavigationRoute {
  final String routeId;
  final String routeName;
  final MotorcycleRouteMode mode;
  final double distanceKm;
  final int durationSeconds;
  final List<MapGeoCoordinate> waypoints;
  final int curvyRating;

  const MapNavigationRoute({
    required this.routeId,
    required this.routeName,
    required this.mode,
    required this.distanceKm,
    required this.durationSeconds,
    required this.waypoints,
    required this.curvyRating,
  });
}

class ProductionMapsProviderEngine {
  static final ProductionMapsProviderEngine instance = ProductionMapsProviderEngine._internal();
  ProductionMapsProviderEngine._internal();

  MapProviderType activeMapProvider = MapProviderType.googleMaps;

  List<PoiEntity> getNearbyPois({
    required double centerLat,
    required double centerLng,
    NearbyCategory category = NearbyCategory.petrolPumps,
  }) {
    throw StateError(
      'Nearby POI provider is not configured for this engine; no synthetic POIs will be returned.',
    );
  }

  Future<List<Map<String, dynamic>>> fetchLiveTrafficIncidents({required MapGeoCoordinate boundsCenter}) async {
    developer.log(
      'Live traffic provider unavailable near [${boundsCenter.latitude}, ${boundsCenter.longitude}].',
      name: 'RideOS.Traffic',
    );
    throw StateError(
      'Live traffic incident provider is not configured for this engine.',
    );
  }
}
