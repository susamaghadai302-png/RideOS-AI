import '../../core/map_abstraction/map_engine_interface.dart';
import '../entities/route_entity.dart';
import 'route_service.dart';

abstract class NavigationService {
  Future<NavigationRouteEntity> startNavigation({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  });

  Future<void> stopNavigation();

  Future<NavigationRouteEntity> reroute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  });
}
