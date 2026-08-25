import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/auth/domain/entities/rider_entity.dart';
import 'package:rideos_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;
  bool isTokenValid = true;

  @override
  Future<RiderEntity> login({required String email, required String password}) async {
    if (shouldFail) throw Exception('Invalid credentials');
    return const RiderEntity(
      id: 'rider-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      phone: '+1234567890',
      garage: [],
    );
  }

  @override
  Future<RiderEntity> loginWithGoogle() async => getProfile();

  @override
  Future<RiderEntity> loginWithGoogleCredential({required String email, required String fullName, String? idToken, String? accessToken}) async => getProfile();

  @override
  Future<RiderEntity> loginWithApple() async => getProfile();

  @override
  Future<RiderEntity> loginWithAppleCredential({String? email, String? fullName, String? identityToken, String? authorizationCode}) async => getProfile();

  @override
  Future<RiderEntity> loginWithPhoneOtp({required String phone, required String otpCode}) async => getProfile();

  @override
  Future<RiderEntity> loginWithBiometrics() async => getProfile();

  @override
  Future<RiderEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return RiderEntity(
      id: 'rider-123',
      email: email,
      fullName: fullName,
      phone: phone,
      garage: const [],
    );
  }

  @override
  Future<RiderEntity> getProfile() async {
    if (shouldFail || !isTokenValid) throw Exception('Not logged in');
    return const RiderEntity(
      id: 'rider-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      phone: '+1234567890',
      garage: [],
    );
  }

  @override
  Future<RiderEntity> addBike({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    double? maxLeanAngleLimit,
  }) async {
    return const RiderEntity(
      id: 'rider-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      phone: '+1234567890',
      garage: [
        MotorcycleEntity(
          bikeId: 'bike-1',
          make: 'Yamaha',
          model: 'MT-09',
          year: 2024,
          engineCC: 890,
          maxLeanAngleLimit: 51.5,
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  Future<RiderEntity> deleteBike({required String bikeId}) async => getProfile();

  @override
  Future<RiderEntity> setPrimaryBike({required String bikeId}) async => getProfile();

  @override
  Future<void> logout() async {
    isTokenValid = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitialState', () {
    expect(authBloc.state, isA<AuthInitialState>());
  });

  test('emits [AuthLoadingState, AuthenticatedState] when login succeeds', () async {
    final expectedStates = [
      AuthLoadingState(),
      const AuthenticatedState(
        rider: RiderEntity(
          id: 'rider-123',
          email: 'test@example.com',
          fullName: 'Jane Doe',
          phone: '+1234567890',
          garage: [],
        ),
      ),
    ];

    expectLater(authBloc.stream, emitsInOrder(expectedStates));

    authBloc.add(const LoginSubmittedEvent(email: 'test@example.com', password: 'password123'));
  });

  test('emits [UnauthenticatedState] when app starts and profile fetch fails', () async {
    mockAuthRepository.shouldFail = true;
    expectLater(authBloc.stream, emits(UnauthenticatedState()));

    authBloc.add(AppStartedEvent());
  });

  test('emits [UnauthenticatedState] when LogoutEvent is triggered', () async {
    expectLater(
      authBloc.stream,
      emits(UnauthenticatedState()),
    );

    authBloc.add(LogoutEvent());
  });

  test('emits [AuthLoadingState, AuthenticatedState] when GoogleLoginEvent succeeds', () async {
    expectLater(
      authBloc.stream,
      emitsInOrder([
        AuthLoadingState(),
        isA<AuthenticatedState>(),
      ]),
    );

    authBloc.add(GoogleLoginEvent());
  });

  test('emits [AuthLoadingState, AuthenticatedState] when AppleLoginEvent succeeds', () async {
    expectLater(
      authBloc.stream,
      emitsInOrder([
        AuthLoadingState(),
        isA<AuthenticatedState>(),
      ]),
    );

    authBloc.add(AppleLoginEvent());
  });
}
