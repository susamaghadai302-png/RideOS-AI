import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'maintenance_state.dart';
import '../../domain/entities/maintenance_log_entity.dart';

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  MaintenanceNotifier() : super(const MaintenanceState());

  void loadTasksForBike(String bikeId) {
    state = state.copyWith(
      tasks: const [
        MaintenanceLogEntity(
          id: 'maint-1',
          bikeId: 'bike-001',
          taskType: 'CHAIN_LUBE',
          performedAtKm: 12000,
          nextDueKm: 12500,
          notes: 'Cleaned with degreaser and applied synthetic lube',
        ),
        MaintenanceLogEntity(
          id: 'maint-2',
          bikeId: 'bike-001',
          taskType: 'OIL_CHANGE',
          performedAtKm: 10000,
          nextDueKm: 15000,
          notes: 'Replaced oil filter & 10W-40 full synthetic oil',
        ),
      ],
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
