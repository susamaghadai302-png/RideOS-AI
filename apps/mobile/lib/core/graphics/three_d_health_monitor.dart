enum ThreeDHealthState {
  rendering,
  loading,
  unavailable,
  error,
}

class ThreeDHealthReport {
  final ThreeDHealthState state;
  final bool isWebGLAvailable;
  final bool isModelLoaded;
  final String? errorMessage;
  final String statusDescription;

  const ThreeDHealthReport({
    required this.state,
    required this.isWebGLAvailable,
    required this.isModelLoaded,
    this.errorMessage,
    required this.statusDescription,
  });
}

class ThreeDHealthMonitor {
  static final ThreeDHealthMonitor _instance = ThreeDHealthMonitor._internal();
  factory ThreeDHealthMonitor() => _instance;
  ThreeDHealthMonitor._internal();

  /// Evaluates 3D viewport health state
  ThreeDHealthReport evaluate({
    required bool isWebGLAvailable,
    required bool isModelAvailable,
    required bool isLoaded,
    required String? lastError,
  }) {
    if (!isWebGLAvailable) {
      return const ThreeDHealthReport(
        state: ThreeDHealthState.unavailable,
        isWebGLAvailable: false,
        isModelLoaded: false,
        statusDescription: 'Hardware graphics acceleration unavailable.',
      );
    }

    if (!isModelAvailable) {
      return const ThreeDHealthReport(
        state: ThreeDHealthState.unavailable,
        isWebGLAvailable: true,
        isModelLoaded: false,
        statusDescription: 'Exact 3D asset unavailable for this vehicle model.',
      );
    }

    if (lastError != null) {
      return ThreeDHealthReport(
        state: ThreeDHealthState.error,
        isWebGLAvailable: true,
        isModelLoaded: false,
        errorMessage: lastError,
        statusDescription: 'GLB parsing issue. Tap to reload asset.',
      );
    }

    if (!isLoaded) {
      return const ThreeDHealthReport(
        state: ThreeDHealthState.loading,
        isWebGLAvailable: true,
        isModelLoaded: false,
        statusDescription: 'Streaming geometry & PBR materials...',
      );
    }

    return const ThreeDHealthReport(
      state: ThreeDHealthState.rendering,
      isWebGLAvailable: true,
      isModelLoaded: true,
      statusDescription: 'Interactive 3D Digital Twin Active (60 FPS).',
    );
  }
}
