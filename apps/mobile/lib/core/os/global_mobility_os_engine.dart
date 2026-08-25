import 'dart:developer' as developer;

enum VehicleCategory {
  motorcycle,
  scooter,
  car,
  electricVehicle,
  commercialVehicle,
}

class RegisteredIotDevice {
  final String deviceId;
  final String deviceType; // 'HELMET_HUD', 'DASHCAM_4K', 'OBD_BLE_5', 'TPMS_SENSOR', 'SMART_WATCH'
  final bool isConnected;
  final int batteryLevelPercentage;

  const RegisteredIotDevice({
    required this.deviceId,
    required this.deviceType,
    required this.isConnected,
    required this.batteryLevelPercentage,
  });
}

class SdkVersionInfo {
  final String sdkName;
  final String version;
  final String buildStatus;

  const SdkVersionInfo({
    required this.sdkName,
    required this.version,
    required this.buildStatus,
  });
}

class GlobalMobilityOsEngine {
  static final GlobalMobilityOsEngine instance = GlobalMobilityOsEngine._internal();
  GlobalMobilityOsEngine._internal();

  List<SdkVersionInfo> getActiveSdkModules() {
    developer.log('Auditing RideOS SDK Suite...', name: 'RideOS.MobilityOS');
    return const [
      SdkVersionInfo(sdkName: 'RideOS Telemetry SDK', version: 'v6.5.0', buildStatus: 'READY'),
      SdkVersionInfo(sdkName: 'RideOS Edge AI SDK', version: 'v6.5.0', buildStatus: 'READY'),
      SdkVersionInfo(sdkName: 'RideOS Plugin SDK', version: 'v6.5.0', buildStatus: 'READY'),
    ];
  }

  List<RegisteredIotDevice> listUniversalIotDevices() {
    return const [
      RegisteredIotDevice(deviceId: 'dev_helmet_ar_v1', deviceType: 'HELMET_HUD', isConnected: true, batteryLevelPercentage: 88),
      RegisteredIotDevice(deviceId: 'dev_obd_fast_ble', deviceType: 'OBD_BLE_5', isConnected: true, batteryLevelPercentage: 100),
      RegisteredIotDevice(deviceId: 'dev_tpms_front_rear', deviceType: 'TPMS_SENSOR', isConnected: true, batteryLevelPercentage: 94),
    ];
  }
}
