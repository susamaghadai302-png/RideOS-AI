import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/vehicle_resolution/models/active_vehicle_context.dart';
import '../../../../core/vehicle_resolution/services/vehicle_model_resolver.dart';
import '../../../../core/vehicle_resolution/services/data_freshness_policy.dart';
import '../../../../core/vehicle_resolution/repositories/my_vehicles_repository.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/vehicle_protocols/models/normalized_telemetry.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleBlocState> {
  final MyVehiclesRepository _repository;
  final VehicleModelResolver _modelResolver;
  final BluetoothEngine? _bluetoothEngine;

  StreamSubscription<NormalizedTelemetry>? _telemetrySub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  DateTime? _lastPacketTime;

  VehicleBloc({
    MyVehiclesRepository? repository,
    VehicleModelResolver? modelResolver,
    BluetoothEngine? bluetoothEngine,
    bool autoSubscribeBluetooth = true,
  })  : _repository = repository ?? MyVehiclesRepository(),
        _modelResolver = modelResolver ?? VehicleModelResolver(),
        _bluetoothEngine = bluetoothEngine,
        super(VehicleBlocState.initial()) {
    on<LoadVehiclesEvent>(_onLoadVehicles);
    on<SwitchVehicleEvent>(_onSwitchVehicle);
    on<SwitchVehicleIdentityEvent>(_onSwitchVehicleIdentity);
    on<VehicleTelemetryUpdatedEvent>(_onTelemetryUpdated);
    on<VehicleConnectionStatusChangedEvent>(_onConnectionStatusChanged);
    on<SelectActiveMotorcycleEvent>(_onSelectActiveMotorcycle);
    on<AddVehicleEvent>(_onAddVehicle);
    on<RemoveVehicleEvent>(_onRemoveVehicle);
    on<SetActiveTripEvent>(_onSetActiveTrip);
    on<SetActiveDtcCodesEvent>(_onSetActiveDtcCodes);
    on<DisconnectAndPurgeVehicleEvent>(_onDisconnectAndPurge);

    if (autoSubscribeBluetooth) {
      _initBluetoothListeners();
    }
  }

  void _initBluetoothListeners() {
    final engine = _bluetoothEngine ?? BluetoothEngine();
    _telemetrySub = engine.telemetryStream.listen((telemetry) {
      add(VehicleTelemetryUpdatedEvent(telemetry));
    });

    _connSub = engine.connectionManager.stateStream.stream.listen((connState) {
      final status = _mapConnectionState(connState);
      add(VehicleConnectionStatusChangedEvent(status));
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

  Future<void> _onLoadVehicles(
    LoadVehiclesEvent event,
    Emitter<VehicleBlocState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      sourceIdentifier: 'repo_load_start',
    ));
    try {
      final vehicles = await _repository.getOwnedVehicles();
      emit(state.copyWith(
        ownedVehicles: vehicles,
        isLoading: false,
        sourceIdentifier: 'repo_load_success',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        sourceIdentifier: 'repo_load_error',
      ));
    }
  }

  void _onSwitchVehicle(
    SwitchVehicleEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    final modelRes = _modelResolver.resolve(event.profile);
    _lastPacketTime = null;

    final newContext = ActiveVehicleContext(
      vehicleId: event.profile.id,
      profile: event.profile,
      identity: null,
      connectionStatus: state.activeContext.connectionStatus,
      modelStatus: modelRes.status,
      modelResolutionStatus: modelRes.resolutionStatus,
      model3DPath: modelRes.modelPath,
      supportedCapabilities: event.profile.specifications.keys.toList(),
      telemetry: NormalizedTelemetry.empty(),
      telemetryQuality: TelemetryQuality.unavailable,
      activeDtcCodes: const [],
      activeTripId: null,
      lastUpdated: DateTime.now(),
    );

    emit(state.copyWith(
      activeContext: newContext,
      sourceIdentifier: 'user_switch_profile',
    ));
  }

  void _onSwitchVehicleIdentity(
    SwitchVehicleIdentityEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    final modelRes = _modelResolver.resolveIdentity(event.identity);
    _lastPacketTime = null;

    final newContext = ActiveVehicleContext(
      vehicleId: event.identity.sessionConnectionId,
      profile: null,
      identity: event.identity,
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

    emit(state.copyWith(
      activeContext: newContext,
      sourceIdentifier: 'identity_switch',
    ));
  }

  void _onTelemetryUpdated(
    VehicleTelemetryUpdatedEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    _lastPacketTime = DateTime.now();
    final quality = DataFreshnessPolicy.evaluate(
      lastPacketTime: _lastPacketTime,
      isConnected: state.activeContext.isConnected,
    );

    final updatedContext = state.activeContext.copyWith(
      telemetry: event.telemetry,
      telemetryQuality: quality,
      lastUpdated: DateTime.now(),
    );

    emit(state.copyWith(
      activeContext: updatedContext,
      sourceIdentifier: 'ble_telemetry',
    ));
  }

  void _onConnectionStatusChanged(
    VehicleConnectionStatusChangedEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    final status = event.status;
    final updatedContext = state.activeContext.copyWith(
      connectionStatus: status,
      telemetryQuality: status == VehicleConnectionStatus.connected
          ? state.activeContext.telemetryQuality
          : TelemetryQuality.unavailable,
      lastUpdated: DateTime.now(),
    );

    emit(state.copyWith(
      activeContext: updatedContext,
      sourceIdentifier: 'transport_conn_state',
    ));
  }

  void _onSelectActiveMotorcycle(
    SelectActiveMotorcycleEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    if (state.ownedVehicles.isEmpty) return;
    final selected = state.ownedVehicles.firstWhere(
      (v) => v.id == event.bikeId,
      orElse: () => state.ownedVehicles.first,
    );
    add(SwitchVehicleEvent(selected));
  }

  Future<void> _onAddVehicle(
    AddVehicleEvent event,
    Emitter<VehicleBlocState> emit,
  ) async {
    await _repository.addOwnedVehicle(event.profile);
    final updatedList = await _repository.getOwnedVehicles();
    emit(state.copyWith(
      ownedVehicles: updatedList,
      sourceIdentifier: 'vehicle_added',
    ));
  }

  Future<void> _onRemoveVehicle(
    RemoveVehicleEvent event,
    Emitter<VehicleBlocState> emit,
  ) async {
    final updatedList = state.ownedVehicles.where((v) => v.id != event.vehicleId).toList();
    ActiveVehicleContext nextContext = state.activeContext;
    if (state.activeContext.vehicleId == event.vehicleId) {
      _lastPacketTime = null;
      nextContext = ActiveVehicleContext.empty();
    }
    emit(state.copyWith(
      ownedVehicles: updatedList,
      activeContext: nextContext,
      sourceIdentifier: 'vehicle_removed',
    ));
  }

  void _onSetActiveTrip(
    SetActiveTripEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    emit(state.copyWith(
      activeContext: state.activeContext.copyWith(
        activeTripId: event.tripId,
        lastUpdated: DateTime.now(),
      ),
      sourceIdentifier: 'set_active_trip',
    ));
  }

  void _onSetActiveDtcCodes(
    SetActiveDtcCodesEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    emit(state.copyWith(
      activeContext: state.activeContext.copyWith(
        activeDtcCodes: event.dtcCodes,
        lastUpdated: DateTime.now(),
      ),
      sourceIdentifier: 'set_dtc_codes',
    ));
  }

  void _onDisconnectAndPurge(
    DisconnectAndPurgeVehicleEvent event,
    Emitter<VehicleBlocState> emit,
  ) {
    _lastPacketTime = null;
    emit(state.copyWith(
      activeContext: ActiveVehicleContext.empty(),
      sourceIdentifier: 'session_purged',
    ));
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    _connSub?.cancel();
    return super.close();
  }
}
