enum VoiceCommandType {
  openGarage,
  startNavigation,
  navigateHome,
  navigateWork,
  findPetrolPump,
  findEvCharger,
  showBikeHealth,
  stopNavigation,
  unknown,
}

class VoiceCommandResult {
  final VoiceCommandType commandType;
  final String aiResponse;

  const VoiceCommandResult({
    required this.commandType,
    required this.aiResponse,
  });
}

/// Lightweight on-device command resolver used by the dashboard voice capsule.
/// It is deterministic, offline-safe, and leaves feature actions to the UI.
class VoiceCommandEngine {
  VoiceCommandResult parseCommand(String input) {
    final text = input.trim().toLowerCase();

    if (text.isEmpty) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.unknown,
        aiResponse: 'I did not hear a command. Please try again.',
      );
    }

    if (_containsAny(text, ['stop navigation', 'cancel navigation', 'end navigation'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.stopNavigation,
        aiResponse: 'Stopping the active navigation session.',
      );
    }
    if (_containsAny(text, ['garage', 'my bike garage', 'open garage'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.openGarage,
        aiResponse: 'Opening your vehicle garage.',
      );
    }
    if (_containsAny(text, ['bike health', 'bike status', 'vehicle health', 'diagnostics', 'diagnostic'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.showBikeHealth,
        aiResponse: 'Opening the vehicle health and diagnostics panel.',
      );
    }
    if (_containsAny(text, ['ev charger', 'ev charging', 'electric charger', 'charging station'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.findEvCharger,
        aiResponse: 'Finding the nearest EV charging option.',
      );
    }
    if (_containsAny(text, ['petrol pump', 'petrol station', 'fuel station', 'gas station', 'fuel'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.findPetrolPump,
        aiResponse: 'Finding the nearest fuel station.',
      );
    }
    if (_containsAny(text, ['navigate home', 'go home', 'take me home'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.navigateHome,
        aiResponse: 'Preparing navigation to Home.',
      );
    }
    if (_containsAny(text, ['navigate work', 'go to work', 'take me to work'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.navigateWork,
        aiResponse: 'Preparing navigation to Work.',
      );
    }
    if (_containsAny(text, ['navigate', 'directions', 'route', 'take me to', 'go to'])) {
      return const VoiceCommandResult(
        commandType: VoiceCommandType.startNavigation,
        aiResponse: 'Navigation command recognized. Opening the navigation cockpit.',
      );
    }

    return VoiceCommandResult(
      commandType: VoiceCommandType.unknown,
      aiResponse: 'I understood: "$input". Try navigation, petrol pump, EV charger, bike health, garage, or stop navigation.',
    );
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any(text.contains);
  }
}
