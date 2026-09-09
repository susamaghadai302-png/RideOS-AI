import '../../../../core/network/api_client.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? action;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
  });
}

class AiAssistantRemoteDatasource {
  final ApiClient apiClient;

  AiAssistantRemoteDatasource({required this.apiClient});

  Future<AiChatMessage> sendQuery(String prompt, [Map<String, dynamic>? telemetryContext]) async {
    final response = await apiClient.dio.post(
      '/ai/assistant/query',
      data: {
        'prompt': prompt,
        'telemetryContext': telemetryContext,
      },
    );

    return AiChatMessage(
      text: response.data['response'] ?? '',
      isUser: false,
      timestamp: response.data['timestamp'] ?? DateTime.now().toIso8601String(),
      action: response.data['suggestedAction'],
    );
  }
}
