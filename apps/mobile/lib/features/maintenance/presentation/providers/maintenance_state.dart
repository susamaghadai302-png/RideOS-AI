import 'package:equatable/equatable.dart';
import '../../domain/entities/maintenance_log_entity.dart';

class MaintenanceState extends Equatable {
  final List<MaintenanceLogEntity> tasks;
  final bool isLoading;

  const MaintenanceState({
    this.tasks = const [],
    this.isLoading = false,
  });

  MaintenanceState copyWith({
    List<MaintenanceLogEntity>? tasks,
    bool? isLoading,
  }) {
    return MaintenanceState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [tasks, isLoading];
}
