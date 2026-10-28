import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rideos_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app launches',
        timeout: const Timeout(Duration(minutes: 3)), (tester) async {
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      final originalOnError = FlutterError.onError;

      await app.main();

      // Allow the app to mount initial widgets and render the initial frames
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(app.RideOSApp).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(app.RideOSApp), findsOneWidget);

      ErrorWidget.builder = originalErrorWidgetBuilder;
      FlutterError.onError = originalOnError;
    });
  });
}
