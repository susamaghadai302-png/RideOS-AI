import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum ConnectionTransportType {
  ble('REAL BLE DETECTED'),
  manualSelection('MANUAL SELECTION'),
  simulator('SIMULATOR'),
  usbSerial('USB SERIAL'),
  obdGateway('OBD-II GATEWAY'),
  canGateway('CAN-BUS GATEWAY'),
  oemApi('OEM CLOUD API');

  final String userFacingLabel;
  const ConnectionTransportType(this.userFacingLabel);
}

enum IdentityConfidence {
  exactMatch('EXACT_MATCH', 1.0, 'VERIFIED', 'Exact OEM & Model Match Verified'),
  verifiedMatch('VERIFIED_MATCH', 0.90, 'IDENTIFIED', 'Known Model Family & Variant Verified'),
  partialMatch('PARTIAL_MATCH', 0.50, 'MODEL_VALIDATION_PENDING', 'Partial Match / Model Validation Pending'),
  unknown('UNKNOWN', 0.10, 'UNKNOWN', 'Unrecognized Vehicle Hardware Signature'),
  conflict('CONFLICT', 0.0, 'UNKNOWN', 'Conflicting Vehicle Signatures Detected');

  final String code;
  final double score;
  final String statusCategory; // 'VERIFIED', 'IDENTIFIED', 'UNKNOWN', 'MODEL_VALIDATION_PENDING'
  final String label;
  const IdentityConfidence(this.code, this.score, this.statusCategory, this.label);

  bool get allowsAutomatic3DModel => this == IdentityConfidence.exactMatch;
}

enum IdentityFieldProvenance {
  vinDecode,
  gattDiscovery,
  advertisedName,
  protocolQuery,
  ecuCalibrationQuery,
  manualSelection,
  cachedDeviceAssociation,
}

@immutable
class VehicleIdentity {
  final String sessionConnectionId;
  final ConnectionTransportType connectionType;
  final String deviceIdentifier; // MAC, Serial, Port, or Endpoint
  final String manufacturer;
  final String make;
  final String model;
  final String variant;
  final int? modelYear;
  final String? vin;
  final String? ecuIdentifier;
  final String? firmwareVersion;
  final String protocolAdapterId;
  final IdentityConfidence confidence;
  final Map<String, IdentityFieldProvenance> fieldProvenance;
  final Map<String, dynamic> metadata;
  final DateTime establishedAt;

  VehicleIdentity({
    String? sessionConnectionId,
    required this.connectionType,
    required this.deviceIdentifier,
    required this.manufacturer,
    String? make,
    required this.model,
    this.variant = '',
    this.modelYear,
    this.vin,
    this.ecuIdentifier,
    this.firmwareVersion,
    required this.protocolAdapterId,
    required this.confidence,
    Map<String, IdentityFieldProvenance>? fieldProvenance,
    Map<String, dynamic>? metadata,
    DateTime? establishedAt,
  })  : sessionConnectionId = sessionConnectionId ?? const Uuid().v4(),
        make = make ?? manufacturer,
        fieldProvenance = Map.unmodifiable(fieldProvenance ?? {}),
        metadata = Map.unmodifiable(metadata ?? {}),
        establishedAt = establishedAt ?? DateTime.now();

  String get canonicalKey => '${make.trim().toLowerCase()}_${model.trim().toLowerCase()}_${variant.trim().toLowerCase()}_${modelYear ?? "unknown"}';
  String get displayName => '$make $model ${variant.isNotEmpty ? variant : ''} ${modelYear != null ? '($modelYear)' : ''}'.trim();
  bool get isExactMatch => confidence == IdentityConfidence.exactMatch;
  bool get isVerified => confidence == IdentityConfidence.exactMatch || confidence == IdentityConfidence.verifiedMatch;

  factory VehicleIdentity.unknown({
    required ConnectionTransportType connectionType,
    required String deviceIdentifier,
    String? rawAdvertisementName,
  }) {
    return VehicleIdentity(
      connectionType: connectionType,
      deviceIdentifier: deviceIdentifier,
      manufacturer: 'Unknown',
      make: 'Unknown',
      model: rawAdvertisementName != null && rawAdvertisementName.isNotEmpty ? rawAdvertisementName : 'Unknown Two-Wheeler',
      variant: 'Unverified',
      modelYear: null,
      protocolAdapterId: 'generic_ble',
      confidence: IdentityConfidence.unknown,
      fieldProvenance: const {
        'model': IdentityFieldProvenance.advertisedName,
      },
    );
  }

  VehicleIdentity copyWith({
    String? sessionConnectionId,
    ConnectionTransportType? connectionType,
    String? deviceIdentifier,
    String? manufacturer,
    String? make,
    String? model,
    String? variant,
    int? modelYear,
    String? vin,
    String? ecuIdentifier,
    String? firmwareVersion,
    String? protocolAdapterId,
    IdentityConfidence? confidence,
    Map<String, IdentityFieldProvenance>? fieldProvenance,
    Map<String, dynamic>? metadata,
    DateTime? establishedAt,
  }) {
    return VehicleIdentity(
      sessionConnectionId: sessionConnectionId ?? this.sessionConnectionId,
      connectionType: connectionType ?? this.connectionType,
      deviceIdentifier: deviceIdentifier ?? this.deviceIdentifier,
      manufacturer: manufacturer ?? this.manufacturer,
      make: make ?? this.make,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      modelYear: modelYear ?? this.modelYear,
      vin: vin ?? this.vin,
      ecuIdentifier: ecuIdentifier ?? this.ecuIdentifier,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      protocolAdapterId: protocolAdapterId ?? this.protocolAdapterId,
      confidence: confidence ?? this.confidence,
      fieldProvenance: fieldProvenance ?? this.fieldProvenance,
      metadata: metadata ?? this.metadata,
      establishedAt: establishedAt ?? this.establishedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionConnectionId': sessionConnectionId,
    'connectionType': connectionType.name,
    'deviceIdentifier': deviceIdentifier,
    'manufacturer': manufacturer,
    'make': make,
    'model': model,
    'variant': variant,
    'modelYear': modelYear,
    'vin': vin,
    'ecuIdentifier': ecuIdentifier,
    'firmwareVersion': firmwareVersion,
    'protocolAdapterId': protocolAdapterId,
    'confidence': confidence.code,
    'fieldProvenance': fieldProvenance.map((k, v) => MapEntry(k, v.name)),
    'metadata': metadata,
    'establishedAt': establishedAt.toIso8601String(),
  };
}
