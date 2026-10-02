
import '../models/display_device_profile.dart';
import 'vehicle_connectivity_adapter.dart';

abstract class DisplayAdapter extends VehicleConnectivityAdapter {
  DisplayDeviceProfile get displayProfile;
  Future<bool> sendDisplayPacket(dynamic packet); // Accepts RideOSDisplayPacket later
}

class DisplayAdapterRegistry {
  static final List<DisplayAdapter> _adapters = [];

  static void register(DisplayAdapter adapter) {
    _adapters.add(adapter);
  }

  static DisplayAdapter? findAdapter(String protocolType) {
    for (final adapter in _adapters) {
      if (adapter.displayProfile.protocolType == protocolType) {
        return adapter;
      }
    }
    return null;
  }
}
