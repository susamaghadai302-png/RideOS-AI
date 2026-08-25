import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/ai_assistant_remote_datasource.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {
  final AiAssistantRemoteDatasource remoteDatasource;
  final List<AiChatMessage> _messages = [];

  AiAssistantBloc({required this.remoteDatasource}) : super(AiAssistantInitialState()) {
    on<SendAiPromptEvent>(_onSendPrompt);
  }

  Future<void> _onSendPrompt(SendAiPromptEvent event, Emitter<AiAssistantState> emit) async {
    final userMsg = AiChatMessage(
      text: event.prompt,
      isUser: true,
      timestamp: DateTime.now().toIso8601String(),
    );
    _messages.add(userMsg);
    emit(AiAssistantLoadingState(messages: List.from(_messages)));

    try {
      final aiResponse = await remoteDatasource.sendQuery(event.prompt);
      _messages.add(aiResponse);
      emit(AiAssistantLoadedState(messages: List.from(_messages)));
    } catch (e) {
      emit(AiAssistantErrorState(errorMessage: e.toString()));
    }
  }
}
