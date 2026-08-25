import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'protocol_adapter.dart';
import 'models/normalized_telemetry.dart';
import 'models/telemetry_value.dart';
import '../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';

/// Real Motorcycle OBD-II & ELM327 BLE Protocol Adapter
/// Handles direct BLE GATT SPP communication, initialization handshakes,
/// continuous Mode 01 PID polling, Mode 03/07 DTC diagnostics, and Mode 04 clearing.
class Obd2ProtocolAdapter extends ProtocolAdapter {
  final _controller = StreamController<NormalizedTelemetry>.broadcast();
  
  // Standard BLE Serial Port Profile (SPP) UUIDs used by ELM327 / OBDLink / vLinker BLE dongles
  static const String sppServiceUuid = "0000fff0-0000-1000-8000-00805f9b34fb";
  static const String sppRxChar = "0000fff1-0000-1000-8000-00805f9b34fb";
  static const String sppTxChar = "0000fff2-0000-1000-8000-00805f9b34fb";

  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;
  
  Timer? _pollingTimer;
  NormalizedTelemetry _cachedTelemetry = NormalizedTelemetry.empty();

  Obd2ProtocolAdapter() : super('generic_obd2', isDevelopmentOnly: false);

  @override
  VehicleCapabilities get capabilities => const VehicleCapabilities(
    supportedTelemetry: {
      TelemetryCapability.speed,
      TelemetryCapability.rpm,
      TelemetryCapability.coolantTemperature,
      TelemetryCapability.batteryVoltage,
      TelemetryCapability.throttlePosition,
      TelemetryCapability.fuelLevel,
      TelemetryCapability.ambientTemperature,
      TelemetryCapability.faultCodes,
    },
    supportedControls: {
      ControlCapability.clearFaultCodes,
    },
    requiresAuthentication: false,
    supportsStateAcknowledgement: true,
  );

