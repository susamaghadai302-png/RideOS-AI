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

    String responseText = '';
    switch (agentType) {
      case AiAgentType.navigation:
        responseText = 'Navigation Agent: Fastest twisty route selected with 0 traffic delays.';
        break;
      case AiAgentType.safety:
        responseText = 'Safety Agent: Road surface clear. Helmet mic connected with active noise reduction.';
        break;
      case AiAgentType.vehicle:
        responseText = 'Vehicle Agent: ECU parameters nominal. Battery voltage at 14.2V.';
        break;
      default:
        responseText = 'Agent: Processed request successfully.';
    }

    return AgentResponse(
      agentType: agentType,
      outputText: responseText,
      confidenceScore: 0.98,
      providerUsed: 'ON_DEVICE_EDGE',
    );
  }
}
