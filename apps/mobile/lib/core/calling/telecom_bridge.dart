import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CallState { idle, incoming, active }

class ActiveCall {
  final String callerName;
  final String callerNumber;
  final CallState state;
  final bool isMuted;

  const ActiveCall({
    required this.callerName,
    required this.callerNumber,
    required this.state,
    required this.isMuted,
  });

  ActiveCall copyWith({CallState? state, bool? isMuted}) {
    return ActiveCall(
      callerName: callerName,
      callerNumber: callerNumber,
      state: state ?? this.state,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class TelecomBridgeNotifier extends StateNotifier<ActiveCall?> {
  static const _channel = MethodChannel('com.rideos.mobile/calling');

  TelecomBridgeNotifier() : super(null) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onIncomingCall':
        final args = call.arguments as Map<dynamic, dynamic>;
        state = ActiveCall(
          callerName: args['callerName'] ?? 'Unknown',
          callerNumber: args['callerNumber'] ?? 'Unknown',
          state: CallState.incoming,
          isMuted: false,
        );
        break;
      case 'onCallActive':
        if (state != null) {
          state = state!.copyWith(state: CallState.active);
        }
        break;
      case 'onCallEnded':
        state = null;
        break;
      case 'onMuteStateChanged':
        if (state != null) {
          final isMuted = call.arguments['isMuted'] as bool;
          state = state!.copyWith(isMuted: isMuted);
        }
        break;
    }
  }

  Future<void> answerCall() async {
    try {
      await _channel.invokeMethod('answerCall');
      if (state != null) state = state!.copyWith(state: CallState.active);
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Calling not supported');
    } catch (e) {
      throw Exception('Calling error: $e');
    }
  }

  Future<void> declineCall() async {
    try {
      await _channel.invokeMethod('declineCall');
      state = null;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Calling not supported');
    } catch (e) {
      state = null;
    }
  }

  Future<void> endCall() async {
    try {
      await _channel.invokeMethod('endCall');
      state = null;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Calling not supported');
    } catch (e) {
      state = null;
    }
  }

  Future<void> toggleMute() async {
    if (state == null) return;
    try {
      final targetMute = !state!.isMuted;
      await _channel.invokeMethod('setMuted', {'muted': targetMute});
      state = state!.copyWith(isMuted: targetMute);
    } catch (e) {
      // Ignored
    }
  }
}

final telecomBridgeProvider = StateNotifierProvider<TelecomBridgeNotifier, ActiveCall?>((ref) {
  return TelecomBridgeNotifier();
});
