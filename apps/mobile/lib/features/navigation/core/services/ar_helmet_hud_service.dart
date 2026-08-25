class ArHelmetHudState {
  final bool isHelmetConnected;
  final double helmetBatteryPct;
  final bool isCameraActive;
  final bool isIntercomActive;
  final String activeChannel;
  final bool isArOverlayActive;

  const ArHelmetHudState({
    required this.isHelmetConnected,
    required this.helmetBatteryPct,
    required this.isCameraActive,
    required this.isIntercomActive,
    required this.activeChannel,
    required this.isArOverlayActive,
  });
}

class ArHelmetHudService {
  ArHelmetHudState state = const ArHelmetHudState(
    isHelmetConnected: true,
    helmetBatteryPct: 92.0,
    isCameraActive: true,
    isIntercomActive: true,
    activeChannel: 'MOTO-MESH CH 1',
    isArOverlayActive: true,
  );

  void toggleArOverlay() {
    state = ArHelmetHudState(
      isHelmetConnected: state.isHelmetConnected,
      helmetBatteryPct: state.helmetBatteryPct,
      isCameraActive: state.isCameraActive,
      isIntercomActive: state.isIntercomActive,
      activeChannel: state.activeChannel,
      isArOverlayActive: !state.isArOverlayActive,
    );
  }
}
