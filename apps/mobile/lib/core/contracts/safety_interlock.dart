/// Canonical Safety Interlock Contract (ADR-16).
///
/// Provides the single, authoritative safety decision point for all
/// vehicle command execution in RideOS-AI.
///
/// ABSOLUTE RULE: No AI, voice, UI, navigation, or automotive surface
/// may bypass this interlock. All safety-sensitive commands MUST pass
/// through [SafetyInterlock.evaluate] before reaching any actuator
/// or hardware command adapter.
///
/// Platform-independent: This contract MUST NOT import Flutter, Android,
/// iOS, BLE, OBD, Map SDK, Gemini, Claude, CarPropertyManager, CarPlay,
/// or Android Auto SDKs.
library;

// ─── Safety Classification ───────────────────────────────────────────────────

/// Canonical safety classification for vehicle commands.
///
/// Determines how the safety interlock treats a command relative to
/// the vehicle's motion state.
enum SafetyClassification {
  /// Command is inherently safe while the vehicle is moving.
  /// Example: toggle headlight, trigger indicator, sound horn.
  safeWhileMoving,

  /// Command is safe while moving only when explicit additional
  /// safety conditions are met (e.g., parameter validation).
  /// Example: change riding mode (requires valid mode parameter).
  conditionallySafe,

  /// Command is sensitive to vehicle state. Blocked when the vehicle
  /// is moving unless an approved policy explicitly permits it.
  /// Example: future OTA firmware update trigger.
  safetySensitive,

  /// Command is unconditionally forbidden while the vehicle is in motion.
  /// Example: toggle lock, arm alarm, clear DTCs, start/stop charging.
  forbiddenWhileMoving,
}

// ─── Speed Trustworthiness ───────────────────────────────────────────────────

/// Describes the trustworthiness of the speed reading used for safety decisions.
enum SpeedTrustLevel {
  /// Speed value is live, available, within valid range, and fresh.
  trusted,

  /// Speed value is available but stale (exceeded freshness threshold).
  stale,

  /// Speed value is unavailable, null, or the source reports unavailability.
  unavailable,

  /// Speed value is present but invalid (NaN, negative, or impossibly high).
  invalid,

  /// Vehicle is disconnected; no telemetry source exists.
  disconnected,
}

// ─── Vehicle Safety Context ──────────────────────────────────────────────────

/// Minimal, deterministic context required for a safety decision.
///
/// Contains ONLY the information the safety interlock needs.
/// Does NOT contain unrelated vehicle telemetry, UI state, AI state,
/// or navigation state.
class VehicleSafetyContext {
  /// Normalized vehicle speed in km/h. Null if unavailable.
  final double? speedKmh;

  /// Trustworthiness assessment of the speed reading.
  final SpeedTrustLevel speedTrust;

  /// Whether the vehicle's physical connection is active.
  final bool isVehicleConnected;

  /// The safety classification of the command being evaluated.
  final SafetyClassification commandClassification;

  /// Age of the speed reading in milliseconds. Null if unavailable.
  final int? speedAgeMs;

  /// Source identifier of the speed reading (e.g., 'vehicle', 'gps', 'imu').
  final String? speedSource;

  const VehicleSafetyContext({
    required this.speedKmh,
    required this.speedTrust,
    required this.isVehicleConnected,
    required this.commandClassification,
    this.speedAgeMs,
    this.speedSource,
  });

  /// Factory for a fully disconnected/unavailable context.
  factory VehicleSafetyContext.disconnected({
    required SafetyClassification commandClassification,
  }) {
    return VehicleSafetyContext(
      speedKmh: null,
      speedTrust: SpeedTrustLevel.disconnected,
      isVehicleConnected: false,
      commandClassification: commandClassification,
    );
  }
}

// ─── Safety Decision ─────────────────────────────────────────────────────────

/// The binary safety decision: ALLOW or BLOCK.
enum SafetyDecision {
  /// Command is permitted to proceed to execution.
  allow,

  /// Command is rejected before reaching the actuator/hardware boundary.
  block,
}

// ─── Safety Verdict ──────────────────────────────────────────────────────────

/// Complete safety evaluation result with diagnostic metadata.
///
/// Provides the decision, the reason, and non-sensitive diagnostic
/// information for observability and audit logging.
class SafetyVerdict {
  /// The binary decision.
  final SafetyDecision decision;

