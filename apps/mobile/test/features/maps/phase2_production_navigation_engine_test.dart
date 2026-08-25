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

    test('Transitions from idle to destinationSelected to routePreview', () async {
      expect(engine.state, equals(NavigationSessionState.idle));

      await engine.selectDestination(origin: origin, destination: destination);

      expect(engine.state, equals(NavigationSessionState.routePreview));
      expect(engine.activeRoute, isNotNull);
      expect(engine.availableAlternatives.length, equals(3));
      expect(engine.remainingDistanceKm, greaterThan(0));
    });

    test('Engages live navigation and switches camera mode to 3D perspective', () async {
      await engine.selectDestination(origin: origin, destination: destination);
      engine.startNavigation();

      expect(engine.state, equals(NavigationSessionState.navigating));
      expect(engine.cameraMode, equals(CameraMode.navigation3D));
      expect(engine.currentInstruction.isNotEmpty, isTrue);
    });

    test('Detects off-route condition beyond threshold and triggers rerouting', () async {
      await engine.selectDestination(origin: origin, destination: destination);
      engine.startNavigation();

      // Simulate off-route coordinate far away (e.g. 500 meters off course)
      const offRouteCoordinate = LatLng(13.0100, 77.5500);

      // Trigger 3 consecutive off-route GPS updates
      engine.updateGpsLocation(position: offRouteCoordinate, speedKmh: 45.0, headingDeg: 90.0);
      engine.updateGpsLocation(position: offRouteCoordinate, speedKmh: 45.0, headingDeg: 90.0);
      engine.updateGpsLocation(position: offRouteCoordinate, speedKmh: 45.0, headingDeg: 90.0);

      expect(engine.state == NavigationSessionState.offRoute || engine.state == NavigationSessionState.rerouting, isTrue);
    });

    test('Detects destination arrival when within 25 meters', () async {
      await engine.selectDestination(origin: origin, destination: destination);
      engine.startNavigation();

      // Send GPS update directly at destination coordinate
      engine.updateGpsLocation(position: destination, speedKmh: 5.0, headingDeg: 180.0);

      expect(engine.state, equals(NavigationSessionState.arrived));
      expect(engine.currentInstruction, contains('arrived'));
    });

    test('Cancels active navigation and cleanly restores idle state', () async {
      await engine.selectDestination(origin: origin, destination: destination);
      engine.startNavigation();
      engine.cancelNavigation();

      expect(engine.state, equals(NavigationSessionState.idle));
      expect(engine.activeRoute, isNull);
    });
  });
}
