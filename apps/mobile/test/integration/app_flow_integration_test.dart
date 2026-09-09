import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/di/service_locator.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rideos_mobile/features/auth/data/models/rider_model.dart';
import 'package:rideos_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rideos_mobile/main.dart';

class MockIntegrationAuthDS implements AuthRemoteDatasource {
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
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideOS Mobile Integration Tests', () {
    setUp(() {
      getIt.setupLocator();
    });

    testWidgets('Full app initialization and splash to main flow smoke test', (WidgetTester tester) async {
      final mockAuthDS = MockIntegrationAuthDS();
      final mockAuthRepo = AuthRepositoryImpl(remoteDatasource: mockAuthDS, tokenStorage: TokenStorage());

      await tester.pumpWidget(RideOSApp(authRepository: mockAuthRepo));

      await tester.pump();
      expect(find.byType(RideOSApp), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
