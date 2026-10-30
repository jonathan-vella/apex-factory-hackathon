---
title: "VS Code: triage assessment findings"
description: Review both assessment reports with plain Agent mode, not the Upgrade agent.
sidebar:
  label: Triage findings (C3)
  order: 3
---

Used in [C3, requirements 3 to 6](../../../challenges/c03-assess-the-source/#requirements).

Turn C3's two raw assessments (the Upgrade agent's `assessment.md` and the Arc SQL migration assessment) into a
reviewed, human-authorized triage table.

## The prompt

Use plain Agent mode in the chat (not the Upgrade agent: it would start the upgrade workflow). Send:

```text
Read .github/upgrades/scenarios/dotnet-version-upgrade/assessment.md. List every distinct finding with its severity, then for each one propose a triage: blocker, accepted risk, or fix, and its impact on the target state. Don't change anything, and don't start planning — this is analysis only.
```

Use the same agent for the Arc assessment. Open it in the Azure portal as in C3 requirement 2 (Azure Arc > SQL Server
instances > the instance under `vm-app01` > **Migration** > **Database migration** > **Assess source instance** >
**View report**), copy its findings, and send:

```text
Here are the findings from the Arc SQL migration assessment: <paste the findings>. List every distinct finding with its severity, then for each one propose a triage: blocker, accepted risk, or fix, and its impact on the target state. Don't change anything — this is analysis only.
```

Keep the results in `C:\src\<your-repo>\factory\evidence\c03\triage.md` in your plain clone on `main`; run `git pull --rebase` there first. Do not save evidence beneath `C:\src\factory` on the app work branch. See [Copy your evidence to your repo](../../../guides/ghcp-upgrade/#copy-your-evidence-to-your-repo).

## The trace-flag finding, specifically

The Arc assessment reports **"Trace flags not supported in Azure SQL Managed Instance"** for flags `1800` and
`9567` — the kit set these on the source on purpose. Work through it by hand, not just by ticking it:

```text
Explain why trace flags 1800 and 9567 would be set on a SQL Server source being prepared for an Azure SQL Managed Instance link, and what happens if they aren't removed before or after migration.
```

Read [Prepare your environment for a link](https://learn.microsoft.com/azure/azure-sql/managed-instance/managed-instance-link-preparation)
if the answer isn't clear, then record your own reasoning, the impact on the target state, and when the flags
should be removed (after cutover — see C7 requirement 7).

## Tell a self-inflicted finding from a real blocker

Ask: does this finding describe something the kit deliberately set up on the source (like the trace flags, with
a known cause and removal step), or does it describe application behavior that SQL MI genuinely can't support
(which needs a target-state decision in C4)?

## Check

- A triage table: finding, source, triage (blocker / accepted risk / fix), target-state impact.
- The trace-flag finding specifically called out with its reason, impact and decision.
- No task started, no application file changed — C3 stops at the plan gate; see
  [Assess and plan](../01-assess-and-plan/).
