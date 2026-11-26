---
title: Roles
description: What a member, the team lead and a coach each do, and when.
sidebar:
  order: 2
---

Every attendee in a platform team is a **member**, and one colleague is also the **team lead** (called the **platform lead** in the workflow and scripts). The **event owner** coordinates the event, and **coaches** support teams on the two event days.

The kit supports two ways to organize a delivery:

- **Path A — Self-service teams:** typically **3 to 5 people** per team, sharing one Azure hub. Each member creates their own repository and runs their own preflight, datacenter and teardown stages in [Deploy](../../deploy/).
- **Path B — Lead-provisioned cohort:** one platform team with **`n` attendees** sharing a single Azure hub. One platform team lead pre-creates the student repositories (`Initialize-CohortRepos.ps1`) and runs the shared foundation, datacenter and vending stages from the lead repository ([Step 1: Cohort repos, roster and preflight](/deploy/lead-setup/step-1-cohort-and-preflight/)); attendees share their GitHub username before day one and complete [Student onboarding (Day 1)](/deploy/lead-setup/student-onboarding/) on Day 1 before C1. When a cohort has **more than 5 attendees** (`n > 5`), split into **breakout pods of 3 to 5 people** for the team challenges (C1, C4 and C10) and showcase, and nominate one **pod lead** per pod.

## Support before the event

- **No coach is available during the pre-hackathon.** Pre-hackathon support is best-effort only.
- **Every pre-event escalation follows this path:** member → team lead → event owner. Your event owner shares how to contact them; start with your designated team lead.
- **Follow your event's setup path in order.** Self-service teams follow Step 1 (T-14) through Step 4 (T-1) in [Deploy](../../deploy/); lead-provisioned cohorts follow [Lead-provisioned setup](/deploy/lead-setup/step-1-cohort-and-preflight/) and [Student onboarding](/deploy/lead-setup/student-onboarding/).

## Member and team lead at a glance

