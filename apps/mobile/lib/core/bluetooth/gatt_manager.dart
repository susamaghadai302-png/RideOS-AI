import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GattCharacteristicDiagnostic {
  final String uuid;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;

  GattCharacteristicDiagnostic(this.uuid, this.canRead, this.canWrite, this.canNotify);
}

class GattServiceDiagnostic {
  final String uuid;
  final List<GattCharacteristicDiagnostic> characteristics;

  GattServiceDiagnostic(this.uuid, this.characteristics);
}

class GattManager {
  static final GattManager _instance = GattManager._internal();
  factory GattManager() => _instance;
  GattManager._internal();

  List<GattServiceDiagnostic> diagnosticMap = [];
  List<BluetoothService> activeServices = [];

  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    activeServices = await device.discoverServices();
    diagnosticMap = activeServices.map((service) {
      return GattServiceDiagnostic(
        service.uuid.toString(),
        service.characteristics.map((c) => GattCharacteristicDiagnostic(
          c.uuid.toString(),
          c.properties.read,
          c.properties.write || c.properties.writeWithoutResponse,
          c.properties.notify || c.properties.indicate,
        )).toList(),
      );
    }).toList();
    
    return activeServices;
  }
}
