import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/ble/obd_ble_service.dart';
import '../../data/datasources/obd_remote_datasource.dart';
import 'obd_event.dart';
import 'obd_state.dart';

class ObdBloc extends Bloc<ObdEvent, ObdState> {
  final ObdBleService bleService;
  final ObdRemoteDatasource remoteDatasource;
  StreamSubscription? _bleSub;

  ObdBloc({
    required this.bleService,
    required this.remoteDatasource,
  }) : super(ObdDisconnectedState()) {
    on<StartBleScanEvent>(_onStartScan);
    on<ObdTelemetryUpdatedEvent>(_onTelemetryUpdated);
    on<ObdScanErrorEvent>(_onScanError);
    on<ClearFaultCodesEvent>(_onClearFaultCodes);
    on<StopBleScanEvent>(_onStopScan);
  }

  void _onStartScan(StartBleScanEvent event, Emitter<ObdState> emit) {
    emit(ObdConnectingState());
    _bleSub?.cancel();
    _bleSub = bleService.streamBleTelemetry().listen(
      (telemetry) {
        add(ObdTelemetryUpdatedEvent(telemetry: telemetry));
        remoteDatasource.sendObdTelemetry(telemetry);
      },
      onError: (error) {
        add(ObdScanErrorEvent(errorMessage: error.toString()));
      },
    );
  }

  void _onTelemetryUpdated(ObdTelemetryUpdatedEvent event, Emitter<ObdState> emit) {
    emit(ObdStreamingState(telemetry: event.telemetry));
  }

  void _onScanError(ObdScanErrorEvent event, Emitter<ObdState> emit) {
    emit(ObdFailureState(errorMessage: event.errorMessage));
  }

  Future<void> _onClearFaultCodes(ClearFaultCodesEvent event, Emitter<ObdState> emit) async {
    try {
      final success = await bleService.clearDtcFaults();
      if (!success) {
        emit(const ObdFailureState(errorMessage: 'Failed to clear ECU fault codes. Ensure vehicle ignition is ON.'));
      }
    } catch (e) {
      emit(ObdFailureState(errorMessage: e.toString()));
    }
  }

  void _onStopScan(StopBleScanEvent event, Emitter<ObdState> emit) {
    _bleSub?.cancel();
    bleService.stopScan();
    emit(ObdDisconnectedState());
  }

  @override
  Future<void> close() {
    _bleSub?.cancel();
    return super.close();
  }
}
