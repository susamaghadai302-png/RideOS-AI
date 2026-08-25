import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_assistant_state.dart';
import '../../domain/entities/ai_message_entity.dart';

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier() : super(const AiAssistantState());

  Future<void> sendQuery(String prompt) async {
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

    await Future.delayed(const Duration(milliseconds: 600));

    String replyText = 'Rideo Pro: Keep your eyes on the road. Enjoy the twisties!';
    String? action;

    if (prompt.toLowerCase().contains('fuel') || prompt.toLowerCase().contains('gas')) {
      replyText = 'Nearest station: Shell High Octane in 4.2 km along current route.';
      action = 'NAVIGATE_FUEL';
    }

    final aiMsg = AiMessageEntity(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: replyText,
      isUser: false,
      suggestedAction: action,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isProcessing: false,
    );
  }
}

final aiAssistantNotifierProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier();
});
