# Team repository

This repository is where your team's factory-kit evidence lives. It's one repo for the whole team, separate from each member's own repo. Every teammate has write access, and everyone commits here.

## Structure

```
evidence/
  c00/ ... c10/        # one folder per challenge
    README.md
    member-<n>/        # member-scoped evidence, one subfolder per member index (n = 1 to 20)
templates/
  (copies of the attendee templates; the source of truth is the kit's templates/attendee/)
```

Team-level deliverables go straight in the challenge's folder: the C1 opportunity canvas is `evidence/c01/opportunity-canvas.md`, and the C10 hand-over package goes in `evidence/c10/`. Member-scoped evidence (for example your C8 acceptance document) goes in your own subfolder: `evidence/c08/member-<n>/`.

## How to use this

1. Pull before you start: `git pull`. Several teammates commit to the same repo.
2. Copy the relevant template from `templates/` into your challenge's evidence folder before you start that challenge.
3. Fill it in as you go, not retroactively: screenshots and command output are more convincing right after you produce them.
4. Commit after each challenge, not just at the end of the day. Commit only your own folder to avoid merge conflicts, then `git pull --rebase` and `git push`.
5. Use the [factory-kit checklist](./templates/factory-kit-checklist.md) in C10 to confirm nothing is missing before handover.

Don't commit secrets, connection strings or tokens. Don't commit tenant IDs, subscription IDs or object IDs.
