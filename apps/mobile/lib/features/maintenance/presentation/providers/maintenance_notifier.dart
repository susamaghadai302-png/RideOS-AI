import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/maintenance_local_datasource.dart';
import '../../data/datasources/maintenance_remote_datasource.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/entities/maintenance_log_entity.dart';
import '../../domain/repositories/maintenance_repository.dart';
import 'maintenance_state.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final remote = MaintenanceRemoteDatasourceImpl(apiClient: apiClient);
  final local = MaintenanceLocalDatasourceImpl();
  return MaintenanceRepositoryImpl(
    remoteDatasource: remote,
    localDatasource: local,
  );
});

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  final MaintenanceRepository _repository;

  MaintenanceNotifier({required MaintenanceRepository repository})
      : _repository = repository,
        super(const MaintenanceState());

  /// Loads maintenance logs for a bike and calculates current service schedules
  Future<void> loadTasksForBike(
    String bikeId, {
    int? currentOdometerKm,
    Map<String, dynamic>? customIntervals,
  }) async {
    final odo = currentOdometerKm ?? state.currentOdometerKm;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedBikeId: bikeId,
      currentOdometerKm: odo,
    );

    try {
      final loadedLogs = await _repository.getLogsForBike(bikeId);

      // Sort logs by date descending
      loadedLogs.sort((a, b) => b.performedAtDate.compareTo(a.performedAtDate));

      // Calculate upcoming schedules based on real odometer & logs
      final calculatedSchedules = calculateSchedules(
        odo,
        loadedLogs,
        customIntervals: customIntervals,
      );

      state = state.copyWith(
        tasks: loadedLogs,
        schedules: calculatedSchedules,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load maintenance records: ${e.toString()}',
      );
    }
  }

  /// Logs a new maintenance task with validation and recalculates schedules
  Future<bool> addMaintenanceTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
    Map<String, dynamic>? customIntervals,
  }) async {
    // 1. Validation
    if (task.performedAtKm < 0) {
      state = state.copyWith(
        errorMessage: 'Odometer reading cannot be negative.',
      );
      return false;
    }

    if (task.taskType.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select a valid maintenance task type.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final savedTask = await _repository.logTask(task, intervalKm: intervalKm);

      // Merge into tasks list
      final updatedTasks = [
        savedTask,
        ...state.tasks.where((t) => t.id != savedTask.id),
      ]..sort((a, b) => b.performedAtDate.compareTo(a.performedAtDate));

      // Update current odometer if the logged service odometer is higher
      final newOdo = task.performedAtKm > state.currentOdometerKm
          ? task.performedAtKm
          : state.currentOdometerKm;

      final updatedSchedules = calculateSchedules(
        newOdo,
        updatedTasks,
        customIntervals: customIntervals,
      );

      state = state.copyWith(
        tasks: updatedTasks,
        schedules: updatedSchedules,
        currentOdometerKm: newOdo,
        isSubmitting: false,
        successMessage: 'Maintenance record logged successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to record maintenance: ${e.toString()}',
      );
      return false;
    }
  }

  /// Deletes a maintenance log
  Future<void> deleteMaintenanceTask(
    String logId, {
    Map<String, dynamic>? customIntervals,
  }) async {
    final bikeId = state.selectedBikeId ?? '';
    try {
      if (bikeId.isNotEmpty) {
        await _repository.deleteLog(logId, bikeId);
      }

      final updatedTasks = state.tasks.where((t) => t.id != logId).toList();
      final updatedSchedules = calculateSchedules(
        state.currentOdometerKm,
        updatedTasks,
        customIntervals: customIntervals,
      );

      state = state.copyWith(
        tasks: updatedTasks,
        schedules: updatedSchedules,
        successMessage: 'Maintenance record deleted.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete record: ${e.toString()}',
      );
    }
  }

  /// Updates current odometer reading and re-evaluates schedules
  void updateCurrentOdometer(
    int km, {
    Map<String, dynamic>? customIntervals,
  }) {
    if (km < 0) return;
    final updatedSchedules = calculateSchedules(
      km,
      state.tasks,
      customIntervals: customIntervals,
    );
    state = state.copyWith(
      currentOdometerKm: km,
      schedules: updatedSchedules,
    );
  }

  /// Sets the active category filter for task history
  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Clears any user-facing error or success messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// Helper that strictly computes schedule items from real service history and odometer
  List<MaintenanceScheduleEntity> calculateSchedules(
    int currentOdo,
    List<MaintenanceLogEntity> logs, {
    Map<String, dynamic>? customIntervals,
  }) {
    final Map<String, int> intervals = {
      MaintenanceTaskTypes.chainLube: 500,
      MaintenanceTaskTypes.chainTension: 1000,
      MaintenanceTaskTypes.oilChange: 5000,
      MaintenanceTaskTypes.generalInspection: 6000,
      MaintenanceTaskTypes.sparkPlugs: 12000,
      MaintenanceTaskTypes.brakePads: 15000,
      MaintenanceTaskTypes.tireChange: 18000,
      MaintenanceTaskTypes.valveClearance: 24000,
    };

    // Apply custom intervals from vehicle profile if provided
    if (customIntervals != null) {
      for (final entry in customIntervals.entries) {
        if (entry.value is num) {
          intervals[entry.key] = (entry.value as num).toInt();
        }
      }
    }

    final List<MaintenanceScheduleEntity> items = [];

    for (final entry in intervals.entries) {
      final taskType = entry.key;
      final interval = entry.value;
      final title = MaintenanceTaskTypes.getDisplayName(taskType);

      // Find the most recent service log for this task type
      final recentLogs = logs
          .where((l) => l.taskType.toUpperCase() == taskType.toUpperCase())
          .toList()
        ..sort((a, b) => b.performedAtDate.compareTo(a.performedAtDate));

      final lastLog = recentLogs.firstOrNull;
      final lastKm = lastLog?.performedAtKm;
      final lastDate = lastLog?.performedAtDate;

      MaintenanceScheduleStatus status;
      String statusDetail;
      String recommendation;
      int dueInKm;

      if (currentOdo <= 0 && lastKm == null) {
        status = MaintenanceScheduleStatus.pendingOdometer;
        dueInKm = interval;
        statusDetail = 'Pending Odometer';
        recommendation = 'Enter vehicle odometer reading to calculate precise service schedule.';
      } else {
        final baselineKm = lastKm ?? 0;
        final elapsedKm = currentOdo - baselineKm;
        dueInKm = interval - elapsedKm;

        final dueSoonThreshold = (interval * 0.25).clamp(50, 500);
        if (dueInKm < -50) {
          status = MaintenanceScheduleStatus.overdue;
          statusDetail = 'Overdue by ${-dueInKm} km';
          recommendation = 'Exceeded manufacturer interval of $interval km. Perform service promptly.';
        } else if (dueInKm <= 0) {
          status = MaintenanceScheduleStatus.dueNow;
          statusDetail = 'Due Immediately';
          recommendation = 'Service interval reached. Schedule maintenance inspection.';
        } else if (dueInKm <= dueSoonThreshold) {
          status = MaintenanceScheduleStatus.dueSoon;
          statusDetail = 'Due in $dueInKm km';
          recommendation = 'Approaching service interval of $interval km. Prepare parts.';
        } else {
          status = MaintenanceScheduleStatus.optimal;
          statusDetail = 'Optimal (Due in $dueInKm km)';
          recommendation = 'Component in good standing. Next service at ${baselineKm + interval} km.';
        }
      }

      items.add(
        MaintenanceScheduleEntity(
          taskType: taskType,
          title: title,
          intervalKm: interval,
          lastPerformedKm: lastKm,
          lastPerformedDate: lastDate,
          currentOdometerKm: currentOdo,
          dueInKm: dueInKm,
          status: status,
          statusDetail: statusDetail,
          recommendation: recommendation,
        ),
      );
    }

    // Sort by urgency: overdue -> dueNow -> dueSoon -> optimal
    items.sort((a, b) => a.dueInKm.compareTo(b.dueInKm));
    return items;
  }
}

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  final repo = ref.watch(maintenanceRepositoryProvider);
  return MaintenanceNotifier(repository: repo);
});
