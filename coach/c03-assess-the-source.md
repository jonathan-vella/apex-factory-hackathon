# C3 answer key: Assess the source

> [!WARNING]
> Coach material. This page has the answers to C3. Attendees triage the Upgrade agent's and Arc's assessments themselves.

The challenge page requires the trace-flag finding specifically — this is the one piece of evidence to check closely, since it's easy to just tick it without understanding it. The student page deliberately doesn't spell out the decision or the reasons; the member has to derive them from the MI link preparation article.

## Expected evidence

- The Upgrade agent's `assessment.md` reviewed, and the `plan.md` it produced at the plan gate (planning is approved in C3, as the playbook's Step 1 says; task execution starts in C6).
- The Arc migration assessment reviewed, with a triage table: finding, source, triage (blocker / accepted risk / fix), target-state impact.
- The trace-flag finding (`1800`, `9567`, "Trace flags not supported in Azure SQL Managed Instance") specifically called out, with the correct reasoning: these are set deliberately on the source to prepare for the MI link (`1800` aligns log I/O across differing sector sizes; `9567` compresses automatic seeding), apply only to the source side of the link, aren't needed on the managed instance, and don't block migration. Decision: accept for the link; remove from the source after cutover (this becomes a C7 task and a deferred-work register entry).
- Nothing changed in `app/` yet.

## Model answer

A correct trace-flag triage entry reads something like:

> **Finding:** Trace flags 1800 and 9567 not supported on SQL MI (warning).
> **Triage:** Accepted risk, self-inflicted.
> **Why:** We set these on the source ourselves, following Microsoft's MI link preparation guidance, to improve log I/O alignment and seeding compression during the link. They have no effect on the managed instance and aren't needed there.
> **Impact on target:** None — doesn't change the platform ADR or push the workload toward SQL Server on an Azure VM.
> **Follow-up:** Remove `-T1800 -T9567` from the source's SQL Server startup parameters after the MI link is removed (C7 task, tracked in the deferred-work register).

Other findings from the Upgrade agent's assessment (framework APIs retired in .NET 10, packages needing updates) should each get a one-line triage: most are "fix" (handled by the Upgrade agent's own tasks in C6), a few might be "accepted risk" if genuinely cosmetic.

## Common mistakes

- Ticking the trace-flag finding as "fix: remove the trace flags now" — this breaks MI link prep before it's even started. The correct answer is to leave them until after cutover.
- Treating every Arc assessment warning as a blocker — most warnings in this environment are expected/self-inflicted; a true blocker needs an actual unsupported feature in use by the application, not a setting the kit itself introduced.
- Starting to run the Upgrade agent's tasks during C3 — the challenge stops at the assessment and the approved plan. Task execution is C6's job.

## Partial credit

- All findings triaged except the trace-flag one is superficial ("accepted, no explanation"): partial credit — ask the member to re-read the MI link preparation article and redo that one entry.
- Triage table complete but informal (not using the deferred-work register template yet): accept, as long as the content is there; the register comes in C4.

## Bonus

Up to 5 points for a second, independent finding (beyond the trace flags) triaged with the same rigor — source, reasoning and target-state impact, not just a label.

## Reset

Not applicable — C3 is read-only against the assessments; nothing to reset.
