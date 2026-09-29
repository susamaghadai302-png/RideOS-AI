import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/domain/models/navigation_models.dart';
import 'package:rideos_mobile/features/maps/services/astar_routing_engine.dart';

void main() {
  group('AStarRoutingEngine Tests', () {
    late AStarRoutingEngine engine;

    setUp(() {
      engine = AStarRoutingEngine();
    });

    test('Calculates gracefully fails offline', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      await expectLater(
        engine.calculateRoutes(origin: origin, destination: destination),
        throwsStateError,
      );
    });

    test('Scenic / Twisty route gracefully fails offline', () async {
      const origin = LatLng(12.9716, 77.5946);
      const destination = LatLng(12.9352, 77.6245);

      await expectLater(
        engine.calculateRoutes(origin: origin, destination: destination, preference: RoutePreference.scenicTwisty),
        throwsStateError,
      );
    });
  });
}
