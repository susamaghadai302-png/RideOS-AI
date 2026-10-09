
import '../../domain/models/ride_route_models.dart';
import 'route_adapter.dart';
import '../services/road_os_routing_engine.dart';

class OsrmRouteAdapter implements RouteAdapter {
  final RoadOsRoutingEngine _engine = RoadOsRoutingEngine.instance;

  @override
  String get providerName => 'OSRM Driving Engine (Adapting Two-Wheeler)';

  @override
  Future<List<RideRouteResponse>> calculateRoute(RideRouteRequest request) async {
    // Map requested preference to internal OSRM option
    RouteOptionType preferredType = RouteOptionType.fastestHighway;
    if (request.preferredRouteType != null) {
      switch (request.preferredRouteType!) {
        case RideRouteType.safe:
          throw UnsupportedError('Safe routing is genuinely not supported by the OSRM engine.');
        case RideRouteType.eco:
          throw UnsupportedError('Eco routing is genuinely not supported by the OSRM engine.');
        case RideRouteType.scenic:
          throw UnsupportedError('Scenic routing is genuinely not supported by the OSRM engine.');
        case RideRouteType.alternative:
          preferredType = RouteOptionType.alternative;
          break;
        case RideRouteType.fastest:
          preferredType = RouteOptionType.fastestHighway;
          break;
      }
    }
    // Convert generic domain request to provider-specific execution
    final multiResult = await _engine.calculateMultiRoutes(
      start: request.origin,
      destination: request.destination,
      waypoints: request.waypoints,
      selectedOption: preferredType,
    );

    return multiResult.allRoutes.map((r) => _mapToCanonical(r, request)).toList();
  }

  RideRouteResponse _mapToCanonical(RouteCalculationResult result, RideRouteRequest request) {
    // OSRM Public API doesn't support live traffic, tolls, or true 2-wheeler
    const metadata = RideRouteMetadata(
      twoWheelerRouting: DataAvailability.unsupported, // We pass TWO_WHEELER request, but OSRM falls back to driving
      liveTraffic: DataAvailability.unsupported,
      alternativeRoutes: DataAvailability.supported,
      tollInformation: DataAvailability.unsupported,
      elevationProfile: DataAvailability.unsupported,
      weatherImpact: DataAvailability.unsupported,
    );

    final segments = [
      RideRouteSegment(
        polyline: result.polylinePoints,
        distanceKm: result.distanceKm,
        durationMinutes: result.durationMinutes,
        roadName: result.viaSummary,
        speedLimitKmh: null, // Unknown
        trafficAvailability: DataAvailability.unavailable,
        tollAvailability: DataAvailability.unavailable,
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
      case RouteOptionType.safeCorridor:
        type = RideRouteType.safe;
        break;
      case RouteOptionType.ecoEfficient:
        type = RideRouteType.eco;
        break;
      case RouteOptionType.scenicTwists:
        type = RideRouteType.scenic;
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
        if (request.twoWheelerMode && metadata.twoWheelerRouting == DataAvailability.unsupported)
          const RideRouteWarning(
            text: 'Two-Wheeler routing unsupported by current provider. Showing driving route.',
            severity: 'WARNING',
          )
      ]
    );
  }
}
