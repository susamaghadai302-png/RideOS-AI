/// Hardware Safety Boundary Contract (ADR-16).
///
/// Represents the physical/firmware-level safety interlock that exists
/// on the actual vehicle hardware, separate from the software safety
/// interlock ([SafetyInterlock]).
///
/// The complete safety chain is:
///
/// ```
/// Command → Software Safety Interlock → Hardware Safety Boundary → Actuator
/// ```
///
/// Both software AND hardware interlocks must independently agree
/// before any safety-sensitive command reaches the actuator.
///
/// This contract establishes the interface; actual implementation
/// is protocol-specific (OBD-II, BLE, CAN, VHAL) and belongs in
/// the adapter layer, NOT the domain layer.
///
/// Platform-independent: No Flutter, Android, iOS, BLE, or OBD SDK imports.
library;

/// Contract for the hardware-level safety boundary.
///
/// This is the final gate before a command reaches a physical actuator.
/// Even if the software [SafetyInterlock] allows a command, the hardware
/// boundary may independently reject it based on firmware-level state.
abstract class HardwareSafetyBoundary {
  /// Queries whether the hardware-level safety interlock is currently engaged.
  ///
  /// When engaged, the hardware independently blocks safety-sensitive commands
  /// regardless of the software interlock state.
  ///
  /// Returns `true` if the hardware interlock is actively blocking commands.
  /// Returns `null` if the hardware interlock state cannot be determined
  /// (fail-closed: this should be treated as engaged/blocking by the caller).
  Future<bool?> isHardwareInterlockEngaged();

  /// Requests a temporary safety override from the hardware.
  ///
  /// This is for authorized maintenance/diagnostic scenarios only
  /// (e.g., factory service mode with physical key authorization).
  ///
  /// The [authorizationToken] must be validated by the hardware.
  /// The override is time-limited and automatically expires.
  ///
  /// Returns `true` if the override was accepted by the hardware.
  /// Returns `false` if the hardware rejected the override request.
  Future<bool> requestHardwareSafetyOverride(String authorizationToken);

  /// A human-readable identifier for audit logging.
  String get boundaryId;
}
