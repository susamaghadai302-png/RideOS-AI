enum CommandResultStatus {
  pending,
  success,
  rejected,
  unsupported,
  timeout,
  disconnected,
  permissionDenied,
  safetyBlocked,
  protocolError,
  deviceError;

  bool get isSuccess => this == CommandResultStatus.success;
  bool get isTerminal => this != CommandResultStatus.pending;
}

class CommandResult {
  final String commandId;
  final CommandResultStatus status;
  final String message;
  final bool acknowledged;
  final int latencyMs;
  final List<int>? rawResponse;
  final DateTime timestamp;

  CommandResult({
    required this.commandId,
    required this.status,
    required this.message,
    this.acknowledged = false,
    this.latencyMs = 0,
    this.rawResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == CommandResultStatus.success;

  factory CommandResult.success({
    required String commandId,
    String message = 'Command executed successfully by vehicle',
    bool acknowledged = true,
    int latencyMs = 0,
    List<int>? rawResponse,
  }) {
    return CommandResult(
      commandId: commandId,
      status: CommandResultStatus.success,
      message: message,
      acknowledged: acknowledged,
      latencyMs: latencyMs,
      rawResponse: rawResponse,
    );
  }

  factory CommandResult.safetyBlocked({
    required String commandId,
    required String reason,
  }) {
    return CommandResult(
      commandId: commandId,
      status: CommandResultStatus.safetyBlocked,
      message: 'Safety System Blocked: $reason',
      acknowledged: false,
    );
  }

  factory CommandResult.unsupported({
    required String commandId,
    String reason = 'Capability not supported by connected vehicle hardware',
  }) {
    return CommandResult(
      commandId: commandId,
      status: CommandResultStatus.unsupported,
      message: reason,
      acknowledged: false,
    );
  }

  factory CommandResult.disconnected({
    required String commandId,
  }) {
    return CommandResult(
      commandId: commandId,
      status: CommandResultStatus.disconnected,
      message: 'Cannot execute command: Vehicle is disconnected',
      acknowledged: false,
    );
  }

  factory CommandResult.timeout({
    required String commandId,
    int timeoutMs = 3000,
  }) {
    return CommandResult(
      commandId: commandId,
      status: CommandResultStatus.timeout,
      message: 'Vehicle did not acknowledge command within ${timeoutMs}ms',
      acknowledged: false,
      latencyMs: timeoutMs,
    );
  }

  factory CommandResult.error({
    required String commandId,
    required CommandResultStatus status,
    required String message,
  }) {
    return CommandResult(
      commandId: commandId,
      status: status,
      message: message,
      acknowledged: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'commandId': commandId,
    'status': status.name,
    'message': message,
    'acknowledged': acknowledged,
    'latencyMs': latencyMs,
    'timestamp': timestamp.toIso8601String(),
  };
}
