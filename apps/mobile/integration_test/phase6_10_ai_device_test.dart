import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:rideos_mobile/firebase_options.dart';
import 'package:rideos_mobile/core/intelligence/services/gemini_provider.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_engine.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/services/ai_tools.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_policy_engine.dart';
import 'package:flutter/foundation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Phase 6.10 Live Gemini Request via Android Device', (WidgetTester tester) async {
    // 1. Initialize exactly like production
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );

    // 2. Initialize the AI Engine
    final provider = GeminiProvider();
    final engine = RideAIEngine(
      provider: provider,
      initialTools: const [GetVehicleTelemetryTool()], // Includes getVehicleCapabilities implicitly or directly
    );

    // 3. Make the request
    const intent = RideAIIntent(
      rawQuery: 'What vehicle capabilities are currently available?', 
      classification: AIRequestClassification.diagnostic
    );

    debugPrint('RIDEOS_TEST_START: Starting Live Firebase AI Logic network request');
    try {
      final response = await engine.handleIntent(intent, RideAIContext.empty());
      debugPrint('RIDEOS_TEST_RESPONSE: ${response.answer}');
      
      // Look for the specific markers of a successful function call flow
      expect(response.answer, isNotEmpty);
      debugPrint('RIDEOS_TEST_SUCCESS');
    } catch (e) {
      debugPrint('RIDEOS_TEST_ERROR: \$e');
      fail('Network request failed: \$e');
    }
  });
}
