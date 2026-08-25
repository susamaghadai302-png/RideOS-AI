import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sos_state.dart';
import '../../domain/entities/sos_contact_entity.dart';

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier() : super(const SosState());

  void addEmergencyContact(SosContactEntity contact) {
    state = state.copyWith(
      emergencyContacts: [...state.emergencyContacts, contact],
    );
  }

  Future<void> triggerManualSos(double lat, double lng) async {
    state = state.copyWith(status: SosStatus.triggering);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      status: SosStatus.active,
      activeIncidentId: 'sos-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> cancelSos() async {
    state = state.copyWith(status: SosStatus.cancelled);
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(status: SosStatus.idle, activeIncidentId: null);
  }
}

final sosNotifierProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier();
});
