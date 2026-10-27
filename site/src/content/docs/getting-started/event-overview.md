---
title: Event overview
description: The pre-work timeline (T-14 to T-1), the readiness gates and what happens each day. The agenda with times is on the About page.
sidebar:
  order: 4
---

The event runs over two days, plus pre-work before day one. Format: a team of members works through the day's challenges in parallel where the challenge is scoped to a member, and together where it's scoped to the team.

## Pre-work

Every member completes [Prerequisites](../prerequisites/) and [C0: Ready to hack](../../challenges/c00-ready-to-hack/) before the event: preflight, datacenter, Arc onboarding, a first migration assessment and the complete setup of `vm-dev01`. The platform lead builds the team's shared foundation in between. The dates count back from day one of the event:

- **T-14 (14 days before day one):** the preflight (the `whatif` stage of the pipeline) is green and you've confirmed the manual checks yourself. This is the last point where an access or quota problem can realistically be escalated and fixed before the event. The event owner also captures every member's workload subscription ID, member index, Entra object ID and email for the roster.
- **T-7 (7 days before day one):** the platform lead runs the `foundation` stage, which deploys ALZ-lite (the kit's scaled-down Azure landing zone) for the team, and someone with the Privileged Role Administrator role grants the SQL MI identity its Graph read. Members have nothing to do.
- **T-3 (3 days before day one):** the datacenter is deployed, the test passes for you (the `member` stage runs it before Arc onboarding), `vm-app01` is connected to Azure Arc, your first migration assessment has run, the legacy app is healthy, and you have a fully set up `vm-dev01` (C0 task 7), with Copilot working in VS Code. A coach reviews every member's C0 output. The test runs before Arc because Arc turns off the run commands it uses. A run command is an Azure feature that runs a script inside a VM without signing in to it.
- **T-1 (1 day before day one):** the platform lead vends every member, which connects each member's subscription to the foundation, restarts the VMs, records the exemptions and runs the connectivity probes. Keep both VMs running. Your Bastion session drops when your VMs restart.

T-14 and T-3 are the gates for members. Missing either puts a member's start on day one at risk; coaches escalate gate misses to the event owner, not to the team. The roster locks at kickoff, so a member who can't get ready can still be swapped or dropped before then.

## Day one

Everyone starts at 09:00 with [C1: Define the opportunity](../../challenges/c01-define-the-opportunity/), the platform lead included; C1 needs no Azure access. After a coach's live portal demo of an Azure landing zone, [C2: Secure, AI-ready foundation](../../challenges/c02-secure-ai-ready-foundation/) verifies and explains the foundation that already exists: the platform lead walks the team through ALZ-lite, the Graph read grant for the SQL MI identity and vending, the coach asks about the policies, and each member checks their own exemptions and connectivity. Members assess the source in [C3: Assess the source](../../challenges/c03-assess-the-source/) in parallel. [C4: Choose target states](../../challenges/c04-choose-target-states/) and [C5: Deploy the CoE archetype with APEX](../../challenges/c05-deploy-the-coe-archetype/) (after a coach's APEX demo) follow. [C6: Modernize with GHCP](../../challenges/c06-modernize-with-ghcp/) starts on day one and spans into day two. The [agenda](../../about/#agenda) on the About page has the times.

## Day two

The MI link (the replication link from the source SQL Server to Azure SQL Managed Instance) starts at 08:30, in tasks 1 and 2 of [C7: Migrate and go live](../../challenges/c07-migrate-and-go-live/) (prepare the source, then start the link), so seeding overlaps the end of C6. C6 finishes, then C7, [C8: Validate the pattern](../../challenges/c08-validate-the-pattern/), [C9: Optimize the DB with GHCP](../../challenges/c09-optimize-the-db-with-ghcp/) and [C10: Package, hand over, review AI readiness](../../challenges/c10-package-hand-over-review-ai-readiness/) close out the event with a team showcase.

## Time boxes are pacing, not hard stops

Each challenge page states a time box to help you pace the day. The two real gates are T-14 and T-3 before the event, and the end of each day during it, not each challenge's individual minutes.

## Where to go next

Start with [Prerequisites](../prerequisites/), then [C0: Ready to hack](../../challenges/c00-ready-to-hack/). The [glossary](../../reference/glossary/) explains the terms.
