import 'package:equatable/equatable.dart';

class SosContactEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;

  const SosContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.isPrimary = false,
  });

  bool get isValidPhoneNumber {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return clean.length >= 10;
  }

  /// Generates real-world emergency SOS text message with location and tracking URL
  String buildEmergencyMessage({
    required double lat,
    required double lng,
    String? riderName,
    String? triggerReason,
  }) {
    final rider = riderName ?? 'RideOS Rider';
    final reason = triggerReason ?? 'Emergency SOS Alert';
    final mapUrl = 'https://maps.google.com/?q=$lat,$lng';
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];

    return '🚨 EMERGENCY ALERT from $rider!\n'
        '$reason triggered at $timestamp.\n'
        '📍 Live GPS Location: $lat, $lng\n'
        '🗺️ Map: $mapUrl\n'
        'Sent via RideOS AI Motorcycle Safety Platform.';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
        'isPrimary': isPrimary,
      };

  factory SosContactEntity.fromJson(Map<String, dynamic> json) => SosContactEntity(
        id: json['id'] as String? ?? 'contact-${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? 'Emergency Contact',
        phone: json['phone'] as String? ?? '',
        relation: json['relation'] as String? ?? 'Family',
        isPrimary: json['isPrimary'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, phone, relation, isPrimary];
}
