# Bluetooth Classic Architecture Decision

## Overview
RideOS requires Bluetooth Classic (RFCOMM/SPP) support because the vast majority of legacy motorcycle ECUs and affordable ELM327 OBD-II diagnostic adapters use Classic Bluetooth, not Bluetooth Low Energy (BLE).

## Current Dependency Audit

- **Package**: `bluetooth_classic` (currently in pubspec.yaml)
- **Version**: `^0.0.4`
- **Maintenance Status**: Stagnant / Low Activity.
- **Protocol**: Classic RFCOMM / SPP.
- **Android Support**: Yes, but relies on older Android Bluetooth APIs.
- **Reason Used**: Initially added as a placeholder to differentiate from BLE.

## Native Android BluetoothSocket Pattern
Android's native `BluetoothSocket` using `createRfcommSocketToServiceRecord(UUID)` is the industry standard for ELM327 SPP connections. The UUID used is almost universally `00001101-0000-1000-8000-00805F9B34FB`.

Currently available Flutter packages like `flutter_bluetooth_serial` provide robust wrappers over this API but are also often poorly maintained for modern Flutter (e.g., missing Android 12+ permission handling updates). 

## Decision
**We will retain `bluetooth_classic` for the architectural boundary definition**, but explicitly mark the actual SPP connection implementation as `UNVERIFIED` until a physical Android device and an ELM327 adapter are paired and bytes are successfully transmitted. 

If `bluetooth_classic` fails to correctly execute RFCOMM in production with an ELM327, we will migrate to a direct Platform Channel (`MethodChannel`) implementation leveraging native Kotlin `BluetoothSocket`, as that provides complete control over threading, connection timeouts, and byte streaming without relying on abandoned third-party plugins.
