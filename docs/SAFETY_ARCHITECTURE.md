# Safety & SOS Architecture

## Objective
Define strict state machines to manage crash detection validations and SOS broadcasts safely, preventing false positives from generating distress calls.

## SOS State Machine
`SosState`:
- `idle`: Default.
- `candidate`: Suspicious physics detected, beginning logic validation.
- `countdown`: User prompt active (cancel or wait).
- `confirmed`: Countdown expired or user manually triggered.
- `sending`: Broadcasting to network.
- `sent`: Successfully delivered.
- `failed`: Network unavailable.
- `cancelled`: User aborted.

## Rule of Evidence
No SOS payload is sent automatically without passing the `countdown` validation barrier, ensuring single-sensor noise (a dropped phone) is never mistaken for a severe crash.
