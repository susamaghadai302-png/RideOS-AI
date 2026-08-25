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
    developer.log('Fetching active production rider session...', name: 'RideOS.Sprint1');
    return ProductionRiderSessionModel(
      uid: 'user_nexus_99812',
      email: '',
      fullName: 'Rider',
      selectedVehicleId: 'veh_bmw_s1000rr_2026',
      isBiometricAuthenticated: true,
      sessionEstablishedAt: DateTime.now(),
    );
  }

  void startTelemetryStreaming() {
    developer.log('Starting live production telemetry streaming...', name: 'RideOS.Sprint1');
    _telemetryStreamController.add(
      const ProductionTelemetryStreamData(
        currentSpeedKmh: 68.5,
        currentRpm: 7200.0,
        leanAngleDegrees: 34.2,
        batteryVoltage: 13.8,
        frontTyrePressurePsi: 36.0,
        rearTyrePressurePsi: 42.0,
      ),
    );
  }

  void dispose() {
    _telemetryStreamController.close();
  }
}
