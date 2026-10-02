import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/obd_gateway_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/phase3_validation_controller.dart';

import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Phase 3 Automated Hardware Validation Flow', (WidgetTester tester) async {
    // Add a basic UI to avoid empty widget tree issues (like "No widgets found at Offset" crash)
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: Text('Running Validation...')))));

    // We only execute this if we actually run on a physical device.
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      debugPrint('Not a physical mobile device. Skipping validation.');
      return;
    }

    final StringBuffer report = StringBuffer();
    report.writeln('<<REPORT_START>>');
    report.writeln('# Phase 3 Hardware Validation Report');
    report.writeln('- Timestamp: ${DateTime.now().toIso8601String()}');
    report.writeln('- Android Model: ${Platform.environment['ro.product.model'] ?? 'Unknown'}');
    report.writeln('- Android Version: ${Platform.environment['ro.build.version.release'] ?? 'Unknown'}');
    
    // Check BLE support
    if (!await FlutterBluePlus.isSupported) {
      report.writeln('## Failure');
      report.writeln('BLE not supported on this device.');
      report.writeln('<<REPORT_END>>');
      debugPrint(report.toString());
      fail('BLE not supported');
    }

    // Wait for adapter state
    final state = await FlutterBluePlus.adapterState.firstWhere((s) => s == BluetoothAdapterState.on);
    if (state != BluetoothAdapterState.on) {
      report.writeln('## Failure');
      report.writeln('Bluetooth is not enabled.');
      report.writeln('<<REPORT_END>>');
      debugPrint(report.toString());
      fail('Bluetooth is not enabled');
    }

    // Start Scan
    BluetoothDevice? targetDevice;
    int? rssi;
    List<Guid> advertisedServices = [];
    
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    
    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        // Look for typical ELM327 BLE names or standard UART UUIDs
        final name = r.device.platformName.toLowerCase();
        if (name.contains('obd') || name.contains('elm327') || name.contains('vlink')) {
          targetDevice = r.device;
          rssi = r.rssi;
          advertisedServices = r.advertisementData.serviceUuids;
          break;
        }
      }
      if (targetDevice != null) break;
    }
    
    await FlutterBluePlus.stopScan();

    if (targetDevice == null) {
      report.writeln('## Failure');
      report.writeln('No real ELM327 / OBD BLE device detected in scan.');
      report.writeln('<<REPORT_END>>');
      debugPrint(report.toString());
      fail('No ELM327 device found');
    }

    report.writeln('- Adapter Identity: ${targetDevice.platformName} (${targetDevice.remoteId})');
    report.writeln('- RSSI: $rssi');
    report.writeln('- Advertised Services: $advertisedServices');

    // Attempt connection and validation using the controller
    final adapter = ObdGatewayAdapter();
    final controller = Phase3ValidationController(adapter);
    
    final controllerReport = await controller.runValidation(targetDevice.remoteId.str);
    report.writeln(controllerReport);
    
    debugPrint(report.toString());
  });
}
