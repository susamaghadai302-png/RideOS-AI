import 'package:equatable/equatable.dart';
import '../../domain/entities/sos_contact_entity.dart';

enum SosStatus { idle, triggering, active, cancelled }

class SosState extends Equatable {
  final SosStatus status;
  final String? activeIncidentId;
  final List<SosContactEntity> emergencyContacts;

  const SosState({
    this.status = SosStatus.idle,
    this.activeIncidentId,
    this.emergencyContacts = const [],
  });

  SosState copyWith({
    SosStatus? status,
    String? activeIncidentId,
    List<SosContactEntity>? emergencyContacts,
  }) {
    return SosState(
      status: status ?? this.status,
      activeIncidentId: activeIncidentId ?? this.activeIncidentId,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  @override
  List<Object?> get props => [status, activeIncidentId, emergencyContacts];
}
