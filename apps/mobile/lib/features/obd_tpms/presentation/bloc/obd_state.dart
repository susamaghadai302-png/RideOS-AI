import 'package:equatable/equatable.dart';
import '../../domain/entities/obd_entity.dart';

abstract class ObdState extends Equatable {
  const ObdState();

  @override
  List<Object?> get props => [];
}

class ObdDisconnectedState extends ObdState {}

class ObdConnectingState extends ObdState {}

class ObdStreamingState extends ObdState {
  final ObdSensorEntity telemetry;

  const ObdStreamingState({required this.telemetry});

  @override
  List<Object?> get props => [telemetry];
}

class ObdFailureState extends ObdState {
  final String errorMessage;

  const ObdFailureState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
