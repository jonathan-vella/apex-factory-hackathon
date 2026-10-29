---
title: Challenges
description: The ten challenges in order, with scope, time, points and the business outcome each one serves.
sidebar:
  label: Overview
  order: 0
---

Ten challenges take Contoso University from a Windows VM in its own datacenter to a modernized app on Azure. You work through them in order, and in each one you show a coach the evidence that you did it.

## The scenario

Contoso University is a fictional public university. Its student enrollment app is old, patched by hand and holds its database password in a file. Your team is the delivery team of the partner the university hired to modernize it. [The customer story](../getting-started/customer-story/) tells it in one page and names the four people you work for.

## How the challenges work

- **Team and member challenges.** Team challenges (C1, C4 and C10) are done together on one shared screen. Member challenges (C2, C3 and C5 to C9) are done by each person in their own repo and subscription. C4 has both.
- **Five parts on every page.** Background says why it matters and which business outcome it serves. Challenge gives the starting point, what the kit fixes and what you decide. Requirements say what you must do. Success criteria say what you show your coach. References link to Microsoft Learn.
- **Hints are folded away.** Open them when you are stuck. Where a challenge leaves a choice to you (C1, C4 and C10), there is no single right answer, and your coach looks at your reasoning.
- **Evidence goes in your own repo.** Commit it under `factory/evidence/` as you finish each challenge, not at the end of the day.

## Ground rules

- Work as a team. The team lead is also a member. For team documents, one person types and the others check.
- Let Copilot do the work and keep a person in charge. Read what it produced and run the check before you commit.
- If a step fails twice, ask your coach.
- Never put tenant, subscription or object IDs, or a password, in anything you commit.

## Before C1: 30-minute hackathon introduction

Day one opens at 08:30 with a 30-minute PowerPoint presentation by the tech lead before any team starts C1. The briefing covers:

1. **How the hackathon works:** the two-day schedule, team and member scopes, evidence rules and how coaches score each challenge.
2. **The Contoso University scenario:** who the university is, the four leaders you work for (Dana, Priya, Marcus and Tomás), the problems that triggered this engagement and the six business outcomes they need.
3. **The ten challenges end to end:** how business outcomes (C1) and platform guardrails (C2) connect to source assessment (C3), target-state decisions (C4), CoE archetype provisioning (C5), app modernization and cutover (C6 and C7), acceptance testing and database tuning (C8 and C9), and the final handover package (C10).

## The challenges

| Day | Challenge | Scope | Time box | Points | Business outcome |
|---|---|---|---|---|---|
| Day 1 | [C1: Define the opportunity](./c01-define-the-opportunity/) | Team | 45 min | 10 | All six, in order |
| Day 1 | [C2: Secure, AI-ready foundation](./c02-secure-ai-ready-foundation/) | Member | 45 min | 15 | Secure by default |
| Day 1 | [C3: Assess the source](./c03-assess-the-source/) | Member | 60 min | 15 | Safe, repeatable change |
| Day 1 | [C4: Choose target states](./c04-choose-target-states/) | Team + member | 45 min | 25 | Current platform |
| Day 1 | [C5: Deploy the CoE archetype with APEX](./c05-deploy-the-coe-archetype/) | Member | 90 min | 15 | Repeatable provisioning |
| Day 1–2 | [C6: Modernize with GHCP](./c06-modernize-with-ghcp/) | Member | 180 min | 30 | Current platform |
| Day 2 | [C7: Migrate and go live](./c07-migrate-and-go-live/) | Member | 120 min | 20 | Safe, repeatable change |
| Day 2 | [C8: Validate the pattern](./c08-validate-the-pattern/) | Member | 45 min | 10 | Secure by default |
| Day 2 | [C9: Optimize the DB with GHCP](./c09-optimize-the-db-with-ghcp/) | Member | 60 min | 10 | Reliable at enrollment peaks |
| Day 2 | [C10: Package, hand over, review AI readiness](./c10-package-hand-over-review-ai-readiness/) | Team | 60 min | 20 | Documented path to AI |

**Totals: 750 min across 10 challenges, 170 base points (45 team + 125 member).** Bonus points (noted per challenge, and from badges) are separate from this base contract. They share one cap of 30 points per team: the per-challenge maxima add up to more than that, and points beyond the cap aren't awarded. The maximum score is 200.

Time boxes are pacing, not hard stops. Coaches flex on the day. The event's real gates are T-14 (14 days before day one) and T-3 (3 days before day one), both before the event, and the end of each day. The [event overview](../getting-started/event-overview/#before-the-event) has both gates.

## Before you start

The pre-hackathon setup is not a challenge and carries no points. Before day one, your team completes Steps 1 to 4 in [Deploy](../deploy/): each member's datacenter (`vm-app01` onboarded to Azure Arc as `Connected`) and `vm-dev01` workstation must be ready before the team lead runs `vending` at Step 4.

## Track your progress

On a challenge page, tick **Done** on each requirement as you finish it. The bar under the header shows how many requirements are done and jumps to each one. Ticks stay in this browser only: they aren't shared with your team, and clearing site data or switching browsers starts you from zero. **Reset** clears the page.

## Where to go next

Start with [C1: Define the opportunity](./c01-define-the-opportunity/), after your [readiness check](../deploy/).
