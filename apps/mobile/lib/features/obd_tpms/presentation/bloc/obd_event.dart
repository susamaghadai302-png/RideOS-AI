import 'package:equatable/equatable.dart';
import '../../domain/entities/obd_entity.dart';

abstract class ObdEvent extends Equatable {
  const ObdEvent();

  @override
  List<Object?> get props => [];
}

class StartBleScanEvent extends ObdEvent {}

class ObdTelemetryUpdatedEvent extends ObdEvent {
  final ObdSensorEntity telemetry;

  const ObdTelemetryUpdatedEvent({required this.telemetry});

  @override
  List<Object?> get props => [telemetry];
}

class ObdScanErrorEvent extends ObdEvent {
  final String errorMessage;

  const ObdScanErrorEvent({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class ClearFaultCodesEvent extends ObdEvent {}

class StopBleScanEvent extends ObdEvent {}
