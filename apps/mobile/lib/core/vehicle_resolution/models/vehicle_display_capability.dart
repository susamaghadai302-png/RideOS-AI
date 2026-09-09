import 'package:flutter/material.dart';

enum ConnectionProtocol {
  androidAuto,
  androidAutomotiveOS,
  secondaryAndroidDisplay,
  bluetooth,
  ble,
  wifi,
  usb,
  vendorApi,
  unsupported
}

enum ConnectionStatus {
  disconnected,
  discovering,
  connecting,
  connected,
  authenticating,
  ready,
  degraded,
  unsupported,
  error
}

class VehicleDisplayCapability {
  final ConnectionProtocol protocol;
  final ConnectionStatus status;
  final bool hasNavigation;
  final bool hasAudio;
  final bool hasMicrophone;
  final bool hasCalling;
  final bool hasTouch;
  final bool hasVoice;
  final Size? screenDimensions;
  final Orientation? orientation;

  const VehicleDisplayCapability({
    required this.protocol,
    required this.status,
    this.hasNavigation = false,
    this.hasAudio = false,
    this.hasMicrophone = false,
    this.hasCalling = false,
    this.hasTouch = false,
    this.hasVoice = false,
    this.screenDimensions,
    this.orientation,
  });

  VehicleDisplayCapability copyWith({
    ConnectionProtocol? protocol,
    ConnectionStatus? status,
    bool? hasNavigation,
    bool? hasAudio,
    bool? hasMicrophone,
    bool? hasCalling,
    bool? hasTouch,
    bool? hasVoice,
    Size? screenDimensions,
    Orientation? orientation,
  }) {
    return VehicleDisplayCapability(
      protocol: protocol ?? this.protocol,
      status: status ?? this.status,
      hasNavigation: hasNavigation ?? this.hasNavigation,
      hasAudio: hasAudio ?? this.hasAudio,
      hasMicrophone: hasMicrophone ?? this.hasMicrophone,
      hasCalling: hasCalling ?? this.hasCalling,
      hasTouch: hasTouch ?? this.hasTouch,
      hasVoice: hasVoice ?? this.hasVoice,
      screenDimensions: screenDimensions ?? this.screenDimensions,
      orientation: orientation ?? this.orientation,
    );
  }

  factory VehicleDisplayCapability.unsupported() {
    return const VehicleDisplayCapability(
      protocol: ConnectionProtocol.unsupported,
      status: ConnectionStatus.unsupported,
    );
  }

  factory VehicleDisplayCapability.androidAuto() {
    return const VehicleDisplayCapability(
      protocol: ConnectionProtocol.androidAuto,
      status: ConnectionStatus.ready,
      hasNavigation: true,
      hasAudio: true,
      hasMicrophone: true,
      hasCalling: true,
      hasTouch: true,
      hasVoice: true,
    );
  }
}
