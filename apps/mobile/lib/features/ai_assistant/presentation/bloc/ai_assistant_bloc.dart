import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/contracts/ai_models.dart';
import '../../../../core/contracts/ai_provider_gateway.dart';
import '../../domain/services/ai_intent_resolver.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final AIProviderGateway gateway;
  final AiIntentResolver intentResolver;
  final List<AiUiMessage> _messages = [];

  AiAssistantBloc({
    required this.gateway,
    required this.intentResolver,
  }) : super(AiAssistantInitialState()) {
    on<SendAiPromptEvent>(_onSendPrompt);
  }

  Future<void> _onSendPrompt(SendAiPromptEvent event, Emitter<AiAssistantState> emit) async {
    final userMsg = AiUiMessage(
      text: event.prompt,
      isUser: true,
      timestamp: DateTime.now().toIso8601String(),
    );
    _messages.add(userMsg);
    emit(AiAssistantLoadingState(messages: List.from(_messages)));

    try {
      // In a real application, context (telemetry, nav, vehicle) would be injected
      // from their respective Blocs here. For Tier 5, we satisfy the canonical request.
      final request = AIRequest(
        requestId: DateTime.now().millisecondsSinceEpoch.toString(),
        prompt: event.prompt,
        timestamp: DateTime.now(),
        context: const AIConsumerContext(), // Minimal context payload
      );

      final aiResponse = await gateway.processQuery(request);

      final systemMsg = AiUiMessage(
        text: aiResponse.text,
        isUser: false,
        timestamp: aiResponse.timestamp,
        intent: aiResponse.intent,
      );
      
      _messages.add(systemMsg);
      emit(AiAssistantLoadedState(messages: List.from(_messages)));

      // Safely evaluate the intent via the boundary
      await intentResolver.resolveAndExecute(aiResponse);

    } catch (e) {
      emit(AiAssistantErrorState(errorMessage: e.toString()));
    }
  }
}
