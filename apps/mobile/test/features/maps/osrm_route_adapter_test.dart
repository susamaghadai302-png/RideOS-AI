import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideos_mobile/features/maps/domain/models/ride_route_models.dart';
import 'package:rideos_mobile/features/maps/core/adapters/osrm_route_adapter.dart';

void main() {
  group('OsrmRouteAdapter Tests', () {
    late OsrmRouteAdapter adapter;

    setUp(() {
      adapter = OsrmRouteAdapter();
    });
    test('Maps RideRouteType.safe throws UnsupportedError', () async {
      const request = RideRouteRequest(
        origin: LatLng(0, 0),
        destination: LatLng(1, 1),
        preferredRouteType: RideRouteType.safe,
      );
      expect(() => adapter.calculateRoute(request), throwsUnsupportedError);
    });

    test('Maps RideRouteType.eco throws UnsupportedError', () async {
      const request = RideRouteRequest(
        origin: LatLng(0, 0),
        destination: LatLng(1, 1),
        preferredRouteType: RideRouteType.eco,
      );
      expect(() => adapter.calculateRoute(request), throwsUnsupportedError);
    });
    
    test('Maps RideRouteType.scenic throws UnsupportedError', () async {
      const request = RideRouteRequest(
        origin: LatLng(0, 0),
        destination: LatLng(1, 1),
        preferredRouteType: RideRouteType.scenic,
      );
      expect(() => adapter.calculateRoute(request), throwsUnsupportedError);
    });
  });
}
