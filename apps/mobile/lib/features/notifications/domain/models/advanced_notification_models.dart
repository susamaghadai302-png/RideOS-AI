import 'package:flutter/foundation.dart';

enum AlertCategory {
  safety,
  vehicleHealth,
  maintenance,
  navigationTrip,
  aiInsights,
  fleet,
  system;

  String get label {
    switch (this) {
      case AlertCategory.safety:
        return 'Safety';
      case AlertCategory.vehicleHealth:
        return 'Vehicle Health';
      case AlertCategory.maintenance:
        return 'Maintenance';
      case AlertCategory.navigationTrip:
        return 'Trip & Navigation';
      case AlertCategory.aiInsights:
        return 'AI Insights';
      case AlertCategory.fleet:
        return 'Fleet';
      case AlertCategory.system:
        return 'System';
    }
  }
}

enum AlertSeverity {
  info,
  normal,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'INFO';
      case AlertSeverity.normal:
        return 'NORMAL';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.critical:
        return 'CRITICAL';
    }
  }
}

@immutable
class RiderNotificationItem {
  final String id;
  final String notificationKey;
  final String title;
  final String message;
  final AlertCategory category;
  final AlertSeverity severity;
  final String vehicleName;
  final bool isRead;
  final DateTime timestamp;
  final String? deepLinkRoute; // '/maintenance', '/safety', '/health', '/trips', '/fleet'

  const RiderNotificationItem({
    required this.id,
    required this.notificationKey,
    required this.title,
    required this.message,
    required this.category,
    this.severity = AlertSeverity.info,
    required this.vehicleName,
    this.isRead = false,
    required this.timestamp,
    this.deepLinkRoute,
  });

  RiderNotificationItem copyWith({
    String? id,
    String? notificationKey,
    String? title,
    String? message,
    AlertCategory? category,
    AlertSeverity? severity,
    String? vehicleName,
    bool? isRead,
    DateTime? timestamp,
    String? deepLinkRoute,
  }) {
    return RiderNotificationItem(
      id: id ?? this.id,
      notificationKey: notificationKey ?? this.notificationKey,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      vehicleName: vehicleName ?? this.vehicleName,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
    );
  }
}

@immutable
class NotificationPreferencesState {
  final Set<AlertCategory> enabledCategories;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool criticalOverrideDnd;

  const NotificationPreferencesState({
    required this.enabledCategories,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.criticalOverrideDnd = true,
  });
}
