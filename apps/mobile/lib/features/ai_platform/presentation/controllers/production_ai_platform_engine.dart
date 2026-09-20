import 'dart:async';
import 'dart:developer' as developer;

enum AiProviderType {
  openAi,
  googleGemini,
  anthropicClaude,
  azureOpenAi,
  localLlm,
  simulationFallback,
}

class AiPromptRequest {
  final String prompt;
  final String systemContext;
  final bool enableStreaming;
  final bool requireVisionAnalysis;
  final Map<String, dynamic>? metadata;

  const AiPromptRequest({
    required this.prompt,
    this.systemContext = 'You are RideOS AI, an intelligent motorcycle copilot.',
    this.enableStreaming = true,
    this.requireVisionAnalysis = false,
    this.metadata,
  });
}

class AiStreamChunk {
  final String tokenText;
  final bool isFinalChunk;
  final AiProviderType activeProvider;
  final int latencyMs;

  const AiStreamChunk({
    required this.tokenText,
    required this.isFinalChunk,
    required this.activeProvider,
    required this.latencyMs,
  });
}

abstract class IAiModelProvider {
  AiProviderType get providerType;
  Future<bool> isAvailable();
  Stream<AiStreamChunk> streamResponse(AiPromptRequest request);
}

class SimulationAiProvider implements IAiModelProvider {
  @override
  AiProviderType get providerType => AiProviderType.simulationFallback;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<AiStreamChunk> streamResponse(AiPromptRequest request) async* {
    yield AiStreamChunk(
      tokenText: 'Error: No active AI provider configured. Internet connection required.',
      isFinalChunk: true,
      activeProvider: providerType,
      latencyMs: 0,
    );
  }
}

class ProductionAiPlatformEngine {
  static final ProductionAiPlatformEngine instance = ProductionAiPlatformEngine._internal();
  ProductionAiPlatformEngine._internal();

  final List<IAiModelProvider> _providers = [
    SimulationAiProvider(),
  ];

  AiProviderType activeProvider = AiProviderType.googleGemini;
  bool isLocalLlmAvailable = true;

  Stream<AiStreamChunk> executeAiRequest(AiPromptRequest request) async* {
    developer.log('Executing AI Platform Request via [$activeProvider]...', name: 'RideOS.AiPlatform');
    final provider = _providers.firstWhere(
      (p) => p.providerType == AiProviderType.simulationFallback,
      orElse: () => SimulationAiProvider(),
    );

    yield* provider.streamResponse(request);
  }

  Future<Map<String, dynamic>> evaluateRoadVisionFrame({required String base64ImageFrame}) async {
    developer.log('Analyzing road vision frame for motorcycle hazards...', name: 'RideOS.VisionAI');
    return {
      'error': 'Vision AI service is not configured.',
      'detected_hazards': [],
      'confidence_score': 0.0,
      'recommended_speed_mph': null,
    };
  }
}
