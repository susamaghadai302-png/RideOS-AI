import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import '../utils/constants.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage tokenStorage;
  bool _isRefreshing = false;

  ApiClient({required this.tokenStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Platform': 'RideOS-Mobile',
          'X-Client-Version': '1.0.0',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiConstants.baseUrl;
          final token = await tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Token refresh on 401 Unauthorized
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshToken = await tokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              _isRefreshing = true;
              try {
                final refreshResponse = await dio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                  options: Options(headers: {'Authorization': null}),
                );

                if (refreshResponse.statusCode == 200 || refreshResponse.statusCode == 201) {
                  final newAccessToken = refreshResponse.data['accessToken'] ?? refreshResponse.data['token'];
                  final newRefreshToken = refreshResponse.data['refreshToken'] ?? refreshToken;
                  
                  if (newAccessToken != null) {
                    await tokenStorage.saveTokens(
                      accessToken: newAccessToken.toString(),
                      refreshToken: newRefreshToken.toString(),
                    );
                    _isRefreshing = false;

                    // Retry original request with new token
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';
                    final cloneReq = await dio.fetch(opts);
                    return handler.resolve(cloneReq);
                  }
                }
              } catch (_) {
                _isRefreshing = false;
                await tokenStorage.clearTokens();
              }
            } else {
              await tokenStorage.clearTokens();
            }
          }

          // Automatic Retry for transient 5xx server errors or timeouts on idempotent requests only
          final isTransient = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              (error.response?.statusCode != null && error.response!.statusCode! >= 500);

          final isIdempotent = error.requestOptions.method.toUpperCase() == 'GET' ||
              error.requestOptions.method.toUpperCase() == 'HEAD' ||
              error.requestOptions.method.toUpperCase() == 'OPTIONS';

          final retryCount = (error.requestOptions.extra['retry_count'] as int?) ?? 0;
          if (isTransient && isIdempotent && retryCount < 2) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;
            await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
            try {
              final response = await dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (_) {}
          }

          return handler.next(error);
        },
      ),
    );
  }

  static String formatErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 409) {
        final data = error.response?.data;
        if (data is Map) {
          if (data['error'] is Map && data['error']['message'] != null) {
            return data['error']['message'].toString();
          }
          if (data['message'] != null) {
            if (data['message'] is List) {
              return (data['message'] as List).join(', ');
            }
            return data['message'].toString();
          }
        }
        return 'An account with this email already exists. Please log in instead.';
      }
      final data = error.response?.data;
      if (data is Map) {
        if (data['error'] is Map && data['error']['message'] != null) {
          return data['error']['message'].toString();
        }
        if (data['message'] != null) {
          if (data['message'] is List) {
            return (data['message'] as List).join(', ');
          }
          return data['message'].toString();
        }
        if (data['error'] is String) {
          return data['error'].toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Backend unreachable. If using USB Mode (for 5G/mobile data), run "adb reverse tcp:3000 tcp:3000". If using Wi-Fi LAN Mode, ensure phone & Mac are on the same Wi-Fi.';
      }
      if (error.response?.statusCode != null) {
        return 'Server error (HTTP ${error.response!.statusCode})';
      }
      return error.message ?? 'Network communication error';
    }
    if (error is TypeError) {
      return 'An unexpected platform data error occurred. Please try again.';
    }
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(String path, {Object? data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(String path, {Object? data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(String path, {Object? data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}

