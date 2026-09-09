# Git Automation Rule

When a development task or Phase reaches a stable completion checkpoint, you MUST automatically create a safe Git checkpoint and push it by running:
`./scripts/checkpoint.sh`

## Conditions
- ONLY run this script when a task/Phase is verifiably complete and stable.
- DO NOT run this script on unfinished intermediate edits.
- If `./scripts/checkpoint.sh` fails, report the exact failure, do NOT attempt to force push, and do NOT manually bypass its checks.
- Let the script handle the `git add`, `git commit`, and `git push`. DO NOT run these commands yourself manually when completing a phase.
