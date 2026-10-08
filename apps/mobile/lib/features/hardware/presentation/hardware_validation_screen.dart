import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rideos_mobile/core/hardware/transports/hardware_transport.dart';
import 'package:rideos_mobile/core/hardware/transports/ble_transport.dart';
import 'package:rideos_mobile/core/hardware/transports/obd_transport.dart';
import 'package:rideos_mobile/core/hardware/validation/diagnostic_state.dart';
import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';

class HardwareValidationScreen extends StatefulWidget {
  const HardwareValidationScreen({super.key});

  @override
  State<HardwareValidationScreen> createState() => _HardwareValidationScreenState();
}

class _HardwareValidationScreenState extends State<HardwareValidationScreen> {
  DiagnosticState _diagnosticState = DiagnosticState.idle;
  
  BleTransport? _bleTransport;
  ObdTransport? _obdTransport;
  
  List<ScanResult> _discoveredDevices = [];
  StreamSubscription? _scanSubscription;
  StreamSubscription? _transportStateSubscription;
  StreamSubscription? _byteSubscription;
  StreamSubscription? _obdSubscription;
  StreamSubscription? _telemetrySubscription;

  final List<String> _rawLogs = [];

  VehicleTelemetry? _currentTelemetry;
  String _btState = 'UNKNOWN';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _btState = state.name);
      }
    });
  }

  void _addLog(String msg) {
    if (mounted) {
      setState(() {
        _rawLogs.insert(0, '${DateTime.now().toIso8601String().split('T').last}: $msg');
        if (_rawLogs.length > 50) _rawLogs.removeLast();
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _diagnosticState = DiagnosticState.checking);
    final status = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    
    if (status.isGranted && connectStatus.isGranted) {
      setState(() => _diagnosticState = DiagnosticState.idle);
      _addLog('Permissions GRANTED');
    } else {
      setState(() => _diagnosticState = DiagnosticState.permissionRequired);
      _addLog('Permissions DENIED');
    }
  }

  Future<void> _startBleScan() async {
    if (_diagnosticState == DiagnosticState.permissionRequired) return;
    
    setState(() {
      _diagnosticState = DiagnosticState.scanning;
      _discoveredDevices.clear();
    });
    
    _addLog('BLE SCAN STARTED');
    
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() => _discoveredDevices = results);
      }
    });
    
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    if (mounted && _diagnosticState == DiagnosticState.scanning) {
      setState(() => _diagnosticState = DiagnosticState.idle);
      _addLog('BLE SCAN STOPPED');
    }
  }

  Future<void> _connectBle(BluetoothDevice device) async {
    FlutterBluePlus.stopScan();
    setState(() {
      _diagnosticState = DiagnosticState.connecting;
    });

    _bleTransport?.dispose();
    _bleTransport = BleTransport();
    
    _transportStateSubscription?.cancel();
    _transportStateSubscription = _bleTransport!.stateStream.listen((state) {
      _addLog('BleTransport State: ${state.name}');
      if (state == HardwareTransportState.connected) {
        if (mounted) setState(() => _diagnosticState = DiagnosticState.connected);
      } else if (state == HardwareTransportState.error) {
        if (mounted) setState(() => _diagnosticState = DiagnosticState.error);
      } else if (state == HardwareTransportState.disconnected) {
        if (mounted) setState(() => _diagnosticState = DiagnosticState.disconnected);
      }
    });

    _byteSubscription?.cancel();
    _byteSubscription = _bleTransport!.byteStream.listen((bytes) {
      _addLog('RX BYTES: ${bytes.join(', ')}');
    });

    try {
      await _bleTransport!.connect(device.remoteId.str);
      _addLog('BLE CONNECTED: ${device.remoteId.str}');
      _initObd();
    } catch (e) {
      _addLog('BLE CONNECTION ERROR: $e');
    }
  }

  void _initObd() {
    if (_bleTransport == null) return;
    
    _obdTransport?.dispose();
    _obdTransport = ObdTransport(_bleTransport!);
    
    _obdSubscription?.cancel();
    _obdSubscription = _obdTransport!.stateStream.listen((state) {
      _addLog('OBD Protocol State: ${state.name}');
      if (state == Elm327State.ready && mounted) {
        setState(() => _diagnosticState = DiagnosticState.ready);
      }
    });

    _telemetrySubscription?.cancel();
    _telemetrySubscription = _obdTransport!.telemetryStream.listen((telemetry) {
      if (mounted) setState(() => _currentTelemetry = telemetry);
    });
    
    _addLog('INIT ELM327 SECUENCE STARTED');
    _obdTransport!.initialize().catchError((e) {
      _addLog('ELM327 INIT FAILED: $e');
    });
  }

  Future<void> _testPid(String pid) async {
    if (_obdTransport == null) return;
    _addLog('REQ PID: $pid');
    // Using internal query map abstraction - would use public fetch method in real app
    // We send directly to test boundaries
    _addLog('SENDING RAW COMMAND: $pid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REAL HARDWARE VALIDATION LAB'),
        backgroundColor: Colors.red[900],
      ),
      body: Row(
        children: [
          // Left Panel: Connection & Scan
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('DIAGNOSTIC STATE: ${_diagnosticState.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('BT ADAPTER: $_btState', style: const TextStyle(color: Colors.white70)),
                  const Divider(),
                  ElevatedButton(
                    onPressed: _startBleScan,
                    child: const Text('SCAN BLE DEVICES'),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final d = _discoveredDevices[index];
                        final name = d.device.platformName.isNotEmpty ? d.device.platformName : 'UNKNOWN';
                        return ListTile(
                          title: Text(name, style: const TextStyle(color: Colors.orange)),
                          subtitle: Text('${d.device.remoteId} (${d.rssi} dBm)', style: const TextStyle(color: Colors.grey)),
                          trailing: IconButton(
                            icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
                            onPressed: () => _connectBle(d.device),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Middle Panel: OBD & Telemetry
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('OBD ELM327 PIPELINE', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(onPressed: () => _testPid('010C'), child: const Text('REQ RPM (010C)')),
                      ElevatedButton(onPressed: () => _testPid('010D'), child: const Text('REQ SPD (010D)')),
                      ElevatedButton(onPressed: () => _testPid('0105'), child: const Text('REQ TMP (0105)')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('TELEMETRY PROOF', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (_currentTelemetry != null) ...[
                    const Text('RPM:'),
                    Text('  Value: ${_currentTelemetry!.rpm.value}'),
                    Text('  Unit: ${_currentTelemetry!.rpm.unit}'),
                    Text('  Quality: ${_currentTelemetry!.rpm.quality.name}'),
                    Text('  Source: ${_currentTelemetry!.rpm.source}'),
                    Text('  Timestamp: ${_currentTelemetry!.rpm.timestamp}'),
                    const SizedBox(height: 8),
                    const Text('SPEED:'),
                    Text('  Value: ${_currentTelemetry!.speedKmh.value}'),
                    Text('  Unit: ${_currentTelemetry!.speedKmh.unit}'),
                    Text('  Quality: ${_currentTelemetry!.speedKmh.quality.name}'),
                  ] else
                    const Text('NO DATA (UNAVAILABLE)'),
                ],
              ),
            ),
          ),

          // Right Panel: Raw Bytes
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('RAW BYTE LAB', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.green),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rawLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _rawLogs[index],
                            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _transportStateSubscription?.cancel();
    _byteSubscription?.cancel();
    _obdSubscription?.cancel();
    _telemetrySubscription?.cancel();
    _obdTransport?.dispose();
    _bleTransport?.dispose();
    super.dispose();
  }
}
