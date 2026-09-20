import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'package:rideos_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rideos_mobile/features/auth/data/models/rider_model.dart';
import 'package:rideos_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rideos_mobile/features/navigation/data/datasources/navigation_remote_datasource.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/place_search_entity.dart';
import 'package:rideos_mobile/features/navigation/domain/entities/route_entity.dart';
import 'package:rideos_mobile/features/obd_tpms/core/ble/obd_ble_service.dart';
import 'package:rideos_mobile/features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import 'package:rideos_mobile/features/squad_ride/data/datasources/squad_remote_datasource.dart';
import 'package:rideos_mobile/main.dart';

class MockAuthRemoteDS implements AuthRemoteDatasource {
  @override
  Future<RiderModel> getProfile() async {
    return const RiderModel(
      id: 'rider-1',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      phone: '+1234567890',
      garage: [],
    );
  }

  @override
  Future<RiderModel> login(String email, String password) async => getProfile();

  @override
  Future<RiderModel> register(String email, String password, String fullName, String phone) async => getProfile();

  @override
  Future<RiderModel> loginWithOAuthGoogle({required String email, required String fullName, String? idToken, String? accessToken}) async => getProfile();

  @override
  Future<RiderModel> loginWithOAuthApple({String? email, String? fullName, String? identityToken, String? authorizationCode}) async => getProfile();

  @override
  Future<RiderModel> addBike(String make, String model, int year, int engineCC, double? maxLeanAngleLimit) async => getProfile();

  @override
  Future<RiderModel> deleteBike(String bikeId) async => getProfile();

  @override
  Future<RiderModel> setPrimaryBike(String bikeId) async => getProfile();

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> requestPhoneOtp(String phone) async {}

  @override
  Future<RiderModel> loginWithPhoneOtp(String phone, String otpCode) async => getProfile();
}


class MockNavRemoteDS implements NavigationRemoteDatasource {
  @override
  Future<NavigationRouteEntity> calculateRoute({required origin, required destination, waypoints, preference, provider}) async {
    return NavigationRouteEntity(
      routeId: 'route-1',
      distanceKm: 10,
      durationMinutes: 10,
      waypoints: [origin, destination],
      steps: const [],
      twistinessScore: 5.0,
      provider: 'OSRM',
    );
  }

  @override
  Future<bool> checkOffRoute({required currentLocation, required waypoints}) async => false;

  @override
  Future<List<PlaceSearchResultEntity>> searchPlaces(String query) async => [];
}

class MockAiDS extends AiAssistantRemoteDatasource {
  MockAiDS() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));
}

class MockSquadDS extends SquadRemoteDatasource {
  MockSquadDS() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));
}

class MockObdDS extends ObdRemoteDatasource {
  MockObdDS() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RideOSApp builds smoke test', (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(tokenStorage: tokenStorage);

    final authRemoteDS = MockAuthRemoteDS();
    final navRemoteDS = MockNavRemoteDS(); debugPrint(navRemoteDS.toString());

    final authRepositoryImpl = AuthRepositoryImpl(remoteDatasource: authRemoteDS, tokenStorage: tokenStorage);

    final aiRemoteDatasource = MockAiDS();
    final squadRemoteDatasource = MockSquadDS();
    final obdRemoteDatasource = MockObdDS();
    final obdBleService = ObdBleService();


    await tester.pumpWidget(RideOSApp(
      authRepository: authRepositoryImpl,
      aiRemoteDatasource: aiRemoteDatasource,
      squadRemoteDatasource: squadRemoteDatasource,
      obdRemoteDatasource: obdRemoteDatasource,
      obdBleService: obdBleService,
      apiClient: apiClient,
    ));

    await tester.pump();
    expect(find.byType(RideOSApp), findsOneWidget);
  });
}
