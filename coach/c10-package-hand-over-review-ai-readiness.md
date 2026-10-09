# C10 answer key: Package, hand over, review AI readiness

> [!WARNING]
> Coach material. This page has the answers to C10. Attendees close out the engagement themselves as a team.

C10 is a synthesis challenge — there's no single technical answer, so grade for honesty and completeness rather than a specific outcome.

## Expected evidence

- One packaged reusable asset (the archetype adaptation, the modernization playbook run, or the perf kit fixes), referenced from the handover document, usable by someone who wasn't in the room.
- A completed acceptance-and-handover document covering every member's C8 results, not just one member's.
- An AI-readiness gap register with at least one entry per lifeline actually used by the team, and — even if none were used — entries for the human-in-the-loop points the kit deliberately keeps (C3's finding triage, C4's ADRs, C7's go/no-go).
- The factory-kit checklist, every item addressed (ticked or explicitly marked not applicable with a reason).
- A short showcase covering what was modernized, what's deferred, and the single most useful thing Copilot did.

## Model answer

A credible AI-readiness gap register entry for a team that used no lifelines:

> **Where:** C7, the cutover go/no-go decision.
> **What needed a human:** confirming replication lag was actually zero and source writes had actually stopped before cutting over.
> **Why:** a wrong cutover risks data loss, and no automated check in the kit makes this call for you.
> **Implication:** migration cutover should stay a human-approved step even in a more automated pipeline — this isn't a gap to close, it's a deliberate control.

A reusable asset that passes the bar: the team's adapted archetype repository with the `adapt-archetype` outputs and As-Built document, committed with a short README explaining what subscription/tenant values a new team would need to supply — not "ask us how this works."

## Common mistakes

- An empty or token AI-readiness gap register ("we didn't need any help") — review C3–C7 with the team; every team has at least the deliberate human-in-the-loop points above, even with a perfect run.
- A "reusable asset" that's really just a link to the team's own repo with no explanation of what to adapt — this fails the "someone outside the team can run it" bar from the challenge's own hint.
- Handover document covering only the platform lead's or one member's C8 results, missing the rest of the team.
- Running out of time and skipping the showcase entirely — even a two-minute verbal walkthrough with one screen shown counts; don't let it disappear silently.

## Partial credit

- Reusable asset and handover complete, gap register thin: partial credit, prompt the team with the C3/C4/C7 examples above if they're stuck.
- Showcase prepared but not given due to time: accept the prepared material as the evidence, note the time constraint.

## Bonus

A live demo of the modernized app against SQL Managed Instance during the showcase (not slides) is worth up to 10 bonus points.

## Reset

Not applicable — C10 is a documentation and synthesis challenge.
