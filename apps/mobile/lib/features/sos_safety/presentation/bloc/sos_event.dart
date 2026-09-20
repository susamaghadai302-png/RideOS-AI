import 'package:equatable/equatable.dart';

abstract class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object?> get props => [];
}

class TriggerSosEvent extends SosEvent {
  final double? lat;
  final double? lng;
  final String triggerType;
  final double? impactForceG;
  final int countdownSeconds;

  const TriggerSosEvent({
    this.lat,
    this.lng,
    required this.triggerType,
    this.impactForceG,
    this.countdownSeconds = 15,
  });

  @override
  List<Object?> get props => [lat, lng, triggerType, impactForceG, countdownSeconds];
}

class ImpactDetectedEvent extends SosEvent {
  final double confidenceScore;
  final String reason;
  final double? lat;
  final double? lng;

  const ImpactDetectedEvent({
    required this.confidenceScore,
    required this.reason,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [confidenceScore, reason, lat, lng];
}

class ConfirmSosEvent extends SosEvent {
  const ConfirmSosEvent();
}

class CancelSosEvent extends SosEvent {
  const CancelSosEvent();
}

class CountdownTickEvent extends SosEvent {
  final int secondsRemaining;

  const CountdownTickEvent({required this.secondsRemaining});

  @override
  List<Object?> get props => [secondsRemaining];
}

class DispatchSosEvent extends SosEvent {
  const DispatchSosEvent();
}

class RetryOfflineSosEvent extends SosEvent {
  const RetryOfflineSosEvent();
}

class RecoverSosEvent extends SosEvent {
  const RecoverSosEvent();
}
