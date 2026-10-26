import 'package:firebase_core/firebase_core.dart';

/// Rejects placeholder or incomplete Firebase configuration in release builds.
/// Debug builds are allowed to use test configuration for local development.
class ProductionFirebaseGuard {
  const ProductionFirebaseGuard._();

  static void validate(
    FirebaseOptions options, {
    required bool releaseMode,
  }) {
    if (!releaseMode) return;

    if (options.apiKey.trim().isEmpty ||
        options.appId.trim().isEmpty ||
        options.messagingSenderId.trim().isEmpty ||
        options.projectId.trim().isEmpty) {
      throw const UnsupportedError(
        'Production deployment blocked: required Firebase configuration is missing.',
      );
    }

    if (options.projectId == 'rideos-mock-project' ||
        options.appId.contains('1234567890')) {
      throw const UnsupportedError(
        'Production deployment blocked: placeholder Firebase configuration detected.',
      );
    }
  }
}
