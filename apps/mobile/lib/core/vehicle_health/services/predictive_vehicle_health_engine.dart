import 'package:flutter/foundation.dart';
import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../../../features/obd_tpms/core/services/obd_full_telemetry_service.dart';
import '../../../features/ai_assistant/domain/entities/ai_recommendation_entity.dart';

@immutable
class VehicleSubsystemHealth {
  final String subsystemName;
  final int healthScore; // 0 - 100
  final String statusText;
  final bool isNominal;
  final String telemetrySource;

  const VehicleSubsystemHealth({
    required this.subsystemName,
    required this.healthScore,
    required this.statusText,
    required this.isNominal,
    required this.telemetrySource,
  });
}

@immutable
class OverallVehicleHealthReport {
  final int overallHealthScore; // 0 - 100
  final String overallStatus;
  final String dataClassification; // LIVE, SIMULATED, HISTORICAL, PREDICTED
  final List<VehicleSubsystemHealth> subsystems;
  final List<AiRecommendationEntity> predictiveRecommendations;
  final DateTime timestamp;

  const OverallVehicleHealthReport({
    required this.overallHealthScore,
    required this.overallStatus,
    required this.dataClassification,
    required this.subsystems,
    required this.predictiveRecommendations,
    required this.timestamp,
  });
}

class PredictiveVehicleHealthEngine {
  static final PredictiveVehicleHealthEngine _instance = PredictiveVehicleHealthEngine._internal();
  factory PredictiveVehicleHealthEngine() => _instance;
  PredictiveVehicleHealthEngine._internal();

