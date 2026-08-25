import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../../vehicle_commands/models/vehicle_command.dart';
import '../../vehicle_commands/models/command_result.dart';
import '../../vehicle_commands/services/vehicle_command_pipeline.dart';
import '../models/diagnostic_item.dart';

final activeDiagnosticsProvider = StateNotifierProvider<DiagnosticNotifier, List<DiagnosticItem>>((ref) {
  return DiagnosticNotifier();
});

class DiagnosticNotifier extends StateNotifier<List<DiagnosticItem>> {
  DiagnosticNotifier() : super([]);

  void setDiagnostics(List<DiagnosticItem> items) {
    state = items;
  }

  void addOrUpdate(DiagnosticItem item) {
    final idx = state.indexWhere((e) => e.code == item.code && e.active);
    if (idx >= 0) {
      final updated = List<DiagnosticItem>.from(state);
      updated[idx] = item;
      state = updated;
    } else {
      state = [item, ...state];
    }
  }

  void clearAll() {
    state = [];
  }
}

class DiagnosticManager {
  static final DiagnosticManager _instance = DiagnosticManager._internal();
  factory DiagnosticManager() => _instance;
  DiagnosticManager._internal();

  static const Map<String, Map<String, dynamic>> _saeDtcDictionary = {
    'P0100': {'desc': 'Mass or Volume Air Flow Circuit Malfunction', 'sev': DiagnosticSeverity.warning},
    'P0117': {'desc': 'Engine Coolant Temperature Circuit Low Input', 'sev': DiagnosticSeverity.warning},
    'P0118': {'desc': 'Engine Coolant Temperature Circuit High Input', 'sev': DiagnosticSeverity.warning},
    'P0122': {'desc': 'Throttle Position Sensor Circuit Low Input', 'sev': DiagnosticSeverity.warning},
    'P0123': {'desc': 'Throttle Position Sensor Circuit High Input', 'sev': DiagnosticSeverity.warning},
    'P0130': {'desc': 'O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)', 'sev': DiagnosticSeverity.notice},
    'P0135': {'desc': 'O2 Sensor Heater Circuit Malfunction', 'sev': DiagnosticSeverity.notice},
    'P0171': {'desc': 'System Too Lean (Bank 1)', 'sev': DiagnosticSeverity.warning},
    'P0172': {'desc': 'System Too Rich (Bank 1)', 'sev': DiagnosticSeverity.warning},
    'P0201': {'desc': 'Injector Circuit Malfunction — Cylinder 1', 'sev': DiagnosticSeverity.critical},
    'P0300': {'desc': 'Random/Multiple Cylinder Misfire Detected', 'sev': DiagnosticSeverity.critical},
    'P0301': {'desc': 'Cylinder 1 Misfire Detected', 'sev': DiagnosticSeverity.critical},
    'P0302': {'desc': 'Cylinder 2 Misfire Detected', 'sev': DiagnosticSeverity.critical},
    'P0335': {'desc': 'Crankshaft Position Sensor A Circuit Malfunction', 'sev': DiagnosticSeverity.critical},
    'P0340': {'desc': 'Camshaft Position Sensor Circuit Malfunction', 'sev': DiagnosticSeverity.critical},
    'P0420': {'desc': 'Catalyst System Efficiency Below Threshold', 'sev': DiagnosticSeverity.notice},
    'P0500': {'desc': 'Vehicle Speed Sensor Malfunction', 'sev': DiagnosticSeverity.warning},
    'P0562': {'desc': 'System Voltage Low (< 11.5V)', 'sev': DiagnosticSeverity.warning},
    'P0563': {'desc': 'System Voltage High (> 15.5V)', 'sev': DiagnosticSeverity.critical},
    'P0606': {'desc': 'ECU / ECM Processor Fault', 'sev': DiagnosticSeverity.critical},
    'C0035': {'desc': 'Left Front Wheel Speed Sensor Circuit Fault (ABS)', 'sev': DiagnosticSeverity.warning},
    'C0040': {'desc': 'Right Front Wheel Speed Sensor Circuit Fault (ABS)', 'sev': DiagnosticSeverity.warning},
    'U0100': {'desc': 'Lost Communication with ECM / Engine Controller', 'sev': DiagnosticSeverity.critical},
    'U0121': {'desc': 'Lost Communication with ABS Control Module', 'sev': DiagnosticSeverity.critical},
  };

  WidgetRef? _ref;
  final List<DiagnosticItem> _history = [];
  List<DiagnosticItem> get diagnosticHistory => List.unmodifiable(_history);

  void initialize(WidgetRef ref) {
    _ref = ref;
    _listenToTelemetry();
  }

  void _listenToTelemetry() {
    BluetoothEngine().telemetryStream.listen((telemetry) {
      if (telemetry.faultCodes.available && telemetry.faultCodes.value != null) {
        final codes = telemetry.faultCodes.value!;
        for (final code in codes) {
          if (code.trim().isNotEmpty) {
            recordFaultCode(code.trim(), source: 'Vehicle ECU (Live Stream)');
          }
        }
      }
    });
  }

  /// Parses and records a diagnostic fault code from ECU or OBD bus
  DiagnosticItem recordFaultCode(String code, {String source = 'Vehicle ECU', String vehicleId = 'active_vehicle'}) {
    final cleanCode = code.toUpperCase().trim();
    final dictEntry = _saeDtcDictionary[cleanCode];

    final description = dictEntry != null
        ? (dictEntry['desc'] as String)
        : 'Unknown diagnostic code — manufacturer documentation required.';

    final severity = dictEntry != null
        ? (dictEntry['sev'] as DiagnosticSeverity)
        : DiagnosticSeverity.notice;

    final existingIdx = _history.indexWhere((e) => e.code == cleanCode && e.active);
    final now = DateTime.now();

    DiagnosticItem item;
    if (existingIdx >= 0) {
      final old = _history[existingIdx];
      item = old.copyWith(
        occurrences: old.occurrences + 1,
        lastSeen: now,
      );
      _history[existingIdx] = item;
    } else {
      item = DiagnosticItem(
        id: 'dtc_${now.microsecondsSinceEpoch}',
        vehicleId: vehicleId,
        code: cleanCode,
        source: source,
        severity: severity,
        description: description,
        firstSeen: now,
        lastSeen: now,
        occurrences: 1,
        active: true,
        resolved: false,
      );
      _history.insert(0, item);
    }

    _ref?.read(activeDiagnosticsProvider.notifier).addOrUpdate(item);
    return item;
  }

  /// Clears DTC fault codes ONLY if the active protocol adapter supports the clear command
  Future<CommandResult> clearDiagnosticFaults() async {
    final engine = BluetoothEngine();
    final adapter = engine.currentAdapter;

    if (adapter == null || !adapter.capabilities.hasControl(ControlCapability.clearFaultCodes)) {
      return CommandResult.unsupported(
        commandId: 'dtc_clear_${DateTime.now().millisecondsSinceEpoch}',
        reason: 'ECU fault clearing is not supported or prohibited on the active protocol interface',
      );
    }

    final cmd = VehicleCommand(type: VehicleCommandType.clearFaultCodes);
    final result = await VehicleCommandPipeline().execute(cmd);

    if (result.isSuccess) {
      for (int i = 0; i < _history.length; i++) {
        if (_history[i].active) {
          _history[i] = _history[i].copyWith(active: false, resolved: true);
        }
      }
      _ref?.read(activeDiagnosticsProvider.notifier).clearAll();
    }

    return result;
  }
}
