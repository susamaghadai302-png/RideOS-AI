class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final Map<String, bool> _featureFlags = {
    'enable_ai_copilot_voice': true,
    'enable_3d_navigation_hud': true,
    'enable_obd_ble_telemetry': true,
    'enable_crash_detection': true,
    'enable_squad_mesh_intercom': true,
    'enable_predictive_maintenance': true,
    'enable_camera_neural_vision': true,
    'enable_cloud_offline_sync': true,
  };

  final Map<String, String> _abTestVariants = {
    'ai_hud_theme_variant': 'hyper_neon',
    'routing_algorithm_v2': 'motorcycle_safe_ai',
  };

  bool isFeatureEnabled(String flagKey) {
    return _featureFlags[flagKey] ?? false;
  }

  String getAbTestVariant(String experimentKey) {
    return _abTestVariants[experimentKey] ?? 'control';
  }

  void setFeatureFlag(String flagKey, bool enabled) {
    _featureFlags[flagKey] = enabled;
  }
}
