import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/hardware/obd/pid_decoder.dart';

void main() {
  group('PidDecoder J1979 Tests', () {
    test('Decodes Engine RPM correctly (010C)', () {
      // 41 0C 1A F8 -> A=26, B=248 -> ((26 * 256) + 248) / 4 = 1726 RPM
      expect(PidDecoder.decode('010C', '41 0C 1A F8'), 1726.0);
    });

    test('Decodes Vehicle Speed correctly (010D)', () {
      // 41 0D 32 -> A=50 -> 50 km/h
      expect(PidDecoder.decode('010D', '41 0D 32'), 50.0);
    });

    test('Decodes Coolant Temp correctly (0105)', () {
      // 41 05 5A -> A=90 -> 90 - 40 = 50°C
      expect(PidDecoder.decode('0105', '41 05 5A'), 50.0);
    });

    test('Throws on malformed or too short response', () {
      expect(() => PidDecoder.decode('010C', '41'), throwsFormatException);
    });

    test('Throws on unsupported PID decoding', () {
      expect(() => PidDecoder.decode('01FF', '41 FF 10'), throwsUnimplementedError);
    });
  });
}
