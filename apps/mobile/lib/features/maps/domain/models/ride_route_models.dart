import 'package:latlong2/latlong.dart';

enum DataAvailability {
  supported,
  unsupported,
  unavailable,
  unknown
}

enum RideRouteType {
  fastest('Fastest Route'),
  safe('Safe Route'),
  eco('Eco Route'),
  scenic('Scenic Route'),
  alternative('Alternative Route');

  final String displayName;
  const RideRouteType(this.displayName);
}

class RideRouteRequest {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> waypoints;
  final bool twoWheelerMode;
  final bool avoidTolls;
  final bool avoidHighways;
  final RideRouteType? preferredRouteType;

  const RideRouteRequest({
    required this.origin,
    required this.destination,
    this.waypoints = const [],
    this.twoWheelerMode = true,
    this.avoidTolls = false,
    this.avoidHighways = false,
    this.preferredRouteType,
  });
}

class RideRouteWarning {
  final String text;
  final String severity; // INFO, WARNING, CRITICAL

  const RideRouteWarning({
    required this.text,
    this.severity = 'INFO',
  });
}

class RideManeuver {
  final String instruction;
  final LatLng coordinate;
  final double distanceMeters;
  final String maneuverType;

  const RideManeuver({
    required this.instruction,
    required this.coordinate,
    required this.distanceMeters,
    required this.maneuverType,
  });
}

class RideRouteSegment {
  final List<LatLng> polyline;
  final double distanceKm;
  final int durationMinutes;
  final List<RideManeuver> maneuvers;
  final List<RideRouteWarning> warnings;
  final String? roadName;
  final double? speedLimitKmh; // nullable: missing speed limit != 0
  final DataAvailability trafficAvailability;
  final DataAvailability tollAvailability;

  const RideRouteSegment({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
    required this.maneuvers,
    this.warnings = const [],
    this.roadName,
    this.speedLimitKmh,
    this.trafficAvailability = DataAvailability.unknown,
    this.tollAvailability = DataAvailability.unknown,
  });
}

class RideRouteMetadata {
  final DataAvailability twoWheelerRouting;
  final DataAvailability liveTraffic;
  final DataAvailability alternativeRoutes;
  final DataAvailability tollInformation;
  final DataAvailability elevationProfile;
  final DataAvailability weatherImpact;

  const RideRouteMetadata({
    this.twoWheelerRouting = DataAvailability.unknown,
    this.liveTraffic = DataAvailability.unknown,
    this.alternativeRoutes = DataAvailability.unknown,
    this.tollInformation = DataAvailability.unknown,
    this.elevationProfile = DataAvailability.unknown,
    this.weatherImpact = DataAvailability.unknown,
  });
}

class RideRouteResponse {
  final String routeId;
  final RideRouteType routeType;
  final List<LatLng> fullPolyline;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<RideRouteSegment> segments;
  final List<RideRouteWarning> globalWarnings;
  final String sourceProvider;
  final DateTime timestamp;
  final RideRouteMetadata metadata;

  const RideRouteResponse({
    required this.routeId,
    required this.routeType,
    required this.fullPolyline,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.segments,
    this.globalWarnings = const [],
    required this.sourceProvider,
    required this.timestamp,
    this.metadata = const RideRouteMetadata(),
  });
}
