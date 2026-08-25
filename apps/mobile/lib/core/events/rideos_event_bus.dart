import 'dart:async';

enum RideOSEventType {
  rideStarted,
  rideFinished,
  crashDetected,
  lowFuel,
  lowBattery,
  serviceDue,
  weatherAlert,
  navigationUpdated,
}

class RideOSBaseEvent {
  final RideOSEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  RideOSBaseEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RideOSEventBus {
  static final RideOSEventBus _instance = RideOSEventBus._internal();
  factory RideOSEventBus() => _instance;
  RideOSEventBus._internal();

  final StreamController<RideOSBaseEvent> _eventController = StreamController<RideOSBaseEvent>.broadcast();

  Stream<RideOSBaseEvent> get eventStream => _eventController.stream;

  Stream<RideOSBaseEvent> onType(RideOSEventType type) {
    return _eventController.stream.where((event) => event.type == type);
  }

  void publish(RideOSBaseEvent event) {
    _eventController.add(event);
  }

  void publishEvent(RideOSEventType type, Map<String, dynamic> data) {
    publish(RideOSBaseEvent(type: type, data: data));
  }

  void dispose() {
    _eventController.close();
  }
}
