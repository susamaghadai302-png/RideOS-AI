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

    test(
      'GoogleMapsProvider does not fabricate routes or places when the live provider is unavailable',
      () async {
        if (GoogleMapsConfig.hasValidApiKey) return;
        await expect(
          googleProvider.calculateRoute(
            origin: const LatLng(12.9716, 77.5946),
            destination: const LatLng(12.9352, 77.6245),
          ),
          throwsStateError,
        );
        await expect(
          googleProvider.searchPlaces('Fuel'),
          throwsStateError,
        );
      },
    );
  });
}
