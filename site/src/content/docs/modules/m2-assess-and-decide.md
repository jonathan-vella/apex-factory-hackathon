---
title: "M2: Assess and decide"
description: Triage the source assessments and commit to target-state ADRs.
---

## Covers

[C3: Assess the source](../../challenges/c03-assess-the-source/) and [C4: Choose target states](../../challenges/c04-choose-target-states/). The tasks and evidence are on the challenge pages.

## Prerequisites

M0 complete: the datacenter, Arc onboarding and a first assessment. M1 doesn't need to be finished, because C3 can run while ALZ-lite deploys.

## Where to run

C3's Upgrade agent assessment runs on `vm-dev01`, set up as in the [GitHub Copilot upgrade guide](../../guides/ghcp-upgrade/#switching-to-vm-dev01). Its Arc assessment runs in the Azure portal. The triage record and C4's ADRs go in the team repo.

## Bootstrap (standalone)

Re-run the Arc SQL migration assessment from the Arc resource, and run the Upgrade agent's assessment step against `app/ContosoUniversity` as in C3 (harness Local, agent Upgrade, scenario `dotnet-version-upgrade`), without approving planning.

## Exit evidence

The items in the Evidence sections of [C3](../../challenges/c03-assess-the-source/#evidence) and [C4](../../challenges/c04-choose-target-states/#evidence): a triage table that covers every finding, including the trace-flag finding (1800 and 9567) with its decision, at least four ADRs, and the deferred-work register.

## Reset

Re-run the assessments; they're read-only against the source and produce no state to reset. ADRs and the register are append-only documents: correct them in place rather than resetting.

## Time box

105 minutes: 60 for C3 and 45 for C4.
