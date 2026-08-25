import '../../../../core/network/api_client.dart';
import '../../domain/entities/obd_entity.dart';

class ObdRemoteDatasource {
  final ApiClient apiClient;

  ObdRemoteDatasource({required this.apiClient});

  Future<void> sendObdTelemetry(ObdSensorEntity telemetry) async {
    await apiClient.post('/obd/telemetry', data: {
      'rpm': telemetry.rpm,
      'engineTempC': telemetry.engineTempC,
      'throttlePct': telemetry.throttlePct,
      'batteryVoltage': telemetry.batteryVoltage,
      'frontTirePsi': telemetry.frontTirePsi,
      'rearTirePsi': telemetry.rearTirePsi,
      'diagnosticCodes': telemetry.diagnosticCodes,
    });
  }

  Future<ObdSensorEntity> fetchLatestDiagnostics(String riderId) async {
    final response = await apiClient.get('/obd/diagnostics/$riderId');
    final data = response.data;
    final codes = (data['dtcList'] as List? ?? []).map((d) => d['code'].toString()).toList();

    return ObdSensorEntity(
      rpm: (data['rpm'] as num?)?.toDouble() ?? 0.0,
      coolantTempC: (data['engineTempC'] as num?)?.toDouble() ?? 0.0,
      throttlePct: 0.0,
      batteryVoltage: (data['batteryVoltage'] as num?)?.toDouble() ?? 12.0,
      frontTirePsi: (data['frontTirePsi'] as num?)?.toDouble() ?? 32.0,
      rearTirePsi: (data['rearTirePsi'] as num?)?.toDouble() ?? 36.0,
      diagnosticCodes: codes,
      isTpmsWarning: data['tpmsWarning'] ?? false,
      tpmsMessage: data['tpmsMessage'],
    );
  }
}
