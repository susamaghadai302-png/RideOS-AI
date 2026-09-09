import 'package:equatable/equatable.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/models/vehicle_identity.dart';
import '../../../../core/vehicle_resolution/models/active_vehicle_context.dart';
import '../../../../core/vehicle_protocols/models/normalized_telemetry.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on startup to load saved vehicles from the repository
class LoadVehiclesEvent extends VehicleEvent {
  const LoadVehiclesEvent();
}

/// Atomically switches the active vehicle using a full VehicleProfile
class SwitchVehicleEvent extends VehicleEvent {
  final VehicleProfile profile;

  const SwitchVehicleEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Atomically switches the active vehicle using canonical VehicleIdentity (e.g. from BLE/OBD scan)
class SwitchVehicleIdentityEvent extends VehicleEvent {
  final VehicleIdentity identity;

  const SwitchVehicleIdentityEvent(this.identity);

  @override
  List<Object?> get props => [identity];
}

/// Real-time incoming telemetry packet from vehicle gateway / bluetooth engine
class VehicleTelemetryUpdatedEvent extends VehicleEvent {
  final NormalizedTelemetry telemetry;

  const VehicleTelemetryUpdatedEvent(this.telemetry);

  @override
  List<Object?> get props => [telemetry];
}

/// Real-time connection status change from physical transport gateway
class VehicleConnectionStatusChangedEvent extends VehicleEvent {
  final VehicleConnectionStatus status;

  const VehicleConnectionStatusChangedEvent(this.status);

  @override
  List<Object?> get props => [status];
}

/// Selects active motorcycle by ID (garage / showroom workflow)
class SelectActiveMotorcycleEvent extends VehicleEvent {
  final String bikeId;

  const SelectActiveMotorcycleEvent(this.bikeId);

  @override
  List<Object?> get props => [bikeId];
}

/// Adds a new vehicle profile to the owned fleet
class AddVehicleEvent extends VehicleEvent {
  final VehicleProfile profile;

  const AddVehicleEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Removes a vehicle profile from the owned fleet
class RemoveVehicleEvent extends VehicleEvent {
  final String vehicleId;

  const RemoveVehicleEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

/// Updates active trip ID on current vehicle context
class SetActiveTripEvent extends VehicleEvent {
  final String? tripId;

  const SetActiveTripEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Updates active diagnostic trouble codes on current vehicle context
class SetActiveDtcCodesEvent extends VehicleEvent {
  final List<String> dtcCodes;

  const SetActiveDtcCodesEvent(this.dtcCodes);

  @override
  List<Object?> get props => [dtcCodes];
}

/// Purges all vehicle-specific session state, 3D paths, and cached telemetry (zero leakage)
class DisconnectAndPurgeVehicleEvent extends VehicleEvent {
  const DisconnectAndPurgeVehicleEvent();
}
