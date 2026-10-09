# Team repository

This repository is where your team's factory-kit evidence lives. Each member gets a folder under `evidence/` for their own challenge artifacts; the team-level deliverables (C1, C2 vending summary, C10) live at the top of `evidence/`.

## Structure

```
evidence/
  member-<n>/
    c00/ ... c10/        # one folder per challenge, member-scoped evidence
  team/
    c01-opportunity-canvas.md
    c10-handover/
templates/
  (copies of the attendee templates, for convenience — the source of truth is the kit's templates/attendee/)
```

## How to use this

1. Copy the relevant template from `templates/` into your challenge's evidence folder before you start that challenge.
2. Fill it in as you go, not retroactively — screenshots and command output are more convincing right after you produce them.
3. Commit after each challenge, not just at the end of the day.
4. Use the [factory-kit checklist](./templates/factory-kit-checklist.md) in C10 to confirm nothing is missing before handover.

Don't commit secrets, connection strings or tokens. Don't commit tenant IDs, subscription IDs or object IDs.
