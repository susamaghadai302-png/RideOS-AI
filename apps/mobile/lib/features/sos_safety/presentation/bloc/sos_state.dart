import 'package:equatable/equatable.dart';

enum EmergencyLifecycleStatus {
  normal,
  suspectedImpact,
  countdownActive,
  userCancelled,
  emergencyConfirmed,
  emergencySent,
  emergencyFailed,
  recovered,
}

abstract class SosState extends Equatable {
  final EmergencyLifecycleStatus status;
  const SosState({this.status = EmergencyLifecycleStatus.normal});

  @override
  List<Object?> get props => [status];
}

class SosIdleState extends SosState {
  const SosIdleState() : super(status: EmergencyLifecycleStatus.normal);
}

class SosSuspectedImpactState extends SosState {
  final double confidenceScore;
  final String reason;
  final double? lat;
  final double? lng;

  const SosSuspectedImpactState({
    required this.confidenceScore,
    required this.reason,
    this.lat,
    this.lng,
  }) : super(status: EmergencyLifecycleStatus.suspectedImpact);

  @override
  List<Object?> get props => [confidenceScore, reason, lat, lng, status];
}

class SosCountdownState extends SosState {
  final int secondsRemaining;
  final double? lat;
  final double? lng;
  final String triggerType;
  final bool isConfirmedByUser;

  const SosCountdownState({
    required this.secondsRemaining,
    this.lat,
    this.lng,
    required this.triggerType,
    this.isConfirmedByUser = false,
  }) : super(status: EmergencyLifecycleStatus.countdownActive);

  @override
  List<Object?> get props => [secondsRemaining, lat, lng, triggerType, isConfirmedByUser, status];
}

class SosConfirmedState extends SosState {
  final double? lat;
  final double? lng;
  final String triggerType;

  const SosConfirmedState({
    this.lat,
    this.lng,
    required this.triggerType,
  }) : super(status: EmergencyLifecycleStatus.emergencyConfirmed);

  @override
  List<Object?> get props => [lat, lng, triggerType, status];
}

class SosDispatchedState extends SosState {
  final String incidentId;
  final String liveTrackingUrl;
  final bool isOfflineQueued;

  const SosDispatchedState({
    required this.incidentId,
    required this.liveTrackingUrl,
    this.isOfflineQueued = false,
  }) : super(status: EmergencyLifecycleStatus.emergencySent);

  @override
  List<Object?> get props => [incidentId, liveTrackingUrl, isOfflineQueued, status];
}

class SosFailedState extends SosState {
  final String errorMessage;
  final double? lat;
  final double? lng;

  const SosFailedState({
    required this.errorMessage,
    this.lat,
    this.lng,
  }) : super(status: EmergencyLifecycleStatus.emergencyFailed);

  @override
  List<Object?> get props => [errorMessage, lat, lng, status];
}

class SosCancelledState extends SosState {
  const SosCancelledState() : super(status: EmergencyLifecycleStatus.userCancelled);
}

class SosRecoveredState extends SosState {
  const SosRecoveredState() : super(status: EmergencyLifecycleStatus.recovered);
}
