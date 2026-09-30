import 'dart:async';
import '../models/telemetry_metric_entry.dart';
import '../../vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';
import '../../vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';

class VehicleTelemetryEngine {
  static final VehicleTelemetryEngine _instance = VehicleTelemetryEngine._internal();
  factory VehicleTelemetryEngine() => _instance;

  final _connectivityEngine = GenericVehicleConnectivityEngine();
  final _snapshotController = StreamController<LiveVehicleCockpitSnapshot>.broadcast();

  LiveVehicleCockpitSnapshot _currentSnapshot = LiveVehicleCockpitSnapshot.initialDisconnected();
  LiveVehicleCockpitSnapshot get currentSnapshot => _currentSnapshot;
  Stream<LiveVehicleCockpitSnapshot> get snapshotStream => _snapshotController.stream;

  StreamSubscription? _rawTelemetrySubscription;
  StreamSubscription? _stateSubscription;
  Timer? _staleDataWatchdog;
  bool _isOffline = false;

  VehicleTelemetryEngine._internal() {
    _initSubscriptions();
  }

  void setOfflineMode(bool offline) {
    _isOffline = offline;
    _emitSnapshot(_currentSnapshot);
  }

  void _initSubscriptions() {
    _stateSubscription = _connectivityEngine.stateStream.listen((state) {
      if (state != AdapterConnectionState.connected) {
        _currentSnapshot = LiveVehicleCockpitSnapshot.initialDisconnected(isOffline: _isOffline);
        _emitSnapshot(_currentSnapshot);
        _staleDataWatchdog?.cancel();
      }
    });

    _rawTelemetrySubscription = _connectivityEngine.telemetryStream.listen((packet) {
      _processRawPacket(packet);
    });
  }

  void _processRawPacket(RawVehicleTelemetryPacket packet) {
    _staleDataWatchdog?.cancel();

    final caps = _connectivityEngine.activeCapabilities;
    final now = DateTime.now();
    const freshness = TelemetryFreshnessState.live;

    TelemetryMetric<T> resolve<T>({
      required T? value,
      required String unit,
      required CapabilitySupportLevel capabilityLevel,
    }) {
      if (capabilityLevel == CapabilitySupportLevel.notSupported) {
        return TelemetryMetric<T>.unsupported(unit: unit);
      }
      if (value == null) {
        return TelemetryMetric<T>.unavailable(unit: unit);
      }
      return TelemetryMetric<T>(
        value: value,
        unit: unit,
        timestamp: now,
        state: freshness,
        qualityScore: 0.98,
        isSupported: true,
      );
    }

    // Dynamic Range calculation based on fuel or battery SoC
    double? estRange;
    if (packet.stateOfChargePct != null) {
      estRange = (packet.stateOfChargePct! / 100.0) * 140.0; // e.g. 140km max EV range
    } else if (packet.fuelLevelPct != null) {
      estRange = (packet.fuelLevelPct! / 100.0) * 350.0; // e.g. 350km max ICE tank range
    }

    _currentSnapshot = LiveVehicleCockpitSnapshot(
      timestamp: now,
      speedKmh: resolve(value: packet.speedKmh, unit: 'km/h', capabilityLevel: caps.speed),
      rpm: resolve(value: packet.rpm, unit: 'RPM', capabilityLevel: caps.rpm),
      fuelLevelPct: resolve(value: packet.fuelLevelPct, unit: '%', capabilityLevel: caps.fuelLevel),
      stateOfChargePct: resolve(value: packet.stateOfChargePct, unit: '%', capabilityLevel: caps.batteryLevel),
      batteryVoltage: resolve(value: packet.batteryVoltage, unit: 'V', capabilityLevel: caps.batteryVoltage),
      engineTempC: resolve(value: packet.engineTempC, unit: ' degC', capabilityLevel: caps.engineTemperature),
      motorTempC: resolve(value: packet.motorTempC, unit: ' degC', capabilityLevel: caps.motorTemperature),
      odometerKm: resolve(value: packet.odometerKm, unit: 'km', capabilityLevel: caps.odometer),
      tripDistanceKm: resolve(value: packet.tripDistanceKm, unit: 'km', capabilityLevel: caps.tripDistance),
      currentGear: resolve(value: packet.currentGear, unit: 'Gear', capabilityLevel: caps.telemetry),
      rideMode: resolve(value: packet.rideMode, unit: 'Mode', capabilityLevel: caps.rideMode),
      absStatus: resolve(value: packet.isAbsActive, unit: 'ABS', capabilityLevel: caps.absStatus),
      tractionControl: resolve(value: packet.isTractionControlActive, unit: 'TCS', capabilityLevel: caps.tractionControl),
      activeDtcCodes: resolve(value: packet.activeDtcCodes, unit: 'DTC', capabilityLevel: caps.diagnosticCodes),
      estimatedRangeKm: resolve(value: estRange, unit: 'km', capabilityLevel: caps.telemetry),
      isVehicleConnected: _connectivityEngine.currentState == AdapterConnectionState.connected,
      isOfflineMode: _isOffline,
    );

    _emitSnapshot(_currentSnapshot);

    // Watchdog to mark telemetry STALE if packet stream stalls for > 2500ms
    _staleDataWatchdog = Timer(const Duration(milliseconds: 2500), () {
      _markSnapshotStale();
    });
  }

  void _markSnapshotStale() {
    if (!_currentSnapshot.isVehicleConnected) return;

    TelemetryMetric<T> stale<T>(TelemetryMetric<T> metric) {
      if (!metric.isSupported || metric.value == null) return metric;
      return metric.copyWithFreshness(TelemetryFreshnessState.stale);
    }

    _currentSnapshot = LiveVehicleCockpitSnapshot(
      timestamp: DateTime.now(),
      speedKmh: stale(_currentSnapshot.speedKmh),
      rpm: stale(_currentSnapshot.rpm),
      fuelLevelPct: stale(_currentSnapshot.fuelLevelPct),
      stateOfChargePct: stale(_currentSnapshot.stateOfChargePct),
      batteryVoltage: stale(_currentSnapshot.batteryVoltage),
      engineTempC: stale(_currentSnapshot.engineTempC),
      motorTempC: stale(_currentSnapshot.motorTempC),
      odometerKm: stale(_currentSnapshot.odometerKm),
      tripDistanceKm: stale(_currentSnapshot.tripDistanceKm),
      currentGear: stale(_currentSnapshot.currentGear),
      rideMode: stale(_currentSnapshot.rideMode),
      absStatus: stale(_currentSnapshot.absStatus),
      tractionControl: stale(_currentSnapshot.tractionControl),
      activeDtcCodes: stale(_currentSnapshot.activeDtcCodes),
      estimatedRangeKm: stale(_currentSnapshot.estimatedRangeKm),
      isVehicleConnected: true,
      isOfflineMode: _isOffline,
    );

    _emitSnapshot(_currentSnapshot);
  }

  void _emitSnapshot(LiveVehicleCockpitSnapshot snapshot) {
    if (!_snapshotController.isClosed) {
      _snapshotController.add(snapshot);
    }
  }

  void dispose() {
    _rawTelemetrySubscription?.cancel();
    _stateSubscription?.cancel();
    _staleDataWatchdog?.cancel();
    _snapshotController.close();
  }
}
