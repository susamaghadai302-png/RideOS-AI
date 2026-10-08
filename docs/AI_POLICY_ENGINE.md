# AI Policy Engine

## Objective
Ensure the AI acts strictly as an assistant and never executes unsafe vehicle commands.

## `RideAIPolicyEngine`
Classifies raw intent queries into deterministic buckets:
- `informational`
- `navigation`
- `diagnostic`
- `maintenance`
- `safety`
- `vehicleControl`

## Execution Rules
- `vehicleControl` commands (e.g., "start the engine", "apply brakes") return `isExecutionAllowed = false`.
- The AI will return a structured `RideAIResponse.blockedAction()` without attempting execution.
- LLMs are restricted from mutating state. They only invoke `RideAITool` endpoints which fetch validated data.
