import 'package:flutter/foundation.dart';

/// Represents the high-level state of the voice input lifecycle.
enum VoiceInputState {
  idle,
  permissionRequired,
  permissionDenied,
  listening,
  processing,
  error,
  unavailable,
}

/// Normalized categories of voice recognition errors.
enum VoiceErrorType {
  network,
  timeout,
  permissionDenied,
  unavailable,
  malformedResult,
  cancelled,
  unknown,
}

/// Represents an active request for voice input.
@immutable
class VoiceRequest {
  final String requestId;
  final String? locale;

  const VoiceRequest({
    required this.requestId,
    this.locale,
  });
}

/// Represents a standardized error from the Voice Gateway.
@immutable
class VoiceRecognitionError implements Exception {
  final VoiceErrorType type;
  final String message;

  const VoiceRecognitionError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'VoiceRecognitionError($type): $message';
}

/// Represents the transcript result of a voice session.
@immutable
class VoiceTranscript {
  final String text;
  final bool isFinal;
  final double? confidence;

  const VoiceTranscript({
    required this.text,
    required this.isFinal,
    this.confidence,
  });
}
