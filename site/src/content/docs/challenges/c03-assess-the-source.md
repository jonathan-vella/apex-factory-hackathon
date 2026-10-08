---
title: "C3: Assess the source"
description: Triage the GHCP and Arc migration assessments, finding by finding.
---

## Goal

Turn raw assessment output into a reviewed, human-authorized list of findings, each triaged as a blocker, an accepted risk, or something to fix.

## Scope and time box

Member. **60 min** (can run while ALZ-lite deploys in C2).

## Points

**15 pts** (member).

## Inputs

C0's first Arc migration assessment. C2's foundation doesn't need to be finished to start this challenge.

## Your tasks

1. Run the GitHub Copilot Upgrade agent's assessment step against `app/ContosoUniversity` (harness **Local**, agent **Upgrade**, scenario `dotnet-version-upgrade` — see the [GHCP upgrade guide](../../guides/ghcp-upgrade/)). Don't approve planning yet; read the assessment first.
2. Re-run, or review, the Arc SQL migration assessment from C0 against the source SQL Server.
3. Triage every finding from both assessments: blocker, accepted risk, or fix, and what it means for the target state.
4. Work through the trace-flag finding by hand, not just by ticking it: the assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** (warning) for flags `1800` and `9567`. These are on the source on purpose, to prepare for the MI link: `1800` aligns log I/O when the replicas' disk sector sizes differ; `9567` compresses automatic seeding. They act on the source side of the link only, aren't needed on the managed instance, and don't block the migration. Decide: accept the finding for the link, and plan to remove the flags from the source after the link is removed.
5. Learn to tell this kind of self-inflicted, expected finding apart from one that would genuinely force the workload onto SQL Server on an Azure VM instead of SQL MI (for example, a feature SQL MI doesn't support at all, used by the application).
6. Record every finding, its triage and its impact in the deferred-work register or the C4 ADR — whichever template fits the finding.

## Evidence

- The Upgrade agent's `assessment.md` and the dashboard's Assessment tab, reviewed (not approved to plan yet — that's still allowed in this challenge, but don't start task execution).
- A triage table: finding, source, triage (blocker / accepted risk / fix), and target-state impact.
- The trace-flag finding specifically called out with its impact and decision, as above.
- Nothing in `app/` changed yet.

## Hints

<details>
<summary>How do I tell a self-inflicted finding from a real blocker?</summary>

Ask: does this finding describe something the kit deliberately set up for a different purpose (like the trace flags, set for MI link prep), or does it describe application behavior that SQL MI genuinely can't support? The first kind has a known cause and a known removal step. The second kind needs a target-state decision in C4.
</details>

<details>
<summary>The Upgrade agent won't produce an assessment</summary>

Check the harness is **Local** (not the Copilot harness) and the agent picker shows **Upgrade**. If the tools report unavailable, reload the VS Code window and start a new chat.
</details>

## Lifeline

Ask your coach if the trace-flag finding's framing doesn't make sense after re-reading it once. Using the lifeline caps C3 at partial credit.

## Bonus

Up to 5 pts for identifying any other finding in the Arc assessment report and writing its own triage, beyond the trace-flag one this challenge requires.

## Learn more

- [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
- [Azure SQL Managed Instance feature differences](https://learn.microsoft.com/azure/azure-sql/managed-instance/transact-sql-tsql-differences-sql-server)
