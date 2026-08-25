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
    return await remoteDatasource.loginWithOAuthGoogle(
      email: 'google.rider@rideos.ai',
      fullName: 'Google Rider',
    );
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
    return await remoteDatasource.loginWithOAuthApple(
      email: 'apple.rider@rideos.ai',
      fullName: 'Apple Rider',
    );
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
  Future<RiderEntity> loginWithPhoneOtp({required String phone, required String otpCode}) async {
    throw Exception('Phone OTP authentication requires SMS gateway verification');
  }

  @override
  Future<RiderEntity> loginWithBiometrics() async {
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return await remoteDatasource.getProfile();
    }
    throw Exception('No active session found for biometric login. Please sign in with email and password.');
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
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }
}
