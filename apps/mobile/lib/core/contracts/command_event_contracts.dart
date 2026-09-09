import 'package:equatable/equatable.dart';

/// Canonical Domain Command Contract (ADR-05).
///
/// Represents an explicit request for the system TO DO something.
/// Commands are immutable intent objects dispatched by UI or system triggers.
/// Commands MUST NOT be used as mutable state.
abstract class RideOSCommand extends Equatable {
  /// Globally unique identifier for tracking execution lifecycle.
  String get commandId;

  /// Human-readable identifier for audit logging.
  String get commandName;

  /// Creation timestamp.
  DateTime get createdAt;

  /// Validates whether command parameters satisfy domain constraints before transmission.
  bool validate();

  @override
  List<Object?> get props => [commandId, commandName, createdAt];
}

/// Canonical Domain Event Contract (ADR-05).
///
/// Represents an immutable fact that HAS OCCURRED in the system.
/// Produced by gateways, repositories, and state machines; observed by presentation layers.
abstract class RideOSEvent extends Equatable {
  /// Unique event identifier for idempotency and event sourcing.
  String get eventId;

  /// Canonical event family identifier (e.g. 'TELEMETRY_UPDATED', 'AUTH_SESSION_EXPIRED').
  String get eventName;

  /// Instant when event occurred at the source.
  DateTime get occurredAt;

  /// Serializable payload containing event details.
  Map<String, dynamic> get payload;

  @override
  List<Object?> get props => [eventId, eventName, occurredAt, payload];
}

/// Standardized Execution Result for RideOS Commands.
class CommandExecutionResult extends Equatable {
  final String commandId;
  final bool isSuccess;
  final String message;
  final String? errorCode;
  final DateTime executedAt;

  CommandExecutionResult({
    required this.commandId,
    required this.isSuccess,
    required this.message,
    this.errorCode,
    DateTime? executedAt,
  }) : executedAt = executedAt ?? DateTime.now();

  factory CommandExecutionResult.success(String commandId, [String message = 'Success']) =>
      CommandExecutionResult(commandId: commandId, isSuccess: true, message: message);

  factory CommandExecutionResult.failure(String commandId, String message, [String? code]) =>
      CommandExecutionResult(commandId: commandId, isSuccess: false, message: message, errorCode: code);

  @override
  List<Object?> get props => [commandId, isSuccess, message, errorCode, executedAt];
}
