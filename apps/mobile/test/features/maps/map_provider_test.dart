import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/core/local_graph_map_provider.dart';

void main() {
  group('MapProvider & LocalGraphMapProvider Tests (Zero-Billing Architecture)', () {
    late MapProvider mapProvider;

    setUp(() {
      mapProvider = LocalGraphMapProvider();
    });

    test('Requires zero paid external billing', () {
      expect(mapProvider.requiresPaidBilling, isFalse);
      expect(mapProvider.providerName, contains('RideOS Local'));
    });

    test('Calculates deterministic offline route throws without real graph', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      await expectLater(
        mapProvider.calculateRoute(origin: origin, destination: destination),
        throwsStateError,
      );
    });

    test('Searches local points of interest throws without external network API', () async {
      await expectLater(
        mapProvider.searchPlaces('fuel'),
        throwsStateError,
      );
    });
  });
}
