import 'dart:async';
import '../../domain/entities/ai_vehicle_alert_entity.dart';
import '../../../obd_tpms/core/services/obd_full_telemetry_service.dart';

class AiCopilotRidingContext {
  final double? currentSpeedKmH;
  final int? engineRpm;
  final double? batteryVoltage;
  final double? coolantTempC;
  final double? fuelLevelPct;
  final double? throttlePct;
  final TelemetryDataSource dataSource;
  final bool isConnected;
  final String activeVehicleName;
  final DateTime timestamp;

  const AiCopilotRidingContext({
    this.currentSpeedKmH,
    this.engineRpm,
    this.batteryVoltage,
    this.coolantTempC,
    this.fuelLevelPct,
    this.throttlePct,
    required this.dataSource,
    required this.isConnected,
    required this.activeVehicleName,
    required this.timestamp,
  });

  bool get isSimulated => dataSource == TelemetryDataSource.simulatorDemo;

  String get summaryDescription {
    final modeLabel = isSimulated ? '[SIMULATED]' : (isConnected ? '[REAL BLE]' : '[OFFLINE]');
    final speed = currentSpeedKmH != null ? '${currentSpeedKmH!.round()} km/h' : 'Unavailable';
    final rpm = engineRpm != null ? '$engineRpm RPM' : 'Unavailable';
    final batt = batteryVoltage != null ? '${batteryVoltage!.toStringAsFixed(1)}V' : 'Unavailable';
    final temp = coolantTempC != null ? '${coolantTempC!.round()} degC' : 'Unavailable';
    return '$modeLabel Vehicle: $activeVehicleName | Speed: $speed | RPM: $rpm | Battery: $batt | Temp: $temp';
  }
}

class AiCopilotEngine {
  static final AiCopilotEngine _instance = AiCopilotEngine._internal();
  factory AiCopilotEngine() => _instance;
  AiCopilotEngine._internal();

  final List<AiVehicleAlertEntity> _alertHistory = [];
  final StreamController<List<AiVehicleAlertEntity>> _alertsStreamController =
      StreamController<List<AiVehicleAlertEntity>>.broadcast();

  Stream<List<AiVehicleAlertEntity>> get alertsStream => _alertsStreamController.stream;
  List<AiVehicleAlertEntity> get alertHistory => List.unmodifiable(_alertHistory);
  List<AiVehicleAlertEntity> get unacknowledgedAlerts =>
      _alertHistory.where((a) => !a.isAcknowledged).toList();

  AiCopilotRidingContext getCurrentContext({
    String activeVehicleName = 'Yamaha YZF-R1M',
    bool isBleConnected = false,
  }) {
    final telemetry = ObdFullTelemetryService().getLatestTelemetry();
    final isSimulated = ObdFullTelemetryService().isSimulatorMode;

    final derivedSpeed = telemetry.engineRpm != null ? (telemetry.engineRpm! / 65.0).clamp(0.0, 299.0) : null;
    final intRpm = telemetry.engineRpm?.round();

    return AiCopilotRidingContext(
      currentSpeedKmH: derivedSpeed,
      engineRpm: intRpm,
      batteryVoltage: telemetry.batteryVoltage,
      coolantTempC: telemetry.coolantTempC,
      fuelLevelPct: telemetry.fuelLevelPct,
      throttlePct: telemetry.throttlePositionPct,
      dataSource: telemetry.source,
      isConnected: isSimulated || isBleConnected,
      activeVehicleName: activeVehicleName,
      timestamp: DateTime.now(),
    );
  }

