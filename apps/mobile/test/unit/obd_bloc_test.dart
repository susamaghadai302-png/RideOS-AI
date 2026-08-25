import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/obd_tpms/core/ble/obd_ble_service.dart';
import 'package:rideos_mobile/features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import 'package:rideos_mobile/features/obd_tpms/domain/entities/obd_entity.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_bloc.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_event.dart';
import 'package:rideos_mobile/features/obd_tpms/presentation/bloc/obd_state.dart';

class MockObdBleService extends ObdBleService {
  @override
  Stream<ObdSensorEntity> streamBleTelemetry() async* {
    yield const ObdSensorEntity(
      rpm: 3200,
      coolantTempC: 84.5,
      throttlePct: 25.0,
      batteryVoltage: 12.6,
      frontTirePsi: 32.0,
      rearTirePsi: 36.0,
      diagnosticCodes: [],
    );
  }
}

class MockObdRemoteDS extends ObdRemoteDatasource {
  MockObdRemoteDS() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));

  @override
  Future<void> sendObdTelemetry(ObdSensorEntity telemetry) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockObdBleService mockBleService;
  late MockObdRemoteDS mockRemoteDS;
  late ObdBloc bloc;

  setUp(() {
    mockBleService = MockObdBleService();
    mockRemoteDS = MockObdRemoteDS();
    bloc = ObdBloc(bleService: mockBleService, remoteDatasource: mockRemoteDS);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is ObdDisconnectedState', () {
    expect(bloc.state, isA<ObdDisconnectedState>());
  });

  test('emits [ObdConnectingState, ObdStreamingState] on StartBleScanEvent', () async {
    final futureExpect = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ObdConnectingState>(),
        isA<ObdStreamingState>(),
      ]),
    );

    bloc.add(StartBleScanEvent());
    await futureExpect;
  });
}
