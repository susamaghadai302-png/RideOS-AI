import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rideos_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android emulator app launch smoke test', () {
    testWidgets(
      'app bootstraps and renders without an uncaught Flutter exception',
      timeout: const Timeout(Duration(minutes: 2)),
      (tester) async {
        // main() is asynchronous because Firebase, App Check, and app services
        // are initialized before runApp. Await startup to avoid a race.
        await app.main();

        // Do not use pumpAndSettle here: the app contains intentional animated
        // surfaces and loading indicators that may never become idle.
        // Pump a bounded 6 seconds, enough to pass the cinematic splash safety
        // timer while keeping the smoke test deterministic.
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }

        expect(find.byType(app.RideOSApp), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'RideOS-AI should not report an uncaught Flutter exception during startup.',
        );
      },
    );
  });
}
