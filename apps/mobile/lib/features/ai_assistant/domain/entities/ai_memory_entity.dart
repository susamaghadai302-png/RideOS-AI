import 'package:equatable/equatable.dart';

/// User-controlled, account-isolated AI memory entry
class AiMemoryEntity extends Equatable {
  final String memoryId;
  final String key;
  final String value;
  final String category;
  final String source;
  final bool isConsentGranted;
  final int retentionDays;
  final DateTime? lastAccessedAt;

  const AiMemoryEntity({
    required this.memoryId,
    required this.key,
    required this.value,
    this.category = 'GENERAL',
    this.source = 'USER_EXPLICIT',
    this.isConsentGranted = true,
    this.retentionDays = 365,
    this.lastAccessedAt,
  });

  factory AiMemoryEntity.fromJson(Map<String, dynamic> json) {
    return AiMemoryEntity(
      memoryId: json['memoryId']?.toString() ?? json['_id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      source: json['source']?.toString() ?? 'USER_EXPLICIT',
      isConsentGranted: json['isConsentGranted'] as bool? ?? true,
      retentionDays: (json['retentionDays'] as num?)?.toInt() ?? 365,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.tryParse(json['lastAccessedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'category': category,
      'source': source,
      'isConsentGranted': isConsentGranted,
      'retentionDays': retentionDays,
    };
  }

  AiMemoryEntity copyWith({
    String? memoryId,
    String? key,
    String? value,
    String? category,
    String? source,
    bool? isConsentGranted,
    int? retentionDays,
    DateTime? lastAccessedAt,
  }) {
    return AiMemoryEntity(
      memoryId: memoryId ?? this.memoryId,
      key: key ?? this.key,
      value: value ?? this.value,
      category: category ?? this.category,
      source: source ?? this.source,
      isConsentGranted: isConsentGranted ?? this.isConsentGranted,
      retentionDays: retentionDays ?? this.retentionDays,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  List<Object?> get props => [
        memoryId,
        key,
        value,
        category,
        source,
        isConsentGranted,
        retentionDays,
        lastAccessedAt,
      ];
}
