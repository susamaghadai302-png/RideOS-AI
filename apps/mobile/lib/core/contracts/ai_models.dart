/// Provider-independent canonical AI Domain Models.
///
/// Ensures AI consumer boundaries never depend on specific SDK models (e.g., Gemini / Claude).
library;

/// Categorizes high-level AI intents returned from the provider reasoning engine.
enum AIIntent {
  informational, // Pure text response, no action needed
  navigate,      // Route generation, destinations, etc.
  diagnostics,   // Check vehicle health, scan codes, clear codes
  telemetry,     // Request specific real-time data
  squadRadar,    // Fleet/group ride radar interactions
  garage,        // Vehicle switching / identity management
  emergency,     // SOS / accident / immediate help
  unsupported,   // Out-of-bounds or non-riding related topics
}

/// Represents the level of certainty the reasoning engine has regarding the extracted intent.
enum AIConfidence {
  high,
  medium,
  low,
  unknown,
}

/// Normalized AI Error taxonomy.
enum AIErrorType {
  network,
  timeout,
  rateLimited,
  providerError,
  malformedResponse,
  unavailable,
  safetyBlocked,
  offline,
  unknown,
}

/// Represents the ambient context sent to the reasoning engine.
class AIConsumerContext {
  final Map<String, dynamic>? telemetryData;
  final Map<String, dynamic>? navigationData;
  final Map<String, dynamic>? vehicleData;

  const AIConsumerContext({
    this.telemetryData,
    this.navigationData,
    this.vehicleData,
  });
}

/// Represents a canonical request payload sent to the AI Gateway.
class AIRequest {
  final String requestId;
  final String prompt;
  final DateTime timestamp;
  final AIConsumerContext context;

  const AIRequest({
    required this.requestId,
    required this.prompt,
    required this.timestamp,
    required this.context,
  });
}

/// Represents a canonical, normalized response payload from the AI Gateway.
class AIResponse {
  final String text;
  final AIIntent intent;
  final AIConfidence confidence;
  final String timestamp;
  final String modelUsed;
  final bool isOfflineFallback;
  final String? suggestedActionPayload;

  const AIResponse({
    required this.text,
    required this.intent,
    this.confidence = AIConfidence.unknown,
    required this.timestamp,
    this.modelUsed = 'default',
    this.isOfflineFallback = false,
    this.suggestedActionPayload,
  });
}

/// Represents a standardized error emitted by the AI Gateway or Intent Resolver.
class AIError implements Exception {
  final AIErrorType type;
  final String message;
  final Object? originalException;

  const AIError({
    required this.type,
    required this.message,
    this.originalException,
  });

  @override
  String toString() => 'AIError($type): $message';
}
