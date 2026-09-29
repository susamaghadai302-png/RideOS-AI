import 'dart:async';
import 'dart:developer' as developer;

class ProductionRiderSessionModel {
  final String uid;
  final String email;
  final String fullName;
  final String selectedVehicleId;
  final bool isBiometricAuthenticated;
  final DateTime sessionEstablishedAt;

  const ProductionRiderSessionModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.selectedVehicleId,
    required this.isBiometricAuthenticated,
    required this.sessionEstablishedAt,
  });
}

class ProductionTelemetryStreamData {
  final double currentSpeedKmh;
  final double currentRpm;
  final double leanAngleDegrees;
  final double batteryVoltage;
  final double frontTyrePressurePsi;
  final double rearTyrePressurePsi;

  const ProductionTelemetryStreamData({
    required this.currentSpeedKmh,
    required this.currentRpm,
    required this.leanAngleDegrees,
    required this.batteryVoltage,
    required this.frontTyrePressurePsi,
    required this.rearTyrePressurePsi,
  });
}

class ProductionSprint1Engine {
  static final ProductionSprint1Engine instance = ProductionSprint1Engine._internal();
  ProductionSprint1Engine._internal();

  final _telemetryStreamController = StreamController<ProductionTelemetryStreamData>.broadcast();

  Stream<ProductionTelemetryStreamData> get telemetryStream => _telemetryStreamController.stream;

  ProductionRiderSessionModel getCurrentRiderSession() {
    throw StateError('Live rider session is not available from this engine.');
  }

  void startTelemetryStreaming() {
    developer.log(
      'Live telemetry source not connected; no synthetic telemetry will be emitted.',
      name: 'RideOS.Sprint1',
    );
  }
  void dispose() {
    _telemetryStreamController.close();
  }
}
