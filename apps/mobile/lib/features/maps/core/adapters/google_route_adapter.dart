
import '../../domain/models/ride_route_models.dart';
import 'route_adapter.dart';
import '../services/google_maps_platform_service.dart';
import '../services/road_os_routing_engine.dart'; // For RouteOptionType

class GoogleRouteAdapter implements RouteAdapter {
  final GoogleMapsPlatformService _service = GoogleMapsPlatformService.instance;

  @override
  String get providerName => 'Google Routes API';

  @override
  Future<List<RideRouteResponse>> calculateRoute(RideRouteRequest request) async {
    // 1. Fetch raw routes using existing Google Maps Platform Service
    // The underlying service already requests 'TWO_WHEELER' mode natively.
    final multiResult = await _service.calculateDirections(
      origin: request.origin,
      destination: request.destination,
      waypoints: request.waypoints,
    );

    return multiResult.allRoutes.map((r) => _mapToCanonical(r, request)).toList();
  }

  RideRouteResponse _mapToCanonical(RouteCalculationResult result, RideRouteRequest request) {
    // Google Routes API natively supports live traffic and true TWO_WHEELER routing
    final metadata = RideRouteMetadata(
      twoWheelerRouting: DataAvailability.supported,
      liveTraffic: DataAvailability.supported,
      alternativeRoutes: DataAvailability.supported,
      tollInformation: DataAvailability.supported,
      elevationProfile: DataAvailability.unavailable, // Not parsed yet
      weatherImpact: DataAvailability.unsupported,
    );

    final segments = [
      RideRouteSegment(
        polyline: result.polylinePoints,
        distanceKm: result.distanceKm,
        durationMinutes: result.durationMinutes,
        roadName: result.routeName,
        speedLimitKmh: null, // Missing speed limit != 0
        trafficAvailability: DataAvailability.supported,
        tollAvailability: DataAvailability.supported, // Depends on toll passes, assuming supported
        maneuvers: result.steps.map((s) => RideManeuver(
          instruction: s.instruction,
          coordinate: s.stepCoordinates.isNotEmpty ? s.stepCoordinates.first : result.polylinePoints.first,
          distanceMeters: s.distanceMeters,
          maneuverType: s.iconType,
        )).toList(),
      )
    ];

    RideRouteType type;
    switch (result.routeType) {
      case RouteOptionType.alternative:
        type = RideRouteType.alternative;
        break;
      default:
        type = RideRouteType.fastest;
    }

    return RideRouteResponse(
      routeId: result.id,
      routeType: type,
      fullPolyline: result.polylinePoints,
      totalDistanceKm: result.distanceKm,
      totalDurationMinutes: result.durationMinutes,
      segments: segments,
      sourceProvider: providerName,
      timestamp: DateTime.now(),
      metadata: metadata,
      globalWarnings: [
        if (request.avoidTolls && metadata.tollInformation == DataAvailability.supported)
          const RideRouteWarning(
            text: 'Route contains tolls despite preference to avoid.',
            severity: 'INFO',
          )
      ],
    );
  }
}
