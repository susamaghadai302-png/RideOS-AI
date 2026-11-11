import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/ai_models.dart';
import 'package:rideos_mobile/core/contracts/ai_provider_gateway.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/providers/ai_assistant_notifier.dart';

class MockTestAIProviderGateway implements AIProviderGateway {
  bool shouldThrow = false;
  String returnedText = 'Tire pressures are nominal.';
  String? returnedAction = 'CHECK_TIRES';

  @override
  AiProviderType get activeProviderType => AiProviderType.mockTest;

  @override
  Future<AIResponse> processQuery(AIRequest request) async {
    if (shouldThrow) {
      throw Exception('Network connection failed');
    }
    return AIResponse(
      text: returnedText,
      intent: AIIntent.diagnostics,
      timestamp: DateTime.now().toIso8601String(),
      modelUsed: 'mock-test',
      isOfflineFallback: false,
      suggestedActionPayload: returnedAction,
    );
  }
}

void main() {
  group('AiAssistantNotifier Real Gateway Delegation Tests', () {
    late MockTestAIProviderGateway mockGateway;
    late AiAssistantNotifier notifier;

    setUp(() {
      mockGateway = MockTestAIProviderGateway();
      notifier = AiAssistantNotifier(gateway: mockGateway);
    });

    test('successfully processes query through AIProviderGateway without fake static strings', () async {
      expect(notifier.state.messages, isEmpty);

      await notifier.sendQuery('check tire pressure');

      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages[0].isUser, true);
      expect(notifier.state.messages[0].text, 'check tire pressure');
      expect(notifier.state.messages[1].isUser, false);
      expect(notifier.state.messages[1].text, 'Tire pressures are nominal.');
      expect(notifier.state.messages[1].suggestedAction, 'CHECK_TIRES');
      expect(notifier.state.isProcessing, false);
    });

    test('handles gateway failure with honest DATA_UNAVAILABLE state', () async {
      mockGateway.shouldThrow = true;

      await notifier.sendQuery('what is my current fuel?');

      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages[1].isUser, false);
      expect(notifier.state.messages[1].text, contains('DATA_UNAVAILABLE'));
      expect(notifier.state.isProcessing, false);
    });
  });
}
