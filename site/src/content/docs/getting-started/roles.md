---
title: Roles
description: What a member, the team lead and a coach each do, and when.
sidebar:
  order: 5
---

A team is **3 to 5 people**. Every attendee on the team is a **member**, and one colleague the team nominates is also the **team lead** (called the **platform lead** in the workflow and scripts). The **event owner** coordinates the event, and **coaches** support teams on the two event days.

## Support before the event

- **No coach is available during the pre-hackathon.** Pre-hackathon support is best-effort only.
- **Every pre-event escalation follows this path:** member → team lead → event owner. Your event owner shares how to contact them; start with your designated team lead.
- **Step 1 to Step 4 are numbered in order.** Follow the chronological steps in [Deploy](../../deploy/), from Step 1 (T-14) through Step 4 (T-1).

## Member and team lead at a glance

The team lead is not a separate non-coding manager. The team lead is a full member of the team who also runs the shared foundation and connects the team's subscriptions.

| Area | Member (everyone, including the team lead) | Team lead (in addition to every member task) |
| --- | --- | --- |
| Azure subscriptions | Owns one **workload subscription** (`rg-datacenter`, `rg-spoke`, and the C5 archetype) | Also owns the team's **shared services subscription** (`rg-management`, `rg-hub`) and holds **Owner at Tenant Root** |
| GitHub repository | Works in one private repo created from `apex-accelerator`, with the kit in `factory/` | Uses the same private repo, configured with the lead pipeline profile (`-RosterPath`) |
| Step 1 (T-14) | Sets up the repo, runs the `whatif` preflight, and sends four roster values privately to the team lead | Assigns team indexes (`1` to `5`; team lead is `1`), collects `roster.json`, and sets up the lead pipeline; scripts accept indexes `1` to `20` |
| Step 2 (T-7) | Nothing to run | Runs the `foundation` stage (ALZ-lite) once for the team, books a Privileged Role Administrator for the Graph grant and escalates to the event owner if unable to find one |
| Step 3 (T-3) | Runs the `member` stage (datacenter, `Test-Datacenter.ps1`, Arc onboarding), runs the first Arc SQL assessment, sets up `vm-dev01`, and commits `factory/evidence/readiness/` | Does the same Step 3 tasks for their own workload subscription (`-f members=1`) |
| Step 4 (T-1) | Starts both datacenter VMs before vending and saves the shared services subscription ID afterward | Runs the `vending` stage once for the team (it automatically checks that each member's datacenter and Arc connection are ready, vends each spoke, restarts the VMs, records exemptions, and runs connectivity probes) |
| Event days (Day 1 and Day 2) | Completes every member challenge in their own repo and subscription, and contributes to the team challenges (C1, C4, C10) | Same as every other member, plus coordinates shared hub or policy questions with the coach |
| First contact | Before day one, asks the **team lead** first and escalates through them to the **event owner**; on event days, asks a coach for challenge support | Is the first contact before the event and escalates to the event owner; on event days, brings in a coach for challenge support |

## Member

Everyone on the team, the team lead included.

Each member has a dedicated workload subscription, a unique member index assigned by your team lead, and a private GitHub repository. Teams use indexes `1` to `5` (the team lead is `1`); scripts accept `1` to `20`. You:

- complete [Step 1: Repo and preflight](../../deploy/set-up-your-repo/) by T-14 and send your four roster values privately to your team lead,
- complete [Step 3: Datacenter and workstation](../../deploy/member-steps/) by T-3 so your datacenter is tested, `vm-app01` is Arc-connected, and `vm-dev01` has VS Code and GitHub Copilot ready,
- start both VMs for [Step 4: Vending](../../deploy/vending/) at T-1,
- work through the member challenges in your own subscription and the team challenges together with your teammates,
- commit your evidence to `factory/evidence/` on `main` in your own repo. There is no shared team repo.

### Roster values

Your team lead needs four values from you in Step 1 (T-14) to connect your subscription in Step 4 (T-1):

1. Your workload subscription ID (`$s.subscriptionId`)
2. Your member index (`$s.memberIndex`, assigned by your team lead)
3. Your Microsoft Entra object ID (`az ad signed-in-user show --query id -o tsv`)
4. Your work email address

Share them privately with your team lead. Never put them in a repo, an issue, or a public channel.

## Team lead

One colleague nominated by the team. You do every member step on your own workload subscription (using member index `1`), and you run the team's shared stages from your repo:

1. **[Step 1: Repo and preflight (T-14)](../../deploy/set-up-your-repo/):** assign each teammate a distinct team index (`1` to `5`, taking `1` yourself; scripts accept `1` to `20`), collect their four roster values into `factory/.local/roster.json`, and initialize the pipeline with `-RosterPath .local/roster.json`.
2. **[Step 2: Foundation and Graph grant (T-7)](../../deploy/team-lead-steps/):** run the `whatif` and `foundation` stages to deploy ALZ-lite in the shared services subscription, then book a Privileged Role Administrator to run `Grant-SqlMiDirectoryRead.ps1` once for the team. If you cannot find a role holder, escalate to the event owner.
3. **[Step 3: Datacenter and workstation (T-3)](../../deploy/member-steps/):** run the `member` stage for your own workload subscription (`-f members=1`) and set up your own `vm-dev01`.
4. **[Step 4: Vending (T-1)](../../deploy/vending/):** once every member has finished Step 3 and started both VMs, run the `vending` stage. The pipeline automatically verifies that each member's datacenter VNet exists and `vm-app01` is Arc-connected before vending their spoke.

The team lead needs a second subscription for shared services and the Owner role at Tenant Root. [Requirements](../requirements/#accounts-and-access) lists both.

<details>
<summary>Why the team lead role exists</summary>

The hub network, management groups, policies, and private DNS zones are shared across the team, so one person deploys them once instead of every member deploying a duplicate hub. Those resources also require Owner at Tenant Root and a one-time Microsoft Graph permission grant that only a directory administrator can perform.

</details>

## Event owner

The event owner confirms each team's roster and member indexes, handles escalations from team leads (for example, when a team lead cannot find a Privileged Role Administrator) and owns cleanup. The event owner shares contact details or an escalation channel with each team before day one.

## Tech lead and coaches (event days)

No coach is on duty during the pre-hackathon window. On day one and day two:

- **Tech lead kickoff (08:30 on Day 1):** the event owner designates a technical presenter from the event delivery team, which may be Microsoft, a partner or another third party. Before C1 begins, they give a 30-minute presentation introducing the hackathon, the Contoso University scenario, the architecture, and how the 10 challenges fit together.
- **Coaches:** support teams during the two event days, give the live APEX archetype demo before C5, review and score challenge evidence, run the curveballs, and decide when to use a lifeline if a member is blocked.

A coach does not do the hands-on work for the team. Ask your team lead first before day one; they can escalate to the event owner. On event days, bring in your coach when your team is stuck after trying the documented recovery steps.

## Next

Go to [Deploy](../../deploy/) for the numbered pre-hackathon steps (Step 1 to Step 4). Terms you don't know are in the [glossary](../../reference/glossary/).
