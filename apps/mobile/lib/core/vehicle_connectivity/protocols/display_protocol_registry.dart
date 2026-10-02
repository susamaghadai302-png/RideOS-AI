import '../models/display_device_profile.dart';
import 'display_protocol.dart';
import 'rideos_native_display_protocol.dart';
import 'generic_ble_display_protocol.dart';
import 'bluetooth_classic_display_protocol.dart';
import 'yamaha_navilite_protocol.dart';
import 'ktm_gen3_protocol.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DISPLAY PROTOCOL REGISTRY
// ─────────────────────────────────────────────────────────────────────────────

class ProtocolBundle {
  final DisplayProtocol protocol;

  const ProtocolBundle({
    required this.protocol,
  });
}

class DisplayProtocolRegistry {
  static final DisplayProtocolRegistry _instance = DisplayProtocolRegistry._internal();
  factory DisplayProtocolRegistry() => _instance;
  DisplayProtocolRegistry._internal() {
    _registerDefaults();
  }

  final Map<String, ProtocolBundle> _registry = {};

  void register(ProtocolBundle bundle) {
    _registry[bundle.protocol.protocolId] = bundle;
  }

  ProtocolBundle? lookup(String protocolId) => _registry[protocolId];

  List<String> get registeredProtocols => _registry.keys.toList(growable: false);

  ProtocolBundle? resolveForProfile(DisplayDeviceProfile profile) {
    final exact = _registry[profile.protocolType];
    if (exact != null) return exact;

    switch (profile.transportType) {
      case 'BLE':
        return _registry['generic_ble_json_v1'];
      case 'BT_CLASSIC':
        return _registry['bt_classic_spp_v1'];
      default:
        return null;
    }
  }

  void _registerDefaults() {
    register(ProtocolBundle(protocol: RideOSNativeDisplayProtocol()));
    register(ProtocolBundle(protocol: GenericBleDisplayProtocol()));
    register(ProtocolBundle(protocol: BluetoothClassicDisplayProtocol()));
    register(ProtocolBundle(protocol: YamahaNaviLiteBluetoothProtocol()));
    register(ProtocolBundle(protocol: KtmGen3BluetoothProtocol()));
  }
}
