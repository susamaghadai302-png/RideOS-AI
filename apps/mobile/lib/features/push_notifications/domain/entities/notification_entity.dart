import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime sentAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [id, title, body, category, sentAt];
}
