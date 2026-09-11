import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ai/presentation/controllers/production_ai_copilot_engine.dart';
import 'package:rideos_mobile/features/ai/presentation/controllers/production_ai_copilot_completion_engine.dart';

void main() {
  group('AI Blocker Remediation Tests', () {
    test('ProductionAiCopilotEngine produces explicit unavailable state when unconfigured', () {
      final engine = ProductionAiCopilotEngine.instance;
      final response = engine.executeCopilotQuery(query: 'test');

      expect(response.textResponse, 'AI service not configured/unavailable.');
      expect(response.executedToolName, isEmpty);
      expect(response.confidenceScore, 0.0);
      expect(response.contextParameters['status'], 'unconfigured');
    });

    test('ProductionAiCopilotCompletionEngine produces explicit unavailable state when unconfigured', () async {
      final engine = ProductionAiCopilotCompletionEngine.instance;

      final responseFuture = engine.copilotStream.first;
      await engine.processRiderVoicePrompt(voicePrompt: 'hello');

      final response = await responseFuture;

      expect(response.responseText, 'AI service not configured/unavailable.');
      expect(response.executedTools, isEmpty);
      expect(response.responseLatencyMs, 0.0);
      expect(response.isVoiceResponseEnabled, isFalse);
    });
  });
}
