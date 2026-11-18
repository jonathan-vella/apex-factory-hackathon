# C10 answer key: Package, hand over, review AI readiness (coach)

> [!WARNING]
> Coach material. This page has the answers to C10. Attendees close out the engagement themselves as a team.

C10 is a synthesis challenge — review for honesty and completeness rather than a single technical answer.

## Expected evidence

**Timing cues:** by 30 minutes, the asset and `handover-and-ai-review.md` should be drafted; reserve the final 15 minutes for committing and preparing the 5-minute showcase.

- One packaged reusable asset (the archetype adaptation, the modernization playbook and plan, or the C9 perf kit fixes), committed in `factory/evidence/c10/reusable-asset/` in the team/pod lead's repository on `main`, with a short `README.md` usable by someone who wasn't in the room.
- `factory/evidence/c10/handover-and-ai-review.md` committed once in the team/pod lead's repository on `main` (and shared in the team channel), covering:
  - Every team member's C8 `acceptance.json` verdict (`ACCEPT`), C8 live check results, and C9 Query Store `baseline` vs `after` CPU/duration improvement.
  - The AI-readiness gap register, with an entry each time a human or coach had to step in (including any lifeline used, plus the human review gates in C3, C5, C6 and C7).
  - The 5-minute showcase talking points.

## Model answer

A credible AI-readiness gap register entry for a team that used no lifelines:

> **Challenge / area:** C7, the cutover go/no-go decision.
> **Where a human had to step in:** confirming replication lag was actually zero and source writes had actually stopped before cutting over.
> **Why the agent could not complete it alone:** a wrong cutover risks data loss, and no automated check in the kit makes this call for you.
> **Next step for customer engagements:** keep migration cutover as an explicit human-approved gate even in automated pipelines.

A reusable asset that passes the bar: the adapted archetype folder or the five C9 `.sql` fix scripts committed in `factory/evidence/c10/reusable-asset/` with a short `README.md` explaining what subscription/tenant or database values a new team supplies.

## Business outcome check

The outcome is a documented path to AI. Open `handover-and-ai-review.md` and check that each AI-readiness gap has a clear reason and next step for customer engagements.

## Common mistakes

- An empty or token AI-readiness gap register ("we didn't need any help") — review C3–C7 with the team; every team has at least the deliberate human-in-the-loop review gates above, even with a perfect run.
- A "reusable asset" that has no `README.md` explaining what inputs to supply.
- Handover summary table covering only the team lead's C8/C9 results, missing the rest of the team.
- Running out of time and skipping the showcase entirely — even a brief verbal walkthrough with one screen shown counts.

## Reset

Not applicable — C10 is a documentation and synthesis challenge.
