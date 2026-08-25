enum TripLifecycleState {
  idle,
  ready,
  tripStarted,
  active,
  paused,
  resumed,
  completed;

  bool get isRecording => this == TripLifecycleState.tripStarted || this == TripLifecycleState.active || this == TripLifecycleState.resumed;
  bool get isPaused => this == TripLifecycleState.paused;
  bool get isIdle => this == TripLifecycleState.idle || this == TripLifecycleState.completed;
}
