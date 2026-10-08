# Hardware Transport Architectural Decisions

## Bluetooth Low Energy (BLE)
- **Dependency Selected**: `flutter_blue_plus`
- **Reasoning**: It is the most actively maintained BLE plugin for Flutter. It supports scanning, connecting, service discovery, and characteristic notifications effectively across both iOS and Android.
- **Role**: Primary transport for smart displays, low-power telemetry broadcasts, and TPMS sensors.

## Bluetooth Classic (RFCOMM)
- **Dependency Selected**: `bluetooth_classic` (existing in pubspec)
- **Reasoning**: `flutter_blue_plus` strictly handles BLE. We must utilize an RFCOMM capable transport to communicate with standard ELM327 OBD-II adapters and older motorcycle ECUs.
- **Role**: Primary transport for ELM327 OBD-II serial communication.

## OBD-II / ELM327
- **Architecture**: A pure Dart state machine layer that sits atop the RFCOMM transport.
- **Reasoning**: Keeps the ELM327 protocol logic transport-agnostic, allowing it to theoretically operate over WiFi (for WiFi OBD adapters) or USB serial in the future.
