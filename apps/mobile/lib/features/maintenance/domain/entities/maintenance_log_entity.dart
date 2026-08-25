import 'package:equatable/equatable.dart';

class MaintenanceLogEntity extends Equatable {
  final String id;
  final String bikeId;
  final String taskType;
  final int performedAtKm;
  final int nextDueKm;
  final String notes;

  const MaintenanceLogEntity({
    required this.id,
    required this.bikeId,
    required this.taskType,
    required this.performedAtKm,
    required this.nextDueKm,
    required this.notes,
  });

  @override
  List<Object?> get props => [id, bikeId, taskType, performedAtKm, nextDueKm, notes];
}
