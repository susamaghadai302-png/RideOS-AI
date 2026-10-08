# AI Tool & Policy Matrix

The RideOS AI utilizes predefined tools configured securely through the `firebase_ai` FunctionDeclarations SDK.

## Active Production Tools

| Tool Name | Action Executed | Required Hardware / Capability | Fallback State |
|-----------|-----------------|--------------------------------|----------------|
| `GetVehicleTelemetry` | Reads RPM, Speed, Temp, Battery | OBD-II / ECU Smart Display | `UNAVAILABLE` |
| `GetNavigationRoute` | Calculates A -> B directions | GPS + Network Connectivity | `OFFLINE_ERROR` |
| `GetWeather` | Queries location weather | Network Connectivity | `UNKNOWN` |
| `TriggerSos` | Initiates Emergency protocols | Cellular / BLE Network | `ABORTED` |

## Enforcement Matrix

### 1. Hard-Coded Denial Tool Execution
Tools that attempt to modify physical safety hardware are NOT coded, NOT declared, and WILL trigger a policy failure if requested by hallucinated execution states.
- `SteerVehicle` -> **BLOCKED**
- `BrakeVehicle` -> **BLOCKED**
- `KillEngineWhileMoving` -> **BLOCKED**

### 2. Argument Validation Policy
- If the AI supplies malformed schemas for `GetNavigationRoute`, the execution layer responds to the LLM with `TOOL_ARGUMENT_ERROR` and halts execution, rather than crashing the dart runtime.
- If the AI attempts to use a tool that is not explicitly in `allowedTools` for the current Intent, it is met with `TOOL_NOT_ALLOWED`.

### 3. Read-Only Context Propagation
When `GetVehicleTelemetry` executes, the result explicitly contains contextual strings like `HARDWARE_ABSENT`. The LLM is instructed via System Prompts and Hallucination Defenses never to guess metrics if the tag `HARDWARE_ABSENT` is present.
