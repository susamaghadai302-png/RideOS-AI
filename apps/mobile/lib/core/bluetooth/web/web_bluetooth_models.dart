
class WebBleSupportInfo {
  final bool isSupported;
  final bool isSecureContext;
  final bool isLocalhost;
  final String userAgent;
  final String reason;

  const WebBleSupportInfo({
    required this.isSupported,
    required this.isSecureContext,
    required this.isLocalhost,
    required this.userAgent,
    required this.reason,
  });

  factory WebBleSupportInfo.fromJson(Map<String, dynamic> json) {
    return WebBleSupportInfo(
      isSupported: json['supported'] == true,
      isSecureContext: json['isSecureContext'] == true,
      isLocalhost: json['isLocalhost'] == true,
      userAgent: json['userAgent']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  factory WebBleSupportInfo.unsupported(String reason) {
    return WebBleSupportInfo(
      isSupported: false,
      isSecureContext: false,
      isLocalhost: false,
      userAgent: '',
      reason: reason,
    );
  }
}

class WebBleCharacteristic {
  final String uuid;
  final List<String> properties;

  const WebBleCharacteristic({
    required this.uuid,
    required this.properties,
  });

  factory WebBleCharacteristic.fromJson(Map<String, dynamic> json) {
    return WebBleCharacteristic(
      uuid: json['uuid']?.toString() ?? '',
      properties: (json['properties'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class WebBleService {
  final String uuid;
  final String name;
  final bool isPrimary;
  final int characteristicsCount;
  final List<WebBleCharacteristic> characteristics;

  const WebBleService({
    required this.uuid,
    required this.name,
    this.isPrimary = true,
    this.characteristicsCount = 0,
    this.characteristics = const [],
  });

  factory WebBleService.fromJson(Map<String, dynamic> json) {
    final charsList = (json['characteristics'] as List<dynamic>?)
            ?.map((e) => WebBleCharacteristic.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return WebBleService(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Custom Service',
      isPrimary: json['isPrimary'] == true,
      characteristicsCount: json['characteristicsCount'] as int? ?? charsList.length,
      characteristics: charsList,
    );
  }
}

class WebBleDevice {
  final String id;
  final String name;
  final bool isConnected;
  final List<WebBleService> services;
  final DateTime connectedAt;

  const WebBleDevice({
    required this.id,
    required this.name,
    required this.isConnected,
    this.services = const [],
    required this.connectedAt,
  });

  WebBleDevice copyWith({
    String? id,
    String? name,
    bool? isConnected,
    List<WebBleService>? services,
    DateTime? connectedAt,
  }) {
    return WebBleDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      isConnected: isConnected ?? this.isConnected,
      services: services ?? this.services,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

class WebBleRequestResult {
  final bool success;
  final bool cancelled;
  final String? deviceId;
  final String? deviceName;
  final bool isConnected;
  final String? error;

  const WebBleRequestResult({
    required this.success,
    this.cancelled = false,
    this.deviceId,
    this.deviceName,
    this.isConnected = false,
    this.error,
  });

  factory WebBleRequestResult.fromJson(Map<String, dynamic> json) {
    return WebBleRequestResult(
      success: json['success'] == true,
      cancelled: json['cancelled'] == true,
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      isConnected: json['isConnected'] == true,
      error: json['error']?.toString(),
    );
  }
}

class WebBleGattResult {
  final bool success;
  final String? deviceId;
  final String? deviceName;
  final bool isConnected;
  final List<WebBleService> services;
  final String? error;

  const WebBleGattResult({
    required this.success,
    this.deviceId,
    this.deviceName,
    this.isConnected = false,
    this.services = const [],
    this.error,
  });

  factory WebBleGattResult.fromJson(Map<String, dynamic> json) {
    final sList = (json['services'] as List<dynamic>?)
            ?.map((e) => WebBleService.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return WebBleGattResult(
      success: json['success'] == true,
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
      isConnected: json['isConnected'] == true,
      services: sList,
      error: json['error']?.toString(),
    );
  }
}
