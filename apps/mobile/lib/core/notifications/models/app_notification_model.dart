enum NotificationCategory {
  vehicle('Vehicle'),
  trip('Trip & Ride'),
  navigation('Navigation'),
  diagnostics('Diagnostics'),
  maintenance('Maintenance'),
  system('System'),
  account('Account');

  final String label;
  const NotificationCategory(this.label);
}

enum NotificationPriority {
  critical,
  warning,
  notice,
  info;

  String get label => name.toUpperCase();
}

enum NotificationStatus {
  unread,
  read,
  archived;
}

class AppNotificationModel {
  final String id;
  final String notificationKey;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime timestamp;
  final String? deepLinkRoute; // e.g. 'health', 'maintenance', 'trips', 'connect_vehicle'

  const AppNotificationModel({
    required this.id,
    required this.notificationKey,
    required this.title,
    required this.body,
    required this.category,
    this.priority = NotificationPriority.info,
    this.status = NotificationStatus.unread,
    required this.timestamp,
    this.deepLinkRoute,
  });

  AppNotificationModel copyWith({
    String? id,
    String? notificationKey,
    String? title,
    String? body,
    NotificationCategory? category,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? timestamp,
    String? deepLinkRoute,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      notificationKey: notificationKey ?? this.notificationKey,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notificationKey': notificationKey,
    'title': title,
    'body': body,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'deepLinkRoute': deepLinkRoute,
  };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) => AppNotificationModel(
    id: json['id'] as String,
    notificationKey: json['notificationKey'] as String? ?? json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    category: NotificationCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['category'] as String? ?? 'system').toLowerCase(),
      orElse: () => NotificationCategory.system,
    ),
    priority: NotificationPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['priority'] as String? ?? 'info').toLowerCase(),
      orElse: () => NotificationPriority.info,
    ),
    status: NotificationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String? ?? 'unread').toLowerCase(),
      orElse: () => NotificationStatus.unread,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    deepLinkRoute: json['deepLinkRoute'] as String?,
  );
}
