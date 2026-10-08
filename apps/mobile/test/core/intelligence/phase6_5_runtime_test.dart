import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_engine.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_policy_engine.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_hallucination_defense.dart';
import 'package:rideos_mobile/core/intelligence/services/ai_model_provider.dart';

class MockAiProvider extends AiModelProvider {
  final AiModelResponse cannedResponse;

  MockAiProvider(this.cannedResponse);

  @override
  Future<AiModelResponse> sendPrompt(String prompt, List<RideAITool> allowedTools, RideAIContext context) async {
    return cannedResponse;
  }

  @override
  Future<AiModelResponse> submitToolResult(String callId, Map<String, dynamic> toolResult, RideAIContext context) async {
    return cannedResponse; // Simplified for test
  }
}

void main() {
  group('Phase 6.5 — Real AI Runtime Integration Tests', () {
    test('1. RideAIEngine blocks vehicle control commands immediately via PolicyEngine', () async {
      final engine = RideAIEngine(
        provider: MockAiProvider(const AiModelResponse.finalResponse(RideAIResponse(answer: 'Faked', evidence: [], confidence: 1.0))),
        initialTools: [],
      );

      const intent = RideAIIntent(rawQuery: 'Turn off the engine', classification: AIRequestClassification.vehicleControl);
      final response = await engine.handleIntent(intent, RideAIContext.empty());

      expect(response.answer, contains('cannot directly control'));
    });

    test('2. Hallucination Defense strips fake RPM claims', () {
      const fakeResponse = RideAIResponse(answer: 'Your RPM is 3500.', evidence: [], confidence: 0.9);
      final context = RideAIContext.empty(); // RPM is unavailable by default

      final validated = RideAIHallucinationDefense.validateResponse(fakeResponse, context);

      expect(validated.answer, contains('unavailable or stale'));
      expect(validated.unavailableData, contains('RPM'));
    });

    test('3. Hallucination Defense blocks fake Weather claims', () {
      const fakeResponse = RideAIResponse(answer: 'The weather is sunny.', evidence: [], confidence: 0.9);
      final context = RideAIContext.empty(); 

      final validated = RideAIHallucinationDefense.validateResponse(fakeResponse, context);

      expect(validated.answer, contains('unavailable'));
      expect(validated.unavailableData, contains('Weather'));
    });

    test('4. Network unavailability gracefully falls back to deterministic safe state', () async {
      final engine = RideAIEngine(
        provider: MockAiProvider(const AiModelResponse.finalResponse(null)), // Simulate null failure
        initialTools: [],
      );

      const intent = RideAIIntent(rawQuery: 'What is my RPM?', classification: AIRequestClassification.informational);
      final response = await engine.handleIntent(intent, RideAIContext.empty());

      expect(response.answer, contains('unavailable'));
      expect(response.unavailableData, contains('AI_INTERNAL_ERROR'));
    });
  });
}
