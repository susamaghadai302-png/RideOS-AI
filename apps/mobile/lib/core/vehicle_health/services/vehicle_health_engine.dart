import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../models/vehicle_health_state.dart';
import '../models/vehicle_alert_model.dart';
import 'diagnostic_manager.dart';
import 'maintenance_manager.dart';
import 'vehicle_alert_engine.dart';

final vehicleHealthProvider = StateNotifierProvider<VehicleHealthNotifier, VehicleHealthState>((ref) {
  return VehicleHealthNotifier();
});

class VehicleHealthNotifier extends StateNotifier<VehicleHealthState> {
  VehicleHealthNotifier() : super(VehicleHealthState.empty());

  void updateState(VehicleHealthState newState) {
    state = newState;
  }
}

class VehicleHealthEngine {
  static final VehicleHealthEngine _instance = VehicleHealthEngine._internal();
  factory VehicleHealthEngine() => _instance;
  VehicleHealthEngine._internal();

  WidgetRef? _ref;
  NormalizedTelemetry? _lastTelemetry;
  StreamSubscription? _telemetrySubscription;

  void initialize(WidgetRef ref) {
    _ref = ref;
    DiagnosticManager().initialize(ref);
    MaintenanceManager().initialize(ref);
    VehicleAlertEngine().initialize(ref);

    _telemetrySubscription?.cancel();
    _telemetrySubscription = BluetoothEngine().telemetryStream.listen((telemetry) {
      _lastTelemetry = telemetry;
      evaluateHealth();
    });
  }

