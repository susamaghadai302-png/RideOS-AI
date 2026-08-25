import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../vehicle_protocols/protocol_adapter.dart';

class SafetyViolationException implements Exception {
  final String message;
  SafetyViolationException(this.message);
  @override
  String toString() => 'SafetyViolationException: $message';
}

class CharacteristicWriter {
  static final CharacteristicWriter _instance = CharacteristicWriter._internal();
  factory CharacteristicWriter() => _instance;
  CharacteristicWriter._internal();

  /// Safely writes data to a characteristic.
  /// Throws SafetyViolationException if the ProtocolAdapter deems it unsafe.
  Future<void> safeWrite(
    BluetoothCharacteristic characteristic,
    List<int> payload,
    ProtocolAdapter adapter,
    String capabilityKey,
  ) async {
    if (!adapter.isSafeToWrite(capabilityKey, payload)) {
      throw SafetyViolationException(
        'Adapter ${adapter.adapterId} rejected write for $capabilityKey: Unsafe vehicle state or unknown payload.',
      );
    }
    
    // Only proceed if safety check passes
    try {
      await characteristic.write(payload, withoutResponse: false);
    } catch (e) {
      throw Exception('Bluetooth write failed: $e');
    }
  }
}
