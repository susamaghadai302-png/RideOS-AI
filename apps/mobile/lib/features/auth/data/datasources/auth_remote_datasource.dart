import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/constants.dart';
import '../models/rider_model.dart';

abstract class AuthRemoteDatasource {
  Future<RiderModel> login(String email, String password);
  Future<RiderModel> register(String email, String password, String fullName, String phone);
  Future<RiderModel> getProfile();
  Future<RiderModel> loginWithOAuthGoogle({required String email, required String fullName, String? idToken, String? accessToken});
  Future<RiderModel> loginWithOAuthApple({String? email, String? fullName, String? identityToken, String? authorizationCode});
  Future<RiderModel> addBike(String make, String model, int year, int engineCC, double? maxLeanAngleLimit);
  Future<RiderModel> deleteBike(String bikeId);
  Future<RiderModel> setPrimaryBike(String bikeId);
  Future<void> requestPasswordReset(String email);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  AuthRemoteDatasourceImpl({required this.apiClient, required this.tokenStorage});

  @override
  Future<RiderModel> login(String email, String password) async {
    final response = await apiClient.dio.post(
      ApiConstants.loginEndpoint,
      data: {'email': email, 'password': password},
    );

    final tokens = response.data['tokens'];
    await tokenStorage.saveTokens(
      accessToken: tokens['accessToken'],
      refreshToken: tokens['refreshToken'],
    );

    return RiderModel.fromJson(response.data['rider']);
  }

  @override
  Future<RiderModel> register(String email, String password, String fullName, String phone) async {
    final response = await apiClient.dio.post(
      ApiConstants.registerEndpoint,
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      },
    );

    final tokens = response.data['tokens'];
    await tokenStorage.saveTokens(
      accessToken: tokens['accessToken'],
      refreshToken: tokens['refreshToken'],
    );

    return RiderModel.fromJson(response.data['rider']);
  }

  @override
  Future<RiderModel> getProfile() async {
    final response = await apiClient.dio.get(ApiConstants.profileEndpoint);
    return RiderModel.fromJson(response.data);
  }

  @override
  Future<RiderModel> loginWithOAuthGoogle({
    required String email,
    required String fullName,
    String? idToken,
    String? accessToken,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/oauth/google',
      data: {
        'email': email,
        'fullName': fullName,
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      },
    );

    final tokens = response.data['tokens'];
    await tokenStorage.saveTokens(
      accessToken: tokens['accessToken'],
      refreshToken: tokens['refreshToken'],
    );

    return RiderModel.fromJson(response.data['rider']);
  }

  @override
  Future<RiderModel> loginWithOAuthApple({
    String? email,
    String? fullName,
    String? identityToken,
    String? authorizationCode,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/oauth/apple',
      data: {
        if (email != null) 'email': email,
        if (fullName != null) 'fullName': fullName,
        if (identityToken != null) 'identityToken': identityToken,
        if (authorizationCode != null) 'authorizationCode': authorizationCode,
      },
    );

    final tokens = response.data['tokens'];
    await tokenStorage.saveTokens(
      accessToken: tokens['accessToken'],
      refreshToken: tokens['refreshToken'],
    );

    return RiderModel.fromJson(response.data['rider']);
  }

  @override
  Future<RiderModel> addBike(String make, String model, int year, int engineCC, double? maxLeanAngleLimit) async {
    final response = await apiClient.dio.post(
      ApiConstants.garageEndpoint,
      data: {
        'make': make,
        'model': model,
        'year': year,
        'engineCC': engineCC,
        if (maxLeanAngleLimit != null) 'maxLeanAngleLimit': maxLeanAngleLimit,
      },
    );
    return RiderModel.fromJson(response.data);
  }

  @override
  Future<RiderModel> deleteBike(String bikeId) async {
    final response = await apiClient.dio.delete('${ApiConstants.garageEndpoint}/$bikeId');
    return RiderModel.fromJson(response.data);
  }

  @override
  Future<RiderModel> setPrimaryBike(String bikeId) async {
    final response = await apiClient.dio.patch('${ApiConstants.garageEndpoint}/$bikeId/primary');
    return RiderModel.fromJson(response.data);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await apiClient.dio.post(
      ApiConstants.forgotPasswordEndpoint,
      data: {'email': email.trim().toLowerCase()},
    );
  }
}
