import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/core/services/road_os_routing_engine.dart';
import 'package:rideos_mobile/features/maps/core/services/india_places_search_engine.dart';

class _MockRoutingAdapter implements HttpClientAdapter {
  int requestCount = 0;
  bool shouldFail = false;
  int statusCode = 200;
  Duration simulatedLatency = Duration.zero;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    if (shouldFail) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Rate limited or server failure'}),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final mockResponse = {
      'code': 'Ok',
      'routes': [
        {
          'geometry': {
            'coordinates': [
              [85.8245, 20.2961],
              [85.8500, 20.3500],
              [85.8830, 20.4625],
            ],
          },
          'legs': [
            {
              'steps': [
                {
                  'name': 'NH16 Expressway',
                  'distance': 25000.0,
                  'maneuver': {'type': 'depart', 'modifier': 'straight'},
                },
                {
                  'name': 'Cuttack Main Link',
                  'distance': 3500.0,
                  'maneuver': {'type': 'turn', 'modifier': 'slight right'},
                },
              ],
            }
          ],
          'distance': 28500.0,
          'duration': 1800.0,
        }
      ]
    };

    return ResponseBody.fromString(
      jsonEncode(mockResponse),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Routing Hardening, Coalescing, Cost-Protection & Observability Tests', () {
    const startBhubaneswar = LatLng(20.2961, 85.8245);
    const endCuttack = LatLng(20.4625, 85.8830);
    late _MockRoutingAdapter mockAdapter;

    setUp(() {
      RoadOsRoutingEngine.instance.clearCache();
      RoadOsRoutingEngine.instance.metrics.reset();
      mockAdapter = _MockRoutingAdapter();
      RoadOsRoutingEngine.instance.setMockAdapter(mockAdapter);
      RoadOsRoutingEngine.environment = RoutingEnvironment.development;
      RoadOsRoutingEngine.activeBaseUrl = RoadOsRoutingEngine.defaultOsrmBaseUrl;
      RoadOsRoutingEngine.allowDemoServerInRelease = false;
    });

    test('1. In-memory routing cache returns cached route on repeated identical queries without hitting network', () async {
      final result1 = await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );

      expect(mockAdapter.requestCount, equals(1));
      expect(result1.activeRoute.polylinePoints.length, equals(3));
      expect(result1.activeRoute.distanceKm, equals(28.5));

      // Second call with identical coordinates resolves from cache
      final result2 = await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );

      expect(mockAdapter.requestCount, equals(1)); // Cache hit
      expect(RoadOsRoutingEngine.instance.metrics.cacheHits, equals(1));
      expect(result2.activeRoute.distanceKm, equals(28.5));
    });

    test('2. clearCache forces fresh network retrieval on next calculation', () async {
      await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );
      expect(mockAdapter.requestCount, equals(1));

      RoadOsRoutingEngine.instance.clearCache();

      await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
        forceRefresh: true,
      );
      expect(mockAdapter.requestCount, equals(2));
    });

    test('3. Production safety: Release mode throws RoutingUnavailableException if demo server is used without explicit configuration', () async {
      RoadOsRoutingEngine.environment = RoutingEnvironment.production;
      RoadOsRoutingEngine.activeBaseUrl = ''; // No dedicated endpoint configured
      RoadOsRoutingEngine.allowDemoServerInRelease = false;

      expect(
        () async => await RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: startBhubaneswar,
          destination: endCuttack,
        ),
        throwsA(isA<RoutingUnavailableException>().having(
          (e) => e.sourceProvider,
          'sourceProvider',
          equals('ROUTING_UNAVAILABLE'),
        )),
      );
      expect(mockAdapter.requestCount, equals(0)); // Never contacted demo server
    });

    test('3b. Production safety: Release mode blocks public demo server even if passed via activeBaseUrl', () async {
      RoadOsRoutingEngine.environment = RoutingEnvironment.production;
      RoadOsRoutingEngine.activeBaseUrl = 'https://router.project-osrm.org/route/v1/driving';
      RoadOsRoutingEngine.allowDemoServerInRelease = false;

      expect(
        () async => await RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: startBhubaneswar,
          destination: endCuttack,
        ),
        throwsA(isA<RoutingUnavailableException>().having(
          (e) => e.sourceProvider,
          'sourceProvider',
          equals('ROUTING_UNAVAILABLE'),
        )),
      );
      expect(mockAdapter.requestCount, equals(0)); // Never contacted demo server
    });

    test('4. Dedicated endpoint in production succeeds with CUSTOM_ROUTING_ENDPOINT provider tagging', () async {
      RoadOsRoutingEngine.environment = RoutingEnvironment.production;
      RoadOsRoutingEngine.activeBaseUrl = 'https://routing.rideos.internal/route/v1/driving';

      final result = await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );

      expect(result.activeRoute.sourceProvider, equals('CUSTOM_ROUTING_ENDPOINT'));
      expect(result.activeRoute.attribution, contains('RideOS Dedicated Routing Cluster'));
      expect(result.activeRoute.sourceProvider, isNot(equals('GOOGLE_MAPS')));
    });

    test('5. Development mode with OSRM demo explicitly tags OSRM_COMMUNITY_DEMO_DEV and dev/test attribution', () async {
      RoadOsRoutingEngine.environment = RoutingEnvironment.development;
      RoadOsRoutingEngine.activeBaseUrl = RoadOsRoutingEngine.defaultOsrmBaseUrl;

      final result = await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );

      expect(result.activeRoute.sourceProvider, equals('OSRM_COMMUNITY_DEMO_DEV'));
      expect(result.activeRoute.attribution, contains('OSRM Demo Server (Dev/Test only)'));
      expect(result.activeRoute.sourceProvider, isNot(equals('GOOGLE_MAPS')));
    });

    test('6. Request coalescing: Concurrent identical requests execute only 1 network call', () async {
      mockAdapter.simulatedLatency = const Duration(milliseconds: 50);

      // Fire 2 concurrent identical requests
      final future1 = RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );
      final future2 = RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );

      final results = await Future.wait([future1, future2]);

      expect(mockAdapter.requestCount, equals(1)); // Coalesced into a single network call!
      expect(RoadOsRoutingEngine.instance.metrics.deduplicatedRequests, equals(1));
      expect(results[0].activeRoute.distanceKm, equals(28.5));
      expect(results[1].activeRoute.distanceKm, equals(28.5));
    });

    test('7. HTTP 429 Provider Rate Limit throws RoutingUnavailableException with OSRM_RATE_LIMITED without retry loops', () async {
      mockAdapter.shouldFail = true;
      mockAdapter.statusCode = 429;

      await expectLater(
        () => RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: startBhubaneswar,
          destination: endCuttack,
        ),
        throwsA(isA<RoutingUnavailableException>().having(
          (e) => e.sourceProvider,
          'sourceProvider',
          equals('OSRM_RATE_LIMITED'),
        )),
      );
      expect(RoadOsRoutingEngine.instance.metrics.failedRequests, equals(1));
    });

    test('8. HTTP 500 Server Error throws RoutingUnavailableException with ROUTING_SERVER_ERROR', () async {
      mockAdapter.shouldFail = true;
      mockAdapter.statusCode = 500;

      await expectLater(
        () => RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: startBhubaneswar,
          destination: endCuttack,
        ),
        throwsA(isA<RoutingUnavailableException>().having(
          (e) => e.sourceProvider,
          'sourceProvider',
          equals('ROUTING_SERVER_ERROR'),
        )),
      );
    });

    test('9. Cost protection: Client daily quota cap triggers RoutingUnavailableException with LIMIT_EXCEEDED', () async {
      RoadOsRoutingEngine.activeBaseUrl = 'https://custom.routing/route';
      RoadOsRoutingEngine.instance.metrics.dailyRequestCap = 2;

      // 1st request (ok)
      await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: startBhubaneswar,
        destination: endCuttack,
      );
      RoadOsRoutingEngine.instance.clearCache();

      // 2nd request (ok)
      await RoadOsRoutingEngine.instance.calculateMultiRoutes(
        start: const LatLng(20.3000, 85.8300),
        destination: endCuttack,
      );
      RoadOsRoutingEngine.instance.clearCache();

      // 3rd request exceeds cap!
      await expectLater(
        () => RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: const LatLng(20.3100, 85.8400),
          destination: endCuttack,
        ),
        throwsA(isA<RoutingUnavailableException>().having(
          (e) => e.sourceProvider,
          'sourceProvider',
          equals('LIMIT_EXCEEDED'),
        )),
      );
    });

    test('10. Off-route detection with thresholding accurately identifies corridor deviations', () {
      final corridor = [
        const LatLng(20.2961, 85.8245),
        const LatLng(20.3200, 85.8300),
        const LatLng(20.3500, 85.8400),
      ];

      // On route
      const onRoutePoint = LatLng(20.3200, 85.8300);
      expect(RoadOsRoutingEngine.instance.isOffRoute(onRoutePoint, corridor, thresholdMeters: 45.0), isFalse);

      // 20m away (within tolerance)
      const nearPoint = LatLng(20.3201, 85.8301);
      expect(RoadOsRoutingEngine.instance.isOffRoute(nearPoint, corridor, thresholdMeters: 45.0), isFalse);

      // 500m away (off route)
      const offRoutePoint = LatLng(20.3200, 85.8450);
      expect(RoadOsRoutingEngine.instance.isOffRoute(offRoutePoint, corridor, thresholdMeters: 45.0), isTrue);
    });

    test('11. Dynamic distance and ETA updates along route compute valid non-negative metrics', () {
      const currentPos = LatLng(20.2961, 85.8245);
      const destination = LatLng(20.4625, 85.8830);

      final distanceKm = IndiaPlacesSearchEngine.calculateDistanceKm(currentPos, destination);
      expect(distanceKm, greaterThan(15.0));
      expect(distanceKm, lessThan(30.0));

      final durationMin = (distanceKm / 0.5).round();
      expect(durationMin, greaterThan(25));
    });
  });
}
