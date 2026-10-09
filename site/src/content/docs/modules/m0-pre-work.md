---
title: "M0: Pre-work"
description: Member prerequisites, datacenter and Arc onboarding, done before the event.
---

## Covers

[C0: Ready to hack](../../challenges/c00-ready-to-hack/).

## Prerequisites

An assigned workload subscription. GitHub and Azure access for the kit's repos and resource providers.

## Bootstrap (standalone)

Run `scripts/Test-Preflight.ps1 -Fix`, then `scripts/Deploy-Datacenter.ps1`, then `scripts/Connect-DatacenterArc.ps1`. No shared-services dependency — this module runs entirely inside one workload subscription.

## Exit evidence

- `Test-Preflight.ps1` and `Test-Datacenter.ps1` both green.
- `vm-app01` visible as a connected machine in Azure Arc, with the SQL Server extension attached.
- A first Arc migration assessment produced.

## Reset

Re-run `Deploy-Datacenter.ps1`; it's idempotent. To fully reset Arc onboarding, remove the Arc resource and re-run `Connect-DatacenterArc.ps1`.

## Time box

150 minutes (pre-work; not on the two-day agenda).

## Last validated

2026-10-02 (B04, B07).
