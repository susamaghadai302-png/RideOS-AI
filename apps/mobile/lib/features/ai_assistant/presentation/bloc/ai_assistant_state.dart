import 'package:equatable/equatable.dart';
import '../../../../core/contracts/ai_models.dart';

class AiUiMessage extends Equatable {
  final String text;
  final bool isUser;
  final String timestamp;
  final AIIntent? intent;

  const AiUiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.intent,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp, intent];
}

abstract class AiAssistantState extends Equatable {
  const AiAssistantState();

  @override
  List<Object?> get props => [];
}

class AiAssistantInitialState extends AiAssistantState {}

class AiAssistantLoadingState extends AiAssistantState {
  final List<AiUiMessage> messages;

  const AiAssistantLoadingState({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class AiAssistantLoadedState extends AiAssistantState {
  final List<AiUiMessage> messages;

  const AiAssistantLoadedState({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class AiAssistantErrorState extends AiAssistantState {
  final String errorMessage;

  const AiAssistantErrorState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
