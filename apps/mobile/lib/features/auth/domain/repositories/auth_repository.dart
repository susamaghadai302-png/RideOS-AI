import '../entities/rider_entity.dart';

abstract class AuthRepository {
  Future<RiderEntity> login({required String email, required String password});
  Future<RiderEntity> loginWithGoogle();
  Future<RiderEntity> loginWithGoogleCredential({
    required String email,
    required String fullName,
    String? idToken,
    String? accessToken,
  });
  Future<RiderEntity> loginWithApple();
  Future<RiderEntity> loginWithAppleCredential({
    String? email,
    String? fullName,
    String? identityToken,
    String? authorizationCode,
  });
  Future<RiderEntity> loginWithPhoneOtp({required String phone, required String otpCode});
  Future<RiderEntity> loginWithBiometrics();
  Future<RiderEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });
  Future<RiderEntity> getProfile();
  Future<RiderEntity> addBike({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    double? maxLeanAngleLimit,
  });
  Future<RiderEntity> deleteBike({required String bikeId});
  Future<RiderEntity> setPrimaryBike({required String bikeId});
  Future<void> forgotPassword({required String email});
  Future<void> logout();
}
