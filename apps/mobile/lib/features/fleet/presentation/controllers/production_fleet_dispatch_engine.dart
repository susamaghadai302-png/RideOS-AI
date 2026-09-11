import 'dart:async';
import 'dart:developer' as developer;

class FleetRiderVehicleState {
  final String riderId;
  final String riderName;
  final String vehicleVin;
  final double currentLatitude;
  final double currentLongitude;
  final double speedKmh;
  final double batteryPct;
  final String geofenceZoneStatus;

  const FleetRiderVehicleState({
    required this.riderId,
    required this.riderName,
    required this.vehicleVin,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.speedKmh,
    required this.batteryPct,
    required this.geofenceZoneStatus,
  });
}

class ProductionFleetDispatchEngine {
  static final ProductionFleetDispatchEngine instance = ProductionFleetDispatchEngine._internal();
  ProductionFleetDispatchEngine._internal();

  final _fleetStreamController = StreamController<List<FleetRiderVehicleState>>.broadcast();

  Stream<List<FleetRiderVehicleState>> get fleetStream => _fleetStreamController.stream;

  List<FleetRiderVehicleState> fetchActiveSquadFleet() {
    developer.log('Fleet telemetry backend not configured. Returning empty fleet state.', name: 'RideOS.FleetDispatch');
    const List<FleetRiderVehicleState> squad = [];
    _fleetStreamController.add(squad);
    return squad;
  }

  void broadcastFleetDispatchAlert({required String alertMessage, required String priorityLevel}) {
    developer.log('FLEET DISPATCH BROADCAST [$priorityLevel]: "$alertMessage"', name: 'RideOS.FleetAlert');
  }

  void dispose() {
    _fleetStreamController.close();
  }
}
