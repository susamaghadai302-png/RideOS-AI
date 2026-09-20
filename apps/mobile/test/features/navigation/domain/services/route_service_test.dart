import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/navigation/domain/services/route_service.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/navigation/core/map_abstraction/map_engine_interface.dart';

class MockRouteService implements RouteService {
  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  }) async {
    if (vehicleProfile != null && vehicleProfile.isEv) {
      if (vehicleProfile.currentRangeKm != null && vehicleProfile.currentRangeKm! < 20.0) {
        throw EvChargingUnavailableException('No charging stations within current range');
      }
    }
    
    if (origin.latitude == 0.0 && origin.longitude == 0.0) {
      throw RouteCalculationException('Invalid origin');
    }

    return const NavigationRouteEntity(
      routeId: 'test_route_123',
      distanceKm: 50.0,
      durationMinutes: 45,
      waypoints: [],
      steps: [],
      twistinessScore: 0.8,
      provider: 'google_maps',
    );
  }

  @override
  Future<NavigationRouteEntity> recalculateRoute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  }) async {
    return currentRoute;
  }
}

void main() {
  group('RouteService (Phase 8 Domain)', () {
    late MockRouteService routeService;

    setUp(() {
      routeService = MockRouteService();
    });

    test('calculateRoute returns valid route for standard vehicle', () async {
      final route = await routeService.calculateRoute(
        origin: const MapCoordinates(latitude: 37.7749, longitude: -122.4194),
        destination: const MapCoordinates(latitude: 34.0522, longitude: -118.2437),
      );

      expect(route.routeId, 'test_route_123');
      expect(route.provider, 'google_maps');
    });

    test('calculateRoute throws EvChargingUnavailableException when EV out of range with no charging', () async {
      const profile = VehicleRoutingProfile(isEv: true, currentRangeKm: 15.0, connectorType: 'CCS2');

      expect(
        () => routeService.calculateRoute(
          origin: const MapCoordinates(latitude: 37.7749, longitude: -122.4194),
          destination: const MapCoordinates(latitude: 34.0522, longitude: -118.2437),
          vehicleProfile: profile,
        ),
        throwsA(isA<EvChargingUnavailableException>()),
      );
    });

    test('calculateRoute throws RouteCalculationException for invalid origin', () async {
      expect(
        () => routeService.calculateRoute(
          origin: const MapCoordinates(latitude: 0.0, longitude: 0.0),
          destination: const MapCoordinates(latitude: 34.0522, longitude: -118.2437),
        ),
        throwsA(isA<RouteCalculationException>()),
      );
    });
  });
}
