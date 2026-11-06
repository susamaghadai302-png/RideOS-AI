import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/contracts/ai_models.dart';
import '../../../../core/contracts/ai_provider_gateway.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/ai_message_entity.dart';
import 'ai_assistant_state.dart';

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AIProviderGateway _gateway;

  AiAssistantNotifier({AIProviderGateway? gateway})
      : _gateway = gateway ?? getIt<AIProviderGateway>(),
        super(const AiAssistantState());

  Future<void> sendQuery(String prompt, [Map<String, dynamic>? telemetry]) async {
    final userMsg = AiMessageEntity(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
    );

    try {
      final request = AIRequest(
        requestId: 'req-${DateTime.now().millisecondsSinceEpoch}',
        prompt: prompt,
        timestamp: DateTime.now(),
        context: AIConsumerContext(telemetryData: telemetry),
      );

      final response = await _gateway.processQuery(request);

      final aiMsg = AiMessageEntity(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: response.text,
        isUser: false,
        suggestedAction: response.suggestedActionPayload,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isProcessing: false,
      );
    } catch (_) {
      final fallbackMsg = AiMessageEntity(
        id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
        text: 'AI Assistant temporarily running in offline mode (DATA_UNAVAILABLE). Please verify connection.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, fallbackMsg],
        isProcessing: false,
      );
    }
  }
}

final aiAssistantNotifierProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier();
});
