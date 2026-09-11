import 'dart:developer' as developer;

enum AiCopilotProviderType {
  cloudGemini,
  onDeviceLocal,
  simulationFallback,
}

class CopilotInteractionResponse {
  final String responseText;
  final String detectedIntent;
  final double rideReadinessScore;
  final List<String> proactiveSuggestions;

  const CopilotInteractionResponse({
    required this.responseText,
    required this.detectedIntent,
    required this.rideReadinessScore,
    required this.proactiveSuggestions,
  });
}

class AiCopilotExcellenceEngine {
  static final AiCopilotExcellenceEngine instance = AiCopilotExcellenceEngine._internal();
  AiCopilotExcellenceEngine._internal();

  CopilotInteractionResponse processUserPrompt({
    required String promptText,
    required String preferredLanguage, // 'en', 'hi', 'or', 'es', etc.
    AiCopilotProviderType provider = AiCopilotProviderType.simulationFallback,
  }) {
    developer.log('Processing Copilot prompt in [$preferredLanguage] using provider [$provider]...', name: 'RideOS.AiCopilot');
    return const CopilotInteractionResponse(
      responseText: 'AI service is not configured. Please connect a valid provider.',
      detectedIntent: 'intent_unknown',
      rideReadinessScore: 0.0,
      proactiveSuggestions: [],
    );
  }

  Map<String, dynamic> fetchRiderContextMemory() {
    return {};
  }
}
