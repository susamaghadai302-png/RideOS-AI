import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_policy_engine.dart';

class RideAIIntent {
  final String rawQuery;
  final AIRequestClassification classification;

  const RideAIIntent({
    required this.rawQuery,
    required this.classification,
  });
}

abstract class RideAITool {
  final String name;
  final String description;

  const RideAITool({required this.name, required this.description});
  
  Future<Map<String, dynamic>> execute(RideAIContext context, Map<String, dynamic> arguments);
}

class RideAIResponse {
  final String answer;
  final List<String> evidence;
  final double confidence;
  final List<String> warnings;
  final List<String> unavailableData;
  final String? recommendedAction;

  const RideAIResponse({
    required this.answer,
    required this.evidence,
    required this.confidence,
    this.warnings = const [],
    this.unavailableData = const [],
    this.recommendedAction,
  });

  factory RideAIResponse.insufficientData({required List<String> missingFields}) {
    return RideAIResponse(
      answer: 'I cannot reliably answer this because necessary vehicle data is unavailable or stale.',
      evidence: [],
      confidence: 0.0,
      unavailableData: missingFields,
      warnings: ['Insufficient verified data to form a conclusion.'],
    );
  }
  
  factory RideAIResponse.blockedAction() {
    return const RideAIResponse(
      answer: 'I am an AI assistant and cannot directly control vehicle hardware for safety reasons.',
      evidence: [],
      confidence: 1.0,
      warnings: ['Vehicle control actions are explicitly blocked by policy.'],
    );
  }
}
