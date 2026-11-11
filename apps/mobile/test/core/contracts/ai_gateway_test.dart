import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/ai_models.dart';
import 'package:rideos_mobile/core/contracts/ai_provider_gateway.dart';
import 'package:rideos_mobile/features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'package:rideos_mobile/core/network/api_client.dart';

class MockAiAssistantRemoteDatasource implements AiAssistantRemoteDatasource {
  bool shouldThrow = false;
  String mockAction = 'OPEN_NAVIGATION';
  String mockText = 'Routing home now.';

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<AiChatMessage> sendQuery(
    String prompt, [
    Map<String, dynamic>? telemetryContext,
    String? conversationId,
    String? language,
  ]) async {
    if (shouldThrow) {
      throw Exception('Network Error');
    }
    return AiChatMessage(
      text: mockText,
      isUser: false,
      timestamp: '2026-09-06T10:00:00.000Z',
      action: mockAction,
    );
  }
}

void main() {
  late MockAiAssistantRemoteDatasource mockDatasource;
  late RemoteAiAssistantGatewayAdapter gateway;

  setUp(() {
    mockDatasource = MockAiAssistantRemoteDatasource();
    gateway = RemoteAiAssistantGatewayAdapter(remoteDatasource: mockDatasource);
  });

  group('AIProviderGateway Contract', () {
    test('Should map provider action strings to canonical AIIntents', () async {
      mockDatasource.mockAction = 'OPEN_NAVIGATION';
      mockDatasource.mockText = 'Routing home now.';

      final request = AIRequest(
        requestId: 'req-1',
        prompt: 'Take me home',
        timestamp: DateTime.now(),
        context: const AIConsumerContext(),
      );

      final response = await gateway.processQuery(request);

      expect(response.intent, AIIntent.navigate);
      expect(response.text, 'Routing home now.');
      expect(response.suggestedActionPayload, 'OPEN_NAVIGATION');
      expect(response.modelUsed, 'cloud-default');
    });

    test('Should handle offline fallback gracefully without leaking exceptions', () async {
      mockDatasource.shouldThrow = true;

      final request = AIRequest(
        requestId: 'req-2',
        prompt: 'Check engine temp',
        timestamp: DateTime.now(),
        context: const AIConsumerContext(),
      );

      final response = await gateway.processQuery(request);

      expect(response.isOfflineFallback, isTrue);
      expect(response.intent, AIIntent.informational);
      expect(response.modelUsed, 'local-fallback');
    });

    test('Should map diagnostics action to AIIntent.diagnostics', () async {
      mockDatasource.mockAction = 'SHOW_DIAGNOSTICS';
      
      final request = AIRequest(
        requestId: 'req-3',
        prompt: 'Is my tire pressure low?',
        timestamp: DateTime.now(),
        context: const AIConsumerContext(),
      );

      final response = await gateway.processQuery(request);
      expect(response.intent, AIIntent.diagnostics);
    });
  });
}