  @override
  Future<bool> identifyDevice(BluetoothDevice device, List<BluetoothService> services) async {
    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == sppServiceUuid.toLowerCase()) return true;
    }
    final name = device.advName.toUpperCase();
    return name.contains('OBD') || name.contains('ELM') || name.contains('VLINK') || name.contains('SCAN');
  }

  @override
  Future<void> discoverCapabilities(BluetoothDevice device, List<BluetoothService> services) async {
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == sppServiceUuid.toLowerCase()) {
        for (var char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == sppRxChar.toLowerCase()) _rxChar = char;
          if (char.uuid.toString().toLowerCase() == sppTxChar.toLowerCase()) _txChar = char;
        }
      }
    }
  }

  @override
  Future<CommandResult> executeCommand(VehicleCommand command) async {
    if (_txChar == null) {
      return CommandResult.unsupported(
        commandId: command.id,
        reason: 'OBD-II SPP transmit characteristic is not connected',
      );
    }

    try {
      switch (command.type) {
        case VehicleCommandType.clearFaultCodes:
          // OBD-II Service 04: Clear DTCs and stored freeze frame data
          const clearCmd = "04\r";
          await _txChar!.write(utf8.encode(clearCmd), withoutResponse: false);
          _cachedTelemetry = _cachedTelemetry.copyWith(
            faultCodes: TelemetryValue.live(<String>[], 'DTC'),
          );
          _controller.add(_cachedTelemetry);
          return CommandResult.success(
            commandId: command.id,
            message: 'OBD-II Mode 04 Clear DTC command transmitted to ECU',
            acknowledged: true,
          );
        default:
          return CommandResult.unsupported(
            commandId: command.id,
            reason: 'Command ${command.type.name} is not an authorized non-invasive OBD-II command',
          );
      }
    } catch (e) {
      return CommandResult.error(
        commandId: command.id,
        status: CommandResultStatus.deviceError,
        message: 'OBD-II bus write failure: $e',
      );
    }
  }

  @override
  Future<void> startTelemetry() async {
    if (_rxChar != null) {
      await _rxChar!.setNotifyValue(true);
      
      String buffer = "";
      
      _rxChar!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          String str = String.fromCharCodes(value);
          buffer += str;
          
          if (buffer.contains('\r') || buffer.contains('>')) {
            _processObdResponse(buffer);
            buffer = "";
          }
        }
      });

      // Send standard ELM327 initialization handshake sequence
      await _initializeElm327();

      // Poll standard motorcycle Mode 01 PIDs continuously every 500ms
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        _queryPid("010C\r"); // PID 0C: Engine RPM
        Future.delayed(const Duration(milliseconds: 60), () => _queryPid("010D\r")); // PID 0D: Vehicle Speed
        Future.delayed(const Duration(milliseconds: 120), () => _queryPid("0105\r")); // PID 05: Coolant Temp
        Future.delayed(const Duration(milliseconds: 180), () => _queryPid("0111\r")); // PID 11: Throttle Position %
        Future.delayed(const Duration(milliseconds: 240), () => _queryPid("012F\r")); // PID 2F: Fuel Level %
        Future.delayed(const Duration(milliseconds: 300), () => _queryPid("010F\r")); // PID 0F: Intake Temp
        Future.delayed(const Duration(milliseconds: 360), () => _queryPid("ATRV\r")); // ELM ATRV: Battery Voltage
        Future.delayed(const Duration(milliseconds: 420), () => _queryPid("0142\r")); // PID 42: Control Module Voltage
      });
    }
  }

  /// Sends standard AT initialization commands to configure ELM327 baudrate, echo, and protocol
  Future<void> _initializeElm327() async {
    await _queryPid("ATZ\r");    // Reset ELM327
    await Future.delayed(const Duration(milliseconds: 300));
    await _queryPid("ATE0\r");   // Echo Off
    await Future.delayed(const Duration(milliseconds: 50));
    await _queryPid("ATL0\r");   // Linefeeds Off
    await Future.delayed(const Duration(milliseconds: 50));
    await _queryPid("ATH0\r");   // Headers Off
    await Future.delayed(const Duration(milliseconds: 50));
    await _queryPid("ATSP0\r");  // Automatic Protocol Selection
    await Future.delayed(const Duration(milliseconds: 100));
    await _queryPid("03\r");     // Query initial Mode 03 DTCs
  }

  Future<void> _queryPid(String pidCmd) async {
    if (_txChar != null) {
      try {
        await _txChar!.write(pidCmd.codeUnits, withoutResponse: false);
      } catch (_) {}
    }
  }

  /// Public entrypoint to process raw ASCII OBD-II string responses from BLE SPP stream
  void processRawResponse(String response) {
    _processObdResponse(response);
  }

  void _processObdResponse(String response) {
    String clean = response
        .replaceAll(' ', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('>', '')
        .toUpperCase();
    
    // Ignore ELM status and searching prompts
    if (clean.isEmpty || clean == 'OK' || clean == 'SEARCHING...' || clean == 'NODATA' || clean.contains('ELM327')) {
      return;
    }

    if (clean.startsWith('410C')) {
      // RPM Response: 41 0C XX YY -> ((XX * 256) + YY) / 4
      if (clean.length >= 8) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        int b = int.tryParse(clean.substring(6, 8), radix: 16) ?? 0;
        int rpm = ((a * 256) + b) ~/ 4;
        _cachedTelemetry = _cachedTelemetry.copyWith(rpm: TelemetryValue.live(rpm, 'RPM'));
      }
    } else if (clean.startsWith('410D')) {
      // Speed Response: 41 0D XX -> XX km/h
      if (clean.length >= 6) {
        int speed = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        _cachedTelemetry = _cachedTelemetry.copyWith(speed: TelemetryValue.live(speed.toDouble(), 'km/h'));
      }
    } else if (clean.startsWith('4105')) {
      // Coolant Temp: 41 05 XX -> XX - 40 C
      if (clean.length >= 6) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 40;
        int temp = a - 40;
        _cachedTelemetry = _cachedTelemetry.copyWith(
          coolantTemperature: TelemetryValue.live(temp, 'C'),
          engineTemperature: TelemetryValue.live(temp, 'C'),
        );
      }
    } else if (clean.startsWith('4111')) {
      // Throttle Position %: 41 11 XX -> (XX * 100) / 255
      if (clean.length >= 6) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        double throttle = double.parse(((a * 100.0) / 255.0).toStringAsFixed(1));
        _cachedTelemetry = _cachedTelemetry.copyWith(throttlePosition: TelemetryValue.live(throttle, '%'));
      }
    } else if (clean.startsWith('412F')) {
      // Fuel Level %: 41 2F XX -> (XX * 100) / 255
      if (clean.length >= 6) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        int fuel = ((a * 100) / 255).round();
        _cachedTelemetry = _cachedTelemetry.copyWith(fuelLevel: TelemetryValue.live(fuel, '%'));
      }
    } else if (clean.startsWith('410F')) {
      // Intake Air Temp: 41 0F XX -> XX - 40 C
      if (clean.length >= 6) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 40;
        int temp = a - 40;
        _cachedTelemetry = _cachedTelemetry.copyWith(ambientTemperature: TelemetryValue.live(temp, 'C'));
      }
    } else if (clean.startsWith('4104')) {
      // Calculated Engine Load %: 41 04 XX -> (XX * 100) / 255
      if (clean.length >= 6) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        double load = double.parse(((a * 100.0) / 255.0).toStringAsFixed(1));
        _cachedTelemetry = _cachedTelemetry.copyWith(
          throttlePosition: _cachedTelemetry.throttlePosition.hasValue
              ? _cachedTelemetry.throttlePosition
              : TelemetryValue.live(load, '%'),
        );
      }
    } else if (clean.startsWith('4100') || clean.startsWith('4120') || clean.startsWith('4140') || clean.startsWith('4160')) {
      // Supported PIDs bitmask response (e.g. 41 00 BE 3F B8 13) -> Valid acknowledgement from ECU
      return;
    } else if (clean.startsWith('4142')) {
      // Control Module Voltage standard Mode 01 PID 42: 41 42 XX YY -> ((XX * 256) + YY) / 1000.0 V
      if (clean.length >= 8) {
        int a = int.tryParse(clean.substring(4, 6), radix: 16) ?? 0;
        int b = int.tryParse(clean.substring(6, 8), radix: 16) ?? 0;
        double volts = double.parse((((a * 256) + b) / 1000.0).toStringAsFixed(2));
        _cachedTelemetry = _cachedTelemetry.copyWith(
          batteryVoltage: TelemetryValue.live(volts, 'V'),
          deviceVoltage: TelemetryValue.live(volts, 'V'),
        );
      }
    } else if (clean.startsWith('43') || clean.startsWith('47')) {
      // DTC Fault Codes: Mode 03 / Mode 07 Response -> 43 XX YY ZZ WW...
      final dtcs = <String>[];
      for (int i = 2; i + 4 <= clean.length; i += 4) {
        final hexChunk = clean.substring(i, i + 4);
        if (hexChunk != '0000') {
          final firstHex = int.tryParse(hexChunk.substring(0, 1), radix: 16) ?? 0;
          final prefix = ['P', 'C', 'B', 'U'][firstHex >> 2];
          final remaining = '${(firstHex & 0x03)}${hexChunk.substring(1)}';
          dtcs.add('$prefix$remaining');
        }
      }
      _cachedTelemetry = _cachedTelemetry.copyWith(faultCodes: TelemetryValue.live(dtcs, 'DTC'));
    } else if (clean.startsWith('44')) {
      // Mode 04 Clear DTC confirmation
      _cachedTelemetry = _cachedTelemetry.copyWith(faultCodes: TelemetryValue.live(<String>[], 'DTC'));
    } else if (clean.contains('V') && !clean.startsWith('4')) {
      // Direct ELM327 ATRV Voltage -> e.g. "12.6V" or "14.2V"
      String voltStr = clean.replaceAll('V', '');
      double? v = double.tryParse(voltStr);
      if (v != null) {
        _cachedTelemetry = _cachedTelemetry.copyWith(
          batteryVoltage: TelemetryValue.live(v, 'V'),
          deviceVoltage: TelemetryValue.live(v, 'V'),
        );
      }
    }

    _controller.add(_cachedTelemetry);
  }

  @override
  Future<void> stopTelemetry() async {
    _pollingTimer?.cancel();
    if (_rxChar != null) {
      try {
        await _rxChar!.setNotifyValue(false);
      } catch (_) {}
    }
  }

  @override
  Future<List<int>> readVehicleData(String capabilityKey) async => [];

  @override
  Future<void> writeCommand(String capabilityKey, List<int> payload) async {
    if (!isSafeToWrite(capabilityKey, payload)) {
      throw Exception("Safety violation: Command is not authorized on motorcycle OBD bus");
    }
    if (_txChar != null) {
      await _txChar!.write(payload, withoutResponse: false);
    }
  }

  @override
  bool isSafeToWrite(String capabilityKey, List<int> payload) {
    // Only non-invasive diagnostic read/query and Mode 04 DTC clearing commands are safe to write
    if (capabilityKey == 'clear_dtc') return true;
    if (capabilityKey == 'query_pid') return true;
    return false; // Default fail-safe: All engine control/actuation writes blocked
  }

  @override
  NormalizedTelemetry parseTelemetry(List<int> rawBytes) => _cachedTelemetry;

  @override
  List<String> getSupportedFeatures() => ['speed', 'rpm', 'coolant_temp', 'voltage', 'throttle', 'fuel', 'diagnostics'];

  @override
  Stream<NormalizedTelemetry> get telemetryStream => _controller.stream;
}
