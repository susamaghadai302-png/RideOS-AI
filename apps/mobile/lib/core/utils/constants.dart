import '../network/api_config.dart';

class ApiConstants {
  static void setOverrideUrl(String url) {
    ApiConfig.setBaseUrl(url);
  }

  static String get baseUrl => ApiConfig.activeBaseUrl;

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String otpEndpoint = '/auth/otp';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String profileEndpoint = '/riders/profile';
  static const String garageEndpoint = '/riders/garage';
  static const String preferencesEndpoint = '/riders/preferences';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String riderProfile = 'rider_profile';
}
