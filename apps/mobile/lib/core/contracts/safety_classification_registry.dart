/// Canonical Safety Classification Registry (ADR-16).
///
/// Provides the authoritative mapping from [VehicleCommandType]
/// to [SafetyClassification].
///
/// This registry is the SINGLE SOURCE OF TRUTH for which commands
/// are permitted while the vehicle is in motion, and which are not.
///
/// No command type may be absent from this registry. Any unregistered
/// command type defaults to [SafetyClassification.forbiddenWhileMoving]
/// (fail-closed).
library;

import '../vehicle_commands/models/vehicle_command.dart';
import 'safety_interlock.dart';

/// Returns the canonical [SafetyClassification] for a given [VehicleCommandType].
///
/// **Fail-closed default:** If a command type is not explicitly registered,
/// it is treated as [SafetyClassification.forbiddenWhileMoving].
SafetyClassification classifyCommand(VehicleCommandType type) {
  return _commandClassificationTable[type] ??
      SafetyClassification.forbiddenWhileMoving;
}

/// Canonical classification table.
///
/// Each command type is explicitly listed to prevent silent omissions.
///
/// Classification rationale:
///
/// | Classification | Rule |
/// |---|---|
/// | `safeWhileMoving` | Lighting controls, horn — rider-initiated, safe at speed |
/// | `conditionallySafe` | Riding mode — depends on parameter validation |
/// | `forbiddenWhileMoving` | Lock, alarm, charging, DTC clear — require standstill |
const Map<VehicleCommandType, SafetyClassification> _commandClassificationTable = {
  // ── Lighting Controls ─────────────────────────────────────────────────
  VehicleCommandType.toggleHeadlight:       SafetyClassification.safeWhileMoving,
  VehicleCommandType.setHighBeam:           SafetyClassification.safeWhileMoving,
  VehicleCommandType.triggerLeftIndicator:   SafetyClassification.safeWhileMoving,
  VehicleCommandType.triggerRightIndicator:  SafetyClassification.safeWhileMoving,
  VehicleCommandType.triggerHazard:          SafetyClassification.safeWhileMoving,

  // ── Audio / Alert ─────────────────────────────────────────────────────
  VehicleCommandType.triggerHorn:            SafetyClassification.safeWhileMoving,

  // ── Conditionally Safe ────────────────────────────────────────────────
  VehicleCommandType.setRidingMode:          SafetyClassification.conditionallySafe,

  // ── Forbidden While Moving ────────────────────────────────────────────
  VehicleCommandType.toggleLock:             SafetyClassification.forbiddenWhileMoving,
  VehicleCommandType.toggleAlarm:            SafetyClassification.forbiddenWhileMoving,
  VehicleCommandType.startCharging:          SafetyClassification.forbiddenWhileMoving,
  VehicleCommandType.stopCharging:           SafetyClassification.forbiddenWhileMoving,
  VehicleCommandType.clearFaultCodes:        SafetyClassification.forbiddenWhileMoving,
};
