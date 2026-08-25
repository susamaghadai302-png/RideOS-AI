import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/core/google_maps_provider.dart';
import 'package:rideos_mobile/features/maps/core/local_graph_map_provider.dart';
import 'package:rideos_mobile/features/maps/core/map_provider_factory.dart';

void main() {
  group('GoogleMapsProvider & MapProviderFactory Production Tests', () {
    late GoogleMapsProvider googleProvider;
    late MapProviderFactory factory;

    setUp(() {
      googleProvider = GoogleMapsProvider();
      factory = MapProviderFactory();
    });

    test('GoogleMapsProvider satisfies MapProvider contract and flags billing', () {
      expect(googleProvider.providerName, equals('Google Maps (Production Provider)'));
      expect(googleProvider.requiresPaidBilling, isTrue);
    });

    test('MapProviderFactory seamlessly switches between Google Maps and LocalGraph fallback', () {
      factory.useGoogleMaps();
      expect(factory.currentEngine, equals(MapEngineType.googleMaps));
      expect(factory.activeProvider is GoogleMapsProvider, isTrue);

      factory.useLocalGraph();
      expect(factory.currentEngine, equals(MapEngineType.localGraph));
      expect(factory.activeProvider is LocalGraphMapProvider, isTrue);
    });

    test('GoogleMapsProvider calculates deterministic route and searches places via fallback engine', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      final route = await googleProvider.calculateRoute(origin: origin, destination: destination);

      expect(route.waypoints.isNotEmpty, isTrue);
      expect(route.totalDistanceKm, greaterThan(0));
      expect(route.segments.isNotEmpty, isTrue);

      final places = await googleProvider.searchPlaces('Fuel');
      expect(places.isNotEmpty, isTrue);
      expect(places.first.category, equals('Fuel & Service'));
    });
  });
}