  /// Human-readable reason for the decision.
  final String reason;

  /// The classification that was evaluated.
  final SafetyClassification classification;

  /// The speed trust level at the time of evaluation.
  final SpeedTrustLevel speedTrust;

  /// The speed value used in evaluation (null if unavailable).
  final double? evaluatedSpeedKmh;

  /// Timestamp of the evaluation.
  final DateTime evaluatedAt;

  const SafetyVerdict({
    required this.decision,
    required this.reason,
    required this.classification,
    required this.speedTrust,
    this.evaluatedSpeedKmh,
    required this.evaluatedAt,
  });

  /// Whether the command is allowed to proceed.
  bool get isAllowed => decision == SafetyDecision.allow;

  /// Whether the command was blocked.
  bool get isBlocked => decision == SafetyDecision.block;

  @override
  String toString() =>
      'SafetyVerdict(${decision.name}: $reason | class=$classification | '
      'speed=${evaluatedSpeedKmh?.toStringAsFixed(1) ?? "N/A"} km/h | '
      'trust=${speedTrust.name})';
}

// ─── Safety Interlock Contract ───────────────────────────────────────────────

/// Canonical Safety Interlock Contract (ADR-16).
///
/// The single authoritative decision point for command safety evaluation.
///
/// All command execution paths — UI, Voice, AI, Navigation, Android Auto,
/// AAOS, CarPlay — MUST route through this contract before reaching any
/// hardware actuator or device command adapter.
abstract class SafetyInterlock {
  /// Evaluates whether a command is safe to execute given the current
  /// vehicle safety context.
  ///
  /// This method MUST be:
  /// - Deterministic (same inputs → same output)
  /// - Synchronous (no network, AI, or database calls)
  /// - Fail-closed (uncertainty → BLOCK)
  /// - Platform-independent (no SDK dependencies)
  SafetyVerdict evaluate(VehicleSafetyContext context);
}

// ─── Canonical Motion Safety Interlock ────────────────────────────────────────

/// Production implementation of the canonical safety interlock.
///
/// Fail-closed policy:
/// - Missing speed → BLOCK
/// - Stale speed → BLOCK
/// - Invalid speed (NaN, negative, >500 km/h) → BLOCK
/// - Disconnected vehicle → BLOCK (for safety-sensitive/forbidden commands)
/// - Unknown state → BLOCK
///
/// Speed threshold for motion detection: > 0.0 km/h (ADR-16).
///
/// The freshness threshold reuses the existing codebase value of 3000ms
/// defined in `TelemetryValue.isStale`.
class MotionSafetyInterlock implements SafetyInterlock {
  /// Maximum accepted speed value in km/h. Values above this are
  /// considered sensor errors and treated as invalid.
  static const double maxValidSpeedKmh = 500.0;

  /// Maximum accepted age of a speed reading in milliseconds before
  /// it is considered stale. Matches existing `TelemetryValue.isStale`
  /// threshold in the codebase (3000ms).
  static const int freshnessThresholdMs = 3000;

  const MotionSafetyInterlock();

