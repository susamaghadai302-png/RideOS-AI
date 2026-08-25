import 'dart:developer' as developer;
import 'package:latlong2/latlong.dart';
import '../../core/services/india_places_search_engine.dart';
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
    return IndiaPlacesSearchEngine.instance.getDynamicNearbyPois(
      center: LatLng(centerLat, centerLng),
      category: category,
    );
  }

  Future<List<Map<String, dynamic>>> fetchLiveTrafficIncidents({required MapGeoCoordinate boundsCenter}) async {
    developer.log('Fetching live traffic incidents near [${boundsCenter.latitude}, ${boundsCenter.longitude}]...', name: 'RideOS.Traffic');
    return [
      {
        'incident_id': 'inc_991',
        'type': 'ROAD_CONSTRUCTION',
        'severity': 'LOW',
        'description': 'Right lane closed on Highway 101 N',
        'lat': boundsCenter.latitude + 0.01,
        'lng': boundsCenter.longitude + 0.01,
      }
    ];
  }
}
