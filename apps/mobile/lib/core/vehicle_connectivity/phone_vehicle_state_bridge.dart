import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../vehicle_resolution/models/active_vehicle_context.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PHONE ↔ VEHICLE STATE BRIDGE
//
//  This is the central coordination layer between the phone app and the
//  vehicle smart display (Android Auto / Automotive OS).
//
//  Responsibilities:
//  • Propagates navigation state from the phone to the car display
//  • Notifies the car display when connection is lost / recovered
//  • Routes vehicle mode changes to the car display
//  • Sends destination changes to the car screen
//
//  On platforms where Android Auto is not connected, calls are no-ops.
//  On web, all calls are no-ops (platform channels not available).
//
//  The bridge is unidirectional: Phone → Vehicle.
//  The vehicle display does NOT push state back to the phone.
//  (Exception: user can tap "navigate here" on car screen → deep link to phone)
// ─────────────────────────────────────────────────────────────────────────────

const _kAutoChannel = MethodChannel('com.rideos.mobile/android_auto');

class PhoneVehicleStateBridge {
  static final PhoneVehicleStateBridge instance = PhoneVehicleStateBridge._();
  PhoneVehicleStateBridge._();

  bool _isAutoConnected = false;
  bool get isAutoConnected => _isAutoConnected;

  // ── Navigation State ───────────────────────────────────────────────────────

  /// Called when navigation starts or a new route is calculated.
  /// Sends the current step instruction + ETA to the car display.
  Future<void> pushNavigationUpdate({
    required String instruction,
    required double stepDistanceMeters,
    required int etaMinutes,
    required double totalDistanceKm,
    required String destinationTitle,
    required double currentLat,
    required double currentLng,
  }) async {
    try {
      await _kAutoChannel.invokeMethod('updateNavigation', {
        'instruction': instruction,
        'stepDistanceMeters': stepDistanceMeters,
        'etaMinutes': etaMinutes,
        'totalDistanceKm': totalDistanceKm,
        'destinationTitle': destinationTitle,
        'currentLat': currentLat,
        'currentLng': currentLng,
      });
    } on MissingPluginException {
      // Android Auto not in this build or platform doesn't support it
    } on PlatformException catch (e) {
      // Auto not connected — silently ignore
      if (e.code == 'NOT_CONNECTED') return;
    }
  }

  /// Called when navigation ends.
  Future<void> pushNavigationStop() async {
    try {
      await _kAutoChannel.invokeMethod('stopNavigation');
    } on MissingPluginException {
      // no-op
    } catch (_) {}
  }

  // ── Connection State ───────────────────────────────────────────────────────

  /// Call this when vehicle Bluetooth connects/disconnects.
  /// The car display updates its connection indicator.
  Future<void> pushConnectionState(VehicleConnectionStatus status) async {
    try {
      await _kAutoChannel.invokeMethod('connectionStateChanged', {
        'status': status.name,
        'displayLabel': status.name.toUpperCase(),
      });
    } on MissingPluginException {
      // no-op
    } catch (_) {}
  }

  // ── Auto Connected Detection ───────────────────────────────────────────────

  Future<void> checkAutoConnection() async {
    try {
      final connected = await _kAutoChannel.invokeMethod<bool>('getAutoConnected') ?? false;
      _isAutoConnected = connected;
    } on MissingPluginException {
      _isAutoConnected = false;
    } catch (_) {
      _isAutoConnected = false;
    }
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final phoneVehicleBridgeProvider = Provider<PhoneVehicleStateBridge>((ref) {
  return PhoneVehicleStateBridge.instance;
});
