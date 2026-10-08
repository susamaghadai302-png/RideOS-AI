import 'dart:async';
import '../telemetry/vehicle_telemetry.dart';

enum HardwareTransportState {
  idle,
  scanning,
  deviceFound,
  connecting,
  initializing,
  connected,
  discoveringServices,
  ready,
  reconnecting,
  disconnecting,
  disconnected,
  error
}

abstract class HardwareTransport {
  final StreamController<HardwareTransportState> _stateController = StreamController<HardwareTransportState>.broadcast();
  final StreamController<VehicleTelemetry> _telemetryController = StreamController<VehicleTelemetry>.broadcast();
  final StreamController<List<int>> _byteStreamController = StreamController<List<int>>.broadcast();

  HardwareTransportState _currentState = HardwareTransportState.idle;

  Stream<HardwareTransportState> get stateStream => _stateController.stream;
  Stream<VehicleTelemetry> get telemetryStream => _telemetryController.stream;
  Stream<List<int>> get byteStream => _byteStreamController.stream;
  HardwareTransportState get currentState => _currentState;

  void updateState(HardwareTransportState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispatchTelemetry(VehicleTelemetry telemetry) {
    _telemetryController.add(telemetry);
  }

  void dispatchBytes(List<int> bytes) {
    _byteStreamController.add(bytes);
  }

  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> write(List<int> bytes);
  
  void dispose() {
    _stateController.close();
    _telemetryController.close();
    _byteStreamController.close();
  }
}
