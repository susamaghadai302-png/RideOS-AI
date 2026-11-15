import '../../../../core/network/api_client.dart';
import '../../domain/entities/ai_provider_status_entity.dart';
import '../../domain/entities/ai_memory_entity.dart';
import '../../domain/entities/ai_conversation_entity.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? action;
  final String? conversationId;
  final String? language;
  final double? confidence;
  final List<String>? citations;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.conversationId,
    this.language,
    this.confidence,
    this.citations,
  });
}

class AiAssistantRemoteDatasource {
  final ApiClient apiClient;

  AiAssistantRemoteDatasource({required this.apiClient});

  /// Sends riding prompt with contextual telemetry to secure backend
  Future<AiChatMessage> sendQuery(
    String prompt, [
    Map<String, dynamic>? telemetryContext,
    String? conversationId,
    String? language,
  ]) async {
    final response = await apiClient.dio.post(
      '/ai/assistant/query',
      data: {
        'prompt': prompt,
        if (telemetryContext != null) 'telemetryContext': telemetryContext,
        if (conversationId != null) 'conversationId': conversationId,
        if (language != null) 'language': language,
      },
    );

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    return AiChatMessage(
      text: data['response']?.toString() ?? '',
      isUser: false,
      timestamp: data['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      action: data['suggestedAction']?.toString(),
      conversationId: data['conversationId']?.toString(),
      language: data['language']?.toString(),
      confidence: (data['confidence'] as num?)?.toDouble(),
      citations: (data['citations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// Verifies live AI provider and security capabilities
  Future<AiProviderStatusEntity> getProviderStatus() async {
    final response = await apiClient.dio.get('/ai/assistant/status');
    if (response.data is Map<String, dynamic>) {
      return AiProviderStatusEntity.fromJson(response.data as Map<String, dynamic>);
    }
    return AiProviderStatusEntity.offlineFallback();
  }

  /// Fetches persistent conversation list for authenticated rider
  Future<List<AiConversationEntity>> getConversations() async {
    final response = await apiClient.dio.get('/ai/assistant/conversations');
    if (response.data is List) {
      return (response.data as List)
          .map((c) => AiConversationEntity.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches single conversation with full message trajectory
  Future<AiConversationEntity> getConversation(String conversationId) async {
    final response = await apiClient.dio.get('/ai/assistant/conversations/$conversationId');
    return AiConversationEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletes a conversation from persistent storage
  Future<void> deleteConversation(String conversationId) async {
    await apiClient.dio.delete('/ai/assistant/conversations/$conversationId');
  }

  /// Fetches rider's active AI memories
  Future<List<AiMemoryEntity>> getMemories() async {
    final response = await apiClient.dio.get('/ai/assistant/memories');
    if (response.data is List) {
      return (response.data as List)
          .map((m) => AiMemoryEntity.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Saves or updates a user-consented memory
  Future<AiMemoryEntity> saveMemory(
    String key,
    String value, {
    String category = 'GENERAL',
    String source = 'USER_EXPLICIT',
    bool isConsentGranted = true,
  }) async {
    final response = await apiClient.dio.post(
      '/ai/assistant/memories',
      data: {
        'key': key,
        'value': value,
        'category': category,
        'source': source,
        'isConsentGranted': isConsentGranted,
      },
    );
    return AiMemoryEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletes a specific memory entry
  Future<void> deleteMemory(String memoryId) async {
    await apiClient.dio.delete('/ai/assistant/memories/$memoryId');
  }

  /// Clears all rider memories
  Future<void> clearAllMemories() async {
    await apiClient.dio.delete('/ai/assistant/memories');
  }

  /// Searches verified technical knowledge and vehicle manuals
  Future<List<Map<String, dynamic>>> searchKnowledge(
    String query, {
    String? vehicleModel,
  }) async {
    final response = await apiClient.dio.get(
      '/ai/assistant/knowledge/search',
      queryParameters: {
        'q': query,
        if (vehicleModel != null) 'vehicleModel': vehicleModel,
      },
    );
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
