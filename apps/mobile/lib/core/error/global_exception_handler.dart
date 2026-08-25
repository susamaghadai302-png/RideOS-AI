import 'dart:developer' as developer;

abstract class BaseAppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const BaseAppException(this.message, {this.code, this.details});

  @override
  String toString() => '[$code] $message ${details ?? ""}';
}

class NetworkException extends BaseAppException {
  const NetworkException(super.message, {super.code, super.details});
}

class ApiException extends BaseAppException {
  final int? statusCode;
  const ApiException(super.message, {this.statusCode, super.code, super.details});
}

class SecurityException extends BaseAppException {
  const SecurityException(super.message, {super.code, super.details});
}

class GlobalExceptionHandler {
  static void handleException(dynamic exception, [StackTrace? stackTrace]) {
    developer.log(
      'UNHANDLED EXCEPTION: $exception',
      name: 'RideOS.GlobalExceptionHandler',
      error: exception,
      stackTrace: stackTrace,
    );
  }
}
