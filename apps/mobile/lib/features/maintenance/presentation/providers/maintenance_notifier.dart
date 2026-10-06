import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'maintenance_state.dart';
import '../../domain/entities/maintenance_log_entity.dart';

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  MaintenanceNotifier() : super(const MaintenanceState());

  void loadTasksForBike(String bikeId) {
    state = state.copyWith(
      tasks: [],
    );
  }

  void addMaintenanceTask(MaintenanceLogEntity task) {
    state = state.copyWith(tasks: [...state.tasks, task]);
  }
}

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  return MaintenanceNotifier();
});
