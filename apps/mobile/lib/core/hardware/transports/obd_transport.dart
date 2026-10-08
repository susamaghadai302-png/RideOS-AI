import 'dart:async';
import '../transports/hardware_transport.dart';
import '../telemetry/vehicle_telemetry.dart';
import '../obd/pid_registry.dart';

enum Elm327State {
  connecting,
  initializing,
  protocolDetecting,
  ready,
  querying,
  retrying,
  stale,
  disconnected,
  error
}

class ObdTransport {
  final HardwareTransport _underlyingTransport;
  
  final StreamController<Elm327State> _stateController = StreamController.broadcast();
  Elm327State _currentState = Elm327State.disconnected;
  Elm327State get currentState => _currentState;
  final Map<String, PidSupport> _capabilityMap = {};

  StreamSubscription<List<int>>? _byteSubscription;
  final List<int> _receiveBuffer = [];
  Completer<String>? _pendingCommandCompleter;
  Timer? _commandTimeout;

  ObdTransport(this._underlyingTransport) {
    _underlyingTransport.stateStream.listen((transportState) {
      if (transportState == HardwareTransportState.disconnected) {
        _updateState(Elm327State.disconnected);
        _abortPending(StateError('Underlying transport disconnected'));
      } else if (transportState == HardwareTransportState.error) {
        _updateState(Elm327State.error);
        _abortPending(StateError('Underlying transport error'));
      }
    });

    _byteSubscription = _underlyingTransport.byteStream.listen(_onBytesReceived);
  }

  Stream<Elm327State> get stateStream => _stateController.stream;
  Stream<VehicleTelemetry> get telemetryStream => _underlyingTransport.telemetryStream;

  void _updateState(Elm327State state) {
    _currentState = state;
    _stateController.add(state);
  }

  void _abortPending(Object error) {
    _commandTimeout?.cancel();
    if (_pendingCommandCompleter != null && !_pendingCommandCompleter!.isCompleted) {
      _pendingCommandCompleter!.completeError(error);
    }
    _pendingCommandCompleter = null;
    _receiveBuffer.clear();
  }

  void _onBytesReceived(List<int> bytes) {
    _receiveBuffer.addAll(bytes);
    
    // ELM327 frames end with '>' character (62 in ASCII) or '\r' (13) depending on mode.
    // Standard response terminator for ELM327 prompt is '>'
    if (_receiveBuffer.contains(62)) {
      final promptIndex = _receiveBuffer.indexOf(62);
      final frameBytes = _receiveBuffer.sublist(0, promptIndex);
      _receiveBuffer.removeRange(0, promptIndex + 1);

      final responseString = String.fromCharCodes(frameBytes).trim();
      
      _commandTimeout?.cancel();
      if (_pendingCommandCompleter != null && !_pendingCommandCompleter!.isCompleted) {
        _pendingCommandCompleter!.complete(responseString);
      }
      _pendingCommandCompleter = null;
    }
  }

  Future<void> initialize() async {
    _updateState(Elm327State.initializing);
    try {
      await _sendAtCommand('ATZ');
      await _sendAtCommand('ATE0'); // Echo off
      await _sendAtCommand('ATL0'); // Linefeeds off
      await _sendAtCommand('ATS0'); // Spaces off
      
      _updateState(Elm327State.protocolDetecting);
      await _sendAtCommand('ATSP0'); // Auto protocol
      
      _updateState(Elm327State.ready);
    } catch (e) {
      _updateState(Elm327State.error);
      rethrow;
    }
  }

  Future<void> discoverCapabilities() async {
    try {
      final response = await _queryPid('0100');
      if (response == null) {
        throw StateError('No response for PID 00');
      }
      for (final pid in PidRegistry.knownPids.keys) {
        _capabilityMap[pid] = PidSupport.unverified;
      }
    } catch (e) {
      _updateState(Elm327State.error);
    }
  }

  Future<String?> _queryPid(String pid) async {
    _updateState(Elm327State.querying);
    try {
      final result = await _sendAtCommand(pid);
      if (result == 'NO DATA' || result == '?' || result.isEmpty) {
        _capabilityMap[pid] = PidSupport.unsupported;
        return null;
      }
      _capabilityMap[pid] = PidSupport.supported;
      _updateState(Elm327State.ready);
      return result;
    } catch (e) {
      _updateState(Elm327State.retrying);
      rethrow;
    }
  }

  Future<String> _sendAtCommand(String command) async {
    if (_pendingCommandCompleter != null) {
      throw StateError('A command is already pending.');
    }

    if (_underlyingTransport.currentState != HardwareTransportState.connected &&
        _underlyingTransport.currentState != HardwareTransportState.ready) {
      throw StateError('Physical OBD-II hardware UNVERIFIED. Command "$command" blocked.');
    }

    _pendingCommandCompleter = Completer<String>();
    
    // Convert string command to bytes and append \r (Carriage Return)
    final bytes = command.codeUnits.toList()..add(13);
    
    try {
      await _underlyingTransport.write(bytes);
    } catch (e) {
      _abortPending(StateError('Failed to write to transport.'));
      rethrow;
    }

    _commandTimeout = Timer(const Duration(seconds: 5), () {
      _abortPending(TimeoutException('ELM327 command "$command" timed out.'));
    });

    return _pendingCommandCompleter!.future;
  }

  void dispose() {
    _commandTimeout?.cancel();
    _byteSubscription?.cancel();
    _stateController.close();
  }
}
