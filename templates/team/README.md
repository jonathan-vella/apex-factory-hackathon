# Evidence folder

This folder, `factory/evidence/` in your own repo on `main`, holds your working artifacts for the challenges. `Import-Kit.ps1` pre-creates the folder structure and working templates so you can fill them in directly on `vm-dev01`.

## Structure

```text
factory/evidence/
  readiness/
  c01/opportunity-canvas.md          # Team deliverable (team/pod lead repo)
  c02/                               # Run Layer 1-3 checks on vm-dev01
  c03/triage.md                      # Member triage table (alongside .github/upgrades/ at repo root)
  c04/decisions-and-register.md      # Team deliverable (team/pod lead repo)
  c05/                               # Archetype outputs live in agent-output/university/ at repo root
  c06/                               # App commits live in app/ContosoUniversity/ at repo root
  c07/cutover-rollback-runbook.md    # Member cutover checklist and notes
  c08/                               # acceptance.json written here by Test-Acceptance.ps1
  c09/                               # 5 .sql fix scripts and Query Store comparison
  c10/handover-and-ai-review.md      # Team deliverable (team/pod lead repo, alongside reusable-asset/)
```

## Team vs member artifacts

- **Team deliverables (C1, C4, C10):** Committed once in the team/pod lead's repository (`C:\src\<your-repo>` on `main`) and shared in the team channel for reference. Teammates do not need to copy-paste identical team files into their own repositories.
- **Member deliverables (C3, C5, C6, C7, C8, C9):** Committed in each member's own repository (`C:\src\<your-repo>` on `main`).

Don't commit secrets, connection strings or tokens. Don't commit tenant IDs, subscription IDs or object IDs.
