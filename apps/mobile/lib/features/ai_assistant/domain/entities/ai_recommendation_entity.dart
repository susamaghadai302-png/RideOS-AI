import 'package:flutter/foundation.dart';

enum RecommendationCategory {
  vehicleHealth,
  ridingStyle,
  safetyRisk,
  maintenance,
  efficiency,
}

enum RecommendationUrgency {
  info,
  upcoming,
  warning,
  critical,
}

@immutable
class AiRecommendationEntity {
  final String id;
  final String title;
  final String explanation;
  final RecommendationCategory category;
  final RecommendationUrgency urgency;
  final String recommendedAction;
  final double confidenceScore;
  final String supportingTelemetry;
  final DateTime timestamp;
  final bool isDismissed;

  const AiRecommendationEntity({
    required this.id,
    required this.title,
    required this.explanation,
    required this.category,
    required this.urgency,
    required this.recommendedAction,
    required this.confidenceScore,
    required this.supportingTelemetry,
    required this.timestamp,
    this.isDismissed = false,
  });

  AiRecommendationEntity copyWith({
    String? id,
    String? title,
    String? explanation,
    RecommendationCategory? category,
    RecommendationUrgency? urgency,
    String? recommendedAction,
    double? confidenceScore,
    String? supportingTelemetry,
    DateTime? timestamp,
    bool? isDismissed,
  }) {
    return AiRecommendationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      category: category ?? this.category,
      urgency: urgency ?? this.urgency,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      supportingTelemetry: supportingTelemetry ?? this.supportingTelemetry,
      timestamp: timestamp ?? this.timestamp,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'explanation': explanation,
      'category': category.name,
      'urgency': urgency.name,
      'recommendedAction': recommendedAction,
      'confidenceScore': confidenceScore,
      'supportingTelemetry': supportingTelemetry,
      'timestamp': timestamp.toIso8601String(),
      'isDismissed': isDismissed,
    };
  }

  factory AiRecommendationEntity.fromJson(Map<String, dynamic> json) {
    return AiRecommendationEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      category: RecommendationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RecommendationCategory.vehicleHealth,
      ),
      urgency: RecommendationUrgency.values.firstWhere(
        (u) => u.name == json['urgency'],
        orElse: () => RecommendationUrgency.info,
      ),
      recommendedAction: json['recommendedAction'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      supportingTelemetry: json['supportingTelemetry'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}
