import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/contracts/ai_models.dart';
import '../../../../core/contracts/ai_provider_gateway.dart';
import '../../../../core/di/service_locator.dart';
import '../../data/datasources/ai_assistant_remote_datasource.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/entities/ai_provider_status_entity.dart';
import 'ai_assistant_state.dart';

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AIProviderGateway _gateway;
  final AiAssistantRemoteDatasource? _remoteDatasource;

  AiAssistantNotifier({
    AIProviderGateway? gateway,
    AiAssistantRemoteDatasource? remoteDatasource,
  })  : _gateway = gateway ?? getIt<AIProviderGateway>(),
        _remoteDatasource = remoteDatasource ??
            (getIt.isRegistered<AiAssistantRemoteDatasource>()
                ? getIt<AiAssistantRemoteDatasource>()
                : null),
        super(const AiAssistantState());

  /// Checks verified backend provider status (Gemini Cloud vs Local Structured Fallback)
  Future<void> checkProviderStatus() async {
    final remote = _remoteDatasource;
    if (remote == null) {
      state = state.copyWith(
        providerStatus: AiProviderStatusEntity.offlineFallback(),
      );
      return;
    }

    try {
      final status = await remote.getProviderStatus();
      state = state.copyWith(providerStatus: status);
    } catch (_) {
      state = state.copyWith(
        providerStatus: AiProviderStatusEntity.offlineFallback(),
      );
    }
  }

  /// Sends riding query through the canonical AI Gateway to secure backend
  Future<void> sendQuery(String prompt, [Map<String, dynamic>? telemetry]) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AiMessageEntity(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      language: state.activeLanguage,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isProcessing: true,
      clearError: true,
    );

    try {
      final request = AIRequest(
        requestId: 'req-${DateTime.now().millisecondsSinceEpoch}',
        prompt: trimmed,
        timestamp: DateTime.now(),
        context: AIConsumerContext(telemetryData: telemetry),
        conversationId: state.currentConversationId,
        language: state.activeLanguage,
      );

      final response = await _gateway.processQuery(request);

      final aiMsg = AiMessageEntity(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: response.text,
        isUser: false,
        suggestedAction: response.suggestedActionPayload,
        timestamp: DateTime.now(),
        confidence: response.confidence == AIConfidence.high ? 100.0 : 80.0,
        language: state.activeLanguage,
        citations: response.citations,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        currentConversationId: response.conversationId ?? state.currentConversationId,
        lastSuggestedAction: response.suggestedActionPayload,
        isProcessing: false,
      );
    } catch (_) {
      final fallbackMsg = AiMessageEntity(
        id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
        text:
            'AI Assistant temporarily running in offline mode (DATA_UNAVAILABLE). Please verify connection.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, fallbackMsg],
        isProcessing: false,
      );
    }
  }

  /// Loads previous persistent conversations for the authenticated rider
  Future<void> loadConversations() async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    try {
      final conversations = await remote.getConversations();
      state = state.copyWith(conversations: conversations);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load conversations: $e');
    }
  }

  /// Switches active conversation trajectory
  Future<void> loadConversation(String conversationId) async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    state = state.copyWith(isProcessing: true);
    try {
      final conv = await remote.getConversation(conversationId);
      state = state.copyWith(
        currentConversationId: conv.conversationId,
        messages: conv.messages,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to open conversation: $e',
      );
    }
  }

  /// Begins a clean, new conversation session
  void startNewConversation() {
    state = state.copyWith(
      clearConversation: true,
      messages: [],
      clearError: true,
    );
  }

  /// Deletes a conversation from persistent storage
  Future<void> deleteConversation(String conversationId) async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    try {
      await remote.deleteConversation(conversationId);
      final updated = state.conversations
          .where((c) => c.conversationId != conversationId)
          .toList();

      if (state.currentConversationId == conversationId) {
        state = state.copyWith(
          conversations: updated,
          clearConversation: true,
          messages: [],
        );
      } else {
        state = state.copyWith(conversations: updated);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete conversation: $e');
    }
  }

  /// Fetches rider's user-consented memories
  Future<void> loadMemories() async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    try {
      final memories = await remote.getMemories();
      state = state.copyWith(memories: memories);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load memories: $e');
    }
  }

  /// Adds or updates an explicit user memory
  Future<bool> saveMemory(
    String key,
    String value, {
    String category = 'GENERAL',
    bool isConsentGranted = true,
  }) async {
    final remote = _remoteDatasource;
    if (remote == null) return false;
    try {
      final saved = await remote.saveMemory(
        key,
        value,
        category: category,
        isConsentGranted: isConsentGranted,
      );
      final updated = [
        saved,
        ...state.memories.where((m) => m.memoryId != saved.memoryId && m.key != saved.key),
      ];
      state = state.copyWith(memories: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save memory: $e');
      return false;
    }
  }

  /// Deletes a specific memory entry
  Future<void> deleteMemory(String memoryId) async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    try {
      await remote.deleteMemory(memoryId);
      final updated = state.memories.where((m) => m.memoryId != memoryId).toList();
      state = state.copyWith(memories: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete memory: $e');
    }
  }

  /// Wipes all memories for account privacy
  Future<void> clearAllMemories() async {
    final remote = _remoteDatasource;
    if (remote == null) return;
    try {
      await remote.clearAllMemories();
      state = state.copyWith(memories: []);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to clear memories: $e');
    }
  }

  /// Sets active speech and reasoning language
  void setLanguage(String languageCode) {
    state = state.copyWith(activeLanguage: languageCode);
  }

  /// Clears any user-facing error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final aiAssistantNotifierProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier();
});
