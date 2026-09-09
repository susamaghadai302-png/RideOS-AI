import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/core/services/road_os_routing_engine.dart';
import 'package:rideos_mobile/features/navigation/core/services/voice_guidance_service.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/place_search_entity.dart';

void main() {
  group('Phase 2 - Advanced Navigation Tests', () {
    late VoiceGuidanceService voiceService;
    late RoadOsRoutingEngine routingEngine;

    setUp(() {
      voiceService = VoiceGuidanceService();
      routingEngine = RoadOsRoutingEngine.instance;
    });

    test('Voice guidance language pack switching', () {
      expect(voiceService.currentLanguage, NavigationLanguage.english);
      voiceService.setLanguage(NavigationLanguage.hindi);
      expect(voiceService.currentLanguage, NavigationLanguage.hindi);
      voiceService.setLanguage(NavigationLanguage.odia);
      expect(voiceService.currentLanguage, NavigationLanguage.odia);
    });

    test('RouteOptionType configurations and metrics', () {
      expect(RouteOptionType.fastestHighway.title, 'Fastest Highway');
      expect(RouteOptionType.twistyCorridor.title, 'Twisty Corridor');
      expect(RouteOptionType.ecoScenic.title, 'Eco Scenic');
    });

    test('Off-route detector classifies points correctly', () {
      final polyline = [
        const LatLng(20.2961, 85.8245),
        const LatLng(20.3000, 85.8300),
        const LatLng(20.3100, 85.8400),
      ];

      // Point directly on/near polyline
      const onRoutePoint = LatLng(20.2962, 85.8246);
      final isOff1 = routingEngine.isOffRoute(onRoutePoint, polyline, thresholdMeters: 50.0);
      expect(isOff1, isFalse);

      // Point far away (>500 meters)
      const farOffPoint = LatLng(20.3500, 85.9000);
      final isOff2 = routingEngine.isOffRoute(farOffPoint, polyline, thresholdMeters: 50.0);
      expect(isOff2, isTrue);
    });

    test('PlaceSearchResultEntity models destination correctly', () {
      const place = PlaceSearchResultEntity(
        id: 'place_dest_01',
        title: 'Puri Golden Beach',
        subtitle: 'Chakratirtha Road, Puri, Odisha',
        category: 'BEACH_SCENIC',
        latitude: 19.8135,
        longitude: 85.8312,
        distanceKm: 62.4,
      );

      expect(place.title, 'Puri Golden Beach');
      expect(place.latitude, 19.8135);
      expect(place.longitude, 85.8312);
      expect(place.distanceKm, 62.4);
    });
  });
}
