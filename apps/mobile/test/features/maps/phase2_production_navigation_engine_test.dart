import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/maps/domain/models/navigation_models.dart';
import 'package:rideos_mobile/features/maps/services/turn_by_turn_navigation_engine.dart';

void main() {
  group('Phase 2 — Production Turn-by-Turn Navigation Engine Tests', () {
    late TurnByTurnNavigationEngine engine;
    const origin = LatLng(12.9716, 77.5946);
    const destination = LatLng(12.9352, 77.6245);

    setUp(() {
      engine = TurnByTurnNavigationEngine();
      engine.cancelNavigation(); // Reset to idle
    });

    test('Fails to transition to destinationSelected offline', () async {
      expect(engine.state, equals(NavigationSessionState.idle));

      await expectLater(
        engine.selectDestination(origin: origin, destination: destination),
        throwsA(isA<StateError>()),
      );
    });
  });
}
