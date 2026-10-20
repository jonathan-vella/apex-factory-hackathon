# Evidence folder

This folder, `factory/evidence/` in your own repo, is where your factory-kit evidence lives. Teams don't share a repo: every member keeps their own copy, on `main`.

## Structure

```text
factory/evidence/
  c00/ ... c10/        # one folder per challenge, each with a README
```

Every challenge's evidence goes in its own `cNN` folder. The folders are the same for team and member items, with no per-member subfolder (the repo is already yours). For example, the C1 opportunity canvas is `factory/evidence/c01/opportunity-canvas.md`, and your C8 acceptance document is in `factory/evidence/c08/`.

Team deliverables (the C1 canvas, the C4 platform and migration ADRs, the C10 package) are written once, together, on one person's screen. Afterwards every teammate copies the final file into their own `factory/evidence/cNN/` and commits it. A team item is scored once per team, from the platform lead's copy, so the other copies must match it.

## How to use this

1. Copy the relevant template from `factory/templates/attendee/` into your challenge's evidence folder before you start that challenge.
2. Fill it in as you go, not retroactively: screenshots and command output are more convincing right after you produce them.
3. Commit after each challenge, not just at the end of the day. Use a conventional commit message, because the repo's commit hook rejects anything else, for example `git commit -m "docs: C1 opportunity canvas"`. Then `git push` to `main`.
4. Use the [factory-kit checklist](../templates/attendee/factory-kit-checklist.md) in C10 to confirm nothing is missing before handover.

Don't commit secrets, connection strings or tokens. Don't commit tenant IDs, subscription IDs or object IDs.
