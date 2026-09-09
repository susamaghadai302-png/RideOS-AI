import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_display_capability.dart';
import '../models/active_vehicle_context.dart';
import '../models/vehicle_profile.dart';

class VehicleConnectionState {
  final VehicleDisplayCapability displayCapability;
  final bool isNavigationReady;
  final bool isGpsReady;
  final bool isCallingAvailable;
  final bool isWeatherConfigured;
  final String connectedDeviceName;

  const VehicleConnectionState({
    required this.displayCapability,
    this.isNavigationReady = false,
    this.isGpsReady = false,
    this.isCallingAvailable = false,
    this.isWeatherConfigured = false,
    this.connectedDeviceName = 'None',
  });

  VehicleConnectionState copyWith({
    VehicleDisplayCapability? displayCapability,
    bool? isNavigationReady,
    bool? isGpsReady,
    bool? isCallingAvailable,
    bool? isWeatherConfigured,
    String? connectedDeviceName,
  }) {
    return VehicleConnectionState(
      displayCapability: displayCapability ?? this.displayCapability,
      isNavigationReady: isNavigationReady ?? this.isNavigationReady,
      isGpsReady: isGpsReady ?? this.isGpsReady,
      isCallingAvailable: isCallingAvailable ?? this.isCallingAvailable,
      isWeatherConfigured: isWeatherConfigured ?? this.isWeatherConfigured,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
    );
  }
}

class VehicleConnectionManager extends Notifier<VehicleConnectionState> {
  @override
  VehicleConnectionState build() {
    return VehicleConnectionState(
      displayCapability: VehicleDisplayCapability.unsupported(),
    );
  }

  void updateConnection(VehicleDisplayCapability capability, String deviceName) {
    state = state.copyWith(
      displayCapability: capability,
      connectedDeviceName: deviceName,
    );
  }

  void setNavigationReady(bool isReady) {
    state = state.copyWith(isNavigationReady: isReady);
  }

  void setGpsReady(bool isReady) {
    state = state.copyWith(isGpsReady: isReady);
  }

  void setCallingAvailable(bool isAvailable) {
    state = state.copyWith(isCallingAvailable: isAvailable);
  }
  
  void setWeatherConfigured(bool isConfigured) {
    state = state.copyWith(isWeatherConfigured: isConfigured);
  }
}

final vehicleConnectionManagerProvider = NotifierProvider<VehicleConnectionManager, VehicleConnectionState>(() {
  return VehicleConnectionManager();
});