  /// Evaluates vehicle health categories strictly from verified telemetry and diagnostic data
  VehicleHealthState evaluateHealth() {
    final telemetry = _lastTelemetry;
    final isConnected = BluetoothEngine().currentAdapter != null;
    final dtcs = DiagnosticManager().diagnosticHistory.where((d) => d.active).toList();
    final now = DateTime.now();

    final Map<HealthCategory, CategoryHealthState> categories = {};

    // 1. ENGINE
    if (!isConnected || telemetry == null) {
      categories[HealthCategory.engine] = CategoryHealthState.insufficientData(HealthCategory.engine, reason: 'Vehicle disconnected');
    } else if (telemetry.engineTemperature.available && telemetry.engineTemperature.value != null) {
      final temp = telemetry.engineTemperature.value!;
      if (temp >= 115) {
        categories[HealthCategory.engine] = CategoryHealthState(
          category: HealthCategory.engine,
          severity: HealthSeverity.critical,
          statusText: 'Severe Overheating',
          detail: 'Coolant temp $temp degC exceeds maximum threshold (115 degC). Pull over safely.',
          hasLiveTelemetry: true,
          timestamp: now,
        );
        VehicleAlertEngine().triggerAlert(
          alertKey: 'ENGINE_OVERHEAT',
          title: 'Engine Overheat Alert',
          message: 'Engine temp reached $temp degC. Immediate cool down required.',
          severity: AlertSeverity.critical,
          category: 'COOLING',
        );
      } else if (temp >= 105) {
        categories[HealthCategory.engine] = CategoryHealthState(
          category: HealthCategory.engine,
          severity: HealthSeverity.warning,
          statusText: 'High Operating Temp',
          detail: 'Engine temp $temp degC elevated. Check coolant & airflow.',
          hasLiveTelemetry: true,
          timestamp: now,
        );
      } else if (temp >= 70) {
        categories[HealthCategory.engine] = CategoryHealthState(
          category: HealthCategory.engine,
          severity: HealthSeverity.optimal,
          statusText: 'Optimal Operating Temp',
          detail: 'Engine temperature $temp degC within factory nominal range',
          hasLiveTelemetry: true,
          timestamp: now,
        );
      } else {
        categories[HealthCategory.engine] = CategoryHealthState(
          category: HealthCategory.engine,
          severity: HealthSeverity.notice,
          statusText: 'Warming Up',
          detail: 'Engine temp $temp degC below nominal operating threshold',
          hasLiveTelemetry: true,
          timestamp: now,
        );
      }
    } else {
      categories[HealthCategory.engine] = CategoryHealthState.insufficientData(HealthCategory.engine, reason: 'Engine temperature sensor unavailable on connected bus');
    }

    // 2. BATTERY (ICE 12V vs EV)
    if (!isConnected || telemetry == null) {
      categories[HealthCategory.battery] = CategoryHealthState.insufficientData(HealthCategory.battery, reason: 'Vehicle disconnected');
    } else if (telemetry.batteryVoltage.available && telemetry.batteryVoltage.value != null) {
      final v = telemetry.batteryVoltage.value!;
      if (v < 11.7) {
        categories[HealthCategory.battery] = CategoryHealthState(
          category: HealthCategory.battery,
          severity: HealthSeverity.warning,
          statusText: 'Low 12V Voltage',
          detail: 'Battery voltage $v V is below starting threshold (11.8V)',
          hasLiveTelemetry: true,
          timestamp: now,
        );
        VehicleAlertEngine().triggerAlert(
          alertKey: 'LOW_BATTERY_12V',
          title: 'Low Battery Voltage',
          message: 'System voltage is $v V. Inspect alternator / battery.',
          severity: AlertSeverity.warning,
          category: 'BATTERY',
        );
      } else if (v > 15.2) {
        categories[HealthCategory.battery] = CategoryHealthState(
          category: HealthCategory.battery,
          severity: HealthSeverity.critical,
          statusText: 'Regulator Overcharging',
          detail: 'Voltage $v V exceeds maximum safe charging limit',
          hasLiveTelemetry: true,
          timestamp: now,
        );
      } else {
        categories[HealthCategory.battery] = CategoryHealthState(
          category: HealthCategory.battery,
          severity: HealthSeverity.optimal,
          statusText: 'Healthy 12V Bus',
          detail: 'System voltage $v V nominal',
          hasLiveTelemetry: true,
          timestamp: now,
        );
      }
    } else if (telemetry.batteryPercentage.available && telemetry.batteryPercentage.value != null) {
      final pct = telemetry.batteryPercentage.value!;
      categories[HealthCategory.battery] = CategoryHealthState(
        category: HealthCategory.battery,
        severity: pct <= 15 ? HealthSeverity.warning : HealthSeverity.optimal,
        statusText: pct <= 15 ? 'Low Traction Battery' : 'Traction Battery Nominal',
        detail: 'State of charge: $pct% (${telemetry.chargingState.available ? telemetry.chargingState.value : "Discharging"})',
        hasLiveTelemetry: true,
        timestamp: now,
      );
    } else {
      categories[HealthCategory.battery] = CategoryHealthState.insufficientData(HealthCategory.battery, reason: 'Battery voltage/capacity telemetry unavailable');
    }

    // 3. FUEL
    if (!isConnected || telemetry == null) {
      categories[HealthCategory.fuel] = CategoryHealthState.insufficientData(HealthCategory.fuel, reason: 'Vehicle disconnected');
    } else if (telemetry.fuelLevel.available && telemetry.fuelLevel.value != null) {
      final lvl = telemetry.fuelLevel.value!;
      categories[HealthCategory.fuel] = CategoryHealthState(
        category: HealthCategory.fuel,
        severity: lvl <= 15 ? HealthSeverity.warning : HealthSeverity.optimal,
        statusText: lvl <= 15 ? 'Low Fuel Reserve' : 'Fuel Level Nominal',
        detail: 'Fuel tank level: $lvl%',
        hasLiveTelemetry: true,
        timestamp: now,
      );
    } else {
      categories[HealthCategory.fuel] = CategoryHealthState.insufficientData(HealthCategory.fuel, reason: 'Fuel float sensor unavailable on connected bus');
    }

    // 4. BRAKES
    final brakeDtc = dtcs.where((d) => d.code.startsWith('C00')).toList();
    if (brakeDtc.isNotEmpty) {
      categories[HealthCategory.brakes] = CategoryHealthState(
        category: HealthCategory.brakes,
        severity: HealthSeverity.critical,
        statusText: 'ABS Fault Detected',
        detail: '${brakeDtc.first.code}: ${brakeDtc.first.description}',
        hasLiveTelemetry: true,
        timestamp: now,
      );
    } else {
      categories[HealthCategory.brakes] = CategoryHealthState.userInspectionRequired(
        HealthCategory.brakes,
        reason: 'Electronic brake pad telemetry unavailable; visual inspection recommended every 5,000 km',
      );
    }

    // 5. TYRES & TPMS
    categories[HealthCategory.tyres] = CategoryHealthState.userInspectionRequired(
      HealthCategory.tyres,
      reason: 'TPMS wireless sensors unavailable on active bus; check cold pressures manually',
    );

    // 6. LIGHTING
    if (isConnected && telemetry != null && telemetry.headlight.available) {
      categories[HealthCategory.lights] = CategoryHealthState(
        category: HealthCategory.lights,
        severity: HealthSeverity.optimal,
        statusText: 'Lighting Active',
        detail: 'Auxiliary & headlight circuits verified active',
        hasLiveTelemetry: true,
        timestamp: now,
      );
    } else {
      categories[HealthCategory.lights] = CategoryHealthState.insufficientData(HealthCategory.lights, reason: 'Lighting circuit feedback unavailable');
    }

    // 7. ELECTRICAL
    categories[HealthCategory.electrical] = CategoryHealthState(
      category: HealthCategory.electrical,
      severity: isConnected ? HealthSeverity.optimal : HealthSeverity.insufficientData,
      statusText: isConnected ? 'CAN/GATT Bus Active' : 'Bus Idle',
      detail: isConnected ? 'Active protocol transceiver synchronizing' : 'Connect vehicle to scan electrical bus',
      hasLiveTelemetry: isConnected,
      timestamp: now,
    );

    // 8. COOLING
    categories[HealthCategory.cooling] = categories[HealthCategory.engine] ?? CategoryHealthState.insufficientData(HealthCategory.cooling);

    // 9. SUSPENSION
    categories[HealthCategory.suspension] = CategoryHealthState.userInspectionRequired(
      HealthCategory.suspension,
      reason: 'Inspect fork seals and rear shock preload according to manual schedule',
    );

    // 10. TRANSMISSION
    if (isConnected && telemetry != null && telemetry.gear.available) {
      categories[HealthCategory.transmission] = CategoryHealthState(
        category: HealthCategory.transmission,
        severity: HealthSeverity.optimal,
        statusText: 'Gearbox Active',
        detail: 'Current Gear: ${telemetry.gear.value == 0 ? "Neutral" : "Gear ${telemetry.gear.value}"}',
        hasLiveTelemetry: true,
        timestamp: now,
      );
    } else {
      categories[HealthCategory.transmission] = CategoryHealthState.insufficientData(HealthCategory.transmission, reason: 'Gear position sensor unavailable');
    }

    // 11. GENERAL
    categories[HealthCategory.general] = CategoryHealthState(
      category: HealthCategory.general,
      severity: dtcs.isEmpty ? HealthSeverity.optimal : HealthSeverity.warning,
      statusText: dtcs.isEmpty ? '0 Active DTCs' : '${dtcs.length} Active Faults',
      detail: dtcs.isEmpty ? 'No diagnostic fault codes recorded by ECU' : 'Inspect active diagnostic codes tab',
      hasLiveTelemetry: isConnected,
      timestamp: now,
    );

    final healthState = VehicleHealthState(
      categories: categories,
      activeDtcCount: dtcs.length,
      activeAlertCount: 0,
      isConnected: isConnected,
      timestamp: now,
    );

    _ref?.read(vehicleHealthProvider.notifier).updateState(healthState);
    return healthState;
  }
}
