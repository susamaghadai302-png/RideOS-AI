import 'package:local_auth/local_auth.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/rider_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.tokenStorage,
  });

  @override
  Future<RiderEntity> login({required String email, required String password}) async {
    return await remoteDatasource.login(email, password);
  }

  @override
  Future<RiderEntity> loginWithGoogle() async {
    throw UnimplementedError('CONFIGURATION REQUIRED: Genuine OAuth provider integration missing.');
  }

  @override
  Future<RiderEntity> loginWithGoogleCredential({
    required String email,
    required String fullName,
    String? idToken,
    String? accessToken,
  }) async {
    return await remoteDatasource.loginWithOAuthGoogle(
      email: email,
      fullName: fullName,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  Future<RiderEntity> loginWithApple() async {
    throw UnimplementedError('CONFIGURATION REQUIRED: Genuine OAuth provider integration missing.');
  }

  @override
  Future<RiderEntity> loginWithAppleCredential({
    String? email,
    String? fullName,
    String? identityToken,
    String? authorizationCode,
  }) async {
    return await remoteDatasource.loginWithOAuthApple(
      email: email,
      fullName: fullName,
      identityToken: identityToken,
      authorizationCode: authorizationCode,
    );
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {
    await remoteDatasource.requestPhoneOtp(phone);
  }

  @override
  Future<RiderEntity> loginWithPhoneOtp({required String phone, required String otpCode}) async {
    return await remoteDatasource.loginWithPhoneOtp(phone, otpCode);
  }

  @override
  Future<RiderEntity> loginWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      throw Exception('Biometric authentication is not supported on this device.');
    }

    final bool didAuthenticate = await auth.authenticate(
      localizedReason: 'Authenticate to access your RideOS account',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (didAuthenticate) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        return await remoteDatasource.getProfile();
      }
      throw Exception('No active session found. Please sign in with email/password.');
    } else {
      throw Exception('Biometric authentication failed or was cancelled.');
    }
  }

  @override
  Future<RiderEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    return await remoteDatasource.register(email, password, fullName, phone);
  }

  @override
  Future<RiderEntity> getProfile() async {
    return await remoteDatasource.getProfile();
  }

  @override
  Future<RiderEntity> addBike({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    double? maxLeanAngleLimit,
  }) async {
    return await remoteDatasource.addBike(make, model, year, engineCC, maxLeanAngleLimit);
  }

  @override
  Future<RiderEntity> deleteBike({required String bikeId}) async {
    return await remoteDatasource.deleteBike(bikeId);
  }

  @override
  Future<RiderEntity> setPrimaryBike({required String bikeId}) async {
    return await remoteDatasource.setPrimaryBike(bikeId);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await remoteDatasource.requestPasswordReset(email);
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}
