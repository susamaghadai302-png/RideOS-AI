# AI Context Flow

## Telemetry Flow Pipeline
1. `BluetoothGatt` / `BluetoothSocket` (Raw bytes)
2. `ObdTransport` (J1979 validation)
3. `VehicleTelemetry` (Quality Engine marks VERIFIED vs STALE)
4. `RideAIContext` (Snapshot generation at T=0)
5. `AiModelProvider` (LLM Context window)
6. `RideAIResponse` (Hallucination defense stripping unverified claims)
7. `UI Layer` (Safe display)
