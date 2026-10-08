enum AIRequestClassification {
  informational,
  navigation,
  diagnostic,
  maintenance,
  safety,
  vehicleControl,
  unknown,
}

class RideAIPolicyEngine {
  static AIRequestClassification classifyIntent(String intent) {
    final lowerIntent = intent.toLowerCase();
    
    // Explicit Vehicle Control heuristics (MUST BE BLOCKED)
    if (lowerIntent.contains('engine') || 
        lowerIntent.contains('turn off') || 
        lowerIntent.contains('throttle') ||
        lowerIntent.contains('brake') ||
        lowerIntent.contains('ignition') ||
        lowerIntent.contains('light')) {
      return AIRequestClassification.vehicleControl;
    }
    
    if (lowerIntent.contains('route') || lowerIntent.contains('navigate') || lowerIntent.contains('turn')) {
      return AIRequestClassification.navigation;
    }
    
    if (lowerIntent.contains('diagnostic') || lowerIntent.contains('fault') || lowerIntent.contains('overheating')) {
      return AIRequestClassification.diagnostic;
    }
    
    if (lowerIntent.contains('service') || lowerIntent.contains('oil') || lowerIntent.contains('maintenance')) {
      return AIRequestClassification.maintenance;
    }
    
    if (lowerIntent.contains('crash') || lowerIntent.contains('sos') || lowerIntent.contains('emergency')) {
      return AIRequestClassification.safety;
    }
    
    return AIRequestClassification.informational;
  }

  static bool isExecutionAllowed(AIRequestClassification classification) {
    if (classification == AIRequestClassification.vehicleControl) {
      return false;
    }
    return true;
  }
}
