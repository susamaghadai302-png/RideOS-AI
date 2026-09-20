import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rideos_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app launches', timeout: const Timeout(Duration(minutes: 1)), (tester) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalOnError = FlutterError.onError;

      app.main();
      
      // Allow the app to fully settle.
      // This will take ~40 seconds due to API endpoint detection and timeout retries.
      await tester.pumpAndSettle();
      
      expect(find.byType(app.RideOSApp), findsOneWidget);

      ErrorWidget.builder = originalErrorWidgetBuilder;
      FlutterError.onError = originalOnError;
    });
  });
}
