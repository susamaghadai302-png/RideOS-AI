# RideOS Bluetooth & BLE Engine Architecture

## 1. Overview
The RideOS Bluetooth Engine (`BluetoothEngine`) coordinates scanning, connecting, GATT service discovery, and telemetry normalization across motorcycle ECUs and standard OBD-II adapters.

---

## 2. Component Structure

```
BluetoothEngine (Singleton)
 ├── DeviceScanner (Filtered BLE Scanner)
 ├── ConnectionManager (GATT lifecycle, reconnection backoff)
 ├── GattManager (Service & Characteristic Discovery)
 ├── ProtocolAdapterManager (Adapter selector & decoder)
 └── Telemetry Stream (Stream<NormalizedTelemetry>)
```

---

## 3. Supported Protocol Adapters

| Adapter | Identifier / Service UUID | Capabilities |
| :--- | :--- | :--- |
| `YamahaProtocolAdapter` | `0000fee0-...` (Y-Connect) | Speed, RPM, Coolant Temp, Battery, Fuel, Gear, Riding Modes, Hazard Lights |
| `DucatiProtocolAdapter` | `000018f0-...` (Ducati Link) | Speed, RPM, Engine Temp, Odometer, DTC Faults, Riding Mode Selection |
| `Obd2ProtocolAdapter` | `0000fff0-...` / ELM327 | Standard PID query (Speed, RPM, Coolant, Voltage, DTC Fault Reading/Clearing) |
| `GenericBleAdapter` | Any standard BLE GATT | Read-only battery voltage and RSSI fallback |

---

## 4. Command Safety Rules & Gating

Before writing any command bytes to a vehicle characteristic:
1. **Protocol Verification**: Active adapter must support the target capability.
2. **Speed Threshold Check**: Critical controls (locking, alarm arming, ECU clear) strictly require `speed == 0 km/h` or `stationary`.
3. **Safety Engine Gate**: `VehicleSafetyManager` rejects unsupported, out-of-range, or hazardous parameters.
