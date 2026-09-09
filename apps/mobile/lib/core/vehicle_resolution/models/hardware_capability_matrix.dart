import 'vehicle_display_capability.dart';

enum MatrixStatus {
  supported,
  supportedWithLimitations,
  requiresHardware,
  unsupported
}

class HardwareCapabilityMatrix {
  static MatrixStatus getStatus({
    required String vehicleCategory,
    required ConnectionProtocol protocol,
  }) {
    if (vehicleCategory.toLowerCase().contains('car')) {
      switch (protocol) {
        case ConnectionProtocol.androidAuto: return MatrixStatus.supported;
        case ConnectionProtocol.androidAutomotiveOS: return MatrixStatus.supportedWithLimitations;
        case ConnectionProtocol.bluetooth: return MatrixStatus.supported;
        case ConnectionProtocol.ble: return MatrixStatus.supported;
        case ConnectionProtocol.usb: return MatrixStatus.supported;
        default: return MatrixStatus.unsupported;
      }
    } else if (vehicleCategory.toLowerCase().contains('motorcycle') || vehicleCategory.toLowerCase().contains('bike')) {
      switch (protocol) {
        case ConnectionProtocol.secondaryAndroidDisplay: return MatrixStatus.supported;
        case ConnectionProtocol.bluetooth: return MatrixStatus.supported;
        case ConnectionProtocol.ble: return MatrixStatus.supported;
        case ConnectionProtocol.wifi: return MatrixStatus.supportedWithLimitations;
        case ConnectionProtocol.vendorApi: return MatrixStatus.requiresHardware;
        default: return MatrixStatus.unsupported;
      }
    } else if (vehicleCategory.toLowerCase().contains('scooter')) {
      switch (protocol) {
        case ConnectionProtocol.secondaryAndroidDisplay: return MatrixStatus.supported;
        case ConnectionProtocol.bluetooth: return MatrixStatus.requiresHardware;
        case ConnectionProtocol.ble: return MatrixStatus.supported;
        default: return MatrixStatus.unsupported;
      }
    }
    
    return MatrixStatus.unsupported;
  }
}
