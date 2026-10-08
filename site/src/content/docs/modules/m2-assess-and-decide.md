---
title: "M2: Assess and decide"
description: Triage the source assessments and commit to target-state ADRs.
---

## Covers

[C3: Assess the source](../../challenges/c03-assess-the-source/), [C4: Choose target states](../../challenges/c04-choose-target-states/).

## Prerequisites

M0 complete (the datacenter, Arc onboarding and a first assessment). M1 doesn't need to be finished — C3 can run while ALZ-lite deploys.

## Bootstrap (standalone)

Re-run the Arc SQL migration assessment from the Arc resource, and run the GitHub Copilot Upgrade agent's assessment step against `app/ContosoUniversity` (harness Local, agent Upgrade, scenario `dotnet-version-upgrade`), without approving planning.

## Exit evidence

- A triage table covering every assessment finding, including the trace-flag finding (1800/9567) with its decision.
- At least four ADRs: platform, migration method, app, data.
- The deferred-work register, listing every deferred finding.

## Reset

Re-run the assessments; they're read-only against the source and produce no state to reset. ADRs and the register are append-only documents — correct them in place rather than resetting.

## Time box

105 minutes (60 + 45).

## Last validated

2026-10-02 (B06, B07).
