import '../../domain/models/ride_route_models.dart';

abstract class RouteAdapter {
  String get providerName;

  /// Calculates a route using the canonical domain request
  Future<List<RideRouteResponse>> calculateRoute(RideRouteRequest request);
}
