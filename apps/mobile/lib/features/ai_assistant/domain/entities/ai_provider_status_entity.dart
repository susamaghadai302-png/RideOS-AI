import 'package:equatable/equatable.dart';

/// Represents the verified connectivity and capability status of the AI backend
class AiProviderStatusEntity extends Equatable {
  final String provider;
  final String model;
  final String status; // 'CONNECTED' | 'OFFLINE_FALLBACK'
  final List<String> supportedLanguages;
  final List<String> toolsRegistered;
  final List<String> securityPolicies;
  final String timestamp;

  const AiProviderStatusEntity({
    required this.provider,
    required this.model,
    required this.status,
    this.supportedLanguages = const ['en', 'hi', 'hinglish', 'or'],
    this.toolsRegistered = const [],
    this.securityPolicies = const [],
    required this.timestamp,
  });

  bool get isCloudConnected => status == 'CONNECTED';

  factory AiProviderStatusEntity.fromJson(Map<String, dynamic> json) {
    return AiProviderStatusEntity(
      provider: json['provider']?.toString() ?? 'RideOS AI',
      model: json['model']?.toString() ?? 'rule-based-v1',
      status: json['status']?.toString() ?? 'OFFLINE_FALLBACK',
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['en', 'hi', 'hinglish', 'or'],
      toolsRegistered: (json['toolsRegistered'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      securityPolicies: (json['securityPolicies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  factory AiProviderStatusEntity.offlineFallback() {
    return AiProviderStatusEntity(
      provider: 'RideOS On-Device Structured Fallback',
      model: 'rule-based-v1',
      status: 'OFFLINE_FALLBACK',
      supportedLanguages: const ['en', 'hi', 'hinglish', 'or'],
      toolsRegistered: const [
        'check_tire_pressure',
        'find_fuel_stations',
        'check_vehicle_health',
        'trigger_emergency_sos',
      ],
      securityPolicies: const [
        'PROMPT_INJECTION_FILTER',
        'UNSAFE_INTENT_BARRIER',
        'LOW_CONFIDENCE_GATE',
      ],
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  @override
  List<Object?> get props => [
        provider,
        model,
        status,
        supportedLanguages,
        toolsRegistered,
        securityPolicies,
        timestamp,
      ];
}
