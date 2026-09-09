import 'dart:async';
import 'ai_models.dart';
import '../../features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';

/// Available AI Provider Types (ADR-13).
enum AiProviderType {
  cloudRemote,
  localRuleBased,
  mockTest,
}

/// Canonical Platform-Independent AI Provider Gateway Contract (ADR-13).
///
/// Guarantees:
/// - Zero hardcoded Gemini / Claude / GPT model identifiers in domain layer.
/// - Model selection is strictly governed by infrastructure configuration.
/// - Enforces uniform query and response envelopes via AIRequest and AIResponse.
abstract class AIProviderGateway {
  /// Currently active provider type.
  AiProviderType get activeProviderType;

  /// Processes an AI query with contextual telemetry and vehicle data.
  Future<AIResponse> processQuery(AIRequest request);
}

/// Production Adapter Bridge wrapping [AiAssistantRemoteDatasource] into the canonical [AIProviderGateway].
class RemoteAiAssistantGatewayAdapter implements AIProviderGateway {
  final AiAssistantRemoteDatasource _remoteDatasource;

  RemoteAiAssistantGatewayAdapter({required AiAssistantRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  AiProviderType get activeProviderType => AiProviderType.cloudRemote;

  @override
  Future<AIResponse> processQuery(AIRequest request) async {
    try {
      final message = await _remoteDatasource.sendQuery(
        request.prompt, 
        request.context.telemetryData,
      );
      
      return AIResponse(
        text: message.text,
        intent: _mapIntentString(message.action),
        timestamp: message.timestamp,
        modelUsed: 'cloud-default', // Obfuscated behind gateway
        isOfflineFallback: false,
        suggestedActionPayload: message.action,
      );
    } catch (_) {
      // Local fallback representation
      return AIResponse(
        text: 'AI Assistant temporarily running in offline mode. Please check connection.',
        intent: AIIntent.informational,
        timestamp: DateTime.now().toIso8601String(),
        modelUsed: 'local-fallback',
        isOfflineFallback: true,
      );
    }
  }

  AIIntent _mapIntentString(String? action) {
    if (action == null) return AIIntent.informational;
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('navigat')) return AIIntent.navigate;
    if (lowerAction.contains('diagnostics')) return AIIntent.diagnostics;
    if (lowerAction.contains('radar')) return AIIntent.squadRadar;
    if (lowerAction.contains('garage')) return AIIntent.garage;
    if (lowerAction.contains('emergency')) return AIIntent.emergency;
    return AIIntent.informational;
  }
}
