import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import '../models/active_vehicle_context.dart';
import '../models/vehicle_profile.dart';
import '../models/vehicle_identity.dart';
import '../services/vehicle_model_resolver.dart';
import '../services/data_freshness_policy.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../../../features/vehicle/presentation/bloc/vehicle_bloc.dart';
import '../../../features/vehicle/presentation/bloc/vehicle_event.dart';

final activeVehicleContextProvider =
    StateNotifierProvider<ActiveVehicleContextNotifier, ActiveVehicleContext>((ref) {
  return ActiveVehicleContextNotifier();
});

class ActiveVehicleContextNotifier extends StateNotifier<ActiveVehicleContext> {
  final VehicleBloc? _vehicleBloc;
  StreamSubscription<NormalizedTelemetry>? _telemetrySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription? _blocSub;
  final VehicleModelResolver _modelResolver = VehicleModelResolver();
  DateTime? _lastPacketTime;

  ActiveVehicleContextNotifier({VehicleBloc? vehicleBloc})
      : _vehicleBloc = vehicleBloc ?? _resolveBlocSafe(),
        super(vehicleBloc?.state.activeContext ?? _resolveInitialContext()) {
    _initListeners();
  }

  static VehicleBloc? _resolveBlocSafe() {
    try {
      if (GetIt.instance.isRegistered<VehicleBloc>()) {
        return GetIt.instance<VehicleBloc>();
      }
    } catch (_) {}
    return null;
  }

  static ActiveVehicleContext _resolveInitialContext() {
    final bloc = _resolveBlocSafe();
    return bloc?.state.activeContext ?? ActiveVehicleContext.empty();
  }

  void _initListeners() {
    if (_vehicleBloc != null) {
      _blocSub = _vehicleBloc!.stream.listen((blocState) {
        state = blocState.activeContext;
      });
    }
    _initBluetoothListeners();
  }

  void _initBluetoothListeners() {
    _telemetrySub = BluetoothEngine().telemetryStream.listen((telemetry) {
      _lastPacketTime = DateTime.now();
      final quality = DataFreshnessPolicy.evaluate(
        lastPacketTime: _lastPacketTime,
        isConnected: state.isConnected,
      );

      state = state.copyWith(
        telemetry: telemetry,
        telemetryQuality: quality,
        lastUpdated: DateTime.now(),
      );
    });

    _connSub = BluetoothEngine().connectionManager.stateStream.stream.listen((connState) {
      final status = _mapConnectionState(connState);
      state = state.copyWith(
        connectionStatus: status,
        telemetryQuality: status == VehicleConnectionStatus.connected
            ? state.telemetryQuality
            : TelemetryQuality.unavailable,
        lastUpdated: DateTime.now(),
      );
    });
  }

  VehicleConnectionStatus _mapConnectionState(BluetoothConnectionState connState) {
    switch (connState) {
      case BluetoothConnectionState.connected:
        return VehicleConnectionStatus.connected;
      case BluetoothConnectionState.disconnected:
        return VehicleConnectionStatus.disconnected;
    }
  }

  /// Atomically switches the active vehicle context using canonical VehicleIdentity
  void switchIdentity(VehicleIdentity identity) {
    final modelRes = _modelResolver.resolveIdentity(identity);
    _lastPacketTime = null;

    state = ActiveVehicleContext(
      vehicleId: identity.sessionConnectionId,
      profile: null,
      identity: identity,
      connectionStatus: VehicleConnectionStatus.connected,
      modelStatus: modelRes.status,
      modelResolutionStatus: modelRes.resolutionStatus,
      model3DPath: modelRes.modelPath,
      supportedCapabilities: const ['telemetry', 'diagnostics', 'navigation'],
      telemetry: NormalizedTelemetry.empty(),
      telemetryQuality: TelemetryQuality.unavailable,
      activeDtcCodes: const [],
      activeTripId: null,
      lastUpdated: DateTime.now(),
    );
    _vehicleBloc?.add(SwitchVehicleIdentityEvent(identity));
  }

  /// Atomically switches the active vehicle context without cross-vehicle state leakage
  void switchVehicle(VehicleProfile profile) {
    final modelRes = _modelResolver.resolve(profile);
    _lastPacketTime = null;

    state = ActiveVehicleContext(
      vehicleId: profile.id,
      profile: profile,
      identity: null,
      connectionStatus: state.connectionStatus,
      modelStatus: modelRes.status,
      modelResolutionStatus: modelRes.resolutionStatus,
      model3DPath: modelRes.modelPath,
      supportedCapabilities: profile.specifications.keys.toList(),
      telemetry: NormalizedTelemetry.empty(),
      telemetryQuality: TelemetryQuality.unavailable,
      activeDtcCodes: const [],
      activeTripId: null,
      lastUpdated: DateTime.now(),
    );
    _vehicleBloc?.add(SwitchVehicleEvent(profile));
  }

  /// Purges all vehicle-specific session state, 3D paths, and cached data
  void disconnectAndPurge() {
    _lastPacketTime = null;
    state = ActiveVehicleContext.empty();
    _vehicleBloc?.add(const DisconnectAndPurgeVehicleEvent());
  }

  void setActiveTrip(String? tripId) {
    state = state.copyWith(activeTripId: tripId, lastUpdated: DateTime.now());
    _vehicleBloc?.add(SetActiveTripEvent(tripId));
  }

  void setActiveDtcCodes(List<String> dtcCodes) {
    state = state.copyWith(activeDtcCodes: dtcCodes, lastUpdated: DateTime.now());
    _vehicleBloc?.add(SetActiveDtcCodesEvent(dtcCodes));
  }

  @override
  void dispose() {
    _blocSub?.cancel();
    _telemetrySub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
