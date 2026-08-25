enum NotificationPriority { critical, high, info }

class AiSmartNotification {
  final String id;
  final String title;
  final String message;
  final String category; // 'RAIN', 'FOG', 'STORM', 'WIND', 'DANGEROUS_ROAD', 'CURVE', 'FUEL_LOW', 'SERVICE_DUE', 'BATTERY_LOW', 'TRAFFIC'
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? actionLabel;

  const AiSmartNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.timestamp,
    this.actionLabel,
  });
}

class AiNotificationService {
  final List<AiSmartNotification> _activeNotifications = [
    AiSmartNotification(
      id: 'notif-1',
      title: 'Rain & Wet Asphalt Ahead',
      message: 'Precipitation detected 4 km ahead on CA-1. Traction control mode recommended.',
      category: 'RAIN',
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      actionLabel: 'ENGAGE RAIN MODE',
    ),
    AiSmartNotification(
      id: 'notif-2',
      title: 'Dense Fog & Reduced Visibility',
      message: 'Visibility dropped below 200 meters in mountain pass.',
      category: 'FOG',
      priority: NotificationPriority.critical,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      actionLabel: 'ENABLE FOG LIGHTS',
    ),
    AiSmartNotification(
      id: 'notif-3',
      title: 'High Crosswind Warning',
      message: 'Gale-force gusts up to 45 km/h reported across coastal bridge.',
      category: 'WIND',
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
    AiSmartNotification(
      id: 'notif-4',
      title: 'Dangerous Hairpin Curve',
      message: 'Sharpening turn ahead with 32 deg recommended max lean angle.',
      category: 'CURVE',
      priority: NotificationPriority.critical,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      actionLabel: 'VIEW CURVE HUD',
    ),
    AiSmartNotification(
      id: 'notif-5',
      title: 'Low Fuel Alert (18% Remaining)',
      message: 'Estimated 38 km range left. Nearest high-octane pump is 4.2 km.',
      category: 'FUEL_LOW',
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      actionLabel: 'ROUTE TO FUEL',
    ),
    AiSmartNotification(
      id: 'notif-6',
      title: 'Drive Chain Service Due',
      message: 'Drive chain lubrication interval reached after 350 km.',
      category: 'SERVICE_DUE',
      priority: NotificationPriority.info,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      actionLabel: 'BOOK SERVICE',
    ),
    AiSmartNotification(
      id: 'notif-7',
      title: 'AGM Battery Voltage Low (11.8V)',
      message: 'Alternator charge low or battery health deteriorating.',
      category: 'BATTERY_LOW',
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AiSmartNotification(
      id: 'notif-8',
      title: 'High Congestion Alert',
      message: 'Accident reported 2.4 km ahead. AI Reroute ready.',
      category: 'TRAFFIC',
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      actionLabel: 'REROUTE NOW',
    ),
  ];

  List<AiSmartNotification> get activeNotifications => List.unmodifiable(_activeNotifications);

  void dismissNotification(String id) {
    _activeNotifications.removeWhere((n) => n.id == id);
  }
}
