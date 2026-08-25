import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_message_entity.dart';

class AiAssistantState extends Equatable {
  final List<AiMessageEntity> messages;
  final bool isProcessing;

  const AiAssistantState({
    this.messages = const [],
    this.isProcessing = false,
  });

  AiAssistantState copyWith({
    List<AiMessageEntity>? messages,
    bool? isProcessing,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [messages, isProcessing];
}
