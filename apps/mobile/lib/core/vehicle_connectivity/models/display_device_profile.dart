import 'package:flutter/foundation.dart';
import 'display_capability.dart';

@immutable
class DisplayDeviceProfile {
  final String manufacturer;
  final String model;
  final String transportType;
  final String protocolType;
  final List<String> serviceUuids;
  final List<String> characteristics;
  final Set<DisplayCapability> supportedCapabilities;
  final String? firmwareVersion;

  const DisplayDeviceProfile({
    required this.manufacturer,
    required this.model,
    required this.transportType,
    required this.protocolType,
    this.serviceUuids = const [],
    this.characteristics = const [],
    this.supportedCapabilities = const {},
    this.firmwareVersion,
  });
}
