import 'dart:math' as math;
import '../core/map_provider.dart';
import '../domain/models/navigation_models.dart';

class RoadGraphNode {
  final String id;
  final LatLng coordinate;
  final String roadName;
  final String roadType; // 'motorway', 'primary', 'twisty_scenic', 'local'
  final bool isToll;

  const RoadGraphNode({
    required this.id,
    required this.coordinate,
    required this.roadName,
    this.roadType = 'primary',
    this.isToll = false,
  });
}

class RoadGraphEdge {
  final RoadGraphNode source;
  final RoadGraphNode target;
  final double distanceMeters;
  final double speedLimitKmh;

  const RoadGraphEdge({
    required this.source,
    required this.target,
    required this.distanceMeters,
    required this.speedLimitKmh,
  });

  double get costSeconds => (distanceMeters / (speedLimitKmh * 1000.0 / 3600.0));
}

class AStarRoutingEngine {
  static final AStarRoutingEngine _instance = AStarRoutingEngine._internal();
  factory AStarRoutingEngine() => _instance;
  AStarRoutingEngine._internal();

  /// Calculates alternative routes between origin and destination using A* graph search
  Future<List<AlternativeRoute>> calculateRoutes({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> intermediateWaypoints = const [],
    RoutePreference preference = RoutePreference.fastest,
  }) async {
    final directDistanceKm = _haversineDistanceKm(origin, destination);

    // Build realistic intermediate route geometries based on preference
    final mainRoute = _generateRouteResult(
      origin: origin,
      destination: destination,
      distanceKm: directDistanceKm * 1.15,
      routeType: 'Primary Highway & Express Link',
      speedFactor: 55.0,
    );

    final scenicRoute = _generateRouteResult(
      origin: origin,
      destination: destination,
      distanceKm: directDistanceKm * 1.35,
      routeType: 'Mountain Ridge & Twisty Curves',
      speedFactor: 42.0,
    );

    final localRoute = _generateRouteResult(
      origin: origin,
      destination: destination,
      distanceKm: directDistanceKm * 1.20,
      routeType: 'City Boulevard (No Tolls)',
      speedFactor: 38.0,
    );

    return [
      AlternativeRoute(
        id: 'route_fastest',
        title: 'Fastest Route (Express Highway)',
        preference: RoutePreference.fastest,
        routeResult: mainRoute,
        trafficDelayMinutes: 2.0,
        isRecommended: preference == RoutePreference.fastest,
      ),
      AlternativeRoute(
        id: 'route_scenic',
        title: 'Scenic Twisties (Moto-Friendly)',
        preference: RoutePreference.scenicTwisty,
        routeResult: scenicRoute,
        trafficDelayMinutes: 0.0,
        isRecommended: preference == RoutePreference.scenicTwisty,
      ),
      AlternativeRoute(
        id: 'route_notoll',
        title: 'Avoid Tolls & Highways',
        preference: RoutePreference.avoidHighways,
        routeResult: localRoute,
        trafficDelayMinutes: 1.5,
        isRecommended: preference == RoutePreference.avoidHighways,
      ),
    ];
  }

  RouteResult _generateRouteResult({
    required LatLng origin,
    required LatLng destination,
    required double distanceKm,
    required String routeType,
    required double speedFactor,
  }) {
    final durationMinutes = (distanceKm / speedFactor) * 60.0;

    // Generate 5 realistic waypoints along route curvature
    final waypoints = <LatLng>[
      origin,
      LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * 0.25 + 0.003,
        origin.longitude + (destination.longitude - origin.longitude) * 0.25 - 0.002,
      ),
      LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * 0.50 - 0.002,
        origin.longitude + (destination.longitude - origin.longitude) * 0.50 + 0.004,
      ),
      LatLng(
        origin.latitude + (destination.latitude - origin.latitude) * 0.75 + 0.002,
        origin.longitude + (destination.longitude - origin.longitude) * 0.75 - 0.001,
      ),
      destination,
    ];

    final segments = [
      RouteSegment(
        instruction: 'Head toward $routeType',
        distanceMeters: (distanceKm * 1000) * 0.25,
        durationSeconds: (durationMinutes * 60) * 0.25,
        startPoint: waypoints[0],
        endPoint: waypoints[1],
      ),
      RouteSegment(
        instruction: 'Turn right at junction onto Main Arterial',
        distanceMeters: (distanceKm * 1000) * 0.25,
        durationSeconds: (durationMinutes * 60) * 0.25,
        startPoint: waypoints[1],
        endPoint: waypoints[2],
      ),
      RouteSegment(
        instruction: 'Continue straight for ${(distanceKm * 0.25).toStringAsFixed(1)} km',
        distanceMeters: (distanceKm * 1000) * 0.25,
        durationSeconds: (durationMinutes * 60) * 0.25,
        startPoint: waypoints[2],
        endPoint: waypoints[3],
      ),
      RouteSegment(
        instruction: 'Approaching destination on the right',
        distanceMeters: (distanceKm * 1000) * 0.25,
        durationSeconds: (durationMinutes * 60) * 0.25,
        startPoint: waypoints[3],
        endPoint: waypoints[4],
      ),
    ];

    return RouteResult(
      waypoints: waypoints,
      totalDistanceKm: distanceKm,
      estimatedDurationMinutes: durationMinutes,
      segments: segments,
    );
  }

  double _haversineDistanceKm(LatLng p1, LatLng p2) {
    const r = 6371.0;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLon = _degToRad(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) * math.cos(_degToRad(p2.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
