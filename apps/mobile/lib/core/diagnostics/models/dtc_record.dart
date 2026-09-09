import 'package:flutter/foundation.dart';
import 'diagnostic_types.dart';

/// Normalized Diagnostic Trouble Code (DTC) representation.
@immutable
class DiagnosticFaultRecord {
  final String code; // e.g. "P0300", "C0035", "U0100", "B1000"
  final EcuModule module;
  final DtcSeverity severity;
  final DtcSystemCategory category;
  final String title;
  final String description;
  final String probableCause;
  final String recommendedRemedy;
  final Map<String, dynamic> freezeFrameSnapshot;
  final DateTime detectedAt;
  final bool isMilLampTriggered;

  const DiagnosticFaultRecord({
    required this.code,
    required this.module,
    required this.severity,
    required this.category,
    required this.title,
    required this.description,
    required this.probableCause,
    required this.recommendedRemedy,
    this.freezeFrameSnapshot = const {},
    required this.detectedAt,
    this.isMilLampTriggered = false,
  });

  /// Factory parser for 2-byte raw OBD-II DTC encoding (SAE J1979 / ISO 15031-6).
  ///
  /// First byte bits 7-6:
  ///   00 -> P (Powertrain)
  ///   01 -> C (Chassis)
  ///   10 -> B (Body)
  ///   11 -> U (Network/Communication)
  /// First byte bits 5-4: 0-3 (second character)
  /// First byte bits 3-0: 0-F (third character)
  /// Second byte bits 7-4: 0-F (fourth character)
  /// Second byte bits 3-0: 0-F (fifth character)
  factory DiagnosticFaultRecord.fromRawBytes(
    int byteA,
    int byteB, {
    EcuModule module = EcuModule.engineControlModule_ECM,
    DtcSeverity severity = DtcSeverity.confirmedActive,
    Map<String, dynamic> freezeFrame = const {},
  }) {
    final catCode = (byteA >> 6) & 0x03;
    final cat = switch (catCode) {
      0 => DtcSystemCategory.powertrain,
      1 => DtcSystemCategory.chassis,
      2 => DtcSystemCategory.body,
      _ => DtcSystemCategory.network,
    };

    final prefix = cat.prefix;
    final digit2 = ((byteA >> 4) & 0x03).toRadixString(16).toUpperCase();
    final digit3 = (byteA & 0x0F).toRadixString(16).toUpperCase();
    final digit4 = ((byteB >> 4) & 0x0F).toRadixString(16).toUpperCase();
    final digit5 = (byteB & 0x0F).toRadixString(16).toUpperCase();

    final code = '$prefix$digit2$digit3$digit4$digit5';

    return DiagnosticFaultRecord(
      code: code,
      module: module,
      severity: severity,
      category: cat,
      title: 'Fault Code $code',
      description: 'Standard diagnostic trouble code reported by ${module.displayName}',
      probableCause: 'Sensor, actuator, or circuit variance detected.',
      recommendedRemedy: 'Inspect wiring and sensor values with diagnostic tool.',
      freezeFrameSnapshot: freezeFrame,
      detectedAt: DateTime.now(),
      isMilLampTriggered: severity == DtcSeverity.criticalStopEngine || severity == DtcSeverity.confirmedActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'module': module.name,
        'severity': severity.name,
        'category': category.name,
        'title': title,
        'description': description,
        'probableCause': probableCause,
        'recommendedRemedy': recommendedRemedy,
        'freezeFrameSnapshot': freezeFrameSnapshot,
        'detectedAt': detectedAt.toIso8601String(),
        'isMilLampTriggered': isMilLampTriggered,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticFaultRecord &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          module == other.module;

  @override
  int get hashCode => code.hashCode ^ module.hashCode;

  @override
  String toString() => 'DiagnosticFaultRecord($code [${severity.label}] - $title)';
}
