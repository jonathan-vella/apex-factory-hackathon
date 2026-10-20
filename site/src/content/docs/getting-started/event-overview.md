---
title: Event overview
description: The two-day agenda and the T-14 and T-3 readiness gates.
sidebar:
  order: 1
---

The event runs over two days, plus pre-work before day one. Format: a team of members works through the day's challenges in parallel where the challenge is scoped to a member, and together where it's scoped to the team.

## Pre-work

Every member completes [Prerequisites](../prerequisites/) and [C0: Ready to hack](../../challenges/c00-ready-to-hack/) before the event: preflight, datacenter, Arc onboarding, a first migration assessment and the complete setup of `vm-dev01`. Two readiness gates apply. They count back from day one of the event:

- **T-14 (14 days before day one):** `Test-Preflight.ps1` reports GO and you've confirmed the manual checks yourself. This is the last point where an access or quota problem can realistically be escalated and fixed before the event.
- **T-3 (3 days before day one):** the datacenter is deployed, `Test-Datacenter.ps1` passes for you (run before Arc onboarding), `vm-app01` is connected to Azure Arc, your first migration assessment has run, the legacy app is healthy, and you have a fully set up `vm-dev01` (C0 task 7), with Copilot working in VS Code. A coach reviews every member's C0 output. Run `Test-Datacenter.ps1` before Arc because Arc turns off the run commands it uses. A run command is an Azure feature that runs a script inside a VM without signing in to it.

Missing either gate puts a member's start on day one at risk; coaches escalate gate misses to the event owner, not to the team. The roster locks at kickoff, so a member who can't get ready can still be swapped or dropped before then.

## Day one

The platform lead starts ALZ-lite (the kit's scaled-down Azure landing zone) at 09:00, while the team does [C1: Define the opportunity](../../challenges/c01-define-the-opportunity/); C1 needs no Azure access. After a coach's live portal demo of ALZ-lite, [C2: Secure, AI-ready foundation](../../challenges/c02-secure-ai-ready-foundation/) continues with the Graph read grant for the SQL MI identity and vending (connecting each member's subscription to the foundation), while members assess the source in [C3: Assess the source](../../challenges/c03-assess-the-source/). [C4: Choose target states](../../challenges/c04-choose-target-states/) and [C5: Deploy the CoE archetype with APEX](../../challenges/c05-deploy-the-coe-archetype/) (after a coach's APEX demo) follow. [C6: Modernize with GHCP](../../challenges/c06-modernize-with-ghcp/) starts on day one and spans into day two. The [agenda](../../about/#agenda) has the times.

## Day two

The MI link (the replication link from the source SQL Server to Azure SQL Managed Instance) starts at 08:30, in tasks 1 and 2 of [C7: Migrate and go live](../../challenges/c07-migrate-and-go-live/) (prepare the source, then start the link), so seeding overlaps the end of C6. C6 finishes, then C7, [C8: Validate the pattern](../../challenges/c08-validate-the-pattern/), [C9: Optimize the DB with GHCP](../../challenges/c09-optimize-the-db-with-ghcp/) and [C10: Package, hand over, review AI readiness](../../challenges/c10-package-hand-over-review-ai-readiness/) close out the event with a team showcase.

## Time boxes are pacing, not hard stops

Each challenge page states a time box to help you pace the day. The two real gates are T-14 and T-3 before the event, and the end of each day during it, not each challenge's individual minutes.

## Where to go next

Start with [Prerequisites](../prerequisites/), then [C0: Ready to hack](../../challenges/c00-ready-to-hack/). The [glossary](../../reference/glossary/) explains the terms.
