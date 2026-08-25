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
    developer.log('Fetching live fleet squad telematics and geofence status...', name: 'RideOS.FleetDispatch');
    const squad = [
      FleetRiderVehicleState(
        riderId: 'rider_squad_01',
        riderName: 'Alex Mercer (Lead)',
        vehicleVin: '1HD1KAM11KB019942',
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
        speedKmh: 78.5,
        batteryPct: 94.0,
        geofenceZoneStatus: 'INSIDE_SAFE_ZONE',
      ),
      FleetRiderVehicleState(
        riderId: 'rider_squad_02',
        riderName: 'Elena Rostova (Sweep)',
        vehicleVin: 'JKAZX600FFA088214',
        currentLatitude: 37.7752,
        currentLongitude: -122.4189,
        speedKmh: 76.2,
        batteryPct: 88.5,
        geofenceZoneStatus: 'INSIDE_SAFE_ZONE',
      ),
    ];
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
