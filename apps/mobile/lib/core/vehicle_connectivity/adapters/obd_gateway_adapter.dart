import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_connectivity_adapter.dart';
import 'dart:io';
import 'ble_transport.dart';
import 'uart_transport.dart';

/// Standard SAE J1979 / ISO 15765-4 OBD-II Diagnostic Gateway Adapter
class ObdGatewayAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId = 'obd2_gateway_standard';
  @override
  final String adapterName = 'Standard OBD-II / ELM327 Gateway Adapter';
  @override
  final String version = '1.2.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.obd2Gateway;
  @override
  final VehicleCapabilities capabilities = VehicleCapabilities.standardObdGateway();

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  late final UartTransport _transport;
  StreamSubscription? _transportSub;

  Timer? _pollingTimer;

  ObdGatewayAdapter({UartTransport? transport}) {
    _transport = transport ?? BleTransport();
  }

  @override
  AdapterConnectionState get connectionState => _currentState;

  @override
  Stream<AdapterConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => _telemetryController.stream;

  void _updateState(AdapterConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async {
    _updateState(AdapterConnectionState.discovering);
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _updateState(AdapterConnectionState.error);
      return false;
    }
    if (!await FlutterBluePlus.isSupported) {
      _updateState(AdapterConnectionState.error);
      return false;
    }
    final adapterState = await FlutterBluePlus.adapterState.firstWhere((s) => s == BluetoothAdapterState.on, orElse: () => BluetoothAdapterState.off);
    if (adapterState != BluetoothAdapterState.on) {
      _updateState(AdapterConnectionState.error);
      return false;
    }
    _updateState(AdapterConnectionState.disconnected);
    return true; // BLE is available
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _updateState(AdapterConnectionState.connecting);
    final success = await _transport.connect(targetIdentifier);
    if (!success) {
      _updateState(AdapterConnectionState.error);
      return false;
    }

    _updateState(AdapterConnectionState.authenticating);
    // Initialize ELM327
    await _sendElm327Command('ATZ');
    await Future.delayed(const Duration(milliseconds: 500));
    await _sendElm327Command('ATE0'); // Echo off
    await _sendElm327Command('ATL0'); // Linefeeds off
    await _sendElm327Command('ATSP0'); // Auto protocol

    _transportSub = _transport.dataStream.listen(_onDataReceived);

    _updateState(AdapterConnectionState.connected);
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollTelemetry());
    return true;
  }

  Future<void> _sendElm327Command(String cmd) async {
    await _transport.write('$cmd\r');
    await Future.delayed(const Duration(milliseconds: 100)); // Rate limit
  }

  String _rxBuffer = '';

  void _onDataReceived(String data) {
    _rxBuffer += data;
    if (_rxBuffer.contains('>')) {
      final responses = _rxBuffer.split('>');
      for (int i = 0; i < responses.length - 1; i++) {
        _processResponse(responses[i].trim().replaceAll('\r', ''));
      }
      _rxBuffer = responses.last;
    }
  }

  int? _lastSpeed;
  int? _lastRpm;
  int? _lastTemp;
  int? _lastThrottle;
  int? _lastIntakeTemp;
  int? _lastMap;

  void _processResponse(String response) {
    // Basic OBD parser
    response = response.replaceAll(' ', '');
    if (response.startsWith('410D') && response.length >= 6) {
      // Speed (PID 0D)
      _lastSpeed = int.tryParse(response.substring(4, 6), radix: 16);
    } else if (response.startsWith('410C') && response.length >= 8) {
      // RPM (PID 0C)
      final a = int.tryParse(response.substring(4, 6), radix: 16) ?? 0;
      final b = int.tryParse(response.substring(6, 8), radix: 16) ?? 0;
      _lastRpm = ((a * 256) + b) ~/ 4;
    } else if (response.startsWith('4105') && response.length >= 6) {
      // Coolant Temp (PID 05)
      final a = int.tryParse(response.substring(4, 6), radix: 16) ?? 0;
      _lastTemp = a - 40;
    } else if (response.startsWith('4111') && response.length >= 6) {
      // Throttle Position (PID 11)
      final a = int.tryParse(response.substring(4, 6), radix: 16) ?? 0;
      _lastThrottle = (a * 100) ~/ 255;
    } else if (response.startsWith('410F') && response.length >= 6) {
      // Intake Air Temp (PID 0F)
      final a = int.tryParse(response.substring(4, 6), radix: 16) ?? 0;
      _lastIntakeTemp = a - 40;
    } else if (response.startsWith('410B') && response.length >= 6) {
      // MAP (PID 0B)
      _lastMap = int.tryParse(response.substring(4, 6), radix: 16);
    }
  }

  Future<void> _pollTelemetry() async {
    if (_currentState != AdapterConnectionState.connected) return;
    await _sendElm327Command('010D'); // Speed
    await _sendElm327Command('010C'); // RPM
    await _sendElm327Command('0105'); // Temp
    await _sendElm327Command('0111'); // Throttle
    await _sendElm327Command('010F'); // Intake Air Temp
    await _sendElm327Command('010B'); // MAP
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async {
    return true; // No extra auth for ELM327 over BLE
  }

  @override
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await _transportSub?.cancel();
    await _transport.disconnect();
    _updateState(AdapterConnectionState.disconnected);
  }

  @override
  VehicleCapabilities getCapabilities() => capabilities;

  @override
  Future<RawVehicleTelemetryPacket> readTelemetry() async {
    if (_currentState != AdapterConnectionState.connected) {
      return RawVehicleTelemetryPacket(
        timestamp: DateTime.now(),
        speedKmh: null,
        rpm: null,
        batteryVoltage: null,
        engineTempC: null,
        fuelLevelPct: null,
        throttlePositionPct: null,
        intakeAirTempC: null,
        manifoldAbsolutePressureKpa: null,
      );
    }
    return RawVehicleTelemetryPacket(
      timestamp: DateTime.now(),
      speedKmh: _lastSpeed?.toDouble(),
      rpm: _lastRpm?.toDouble(),
      batteryVoltage: null,
      engineTempC: _lastTemp?.toDouble(),
      fuelLevelPct: null,
      throttlePositionPct: _lastThrottle?.toDouble(),
      intakeAirTempC: _lastIntakeTemp?.toDouble(),
      manifoldAbsolutePressureKpa: _lastMap?.toDouble(),
    );
  }

  @override
  Future<List<String>> readDiagnostics() async {
    // Read DTCs (Mode 03)
    await _sendElm327Command('03');
    await Future.delayed(const Duration(seconds: 1)); // Wait for response
    return []; // A proper parser would extract DTCs from _rxBuffer
  }

  @override
  Future<bool> sendNavigationManeuver({
    required String turnInstruction,
    required double distanceToTurnMeters,
    required int maneuverIconCode,
  }) async {
    return false; // OBD-II standard does not support cluster display write
  }

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    return false;
  }

  @override
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_currentState != AdapterConnectionState.connected) return false;
    if (commandName == 'clear_dtc') {
      await _sendElm327Command('04'); // Mode 04 Clear DTC request
      return true;
    }
    return false;
  }
}