The team lead is not a separate non-coding manager. The team lead is a full member who also runs the shared foundation and connects the workload subscriptions (and, in Path B, provisions the cohort's student repositories and datacenters).

| Area | Member (everyone, including the team lead) | Team lead (in addition to every member task) |
| --- | --- | --- |
| Azure subscriptions | Owns one **workload subscription** (`rg-datacenter`, `rg-spoke`, and the C5 archetype) | Also owns the team's **shared services subscription** (`rg-management`, `rg-hub`) and holds **Owner at Tenant Root** |
| GitHub repository | Works in one private repo from `apex-accelerator` with the kit in `factory/` (self-created in Path A; pre-created by the lead in Path B) | Uses their private repo configured with the lead pipeline profile (`-RosterPath`) |
| Step 1 (T-14) | Path A: sets up the repo, runs `whatif`, and sends four roster values privately to the team lead. Path B: sends GitHub username privately and accepts the repo invite | Assigns distinct positive whole-number member indexes starting at `1` (taking `1`); builds `roster.json`, sets up the lead pipeline, and in Path B runs `Initialize-CohortRepos.ps1` |
| Step 2 (T-7) | Nothing to run | Bootstraps `<mgPrefix>-readers` (`Sync-FactoryReaderGroup.ps1`), runs the `foundation` stage (ALZ-lite) once for the hub, books a Privileged Role Administrator for the Graph grant and escalates to the event owner if unable to find one |
| Step 3 (T-3) | Path A: runs the `member` stage, runs the first Arc SQL assessment, sets up `vm-dev01` and commits `factory/evidence/readiness/`. Path B: nothing to run at T-3 | Path A: runs Step 3 for their own subscription (`-f members=1`). Path B: runs the `member` stage across the cohort roster |
| Step 4 (T-1) | Path A: starts both datacenter VMs before vending and saves the shared services subscription ID afterward. Path B: shares GitHub username if not already sent and accepts the repo invite | Syncs `<mgPrefix>-readers` from the full roster, then runs the `vending` stage across the roster (checks datacenter and Arc readiness, vends each spoke, restarts the VMs, records exemptions, and runs connectivity probes) |
| Event days (Day 1 and Day 2) | In Path B, completes [Student onboarding (Day 1)](/deploy/lead-setup/student-onboarding/) on Day 1 before C1. Completes every member challenge in their own repo and subscription, and contributes to the team challenges (C1, C4, C10) in their team or breakout pod | Same as every other member, plus coordinates shared hub or policy questions with the coach |
| [After the event (T+2)](../../deploy/tear-down/) | Saves and pushes work; in Path A also removes their member scope | Removes member scopes (all scopes in Path B, remaining scopes in Path A) before the shared foundation and coordinates pipeline-access removal with the named admin |
| First contact | Before day one, asks the **team lead** first and escalates through them to the **event owner**; on event days, asks a coach for challenge support | Is the first contact before the event and escalates to the event owner; on event days, brings in a coach for challenge support |

## Member

Everyone on the team or cohort, the team lead included.

Each member has a dedicated workload subscription, a private repo and a unique index assigned by the team lead: a **positive whole number starting at 1**, with the **team lead as 1**.

- **In Path A (Self-service teams),** you complete [Step 1: Repo and preflight](../../deploy/set-up-your-repo/) by T-14, send your four roster values privately to your team lead, complete [Step 3: Datacenter and workstation](../../deploy/member-steps/) by T-3, and start both VMs for [Step 4: Vending](../../deploy/vending/) at T-1.
- **In Path B (Lead-provisioned cohort),** you send your GitHub username privately to the team lead before day one, accept the repository invitation, and complete [Student onboarding (Day 1)](/deploy/lead-setup/student-onboarding/) on Day 1 once you receive your Handoff Card.
- **On event days (both paths),** you work through the member challenges in your own subscription and the team challenges together with your team or breakout pod, committing your evidence to `factory/evidence/` on `main` in your own repo. There is no shared team repo.

### Roster values

In **Path A**, your team lead needs four values from you in Step 1 (T-14) to connect your subscription in Step 4 (T-1). (In **Path B**, the event owner or team lead may already hold the subscription map and ask you only for your GitHub username, Entra object ID and work email; follow [Student onboarding](/deploy/lead-setup/student-onboarding/).)

After `.local/settings.json` is created, load `$s = Get-Content .local/settings.json | ConvertFrom-Json` from `factory/` before using the values below:

1. Your workload subscription ID (`$s.subscriptionId`)
2. Your member index (`$s.memberIndex`, assigned by your team lead)
3. Your Microsoft Entra object ID (`az ad signed-in-user show --query id -o tsv`)
4. Your work email address (the vending subscription budget sends its 80% alert here)

Share them privately with your team lead. Never put them in a repo, an issue, or a public channel.

## Team lead

One colleague nominated for each platform hub. You do every member challenge on your own workload subscription (using member index `1`), and you run the shared stages from your repo:

1. **Step 1 (T-14):** assign distinct positive whole-number member indexes starting at `1` (taking `1` yourself), collect `factory/.local/roster.json`, and initialize the lead pipeline with `-RosterPath .local/roster.json` ([Path A](../../deploy/set-up-your-repo/) or [Path B cohort setup](/deploy/lead-setup/step-1-cohort-and-preflight/) with `Initialize-CohortRepos.ps1`).
2. **Step 2 (T-7):** bootstrap `<mgPrefix>-readers` with `Sync-FactoryReaderGroup.ps1`, run the `whatif` and `foundation` stages to deploy ALZ-lite in the shared services subscription, then book a Privileged Role Administrator to run `Grant-SqlMiDirectoryRead.ps1` once for the hub ([Path A](../../deploy/team-lead-steps/) or Path B Step 2). If you cannot find a role holder, escalate to the event owner.
3. **Step 3 (T-3):** in Path A, run the `member` stage for your own workload subscription (`-f members=1`) and set up your own `vm-dev01` ([Step 3](../../deploy/member-steps/)). In Path B, run the `member` stage across the cohort roster so every student's datacenter and Arc connection are ready before onboarding.
4. **Step 4 (T-1):** once every member's datacenter is Arc-connected and both VMs are running, sync `<mgPrefix>-readers` from the full roster and run the `vending` stage ([Step 4](../../deploy/vending/) or Path B Step 4; batch with `-f members=1-50`, `-f members=51-100` when `n > 60`).

The team lead needs a second subscription for shared services and the Owner role at Tenant Root. [Requirements](../requirements/#accounts-and-access) lists both.

<details>
<summary>Why the team lead role exists</summary>

The hub network, management groups, policies, and private DNS zones are shared across all members on that hub, so one person deploys them once instead of every member deploying a duplicate hub. Those resources also require Owner at Tenant Root and a one-time Microsoft Graph permission grant that only a directory administrator can perform.

</details>

## Pod lead (breakout pods in larger cohorts)

When a single-hub cohort has **more than 5 attendees** (`n > 5`), working on one shared screen for C1, C4 and C10 is too crowded. Split the cohort into **breakout pods of 3 to 5 members** for collaboration and scoring:

- **One platform team lead** still manages the shared Azure hub, `roster.json` and pipeline stages for all `n` members.
- **Each breakout pod** nominates one **pod lead**. During C1, C4 and C10, each pod writes its own canvas, team ADRs, deferred-work register and handover package together, every pod member commits the pod's final files to their own repo, and the coach scores team items once per pod from **that pod lead's copy**. Each pod gets its own scoreboard sheet.

## Event owner

The event owner confirms each team's roster and member indexes, handles escalations from team leads (for example, when a team lead cannot find a Privileged Role Administrator) and owns cleanup. The event owner shares contact details or an escalation channel with each team before day one.

## Tech lead and coaches (event days)

No coach is on duty during the pre-hackathon window. On day one and day two:

- **Tech lead kickoff (08:30 on Day 1):** the event owner designates a technical presenter from the event delivery team, which may be Microsoft, a partner or another third party. Before C1 begins, they give a 30-minute presentation introducing the hackathon, the Contoso University scenario, the architecture, and how the 10 challenges fit together.
- **Coaches:** support teams during the two event days, give the live APEX archetype demo before C5, review and score challenge evidence, and help you when you're blocked.

A coach does not do the hands-on work for the team. Ask your team lead first before day one; they can escalate to the event owner. On event days, bring in your coach when your team is stuck after trying the documented recovery steps.

## Next

Read [Requirements](../requirements/), then [The kit at a glance](../kit-at-a-glance/). Terms you don't know are in the [glossary](../../reference/glossary/).
