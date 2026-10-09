---
title: "M1: Foundation"
description: The team's opportunity canvas and ALZ-lite landing zone.
---

## Covers

[C1: Define the opportunity](../../challenges/c01-define-the-opportunity/), [C2: Secure, AI-ready foundation](../../challenges/c02-secure-ai-ready-foundation/).

## Prerequisites

Every member's M0 complete. A shared services subscription for the platform lead, with Owner at Tenant Root scope to create management groups and move subscriptions.

## Bootstrap (standalone)

`scripts/Deploy-AlzLite.ps1` against the shared services subscription, then `scripts/Deploy-Vending.ps1` once per member workload subscription, then `scripts/New-DatacenterExemptions.ps1`.

## Exit evidence

- ALZ-lite's management groups, hub and core policies deployed.
- Every member's subscription vended: spoke, subnets, peering, UDRs, DNS, RBAC, budget.
- `scripts/Test-Connectivity.ps1` passing from inside the datacenter.
- The opportunity canvas committed.

## Reset

Re-run `Deploy-AlzLite.ps1` and `Deploy-Vending.ps1`; both are idempotent against existing resources. Policy exemptions must be re-recorded if the datacenter resource group is redeployed.

## Time box

165 minutes (45 + 120).

## Last validated

2026-10-02 (B08).
