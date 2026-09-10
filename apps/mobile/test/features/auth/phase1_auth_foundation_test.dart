import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/auth/domain/entities/rider_entity.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:rideos_mobile/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  RiderEntity? currentRider;
  bool shouldThrowError = false;

  @override
  Future<RiderEntity> login({required String email, required String password}) async {
    if (shouldThrowError) throw Exception('Invalid email or password');
    currentRider = RiderEntity(
      id: 'rider_001',
      email: email,
      fullName: 'Speed Rider',
      phone: '+15551234567',
      garage: const [],
    );
    return currentRider!;
  }

  @override
  Future<RiderEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (shouldThrowError) throw Exception('Email already registered');
    currentRider = RiderEntity(
      id: 'rider_002',
      email: email,
      fullName: fullName,
      phone: phone,
      garage: const [],
    );
    return currentRider!;
  }

  @override
  Future<RiderEntity> getProfile() async {
    if (shouldThrowError || currentRider == null) throw Exception('Unauthorized session');
    return currentRider!;
  }

  @override
  Future<RiderEntity> loginWithGoogle() async {
    if (currentRider != null) return currentRider!;
    throw Exception('Google Sign-In requires native credential authorization');
  }

  @override
  Future<RiderEntity> loginWithGoogleCredential({
    required String email,
    required String fullName,
    String? idToken,
    String? accessToken,
  }) async {
    currentRider = RiderEntity(
      id: 'google_rider_001',
      email: email,
      fullName: fullName,
      phone: '',
      garage: const [],
    );
    return currentRider!;
  }

  @override
  Future<RiderEntity> loginWithApple() async {
    if (currentRider != null) return currentRider!;
    throw Exception('Apple Sign-In requires native credential authorization');
  }

  @override
  Future<RiderEntity> loginWithAppleCredential({
    String? email,
    String? fullName,
    String? identityToken,
    String? authorizationCode,
  }) async {
    currentRider = RiderEntity(
      id: 'apple_rider_001',
      email: email ?? 'apple.user@icloud.com',
      fullName: fullName ?? 'Apple Rider',
      phone: '',
      garage: const [],
    );
    return currentRider!;
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {}

  @override
  Future<RiderEntity> loginWithPhoneOtp({required String phone, required String otpCode}) async {
    throw Exception('Phone OTP authentication requires SMS gateway verification');
  }

  @override
  Future<RiderEntity> loginWithBiometrics() async {
    if (currentRider != null) return currentRider!;
    throw Exception('No active session found for biometric login.');
  }

  @override
  Future<RiderEntity> addBike({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    double? maxLeanAngleLimit,
  }) async {
    final bike = MotorcycleEntity(
      bikeId: 'bike_${DateTime.now().millisecondsSinceEpoch}',
      make: make,
      model: model,
      year: year,
      engineCC: engineCC,
      maxLeanAngleLimit: maxLeanAngleLimit ?? 45.0,
      isPrimary: currentRider?.garage.isEmpty ?? true,
    );
    final updatedGarage = [...?currentRider?.garage, bike];
    currentRider = RiderEntity(
      id: currentRider?.id ?? 'rider_001',
      email: currentRider?.email ?? '',
      fullName: currentRider?.fullName ?? '',
      phone: currentRider?.phone ?? '',
      garage: updatedGarage,
    );
    return currentRider!;
  }

  @override
  Future<RiderEntity> deleteBike({required String bikeId}) async {
    final updatedGarage = currentRider?.garage.where((b) => b.bikeId != bikeId).toList() ?? [];
    currentRider = RiderEntity(
      id: currentRider?.id ?? 'rider_001',
      email: currentRider?.email ?? '',
      fullName: currentRider?.fullName ?? '',
      phone: currentRider?.phone ?? '',
      garage: updatedGarage,
    );
    return currentRider!;
  }

  @override
  Future<RiderEntity> setPrimaryBike({required String bikeId}) async {
    final updatedGarage = currentRider?.garage.map((b) {
      return b.copyWith(isPrimary: b.bikeId == bikeId);
    }).toList() ?? [];
    currentRider = RiderEntity(
      id: currentRider?.id ?? 'rider_001',
      email: currentRider?.email ?? '',
      fullName: currentRider?.fullName ?? '',
      phone: currentRider?.phone ?? '',
      garage: updatedGarage,
    );
    return currentRider!;
  }

  @override
  Future<void> logout() async {
    currentRider = null;
  }

  @override
  Future<void> forgotPassword({required String email}) async {}
}

void main() {
  group('Phase 1 - Authentication & Session Tests', () {
    late MockAuthRepository mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    test('Initial state is AuthInitialState', () {
      expect(authBloc.state, isA<AuthInitialState>());
    });

    test('Login success emits AuthenticatedState with valid rider', () async {
      authBloc.add(const LoginSubmittedEvent(email: 'rider@example.com', password: 'password123'));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoadingState>(),
          predicate<AuthState>((s) => s is AuthenticatedState && s.rider.email == 'rider@example.com' && s.rider.fullName == 'Speed Rider'),
        ]),
      );
    });

    test('Login failure emits AuthFailureState with proper error message', () async {
      mockRepo.shouldThrowError = true;
      authBloc.add(const LoginSubmittedEvent(email: 'wrong@example.com', password: 'wrong'));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoadingState>(),
          isA<AuthFailureState>(),
        ]),
      );
    });

    test('Register success emits AuthenticatedState', () async {
      authBloc.add(const RegisterSubmittedEvent(
        email: 'newuser@example.com',
        password: 'securePassword123',
        fullName: 'Alex Vance',
        phone: '+15559876543',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoadingState>(),
          predicate<AuthState>((s) => s is AuthenticatedState && s.rider.email == 'newuser@example.com' && s.rider.fullName == 'Alex Vance'),
        ]),
      );
    });

    test('Google OAuth with credentials emits AuthenticatedState', () async {
      authBloc.add(const GoogleSignInWithCredentialEvent(
        email: 'alex.oauth@gmail.com',
        fullName: 'Alex OAuth',
        idToken: 'valid_google_token_123',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoadingState>(),
          predicate<AuthState>((s) => s is AuthenticatedState && s.rider.email == 'alex.oauth@gmail.com'),
        ]),
      );
    });

    test('Logout clears authenticated session and emits UnauthenticatedState', () async {
      // First login
      authBloc.add(const LoginSubmittedEvent(email: 'rider@example.com', password: 'password123'));
      await expectLater(
        authBloc.stream,
        emitsThrough(isA<AuthenticatedState>()),
      );

      // Now logout
      authBloc.add(LogoutEvent());
      await expectLater(
        authBloc.stream,
        emits(isA<UnauthenticatedState>()),
      );
    });
  });
}
