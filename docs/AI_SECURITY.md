# AI Security & Verification Envelope

RideOS AI implements rigorous safety parameters limiting LLM execution in production contexts.

## 1. Firebase App Check Authentication
To avoid leaking `GEMINI_API_KEY` in reverse-engineered client APKs/IPAs:
- We rely on `firebase_core` and `firebase_ai`.
- Firebase App Check acts as the gatekeeper.
- It verifies the request originates from an unmodified, Play Integrity-certified (Android) or DeviceCheck-certified (iOS) build.
- Malicious API flooding using our credentials is mathematically blocked.

## 2. Hardcoded Key Sweeps
- Regex automated CI tests (`production_hardening_engine.dart`) block any commits containing `GEMINI_API_KEY`, `AIza...`, or similar token prefixes.

## 3. Strict Deterministic Scaffolding
- Model generation configuration strictly forces `responseMimeType: 'application/json'`.
- Responses are forced to adhere to a predefined `Schema.object()`. Unstructured conversational chat is blocked at the SDK level.
- Hallucination defense guarantees that any data (e.g. RPM, Speed, Weather) reported by the AI must map to an evidentiary tool payload.

## 4. Disallowed Directives
The policy engine (`RideAIPolicyEngine`) explicitly prevents:
- **Vehicle Manipulation**: Commands attempting to actuate brakes, steering, or transmission are caught via intent classification and rejected.
- **Diagnostics Fabrication**: If a real ECU/OBD adapter is not connected (`HardwareValidationScreen` marks `UNVERIFIED`), the AI cannot guess or assume normal engine metrics. It must report `UNAVAILABLE`.
- **System Override**: AI cannot override SOS protocol or cancel a running crash detection state.
