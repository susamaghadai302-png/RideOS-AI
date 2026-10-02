import 'dart:typed_data';
import '../models/rideos_display_packet.dart';
import '../models/display_capability.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DISPLAY PROTOCOL — Abstract protocol layer
//
//  Every concrete protocol MUST implement this interface to perform real
//  evidence-based connection, probing, capability negotiation, and streaming.
//  No simulated success or fixed delays are allowed.
// ─────────────────────────────────────────────────────────────────────────────

abstract class DisplayProtocol {
  /// Unique protocol identifier (e.g. 'rideos_native_v1', 'bt_classic_spp_v1').
  String get protocolId;

  /// Human-readable name.
  String get protocolName;

  /// The physical transport this protocol requires (e.g., 'BLE' or 'BT_CLASSIC').
  String get requiredTransport;

  /// Performs a fast, non-state-changing probe to see if the connected
  /// device actually speaks this protocol. Must return true ONLY if
  /// explicit evidence (e.g., correct frame format response) is received.
  Future<bool> probe(DisplayTransport transport);

  /// Performs the full session handshake and authentication.
  Future<bool> handshake(DisplayTransport transport);

  /// Requests actual supported capabilities from the device.
  /// If the protocol does not support capability negotiation, it returns
  /// its known static capabilities.
  Future<Set<DisplayCapability>> getCapabilities(DisplayTransport transport);

  /// Executes any final commands required before the stream begins.
  Future<bool> startSession(DisplayTransport transport);

  /// Sends a data packet filtered by the negotiated capabilities.
  Future<bool> sendPacket(DisplayTransport transport, RideOSDisplayPacket packet, Set<DisplayCapability> activeCapabilities);

  /// Cleanly closes the protocol session.
  Future<void> disconnect(DisplayTransport transport);
}

/// Abstract transport layer allowing protocols to read/write bytes
/// without knowing if it's BLE GATT or Classic RFCOMM.
abstract class DisplayTransport {
  Future<bool> connect(String identifier);
  Future<void> disconnect();
  Future<bool> write(Uint8List data);
  Future<Uint8List?> read({Duration timeout = const Duration(seconds: 3)});
  Future<Uint8List?> sendAndReceive(Uint8List data, {Duration timeout = const Duration(seconds: 3)});
  
  // Specific to BLE discovery
  Future<bool> discoverAndSelectCharacteristics();
}
