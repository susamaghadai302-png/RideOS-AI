import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';
import 'package:rideos_mobile/core/hardware/transports/hardware_transport.dart';
import 'package:rideos_mobile/core/safety/models/sensor_fusion_state.dart';
import 'package:rideos_mobile/core/safety/models/rider_alert.dart';
import 'package:rideos_mobile/features/maps/domain/models/ride_route_models.dart';

class RideAIContext {
  final DateTime snapshotTimestamp;
  final VehicleTelemetry telemetry;
  final HardwareTransportState connectivityState;
  final SensorFusionState sensorState;
  final List<RiderAlert> activeAlerts;
  final RideRouteResponse? currentRoute;
  final String weatherState;
  final double gpsQualityConfidence;

  const RideAIContext({
    required this.snapshotTimestamp,
    required this.telemetry,
    required this.connectivityState,
    required this.sensorState,
    required this.activeAlerts,
    this.currentRoute,
    required this.weatherState,
    required this.gpsQualityConfidence,
  });

  factory RideAIContext.empty() {
    return RideAIContext(
      snapshotTimestamp: DateTime.now(),
      telemetry: VehicleTelemetry.empty(),
      connectivityState: HardwareTransportState.disconnected,
      sensorState: SensorFusionState.insufficientData,
      activeAlerts: [],
      currentRoute: null,
      weatherState: 'UNAVAILABLE',
      gpsQualityConfidence: 0.0,
    );
  }
}
