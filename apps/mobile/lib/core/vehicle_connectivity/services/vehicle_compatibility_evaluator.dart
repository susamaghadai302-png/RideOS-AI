import 'package:flutter/foundation.dart';
import '../models/vehicle_capabilities.dart';

enum CompatibilityScoreCategory {
  fullyCompatible,
  partiallyCompatible,
  gatewayRequired,
  protocolNotVerified,
  unsupported,
}

enum TelemetryDataSourceClassification {
  liveBleHardware,
  simulatedData,
  historicalOfflineCache,
  predictedAiEstimate,
  unavailable,
}

@immutable
class CapabilityFeatureAudit {
  final String featureName;
  final String category; // Powertrain, Safety, Cluster, Diagnostics, Telemetry
  final bool isSupported;
  final bool isWriteable;
  final TelemetryDataSourceClassification defaultSource;
  final String note;

  const CapabilityFeatureAudit({
    required this.featureName,
    required this.category,
    required this.isSupported,
    required this.isWriteable,
    required this.defaultSource,
    required this.note,
  });
}

@immutable
class VehicleCompatibilityEvaluation {
  final CompatibilityScoreCategory category;
  final int overallScorePercentage; // 0 to 100
  final List<CapabilityFeatureAudit> supportedFeatures;
  final List<CapabilityFeatureAudit> unsupportedFeatures;
  final String summaryMessage;

  const VehicleCompatibilityEvaluation({
    required this.category,
    required this.overallScorePercentage,
    required this.supportedFeatures,
    required this.unsupportedFeatures,
    required this.summaryMessage,
  });

  String get categoryLabel {
    switch (category) {
      case CompatibilityScoreCategory.fullyCompatible:
        return 'FULLY COMPATIBLE';
      case CompatibilityScoreCategory.partiallyCompatible:
        return 'PARTIALLY COMPATIBLE';
      case CompatibilityScoreCategory.gatewayRequired:
        return 'GATEWAY REQUIRED';
      case CompatibilityScoreCategory.protocolNotVerified:
        return 'PROTOCOL NOT VERIFIED';
      case CompatibilityScoreCategory.unsupported:
        return 'UNSUPPORTED';
    }
  }
}

class VehicleCompatibilityEvaluator {
  static final VehicleCompatibilityEvaluator _instance = VehicleCompatibilityEvaluator._internal();
  factory VehicleCompatibilityEvaluator() => _instance;
  VehicleCompatibilityEvaluator._internal();

  VehicleCompatibilityEvaluation evaluate(VehicleCapabilities caps, {bool isOffline = false}) {
    final List<CapabilityFeatureAudit> supported = [];
    final List<CapabilityFeatureAudit> unsupported = [];

    void check(
      String name,
      String cat,
      CapabilitySupportLevel level,
      String supportedNote,
      String unsupportedNote,
    ) {
      final isSupp = level == CapabilitySupportLevel.supported ||
          level == CapabilitySupportLevel.readOnly ||
          level == CapabilitySupportLevel.readWrite;
      final isWrite = level == CapabilitySupportLevel.readWrite;

      final audit = CapabilityFeatureAudit(
        featureName: name,
        category: cat,
        isSupported: isSupp,
        isWriteable: isWrite,
        defaultSource: isSupp
            ? (isOffline
                ? TelemetryDataSourceClassification.historicalOfflineCache
                : TelemetryDataSourceClassification.liveBleHardware)
            : TelemetryDataSourceClassification.unavailable,
        note: isSupp ? supportedNote : unsupportedNote,
      );

      if (isSupp) {
        supported.add(audit);
      } else {
        unsupported.add(audit);
      }
    }

    check('Vehicle Speed (km/h)', 'Powertrain', caps.speed, 'Real-time wheel speed sensor telemetry', 'Wheel speed sensor broadcast not accessible');
    check('Engine RPM & Tachometer', 'Powertrain', caps.rpm, 'Engine rotational speed from ECU/CCU', 'RPM telemetry not exposed over protocol');
    check('Battery Voltage (12V)', 'Electrical', caps.batteryVoltage, 'Lead-acid / Lithium 12V battery health', 'Battery voltage telemetry unavailable');
    check('State of Charge (EV SoC %)', 'Electrical', caps.batteryLevel, 'High-voltage traction pack SoC', 'EV battery BMS telemetry not available');
    check('Fuel Level (%)', 'Powertrain', caps.fuelLevel, 'Fuel tank level sensor stream', 'Fuel level sensor stream not exposed');
    check('Engine Coolant Temperature', 'Powertrain', caps.engineTemperature, 'Cylinder head / coolant thermal telemetry', 'Engine coolant temperature not accessible');
    check('Motor Inverter Temperature', 'Powertrain', caps.motorTemperature, 'EV motor & inverter thermal status', 'EV motor temperature unavailable');
    check('Odometer & Total Distance', 'Telemetry', caps.odometer, 'Total cumulative vehicle mileage', 'Odometer mileage not exposed');
    check('Trip Meter Distances', 'Telemetry', caps.tripDistance, 'Trip A / Trip B reset & distance counter', 'Trip distance counter not available');
    check('Riding Modes (Sport/Rain/Track)', 'Control', caps.rideMode, 'Selected throttle map & mode read', 'Riding mode state not accessible');
    check('ABS & Braking Health', 'Safety', caps.absStatus, 'Dual-channel / Cornering ABS status', 'ABS telemetry not broadcast');
    check('Traction Control (TCS)', 'Safety', caps.tractionControl, 'Rear wheel slip intervention status', 'TCS status telemetry unavailable');
    check('Diagnostic Codes (DTC)', 'Diagnostics', caps.diagnosticCodes, 'ISO 15031 / SAE J1979 DTC fault codes', 'DTC fault stream not accessible');
    check('Smart Display Turn-by-Turn', 'Cluster', caps.navigationData, 'Direction arrows, maneuvers & distance to turn', 'Cluster display HUD write not supported');
    check('Caller ID & Notifications', 'Cluster', caps.smartDisplayData, 'Incoming call banner and messaging overlay', 'Cluster notification write not supported');
    check('Real-time Telemetry Bus', 'Telemetry', caps.telemetry, 'Continuous high-rate CAN/BLE streaming', 'Continuous telemetry streaming unavailable');

    final total = supported.length + unsupported.length;
    final pct = total > 0 ? ((supported.length / total) * 100).round() : 0;

    CompatibilityScoreCategory cat;
    String summary;

    if (pct >= 80) {
      cat = CompatibilityScoreCategory.fullyCompatible;
      summary = 'Full telemetry, diagnostics, and smart display integration verified.';
    } else if (pct >= 40) {
      cat = CompatibilityScoreCategory.partiallyCompatible;
      summary = 'Essential telemetry and vehicle telemetry verified. Some advanced cluster features unavailable.';
    } else if (caps.connectionType == CapabilitySupportLevel.notSupported) {
      cat = CompatibilityScoreCategory.unsupported;
      summary = 'Vehicle does not expose wireless connectivity or standard diagnostic protocol.';
    } else {
      cat = CompatibilityScoreCategory.gatewayRequired;
      summary = 'Standard OBD-II / CAN diagnostic gateway required to read ECU telemetry.';
    }

    return VehicleCompatibilityEvaluation(
      category: cat,
      overallScorePercentage: pct,
      supportedFeatures: supported,
      unsupportedFeatures: unsupported,
      summaryMessage: summary,
    );
  }
}
