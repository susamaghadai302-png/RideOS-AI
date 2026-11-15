import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/entities/ai_provider_status_entity.dart';
import '../../domain/entities/ai_memory_entity.dart';
import '../../domain/entities/ai_conversation_entity.dart';

class AiAssistantState extends Equatable {
  final List<AiMessageEntity> messages;
  final bool isProcessing;
  final String? currentConversationId;
  final List<AiConversationEntity> conversations;
  final List<AiMemoryEntity> memories;
  final AiProviderStatusEntity? providerStatus;
  final String activeLanguage;
  final String? errorMessage;
  final String? lastSuggestedAction;

  const AiAssistantState({
    this.messages = const [],
    this.isProcessing = false,
    this.currentConversationId,
    this.conversations = const [],
    this.memories = const [],
    this.providerStatus,
    this.activeLanguage = 'en',
    this.errorMessage,
    this.lastSuggestedAction,
  });

  bool get isCloudConnected => providerStatus?.isCloudConnected ?? false;

  AiAssistantState copyWith({
    List<AiMessageEntity>? messages,
    bool? isProcessing,
    String? currentConversationId,
    bool clearConversation = false,
    List<AiConversationEntity>? conversations,
    List<AiMemoryEntity>? memories,
    AiProviderStatusEntity? providerStatus,
    String? activeLanguage,
    String? errorMessage,
    String? lastSuggestedAction,
    bool clearError = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      currentConversationId: clearConversation
          ? null
          : (currentConversationId ?? this.currentConversationId),
      conversations: conversations ?? this.conversations,
      memories: memories ?? this.memories,
      providerStatus: providerStatus ?? this.providerStatus,
      activeLanguage: activeLanguage ?? this.activeLanguage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuggestedAction: lastSuggestedAction ?? this.lastSuggestedAction,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isProcessing,
        currentConversationId,
        conversations,
        memories,
        providerStatus,
        activeLanguage,
        errorMessage,
        lastSuggestedAction,
      ];
}
