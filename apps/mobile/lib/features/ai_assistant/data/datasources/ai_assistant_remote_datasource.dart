import '../../../../core/network/api_client.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? action;
  final String? conversationId;
  final String? language;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.conversationId,
    this.language,
  });
}

class AiAssistantRemoteDatasource {
  final ApiClient apiClient;

  AiAssistantRemoteDatasource({required this.apiClient});

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

    return AiChatMessage(
      text: response.data['response'] ?? '',
      isUser: false,
      timestamp: response.data['timestamp'] ?? DateTime.now().toIso8601String(),
      action: response.data['suggestedAction'],
      conversationId: response.data['conversationId'],
      language: response.data['language'],
    );
  }
}