  void evaluateTelemetryForAlerts(AiCopilotRidingContext context) {
    final now = DateTime.now();

    // 1. High Engine Temperature Check (>105 degC)
    if (context.coolantTempC != null && context.coolantTempC! > 105.0) {
      _addAlertIfUnique(
        AiVehicleAlertEntity(
          id: 'alert_temp_${now.millisecondsSinceEpoch}',
          title: 'High Engine Temperature',
          description: 'Engine coolant temperature has reached ${context.coolantTempC!.toStringAsFixed(1)} degC. High heat threshold exceeded.',
          severity: AlertSeverity.critical,
          source: AlertSource.telemetryEngine,
          timestamp: now,
          recommendedAction: 'Reduce engine load and pull over safely to allow idle cooling.',
        ),
      );
    }

    // 2. Low Battery Voltage (<11.8V)
    if (context.batteryVoltage != null && context.batteryVoltage! < 11.8 && context.batteryVoltage! > 0) {
      _addAlertIfUnique(
        AiVehicleAlertEntity(
          id: 'alert_batt_${now.millisecondsSinceEpoch}',
          title: 'Low Battery Voltage',
          description: 'Motorcycle electrical bus voltage dropped to ${context.batteryVoltage!.toStringAsFixed(1)}V.',
          severity: AlertSeverity.warning,
          source: AlertSource.telemetryEngine,
          timestamp: now,
          recommendedAction: 'Check stator output and avoid restarting engine with accessories on.',
        ),
      );
    }

    // 3. Low Fuel Level (<15%)
    if (context.fuelLevelPct != null && context.fuelLevelPct! < 15.0 && context.fuelLevelPct! > 0) {
      _addAlertIfUnique(
        AiVehicleAlertEntity(
          id: 'alert_fuel_${now.millisecondsSinceEpoch}',
          title: 'Low Fuel Reserve',
          description: 'Fuel level is at ${context.fuelLevelPct!.toStringAsFixed(0)}%. Reserve range low.',
          severity: AlertSeverity.warning,
          source: AlertSource.telemetryEngine,
          timestamp: now,
          recommendedAction: 'Voice command "Find nearest fuel" to navigate to nearby gas station.',
        ),
      );
    }

    // 4. Excessive Speed Alert (>160 km/h)
    if (context.currentSpeedKmH != null && context.currentSpeedKmH! > 160.0) {
      _addAlertIfUnique(
        AiVehicleAlertEntity(
          id: 'alert_speed_${now.millisecondsSinceEpoch}',
          title: 'High Velocity Notice',
          description: 'Vehicle velocity is ${context.currentSpeedKmH!.round()} km/h. Maintain extended stopping distance.',
          severity: AlertSeverity.info,
          source: AlertSource.telemetryEngine,
          timestamp: now,
          recommendedAction: 'Scan ahead for road hazards and adjust braking buffer.',
        ),
      );
    }
  }

  void _addAlertIfUnique(AiVehicleAlertEntity newAlert) {
    final hasRecentSame = _alertHistory.any(
      (a) => a.title == newAlert.title && a.timestamp.isAfter(newAlert.timestamp.subtract(const Duration(seconds: 30))),
    );
    if (!hasRecentSame) {
      _alertHistory.insert(0, newAlert);
      if (_alertHistory.length > 50) {
        _alertHistory.removeLast();
      }
      _alertsStreamController.add(List.unmodifiable(_alertHistory));
    }
  }

  void acknowledgeAlert(String alertId) {
    final index = _alertHistory.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alertHistory[index] = _alertHistory[index].copyWith(isAcknowledged: true);
      _alertsStreamController.add(List.unmodifiable(_alertHistory));
    }
  }

  void clearAlerts() {
    _alertHistory.clear();
    _alertsStreamController.add(const []);
  }

  String generateTelemetryQueryResponse(String query) {
    final context = getCurrentContext();
    final lower = query.toLowerCase();

    if (lower.contains('speed')) {
      if (context.currentSpeedKmH != null) {
        final mode = context.isSimulated ? ' (Simulated)' : '';
        return 'Your current speed is ${context.currentSpeedKmH!.round()} km/h$mode.';
      }
      return 'Current speed is unavailable from vehicle. Ensure BLE telemetry is active.';
    }

    if (lower.contains('rpm') || lower.contains('revs')) {
      if (context.engineRpm != null) {
        final mode = context.isSimulated ? ' (Simulated)' : '';
        return 'Engine speed is currently ${context.engineRpm} RPM$mode.';
      }
      return 'Engine RPM is currently unavailable from vehicle.';
    }

    if (lower.contains('battery') || lower.contains('voltage')) {
      if (context.batteryVoltage != null) {
        final mode = context.isSimulated ? ' (Simulated)' : '';
        return 'Motorcycle battery is at ${context.batteryVoltage!.toStringAsFixed(1)} Volts$mode.';
      }
      return 'Battery voltage is currently unavailable from vehicle.';
    }

    if (lower.contains('temp') || lower.contains('coolant')) {
      if (context.coolantTempC != null) {
        final mode = context.isSimulated ? ' (Simulated)' : '';
        return 'Engine coolant temperature is ${context.coolantTempC!.round()} °C$mode.';
      }
      return 'Engine temperature is currently unavailable from vehicle.';
    }

    if (lower.contains('connected') || lower.contains('connection')) {
      if (context.isSimulated) {
        return 'RideOS is in SIMULATOR MODE with synthetic CAN-bus telemetry active.';
      }
      if (context.isConnected) {
        return 'Motorcycle is CONNECTED via real BLE hardware.';
      }
      return 'Motorcycle is DISCONNECTED. No live BLE telemetry is receiving.';
    }

    if (lower.contains('alert') || lower.contains('warning')) {
      final unack = unacknowledgedAlerts;
      if (unack.isEmpty) {
        return 'All vehicle parameters are nominal. Zero active alerts.';
      }
      return 'You have ${unack.length} active alert: ${unack.first.title} - ${unack.first.description}';
    }

    return 'RideOS AI Co-Pilot: Telematics monitored. Eyes on the apex, ride safe!';
  }
}
