import '../entities/route_entity.dart';
import '../../core/map_abstraction/map_engine_interface.dart';

class RouteCalculationException implements Exception {
  final String message;
  RouteCalculationException(this.message);
  @override
  String toString() => 'RouteCalculationException: $message';
}

class EvChargingUnavailableException implements Exception {
  final String message;
  EvChargingUnavailableException(this.message);
  @override
  String toString() => 'EvChargingUnavailableException: $message';
}

class VehicleRoutingProfile {
  final bool isEv;
  final double? currentRangeKm;
  final String? connectorType;

  const VehicleRoutingProfile({
    this.isEv = false,
    this.currentRangeKm,
    this.connectorType,
  });
}

abstract class RouteService {
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  });

  Future<NavigationRouteEntity> recalculateRoute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  });
}
