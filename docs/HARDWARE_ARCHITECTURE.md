# Hardware Architecture

## Transport Separation
The application uses strict hardware transport separation to isolate network boundaries from the telemetry protocols.

1. **`HardwareTransport` Base**
   - Manages canonical state mapping (`connecting`, `initializing`, `ready`, etc.)
   - Dispatches a generic byte stream or raw frames depending on underlying interface.

2. **`BleTransport`**
   - Built directly on top of `flutter_blue_plus`.
   - Used for scanning low-power beacons, BLE vehicle ECUs, and smart helmet/headset integration.

3. **`BluetoothClassicTransport`**
   - Connects using standard RFCOMM serial socket.
   - Specifically built to talk to older OBD-II ELM327 adapters and standard SPP (Serial Port Profile) devices.

## Capability Discovery
No device is implicitly assumed to be fully featured. `VehicleCapabilities` acts as the gatekeeper.

If an adapter connects successfully but does not respond to PID `010C` (Engine RPM), the capability is marked `UNSUPPORTED`. If no adapter is connected, it is `UNVERIFIED`. The AI assistant and UI layers only render or process data corresponding to `SUPPORTED` and `VERIFIED` fields.