  OverallVehicleHealthReport evaluateHealthReport({
    bool isBleConnected = false,
    NormalizedTelemetry? normalizedTelemetry,
  }) {
    final obd = ObdFullTelemetryService().getLatestTelemetry();
    String classification = 'HISTORICAL / OFFLINE';
    if (isBleConnected) {
      classification = 'LIVE BLE VEHICLE';
    } else {
      classification = 'HARDWARE_NOT_CONNECTED';
    }

    final subsystems = <VehicleSubsystemHealth>[];
    final recommendations = <AiRecommendationEntity>[];
    final now = DateTime.now();

    if (!isBleConnected) {
      return OverallVehicleHealthReport(
        overallHealthScore: 0,
        overallStatus: 'DATA_UNAVAILABLE',
        dataClassification: classification,
        subsystems: const [],
        predictiveRecommendations: const [],
        timestamp: now,
      );
    }

    // 1. Engine & Powertrain Subsystem
    int engineScore = 100;
    String engineStatus = 'Connected - Scanning...';
    if (obd.coolantTempC != null) {
      if (obd.coolantTempC! > 105.0) {
        engineScore = 45;
        engineStatus = 'High coolant temperature (${obd.coolantTempC!.round()} degC)';
        recommendations.add(
          AiRecommendationEntity(
            id: 'rec_cooling_${now.millisecondsSinceEpoch}',
            title: 'Inspect Radiator Coolant Level',
            explanation: 'Engine operating temperature is elevated above nominal threshold (105 degC).',
            category: RecommendationCategory.vehicleHealth,
            urgency: RecommendationUrgency.critical,
            recommendedAction: 'Allow engine to cool and verify coolant reservoir level.',
            confidenceScore: 0.94,
            supportingTelemetry: 'Coolant Temp: ${obd.coolantTempC!.round()} degC',
            timestamp: now,
          ),
        );
      } else if (obd.coolantTempC! > 95.0) {
        engineScore = 85;
        engineStatus = 'Warm operating temperature (${obd.coolantTempC!.round()} degC)';
      } else {
        engineScore = 100;
        engineStatus = 'Optimal operating parameters';
      }
    } else {
      engineScore = 0;
      engineStatus = 'Sensor data unavailable';
    }

    subsystems.add(
      VehicleSubsystemHealth(
        subsystemName: 'Powertrain & ECU',
        healthScore: engineScore,
        statusText: engineStatus,
        isNominal: engineScore >= 80,
        telemetrySource: classification,
      ),
    );

    // 2. Electrical & 12V Battery Subsystem
    int batteryScore = 100;
    String batteryStatus = 'Connected - Scanning...';
    if (obd.batteryVoltage != null) {
      if (obd.batteryVoltage! < 11.8) {
        batteryScore = 50;
        batteryStatus = 'Low battery voltage (${obd.batteryVoltage!.toStringAsFixed(1)}V)';
        recommendations.add(
          AiRecommendationEntity(
            id: 'rec_batt_${now.millisecondsSinceEpoch}',
            title: 'Charge or Test 12V Battery',
            explanation: 'Bus voltage dropped below 11.8V indicating potential parasitic draw or cell decay.',
            category: RecommendationCategory.maintenance,
            urgency: RecommendationUrgency.warning,
            recommendedAction: 'Connect smart trickle charger and test cold cranking capacity.',
            confidenceScore: 0.91,
            supportingTelemetry: 'Battery Voltage: ${obd.batteryVoltage!.toStringAsFixed(1)}V',
            timestamp: now,
          ),
        );
      } else if (obd.batteryVoltage! < 12.4) {
        batteryScore = 80;
        batteryStatus = 'Discharge detected (${obd.batteryVoltage!.toStringAsFixed(1)}V)';
      } else {
        batteryScore = 100;
        batteryStatus = 'Stator & voltage bus nominal';
      }
    } else {
      batteryScore = 0;
      batteryStatus = 'Sensor data unavailable';
    }

    subsystems.add(
      VehicleSubsystemHealth(
        subsystemName: 'Electrical & 12V Battery',
        healthScore: batteryScore,
        statusText: batteryStatus,
        isNominal: batteryScore >= 80,
        telemetrySource: classification,
      ),
    );

    // 3. TPMS & Tire Pressure Subsystem
    int tpmsScore = 100;
    String tpmsStatus = 'Connected - Scanning...';
    if (obd.frontTirePsi != null) {
      if (obd.frontTirePsi! < 28.0) {
        tpmsScore = 60;
        tpmsStatus = 'Low front tire pressure (${obd.frontTirePsi!.round()} PSI)';
        recommendations.add(
          AiRecommendationEntity(
            id: 'rec_tpms_${now.millisecondsSinceEpoch}',
            title: 'Inflate Front Tire',
            explanation: 'Front tire pressure is underinflated, affecting handling and turn-in grip.',
            category: RecommendationCategory.safetyRisk,
            urgency: RecommendationUrgency.upcoming,
            recommendedAction: 'Inflate front tire to factory cold spec (36 PSI).',
            confidenceScore: 0.96,
            supportingTelemetry: 'Front TPMS: ${obd.frontTirePsi!.round()} PSI',
            timestamp: now,
          ),
        );
      } else {
        tpmsScore = 100;
        tpmsStatus = 'Front ${obd.frontTirePsi!.round()} PSI / Rear ${obd.rearTirePsi?.round() ?? 'N/A'} PSI';
      }
    } else {
      tpmsScore = 0;
      tpmsStatus = 'Sensor data unavailable';
    }

    subsystems.add(
      VehicleSubsystemHealth(
        subsystemName: 'Tires & TPMS Dynamics',
        healthScore: tpmsScore,
        statusText: tpmsStatus,
        isNominal: tpmsScore >= 80,
        telemetrySource: classification,
      ),
    );

    // Calculate aggregate score
    final avgScore = ((engineScore + batteryScore + tpmsScore) / 3.0).round();
    String overallStatus = 'EXCELLENT';
    if (avgScore < 70) {
      overallStatus = 'ATTENTION NEEDED';
    } else if (avgScore < 85) {
      overallStatus = 'GOOD';
    }

    return OverallVehicleHealthReport(
      overallHealthScore: avgScore,
      overallStatus: overallStatus,
      dataClassification: classification,
      subsystems: subsystems,
      predictiveRecommendations: recommendations,
      timestamp: now,
    );
  }
}
