# PERMANENT PHASE COMPLETION GIT WORKFLOW

This rule applies to EVERY PHASE of the project.

## PHASE WORKFLOW

1. NEVER COMMIT OR PUSH MID-PHASE unless explicitly requested.
2. Work only inside the currently authorized phase scope.
3. NEVER start Phase N+1 while Phase N is unfinished.
4. At the end of Phase N, perform a FINAL PHASE GATE.

### FINAL PHASE GATE MUST VERIFY:
- functional requirements complete
- no known production-truth blockers
- no fake/simulated production behavior
- tests pass
- static analysis has 0 errors
- required integration tests pass
- build verification passes where applicable
- no unrelated files
- no temporary/generated/debug artifacts
- no accidental deletions
- git diff --check is clean
- exact final commit scope is audited

### ONLY AFTER ALL GATES PASS:

5. Create ONE clean phase-final commit.
6. Commit message format:
   `<type>: complete Phase N <phase-name>`
   or
   `fix: finalize Phase N <phase-name>`

7. Push automatically to the intended remote branch.
8. NEVER use force push.
9. NEVER push if any required gate failed.
10. NEVER hide or ignore test failures.
11. NEVER weaken tests only to obtain a passing result.
12. NEVER restore fake data, fake connectivity, fake telemetry, or placeholder production states to make CI green.

### AFTER PUSH:

13. Verify the remote repository contains the new commit.
14. Verify local HEAD matches the pushed commit.
15. Verify git status is clean.
16. Record:
    - phase number
    - commit hash
    - commit message
    - push branch
    - test results
    - analyzer result
    - integration result
    - scope result

17. Mark the phase COMPLETE only after remote verification succeeds.

### IMPORTANT:
- Do NOT automatically begin the next phase.
- Wait for explicit authorization before starting Phase N+1.
- Never force-push.
- Never overwrite another person's remote work.
- Never commit unrelated changes.
- Never commit secrets, credentials, API keys, debug dumps, generated reports, or temporary helper scripts.
