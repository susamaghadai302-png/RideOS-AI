import 'package:equatable/equatable.dart';
import '../../data/datasources/ai_assistant_remote_datasource.dart';

abstract class AiAssistantState extends Equatable {
  const AiAssistantState();

  @override
  List<Object?> get props => [];
}

class AiAssistantInitialState extends AiAssistantState {}

class AiAssistantLoadingState extends AiAssistantState {
  final List<AiChatMessage> messages;

  const AiAssistantLoadingState({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class AiAssistantLoadedState extends AiAssistantState {
  final List<AiChatMessage> messages;

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
