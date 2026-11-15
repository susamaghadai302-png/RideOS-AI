import '../../../../core/network/api_client.dart';
import '../../domain/entities/maintenance_log_entity.dart';

abstract class MaintenanceRemoteDatasource {
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId);
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  });
}

class MaintenanceRemoteDatasourceImpl implements MaintenanceRemoteDatasource {
  final ApiClient apiClient;

  MaintenanceRemoteDatasourceImpl({required this.apiClient});

  @override
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId) async {
    final response = await apiClient.dio.get('/maintenance/bike/$bikeId');
    if (response.data is List) {
      final list = response.data as List;
      return list
          .map((item) =>
              MaintenanceLogEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  }) async {
    final payload = {
      'bikeId': task.bikeId,
      'taskType': task.taskType,
      'currentKm': task.performedAtKm,
      'intervalKm': intervalKm ?? MaintenanceTaskTypes.getDefaultIntervalKm(task.taskType),
      'notes': task.notes,
      if (task.cost != null) 'cost': task.cost,
      if (task.serviceProvider != null) 'serviceProvider': task.serviceProvider,
    };

    final response = await apiClient.dio.post('/maintenance/log', data: payload);
    return MaintenanceLogEntity.fromJson(response.data as Map<String, dynamic>);
  }
}
