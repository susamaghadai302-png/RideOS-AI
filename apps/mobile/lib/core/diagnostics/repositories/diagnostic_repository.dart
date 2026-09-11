import 'package:flutter/foundation.dart' show debugPrint;
import '../models/dtc_record.dart';
import '../models/diagnostic_types.dart';
import '../../di/service_locator.dart';
import '../../network/api_client.dart';

class DiagnosticRepository {
  static final DiagnosticRepository _instance = DiagnosticRepository._internal();
  factory DiagnosticRepository() => _instance;
  DiagnosticRepository._internal();

  ApiClient? get _apiClient {
    try {
      return getIt<ApiClient>();
    } catch (_) {
      return null;
    }
  }

  Future<List<DiagnosticFaultRecord>> submitScan(String vehicleId, {
    required List<String> rawPayloads,
    required String protocol,
    required String transportType,
  }) async {
    try {
      final client = _apiClient;
      if (client == null) {
        debugPrint('DiagnosticRepository: Offline, cannot decode raw payloads for $vehicleId');
        throw Exception('Offline: Cannot verify scan with backend decoder.');
      }

      final response = await client.post(
        '/vehicles/$vehicleId/diagnostics/scans',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          'protocol': protocol,
          'transportType': transportType,
          'rawPayloads': rawPayloads,
        },
      );

      final data = response.data;
      if (data != null && data['faults'] != null) {
        final List<dynamic> faultsJson = data['faults'];
        return faultsJson.map<DiagnosticFaultRecord>((f) => DiagnosticFaultRecord(
          code: f['code'] ?? '',
          title: 'Fault Code ${f['code'] ?? ''}',
          description: f['description'] ?? 'Standard diagnostic trouble code',
          probableCause: 'Sensor, actuator, or circuit variance detected.',
          recommendedRemedy: 'Inspect wiring and sensor values with diagnostic tool.',
          module: EcuModule.values.firstWhere((e) => e.name == f['module'], orElse: () => EcuModule.engineControlModule_ECM),
          severity: DtcSeverity.values.firstWhere((e) => e.name == f['severity'], orElse: () => DtcSeverity.confirmedActive),
          category: DtcSystemCategory.powertrain,
          detectedAt: DateTime.now(),
        )).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error syncing diagnostic scan: $e');
      throw Exception(ApiClient.formatErrorMessage(e));
    }
  }

  Future<bool> clearDtcs(String vehicleId, {
    required String protocol,
    required String transportType,
    required String speedPayload,
    required String clearAckPayload,
  }) async {
    try {
      final client = _apiClient;
      if (client == null) {
        debugPrint('DiagnosticRepository: Offline, cannot safely clear dtcs for $vehicleId');
        throw Exception('Offline: Safety interlock requires backend verification.');
      }

      final response = await client.post(
        '/vehicles/$vehicleId/diagnostics/dtcs/clear',
        data: {
          'protocol': protocol,
          'transportType': transportType,
          'speedPayload': speedPayload,
          'clearAckPayload': clearAckPayload,
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error clearing dtcs on backend: $e');
      throw Exception(ApiClient.formatErrorMessage(e));
    }
  }
}

