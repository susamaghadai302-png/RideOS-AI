import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import 'sos_event.dart';
import 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  final ApiClient apiClient;
  Timer? _countdownTimer;
  static const String _offlineQueueKey = 'rideos_offline_sos_incidents_v1';

  SosBloc({required this.apiClient}) : super(const SosIdleState()) {
    on<ImpactDetectedEvent>(_onImpactDetected);
    on<TriggerSosEvent>(_onTriggerSos);
    on<ConfirmSosEvent>(_onConfirmSos);
    on<CountdownTickEvent>(_onCountdownTick);
    on<CancelSosEvent>(_onCancelSos);
    on<DispatchSosEvent>(_onDispatchSos);
    on<RetryOfflineSosEvent>(_onRetryOfflineSos);
    on<RecoverSosEvent>(_onRecoverSos);
  }

  void _onImpactDetected(ImpactDetectedEvent event, Emitter<SosState> emit) {
    if (state is SosCountdownState || state is SosDispatchedState) return;

    emit(SosSuspectedImpactState(
      confidenceScore: event.confidenceScore,
      reason: event.reason,
      lat: event.lat,
      lng: event.lng,
    ));

    // Automatically transition high-confidence impacts (>=0.65) to countdown
    if (event.confidenceScore >= 0.65) {
      add(TriggerSosEvent(
        lat: event.lat,
        lng: event.lng,
        triggerType: 'AUTOMATIC_IMPACT_DETECTION',
        impactForceG: 4.8,
        countdownSeconds: 15,
      ));
    }
  }

  void _onTriggerSos(TriggerSosEvent event, Emitter<SosState> emit) {
    _countdownTimer?.cancel();
    int secondsLeft = event.countdownSeconds;

    emit(SosCountdownState(
      secondsRemaining: secondsLeft,
      lat: event.lat,
      lng: event.lng,
      triggerType: event.triggerType,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft -= 1;
      if (secondsLeft <= 0) {
        timer.cancel();
        add(const DispatchSosEvent());
      } else {
        add(CountdownTickEvent(secondsRemaining: secondsLeft));
      }
    });
  }

  void _onConfirmSos(ConfirmSosEvent event, Emitter<SosState> emit) {
    _countdownTimer?.cancel();
    if (state is SosCountdownState) {
      final current = state as SosCountdownState;
      emit(SosConfirmedState(
        lat: current.lat,
        lng: current.lng,
        triggerType: current.triggerType,
      ));
      add(const DispatchSosEvent());
    }
  }

  void _onCountdownTick(CountdownTickEvent event, Emitter<SosState> emit) {
    if (state is SosCountdownState) {
      final current = state as SosCountdownState;
      emit(SosCountdownState(
        secondsRemaining: event.secondsRemaining,
        lat: current.lat,
        lng: current.lng,
        triggerType: current.triggerType,
        isConfirmedByUser: current.isConfirmedByUser,
      ));
    }
  }

  void _onCancelSos(CancelSosEvent event, Emitter<SosState> emit) {
    _countdownTimer?.cancel();
    emit(const SosCancelledState());
    emit(const SosIdleState());
  }

  void _onRecoverSos(RecoverSosEvent event, Emitter<SosState> emit) {
    emit(const SosRecoveredState());
    emit(const SosIdleState());
  }

  Future<void> _onDispatchSos(DispatchSosEvent event, Emitter<SosState> emit) async {
    double? lat;
    double? lng;
    String triggerType = 'MANUAL_SOS';

    if (state is SosCountdownState) {
      final s = state as SosCountdownState;
      lat = s.lat;
      lng = s.lng;
      triggerType = s.triggerType;
    } else if (state is SosConfirmedState) {
      final s = state as SosConfirmedState;
      lat = s.lat;
      lng = s.lng;
      triggerType = s.triggerType;
    }

    try {
      final response = await apiClient.dio.post(
        '/sos/trigger',
        data: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          'triggerType': triggerType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final incidentId = response.data['_id'] ?? 'incident-${DateTime.now().millisecondsSinceEpoch}';
      emit(SosDispatchedState(
        incidentId: incidentId,
        liveTrackingUrl: 'https://rideos.ai/track/sos/$incidentId',
        isOfflineQueued: false,
      ));
    } catch (_) {
      emit(SosFailedState(
        errorMessage: 'Emergency dispatch failed. No cellular connection available.',
        lat: lat,
        lng: lng,
      ));
    }
  }

  Future<void> _onRetryOfflineSos(RetryOfflineSosEvent event, Emitter<SosState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineQueueKey) ?? [];
      if (queue.isEmpty) return;

      final remaining = <String>[];
      for (final item in queue) {
        try {
          final data = jsonDecode(item) as Map<String, dynamic>;
          await apiClient.dio.post('/sos/trigger', data: data);
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setStringList(_offlineQueueKey, remaining);
    } catch (_) {}
  }

  Future<void> _queueOfflineSos(String id, double? lat, double? lng, String triggerType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineQueueKey) ?? [];
      final payload = jsonEncode({
        'id': id,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'triggerType': triggerType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      queue.add(payload);
      await prefs.setStringList(_offlineQueueKey, queue);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
