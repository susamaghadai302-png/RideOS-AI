import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('3D Motorcycle Official OEM GLB Assets Tests', () {
    test('Ducati Panigale V4 S OEM GLB exists and is non-empty', () async {
      final byteData = await rootBundle.load('assets/models/ducati_panigale.glb');
      expect(byteData.lengthInBytes, greaterThan(1000000));
    });

    test('BMW M 1000 RR OEM GLB exists and is non-empty', () async {
      final byteData = await rootBundle.load('assets/models/bmw_m1000rr.glb');
      expect(byteData.lengthInBytes, greaterThan(1000000));
    });
  });
}
