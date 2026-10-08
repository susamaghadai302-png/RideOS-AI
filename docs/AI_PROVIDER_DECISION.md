# AI Provider Decision (Phase 6.7)

## Previous State
- **SDK**: `google_generative_ai: ^0.4.7`
- **Why it was replaced**: The Dart/Flutter standalone API required manual API key initialization in the client, posing a risk of secret leakage in the Android/iOS production builds.
- **Previous Model**: `gemini-1.5-flash`

## Current Selected Architecture
- **SDK**: `firebase_ai: ^4.0.0`
- **Core Strategy**: Shift away from standalone Dart AI SDK to Firebase AI logic.
- **Supported Path**: Google's officially supported and highly-maintained production path for Flutter is now routing Gemini calls through Firebase using `firebase_core` and `firebase_ai`.
- **Model**: `gemini-1.5-flash` remains the stable, fast, cost-aware model suitable for tool calling on mobile.

## Authentication & App Check Strategy
- **Authentication**: `firebase_ai` relies on Firebase Core initialization. In production, this binds directly to Firebase App Check.
- **App Check**: `firebase_app_check` is added to ensure that only our verified Android app (via Play Integrity) and iOS app (via DeviceCheck) can invoke the Firebase AI backend. No raw `GEMINI_API_KEY` is shipped inside the APK.
- **Migration Code**: `gemini_live_test.dart` dynamically injects a `FirebaseApp` initialized entirely via CI environment variables. The production app will rely on its default `Firebase.initializeApp()` generated config.

## Capabilities Retained
- **Structured Output**: Retained via `GenerationConfig(responseMimeType: 'application/json', responseSchema: Schema.object(...))` (updated to use the new `optionalProperties` syntax).
- **Function/Tool Calling**: Retained via `FunctionDeclaration` mapping, integrated flawlessly with the `RideAIEngine` sandbox.

## Migration Risks Addressed
- The previous package `firebase_vertexai` was discontinued and replaced by `firebase_ai`.
- API differences in schema definitions (e.g., `optionalProperties` vs `requiredProperties`) were fixed.
- Tool instantiation (`Tool(functionDeclarations: ...) -> Tool.functionDeclarations(...)`) was updated.
