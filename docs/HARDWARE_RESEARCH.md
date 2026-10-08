# Hardware Integration Research & References

This document records the current state of the art for Bluetooth and OBD-II parsing in Dart/Flutter, ensuring we adhere to proven standards without blindly copying untested code.

## 1. Bluetooth Low Energy (BLE)
**Reference:** `flutter_blue_plus` (v2.3+)
- **Architecture**: Employs rigorous state-change observation. Connect methods are inherently asynchronous and can throw on timeout. 
- **Physical Validation**: Scanning and connection MUST verify Android permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`) at runtime.
- **Limitation**: Cannot interact with standard RFCOMM.

## 2. Bluetooth Classic (RFCOMM / SPP)
**Reference:** `flutter_bluetooth_serial`, `bluetooth_classic`
- **Architecture**: Relies on Android's native `BluetoothSocket` connecting to UUID `00001101-0000-1000-8000-00805F9B34FB`.
- **Physical Validation**: Stream subscriptions often fail silently if the underlying socket breaks. Robust implementations must aggressively ping or listen for socket disconnections.
- **RideOS Strategy**: We encapsulate the stream in `BluetoothClassicTransport` so that if we must drop `bluetooth_classic` and write our own PlatformChannel, the application layer remains completely oblivious.

## 3. ELM327 / OBD-II Protocol
**Reference:** SAE J1979 Standard, pub.dev `obd2`
- **Initialization**: 
  - `ATZ` (Reset)
  - `ATE0` (Echo off - critical for preventing parsing errors)
  - `ATL0` (Linefeeds off)
  - `ATH1` (Headers on, if strict mapping is needed)
- **Data Flow**: Text-based hex streams terminated by `\r` (Carriage Return).
- **Parsing Math**: 
  - Engine RPM (`010C`): `((A * 256) + B) / 4`
  - Vehicle Speed (`010D`): `A`
  - Coolant Temp (`0105`): `A - 40`
- **RideOS Strategy**: We will implement a strict buffer that awaits `\r` before decoding. If a response is `NO DATA` or `?`, the decoder maps this to an `UNSUPPORTED` state, preventing default fallback to `0`.
