import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/core/services/google_maps_platform_service.dart';
import 'package:rideos_mobile/features/maps/core/services/road_os_routing_engine.dart';

class MockBackendRoutingAdapter implements HttpClientAdapter {
  final Map<String, dynamic> responseData;
  final int statusCode;
  RequestOptions? lastRequestOptions;

  MockBackendRoutingAdapter({required this.responseData, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    final jsonStr = jsonEncode(responseData);
    return ResponseBody.fromString(
      jsonStr,
      statusCode,
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

  group('GoogleMapsPlatformService Backend Routing Integration', () {
    late GoogleMapsPlatformService service;

    setUp(() {
      service = GoogleMapsPlatformService.instance;
    });

    test('calculateDirections calls backend /navigation/route with GOOGLE_MAPS provider and parses route correctly', () async {
      final mockData = {
        'routeId': 'backend-route-uuid-1',
        'distanceKm': 7.47,
        'durationMinutes': 18,
        'polyline': 'ua{zBoryjOmEx@uGvAcRzDcQhDeDt@y@Z{CjB{@h@wCxAiAd@qATaAJiC?qCIsIIgRKiGIuGG}FIqSQyLEcDCoHg@s^eC}OeAaAEuQoAuSwAoGe@eD_AoEgAeDu@sAU_G}AgDo@qEoA}HkBwHkBuGiBS~@INOjHI|BQhICxB[`TGjBx@DDAX@',
        'routeName': 'Nandankanan Rd',
        'provider': 'GOOGLE_MAPS',
        'steps': [
          {
            'instruction': 'Head north on Nandankanan Rd',
            'distanceMeters': 500.0,
            'durationSeconds': 60,
            'type': 'DEPART',
            'maneuverPoint': {'lat': 20.2961, 'lng': 85.8245},
            'stepCoordinates': [
              {'lat': 20.2961, 'lng': 85.8245},
              {'lat': 20.3000, 'lng': 85.8250},
            ],
          },
          {
            'instruction': 'Turn left onto KIIT Rd',
            'distanceMeters': 6973.0,
            'durationSeconds': 1027,
            'type': 'TURN_LEFT',
            'maneuverPoint': {'lat': 20.3000, 'lng': 85.8250},
            'stepCoordinates': [
              {'lat': 20.3000, 'lng': 85.8250},
              {'lat': 20.3533, 'lng': 85.8178},
            ],
          },
        ],
        'alternatives': [
          {
            'routeId': 'backend-route-alt-1',
            'distanceKm': 10.52,
            'durationMinutes': 22,
            'polyline': 'ua{zBoryjOmEx@uGvAcRzDcQhDeDt@y@Z{CjB{@h@wCxAiAd@Lj@f@nC@l@a@~Lk@nMQtFYzGG~BOpCM`FDb@BLT`@?TKTMFUAOOCI_@OgMyCcFi@}EUiCEcA@eAJk@NWHUCeB`@eAJqAAkCIeJi@}ACa@NMNKh@MhEKxBy@pFK^yAtJiAnJKpBBfAt@rJAb@ETQTWL_@BkAMeDe@_Fi@uBMiBUaBYkFe@_Dc@WGgEc@wB[oBQeGUo@EkFUwE[qYaCILSDQEMQASHSPIH?Lw@Du@BeCMkGSiEDOMsBAcA?gA_BWs@E{JXyDVaGNsKBgQJ}TVw@AoGH{DFkE@@aFLwDLoHPgGHWTiDHcEBa@JoKBqBN}ALsDx@DDAX@',
            'routeName': 'Technology Corridor',
            'provider': 'GOOGLE_MAPS',
            'steps': [
              {
                'instruction': 'Head north toward Xavier Rd',
                'distanceMeters': 800.0,
                'durationSeconds': 100,
                'type': 'DEPART',
                'maneuverPoint': {'lat': 20.2961, 'lng': 85.8245},
              },
            ],
          },
        ],
      };

      final adapter = MockBackendRoutingAdapter(responseData: mockData);
      service.setMockAdapter(adapter);

      const origin = LatLng(20.2961, 85.8245);
      const dest = LatLng(20.3533, 85.8178);

      final result = await service.calculateDirections(
        origin: origin,
        destination: dest,
        selectedOption: RouteOptionType.fastestHighway,
      );

      // Verify request to backend
      expect(adapter.lastRequestOptions, isNotNull);
      expect(adapter.lastRequestOptions!.path, contains('/navigation/route'));
      final reqBody = adapter.lastRequestOptions!.data as Map<String, dynamic>;
      expect(reqBody['provider'], equals('GOOGLE_MAPS'));
      expect(reqBody['origin']['lat'], equals(20.2961));
      expect(reqBody['destination']['lat'], equals(20.3533));

      // Verify primary route parsing
      expect(result.activeRoute.id, equals('backend-route-uuid-1'));
      expect(result.activeRoute.distanceKm, equals(7.5));
      expect(result.activeRoute.durationMinutes, equals(18));
      expect(result.activeRoute.routeName, equals('via Nandankanan Rd'));
      expect(result.activeRoute.sourceProvider, equals('GOOGLE_MAPS'));
      expect(result.activeRoute.steps.length, equals(2));
      expect(result.activeRoute.steps[0].instruction, equals('Head north on Nandankanan Rd'));
      expect(result.activeRoute.steps[0].iconType, equals('straight'));
      expect(result.activeRoute.steps[1].instruction, equals('Turn left onto KIIT Rd'));
      expect(result.activeRoute.steps[1].iconType, equals('left'));

      // Verify alternative routes
      expect(result.alternativeRoutes.length, equals(1));
      expect(result.alternativeRoutes[0].distanceKm, equals(10.5));
      expect(result.alternativeRoutes[0].routeName, equals('via Technology Corridor'));
      expect(result.allRoutes.length, equals(2));
    });

    test('calculateDirections throws StateError when backend fails and no direct key is configured', () async {
      final adapter = MockBackendRoutingAdapter(responseData: {'error': 'Service Unavailable'}, statusCode: 503);
      service.setMockAdapter(adapter);

      const origin = LatLng(20.2961, 85.8245);
      const dest = LatLng(20.3533, 85.8178);

      await expectLater(
        () => service.calculateDirections(origin: origin, destination: dest),
        throwsStateError,
      );
    });
  });
}
