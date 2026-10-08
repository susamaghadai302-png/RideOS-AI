# AI Runtime Architecture

RideOS AI runs as a tightly governed, multi-layered reasoning engine atop the `firebase_ai` Flutter SDK. 
It operates strictly within predefined hardware telemetry contexts.

## Architecture Layers

```
[ Rider Request / Voice ]
           |
           v
[ RideAIEngine (Sandbox) ]
           |
    ---------------------
    |                   |
[ Context Engine ]  [ Policy Engine ]  -> Validates request/safety rules
    |                   |
    v                   v
[ FirebaseAI ] <==> [ App Check / Security Gate ]
    |
    v
[ Tool Exec Layer ] -> Fetches real hardware metrics (RPM, TPMS, Maps)
    |
    v
[ Hallucination Defense ] -> Strips out unverified data and fake assumptions
    |
    v
[ Structured JSON Output ] -> Presented safely to UI or Audio Engine
```

## 1. Firebase AI SDK Layer
- Integrates `firebase_ai` via Firebase Core.
- Secures requests inherently via Firebase App Check using Google Play Integrity and DeviceCheck APIs.

## 2. Intent Context Engine (`RideAIContext`)
Provides the only verified state of the real world.
- If TPMS hardware is absent, `TPMS_STATE` is set to `UNAVAILABLE`.
- If OBD is disconnected, RPM/Speed is `UNAVAILABLE`.

## 3. Tool Execution Engine
Implements function declarations (via `FunctionDeclaration` schema) securely mapping Dart tools to LLM functions.
- Prevents LLMs from controlling hardware directly (e.g. `SetBrakesTool` is strictly disallowed by architecture).
- Strictly forces tools to return typed evidence.

## 4. Hallucination Defense
Cross-references LLM outputs against Context State.
- If LLM generates `RPM = 0` but Context State is `UNAVAILABLE`, the Engine intercepts and scrubs the false data, replacing it with `UNVERIFIED_DATA_BLOCKED`.
- Maintains the rule: "The Model is NOT the authority on truth."

## 5. Security Envelope
- Zero static API Keys embedded in Dart.
- CI injects keys strictly for unit/live testing; Production runs completely isolated relying on platform assertions (App Check).
