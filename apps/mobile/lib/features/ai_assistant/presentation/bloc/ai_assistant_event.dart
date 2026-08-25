import 'package:equatable/equatable.dart';

abstract class AiAssistantEvent extends Equatable {
  const AiAssistantEvent();

  @override
  List<Object?> get props => [];
}

class SendAiPromptEvent extends AiAssistantEvent {
  final String prompt;

  const SendAiPromptEvent({required this.prompt});

  @override
  List<Object?> get props => [prompt];
}
