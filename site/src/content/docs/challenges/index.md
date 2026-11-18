---
title: Challenges
description: The ten challenges in order, with scope, time and the business outcome each one serves.
sidebar:
  label: Challenges overview
  order: 0
prev:
  link: /deploy/vending/
  label: "Step 4: Vending (T-1)"
---

Ten challenges take Contoso University from a Windows VM in its own datacenter to a modernized app on Azure. You work through them in order, and in each one you review your working artifacts with a coach.

## The scenario

Contoso University is a fictional public university. Its student enrollment app is old, patched by hand and holds its database password in a file. Your team is the delivery team of the partner the university hired to modernize it. [The customer story](../getting-started/customer-story/) tells it in one page and names the four people you work for.

## How the challenges work

- **Team and member challenges.** Team challenges (C1, C4 and C10) are done together on one shared screen and committed once in the team/pod lead's repository (`C:\src\<your-repo>` on `main`), then shared in the team channel. Member challenges (C2, C3 and C5 to C9) are done by each person in their own repository (`C:\src\<your-repo>` on `main`) and subscription on `vm-dev01`.
- **Five parts on every page.** Background says why it matters and which business outcome it serves. Challenge gives the starting point, what the kit fixes and what you decide. Requirements say what you must do. Success criteria say what you review with your coach. References link to Microsoft Learn.
- **Hints are folded away.** Open them when you are stuck. Where a challenge leaves a choice to you (C1, C4 and C10), there is no single right answer, and your coach looks at your reasoning.
- **Working artifacts live in `factory/evidence/`.** `Import-Kit.ps1` pre-populates the working templates on `main`.

:::note[Where to run commands]

Every requirement and command block on a challenge page shows a badge or header naming where it runs:

- <span class="sl-badge note">vm-dev01</span> — Your Windows 11 workstation via Azure Bastion (`C:\src\<your-repo>` on `main` for all 10 challenges, plus SSMS).
- <span class="sl-badge caution">vm-app01 · Bastion</span> — The legacy IIS and SQL Server VM via Azure Bastion (used only in C7).
- <span class="sl-badge tip">Azure portal</span> / <span class="sl-badge tip">Browser</span> — In your browser.

:::

## Ground rules

- Work as a team. The team lead is also a member. For team documents (C1, C4, C10), the team/pod lead commits the file once on `main` and shares it in the team channel.
- Let Copilot do the work and keep a person in charge. Read what it produced and run the check before you commit.
- If a step fails twice, ask your coach.
- Never put tenant, subscription or object IDs, or a password, in anything you commit.

## Before C1: 30-minute hackathon introduction

Day one opens at 08:30 with a 30-minute PowerPoint presentation by the tech lead before any team starts C1. The briefing covers:

1. **How the hackathon works:** the two-day schedule, team and member scopes, and working artifacts on `vm-dev01`.
2. **The Contoso University scenario:** who the university is, the four leaders you work for (Dana, Priya, Marcus and Tomás), the problems that triggered this engagement and the six business outcomes they need.
3. **The ten challenges end to end:** how business outcomes (C1) and platform guardrails (C2) connect to source assessment (C3), target-state decisions (C4), CoE archetype provisioning (C5), app modernization and cutover (C6 and C7), acceptance testing and database tuning (C8 and C9), and the final handover review (C10).

## The challenges

| Day | Challenge | Scope | Time box | Business outcome |
|---|---|---|---|---|
| Day 1 | [C1: Define the opportunity](./c01-define-the-opportunity/) | Team | 45 min | All six, in order |
| Day 1 | [C2: Secure, AI-ready foundation](./c02-secure-ai-ready-foundation/) | Member | 45 min | Secure by default |
| Day 1 | [C3: Assess the source](./c03-assess-the-source/) | Member | 60 min | Safe, repeatable change |
| Day 1 | [C4: Choose target states](./c04-choose-target-states/) | Team | 45 min | Current platform |
| Day 1 | [C5: Deploy the CoE archetype with APEX](./c05-deploy-the-coe-archetype/) | Member | 90 min | Repeatable provisioning |
| Day 1–2 | [C6: Modernize with GitHub Copilot](./c06-modernize-with-ghcp/) | Member | 180 min | Current platform |
| Day 2 | [C7: Migrate and go live](./c07-migrate-and-go-live/) | Member | 120 min | Safe, repeatable change |
| Day 2 | [C8: Validate the pattern](./c08-validate-the-pattern/) | Member | 45 min | Secure by default |
| Day 2 | [C9: Optimize the DB with GitHub Copilot](./c09-optimize-the-db-with-ghcp/) | Member | 60 min | Reliable at enrollment peaks |
| Day 2 | [C10: Package, hand over, review AI readiness](./c10-package-hand-over-review-ai-readiness/) | Team | 60 min | Documented path to AI |

**Totals: 750 min across 10 challenges.**

Time boxes are pacing, not hard stops. Coaches flex on the day. Members' gates are T-14 and T-3; the team lead's foundation (T-7) and vending (T-1) must also be done before day one. The [event overview](../getting-started/event-overview/#before-the-event) has all four steps. During the event, review progress at the end of each day.

## Before you start

Before day one, your team completes Steps 1 to 4 in [Deploy](../deploy/): each member's datacenter (`vm-app01` onboarded to Azure Arc as `Connected`) and `vm-dev01` workstation must be ready before the team lead runs `vending` at Step 4.

:::tip[One-command `vm-dev01` bootstrap (including pre-existing VMs)]
When you connect to `vm-dev01` via Bastion, run `Initialize-Workstation.ps1` in PowerShell 7 (`pwsh`) to install Node.js 24 LTS and `azd` (if your VM was provisioned before the single-clone update), sign in to GitHub/Azure/`azd`, auto-detect your member index and subscriptions, create or clone your single private repository (`C:\src\<your-repo>` on `main`), and write `factory/.local/settings.json`:

```powershell title="vm-dev01 — PowerShell 7 (pwsh)"
New-Item -ItemType Directory -Force C:\LabTools | Out-Null
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/jonathan-vella/apex-factory-hackathon/main/scripts/Initialize-Workstation.ps1' -OutFile C:\LabTools\Initialize-Workstation.ps1
pwsh -NoProfile -File C:\LabTools\Initialize-Workstation.ps1
```

:::

## Track your progress

On a challenge page, tick **Done** on each requirement as you finish it and tick the **Success criteria** checkboxes as you complete each check. The bar shows requirements completed and jumps to each one. Ticks stay in this browser only; they aren't shared, and clearing site data or changing browsers starts from zero. **Reset**, then **Confirm reset** within four seconds, clears this page's ticks.

## Where to go next

Start with [C1: Define the opportunity](./c01-define-the-opportunity/) after completing the [pre-hackathon setup (Steps 1 to 4)](../deploy/).
