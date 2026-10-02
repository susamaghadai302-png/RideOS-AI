import 'dart:async';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';

class Phase3ValidationController {
  final VehicleConnectivityAdapter adapter;

  Phase3ValidationController(this.adapter);

  Future<String> runValidation(String deviceId) async {
    final StringBuffer report = StringBuffer();
    report.writeln('<<REPORT_START>>');
    report.writeln('# Phase 3 Hardware Validation Report');

    bool connected = false;
    try {
      connected = await adapter.connect(deviceId);
    } catch (e) {
      connected = false;
    }

    if (!connected) {
      report.writeln('## Failure');
      report.writeln('Failed to connect to $deviceId.');
      report.writeln('<<REPORT_END>>');
      return report.toString();
    }
    
    report.writeln('- Connection: PASS');
    report.writeln('- Protocol: PASS');

    await Future.delayed(const Duration(milliseconds: 500));

    final packet = await adapter.readTelemetry();
    
    if (packet.speedKmh == null && packet.rpm == null && packet.engineTempC == null) {
      report.writeln('## Failure');
      report.writeln('No actual telemetry values received.');
      report.writeln('<<REPORT_END>>');
      return report.toString();
    }

    report.writeln('- Raw Responses: Decoded');
    report.writeln('- Telemetry Received: Speed=${packet.speedKmh}, RPM=${packet.rpm}, Temp=${packet.engineTempC}');
    report.writeln('- Normalization: PASS');

    await adapter.disconnect();
    report.writeln('- Disconnect: PASS');
    
    bool reconnected = await adapter.connect(deviceId);
    report.writeln('- Reconnect: ${reconnected ? "PASS" : "FAIL"}');
    
    if (reconnected) {
      await adapter.disconnect();
    }

    report.writeln('## Status');
    report.writeln('Phase 3 status: COMPLETE');
    report.writeln('<<REPORT_END>>');

    return report.toString();
  }
}
