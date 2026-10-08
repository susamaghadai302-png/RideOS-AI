import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/domain/models/ride_route_models.dart';
import 'package:rideos_mobile/features/maps/core/adapters/route_adapter.dart';
import 'package:rideos_mobile/features/maps/core/services/route_request_coordinator.dart';

class MockRouteAdapter implements RouteAdapter {
  int callCount = 0;
  bool shouldFail = false;

  @override
  String get providerName => 'MockProvider';

  @override
  Future<List<RideRouteResponse>> calculateRoute(RideRouteRequest request) async {
    callCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (shouldFail) {
      throw StateError('Mock network failure');
    }

    return [
      RideRouteResponse(
        routeId: 'mock-route',
        routeType: RideRouteType.fastest,
        fullPolyline: [request.origin, request.destination],
        totalDistanceKm: 1.0,
        totalDurationMinutes: 5,
        segments: [],
        sourceProvider: providerName,
        timestamp: DateTime.now(),
        metadata: const RideRouteMetadata(
          twoWheelerRouting: DataAvailability.supported,
          liveTraffic: DataAvailability.unsupported,
          alternativeRoutes: DataAvailability.unsupported,
          tollInformation: DataAvailability.unsupported,
          elevationProfile: DataAvailability.unsupported,
          weatherImpact: DataAvailability.unsupported,
        ),
        globalWarnings: [],
      )
    ];
  }
}

void main() {
  group('RouteRequestCoordinator Tests', () {
    late MockRouteAdapter mockAdapter;
    late RouteRequestCoordinator coordinator;
    const reqA = RideRouteRequest(origin: LatLng(0,0), destination: LatLng(1,1), twoWheelerMode: true);
    const reqB = RideRouteRequest(origin: LatLng(0,0), destination: LatLng(2,2), twoWheelerMode: true);

    setUp(() {
      mockAdapter = MockRouteAdapter();
      coordinator = RouteRequestCoordinator(mockAdapter);
    });

    test('Cache hit returns cached result and prevents API call', () async {
      await coordinator.calculateRoute(reqA);
      expect(mockAdapter.callCount, 1);
      
      final res2 = await coordinator.calculateRoute(reqA);
      expect(mockAdapter.callCount, 1); // Not called again
      expect(coordinator.metrics.cacheHits, 1);
      expect(res2.first.routeId, 'mock-route');
    });

    test('Cache miss calls API', () async {
      await coordinator.calculateRoute(reqA);
      await coordinator.calculateRoute(reqB);
      expect(mockAdapter.callCount, 2);
      expect(coordinator.metrics.cacheMisses, 2);
    });

    test('Concurrent identical requests are coalesced into a single API call', () async {
      final f1 = coordinator.calculateRoute(reqA);
      final f2 = coordinator.calculateRoute(reqA);
      
      await Future.wait([f1, f2]);
      
      expect(mockAdapter.callCount, 1);
      expect(coordinator.metrics.deduplicatedRequests, 1);
    });

    test('Cancellation prevents late returns', () async {
      final future = coordinator.calculateRoute(reqA);
      coordinator.cancelAll();
      
      expect(() async => await future, throwsStateError);
      expect(coordinator.metrics.cancelledRequests, 1);
    });

    test('Backoff retries on failure', () async {
      mockAdapter.shouldFail = true;
      try {
        await coordinator.calculateRoute(reqA);
      } catch (e) {
        expect(e, isA<StateError>());
      }
      expect(mockAdapter.callCount, 3); // 1 initial + 2 retries
      expect(coordinator.metrics.retryCount, 3); // 3 exceptions caught total
    });
  });
}
