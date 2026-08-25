import '../models/active_vehicle_context.dart';

class VehicleStatusReport {
  final bool isOperational;
  final String statusSummary;
  final List<String> activeWarnings;
  final int activeDtcCount;
  final bool isTelemetryFresh;
  final bool hasActiveTrip;

  const VehicleStatusReport({
    required this.isOperational,
    required this.statusSummary,
    required this.activeWarnings,
    required this.activeDtcCount,
    required this.isTelemetryFresh,
    required this.hasActiveTrip,
  });
}

class VehicleStatusEngine {
  static final VehicleStatusEngine _instance = VehicleStatusEngine._internal();
  factory VehicleStatusEngine() => _instance;
  VehicleStatusEngine._internal();

  /// Calculates truthful vehicle status strictly from verified live context
  VehicleStatusReport evaluate(ActiveVehicleContext context) {
    if (!context.hasActiveVehicle) {
      return const VehicleStatusReport(
        isOperational: false,
        statusSummary: 'No Vehicle Selected',
        activeWarnings: [],
        activeDtcCount: 0,
        isTelemetryFresh: false,
        hasActiveTrip: false,
      );
    }

    final warnings = <String>[];

    // Check Connection
    if (!context.isConnected) {
      return VehicleStatusReport(
        isOperational: false,
        statusSummary: 'Vehicle Disconnected',
        activeWarnings: ['Bluetooth connection inactive. Telemetry paused.'],
        activeDtcCount: context.activeDtcCodes.length,
        isTelemetryFresh: false,
        hasActiveTrip: context.activeTripId != null,
      );
    }

    // Check Telemetry Freshness
    if (context.telemetryQuality == TelemetryQuality.stale) {
      warnings.add('Telemetry data stale (>3.5s since last ECU packet).');
    }

    // Check DTC Faults
    if (context.activeDtcCodes.isNotEmpty) {
      warnings.add('${context.activeDtcCodes.length} active Diagnostic Trouble Code(s) reported.');
    }

    // Check Coolant Overheat
    final temp = context.telemetry.engineTemperature.value;
    if (context.telemetry.engineTemperature.available && temp != null && temp > 105.0) {
      warnings.add('High Engine Temperature: ${temp.toStringAsFixed(0)} degC');
    }

    // Check Low Voltage
    final voltage = context.telemetry.batteryVoltage.value;
    if (context.telemetry.batteryVoltage.available && voltage != null && voltage < 11.8) {
      warnings.add('Low 12V Battery Voltage: ${voltage.toStringAsFixed(1)}V');
    }

    final isOperational = warnings.isEmpty;
    final statusSummary = isOperational
        ? 'Live Telemetry Active | All Systems Normal'
        : 'Active Vehicle Alerts (${warnings.length})';

    return VehicleStatusReport(
      isOperational: isOperational,
      statusSummary: statusSummary,
      activeWarnings: warnings,
      activeDtcCount: context.activeDtcCodes.length,
      isTelemetryFresh: context.isTelemetryLive,
      hasActiveTrip: context.activeTripId != null,
    );
  }
}
