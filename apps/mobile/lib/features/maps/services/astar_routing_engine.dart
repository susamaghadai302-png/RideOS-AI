
import '../core/map_provider.dart';
import '../core/map_provider_factory.dart';
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

  /// Calculates routes using the active map provider
  Future<List<AlternativeRoute>> calculateRoutes({
    required LatLng origin,
    required LatLng destination,
    List<LatLng> intermediateWaypoints = const [],
    RoutePreference preference = RoutePreference.fastest,
  }) async {
    final activeProvider = MapProviderFactory().activeProvider;
    
    // This will throw a StateError if offline/no dataset, which is the truthful behavior
    final route = await activeProvider.calculateRoute(
      origin: origin,
      destination: destination,
      waypoints: intermediateWaypoints,
    );

    return [
      AlternativeRoute(
        id: 'route_primary',
        title: 'Primary Route',
        preference: preference,
        routeResult: route,
        trafficDelayMinutes: 0.0,
        isRecommended: true,
      ),
    ];
  }

}
