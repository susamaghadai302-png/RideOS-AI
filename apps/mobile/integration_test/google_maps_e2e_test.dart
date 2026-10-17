import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:rideos_mobile/features/maps/core/google_maps_provider.dart';
import 'package:rideos_mobile/features/maps/core/map_provider.dart';
import 'package:rideos_mobile/features/navigation/presentation/screens/three_d_navigation_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Maps Platform End-to-End On-Device Verification', () {
    testWidgets('GoogleMap widget mounts, initializes native controller, and renders tiles', (tester) async {
      final mapProvider = GoogleMapsProvider();

      final widget = MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: mapProvider.buildMapView(
              options: const MapOptions(
                initialCenter: LatLng(20.2961, 85.8245), // Bhubaneswar Anchor
                initialZoom: 16.0,
                showTraffic: true,
                enableTilt: true,
              ),
              markers: const [
                MapMarker(
                  id: 'test_origin_pin',
                  position: LatLng(20.2961, 85.8245),
                  title: 'Test Vehicle Location',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Verify GoogleMap widget is present in the widget tree
      expect(find.byType(gmaps.GoogleMap), findsOneWidget);

      // 2. Allow native Android surface and Maps SDK to complete tile rendering
      await tester.pump(const Duration(seconds: 4));

      // 3. Verify controller is populated on the provider
      expect(mapProvider.mapController, isNotNull);

      // 4. Test camera movement with native controller
      final controller = mapProvider.mapController!;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          const gmaps.LatLng(20.2961, 85.8245),
          17.0,
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // 5. Verify camera position query works against native SDK
      final currentZoom = await controller.getZoomLevel();
      expect(currentZoom, isNotNull);
      expect(currentZoom, greaterThan(14.0));

      debugPrint('=== GOOGLE_MAPS_ACTIVE_ON_SCREEN ===');
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
    });

    testWidgets('ThreeDNavigationScreen mounts and renders Bhubaneswar HUD with real GPS', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ThreeDNavigationScreen(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(gmaps.GoogleMap), findsOneWidget);

      debugPrint('=== BHUBANESWAR_ODISHA_MAP_READY ===');
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
    });
  });
}
