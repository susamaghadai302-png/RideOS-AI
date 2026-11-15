import 'package:equatable/equatable.dart';
import '../../domain/entities/maintenance_log_entity.dart';

class MaintenanceState extends Equatable {
  final List<MaintenanceLogEntity> tasks;
  final List<MaintenanceScheduleEntity> schedules;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final String? selectedBikeId;
  final int currentOdometerKm;
  final String activeFilter;

  const MaintenanceState({
    this.tasks = const [],
    this.schedules = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.selectedBikeId,
    this.currentOdometerKm = 0,
    this.activeFilter = 'ALL',
  });

  MaintenanceState copyWith({
    List<MaintenanceLogEntity>? tasks,
    List<MaintenanceScheduleEntity>? schedules,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    String? selectedBikeId,
    int? currentOdometerKm,
    String? activeFilter,
  }) {
    return MaintenanceState(
      tasks: tasks ?? this.tasks,
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
      selectedBikeId: selectedBikeId ?? this.selectedBikeId,
      currentOdometerKm: currentOdometerKm ?? this.currentOdometerKm,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  /// Returns tasks filtered by active category tab
  List<MaintenanceLogEntity> get filteredTasks {
    if (activeFilter == 'ALL') return tasks;
    return tasks.where((t) {
      final type = t.taskType.toUpperCase();
      switch (activeFilter) {
        case 'OIL':
          return type.contains('OIL');
        case 'CHAIN':
          return type.contains('CHAIN');
        case 'BRAKES':
          return type.contains('BRAKE');
        case 'INSPECTION':
          return type.contains('INSPECTION') || type.contains('VALVE') || type.contains('TIRE') || type.contains('SPARK');
        default:
          return true;
      }
    }).toList();
  }

  /// Total recorded maintenance expenditure
  double get totalMaintenanceCost {
    return tasks.fold<double>(0.0, (acc, t) => acc + (t.cost ?? 0.0));
  }

  /// Schedules requiring immediate action
  List<MaintenanceScheduleEntity> get urgentSchedules {
    return schedules
        .where((s) =>
            s.status == MaintenanceScheduleStatus.overdue ||
            s.status == MaintenanceScheduleStatus.dueNow)
        .toList();
  }

  /// Whether any component has reached critical due limits
  bool get hasUrgentMaintenance => urgentSchedules.isNotEmpty;

  /// The next nearest scheduled upkeep item
  MaintenanceScheduleEntity? get nextDueSchedule {
    if (schedules.isEmpty) return null;
    final sorted = List<MaintenanceScheduleEntity>.from(schedules)
      ..sort((a, b) => a.dueInKm.compareTo(b.dueInKm));
    return sorted.first;
  }

  @override
  List<Object?> get props => [
        tasks,
        schedules,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
        selectedBikeId,
        currentOdometerKm,
        activeFilter,
      ];
}
