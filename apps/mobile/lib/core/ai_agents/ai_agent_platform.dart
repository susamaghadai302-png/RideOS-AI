import 'dart:developer' as developer;

enum AiAgentType {
  ride,
  navigation,
  vehicle,
  maintenance,
  safety,
  tripPlanner,
  weather,
  emergency,
  marketplace,
}

class AgentResponse {
  final AiAgentType agentType;
  final String outputText;
  final double confidenceScore;
  final String providerUsed; // 'ON_DEVICE_EDGE', 'GEMINI_CLOUD', 'FALLBACK_SIM'

  const AgentResponse({
    required this.agentType,
    required this.outputText,
    required this.confidenceScore,
    required this.providerUsed,
  });
}

class AiAgentPlatform {
  static final AiAgentPlatform instance = AiAgentPlatform._internal();
  AiAgentPlatform._internal();

  Future<AgentResponse> dispatchTaskToAgent({
    required AiAgentType agentType,
    required String prompt,
  }) async {
    developer.log('Dispatching prompt to $agentType: "$prompt"', name: 'RideOS.AiAgentPlatform');

    throw Exception('CONFIGURATION REQUIRED: No active AI provider configuration found for production use.');
  }
}