  @override
  SafetyVerdict evaluate(VehicleSafetyContext context) {
    final now = DateTime.now();

    // ── SAFE_WHILE_MOVING commands always pass ──────────────────────────
    if (context.commandClassification == SafetyClassification.safeWhileMoving) {
      return SafetyVerdict(
        decision: SafetyDecision.allow,
        reason: 'Command is classified as safe while moving.',
        classification: context.commandClassification,
        speedTrust: context.speedTrust,
        evaluatedSpeedKmh: context.speedKmh,
        evaluatedAt: now,
      );
    }

    // ── CONDITIONALLY_SAFE commands pass through (safety conditions
    //    are validated by the caller, not the motion interlock) ───────────
    if (context.commandClassification == SafetyClassification.conditionallySafe) {
      return SafetyVerdict(
        decision: SafetyDecision.allow,
        reason: 'Command is conditionally safe; additional validation is the caller\'s responsibility.',
        classification: context.commandClassification,
        speedTrust: context.speedTrust,
        evaluatedSpeedKmh: context.speedKmh,
        evaluatedAt: now,
      );
    }

    // ── For SAFETY_SENSITIVE and FORBIDDEN_WHILE_MOVING: evaluate state ──

    // 1. Vehicle disconnected → BLOCK
    if (!context.isVehicleConnected ||
        context.speedTrust == SpeedTrustLevel.disconnected) {
      return SafetyVerdict(
        decision: SafetyDecision.block,
        reason: 'Vehicle is disconnected. Cannot verify motion state for safety-sensitive command.',
        classification: context.commandClassification,
        speedTrust: context.speedTrust,
        evaluatedSpeedKmh: null,
        evaluatedAt: now,
      );
    }

    // 2. Speed unavailable → BLOCK (fail-closed: missing ≠ zero)
    if (context.speedTrust == SpeedTrustLevel.unavailable ||
        context.speedKmh == null) {
      return SafetyVerdict(
        decision: SafetyDecision.block,
        reason: 'Speed data is unavailable. Safety interlock defaults to BLOCK. '
            'Missing speed must never be treated as zero.',
        classification: context.commandClassification,
        speedTrust: SpeedTrustLevel.unavailable,
        evaluatedSpeedKmh: null,
        evaluatedAt: now,
      );
    }

    // 3. Speed stale → BLOCK
    if (context.speedTrust == SpeedTrustLevel.stale) {
      return SafetyVerdict(
        decision: SafetyDecision.block,
        reason: 'Speed data is stale (age: ${context.speedAgeMs ?? "unknown"}ms, '
            'threshold: ${freshnessThresholdMs}ms). Safety interlock defaults to BLOCK.',
        classification: context.commandClassification,
        speedTrust: SpeedTrustLevel.stale,
        evaluatedSpeedKmh: context.speedKmh,
        evaluatedAt: now,
      );
    }

    // 4. Speed invalid (NaN, negative, impossibly high) → BLOCK
    if (context.speedTrust == SpeedTrustLevel.invalid ||
        context.speedKmh!.isNaN ||
        context.speedKmh!.isInfinite ||
        context.speedKmh! < 0.0 ||
        context.speedKmh! > maxValidSpeedKmh) {
      return SafetyVerdict(
        decision: SafetyDecision.block,
        reason: 'Speed value is invalid (${context.speedKmh} km/h). '
            'Valid range: 0.0–$maxValidSpeedKmh km/h. Safety interlock defaults to BLOCK.',
        classification: context.commandClassification,
        speedTrust: SpeedTrustLevel.invalid,
        evaluatedSpeedKmh: context.speedKmh,
        evaluatedAt: now,
      );
    }

    // 5. Speed is trusted and within valid range — evaluate motion policy
    final isMoving = context.speedKmh! > 0.0;

    if (isMoving) {
      // FORBIDDEN_WHILE_MOVING → always block when moving
      if (context.commandClassification == SafetyClassification.forbiddenWhileMoving) {
        return SafetyVerdict(
          decision: SafetyDecision.block,
          reason: 'Command is forbidden while vehicle is in motion '
              '(speed: ${context.speedKmh!.toStringAsFixed(1)} km/h).',
          classification: context.commandClassification,
          speedTrust: context.speedTrust,
          evaluatedSpeedKmh: context.speedKmh,
          evaluatedAt: now,
        );
      }

      // SAFETY_SENSITIVE → block when moving (unless future policy overrides)
      if (context.commandClassification == SafetyClassification.safetySensitive) {
        return SafetyVerdict(
          decision: SafetyDecision.block,
          reason: 'Safety-sensitive command blocked while vehicle is in motion '
              '(speed: ${context.speedKmh!.toStringAsFixed(1)} km/h).',
          classification: context.commandClassification,
          speedTrust: context.speedTrust,
          evaluatedSpeedKmh: context.speedKmh,
          evaluatedAt: now,
        );
      }
    }

    // Vehicle is stationary with trusted speed data → ALLOW
    return SafetyVerdict(
      decision: SafetyDecision.allow,
      reason: 'Vehicle is stationary (speed: ${context.speedKmh!.toStringAsFixed(1)} km/h) '
          'with trusted telemetry. Command is permitted.',
      classification: context.commandClassification,
      speedTrust: context.speedTrust,
      evaluatedSpeedKmh: context.speedKmh,
      evaluatedAt: now,
    );
  }
}
