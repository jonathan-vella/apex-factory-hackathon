---
title: "M1: Foundation"
description: The team's opportunity canvas and ALZ-lite landing zone.
---

## Covers

[C1: Define the opportunity](../../challenges/c01-define-the-opportunity/) and [C2: Secure, AI-ready foundation](../../challenges/c02-secure-ai-ready-foundation/). The tasks, commands and evidence are on the challenge pages.

## Prerequisites

Every member's M0 complete, because vending needs each member's datacenter to exist. A shared services subscription for the platform lead, with the built-in Owner role at Tenant Root scope: see the [ALZ-lite guide](../../guides/alz-lite/#what-the-platform-lead-needs) for how to get it. Someone with the Privileged Role Administrator directory role for one step.

## Where to run

The dev container of your own repo, from `factory/`. C1's team repo setup runs on your own computer.

## Bootstrap (standalone)

Follow the C2 tasks in order: record the shared services subscription with `Initialize-Settings.ps1`, the platform lead runs `Deploy-AlzLite.ps1`, a Privileged Role Administrator runs `Grant-SqlMiDirectoryRead.ps1` once per team, the platform lead runs `Deploy-Vending.ps1` for every member (including themselves), then each member runs `New-DatacenterExemptions.ps1` and `Test-Connectivity.ps1`. `Test-Connectivity.ps1` runs from the dev container and runs its probes inside the datacenter VMs through Azure.

## Exit evidence

The items in the Evidence sections of [C1](../../challenges/c01-define-the-opportunity/#evidence) and [C2](../../challenges/c02-secure-ai-ready-foundation/#evidence): the opportunity canvas, the ALZ-lite, Graph grant and vending output for every member, the exemptions table and the connectivity probes.

## Reset

Re-run `Deploy-AlzLite.ps1` and `Deploy-Vending.ps1`; both converge on existing resources. If a member's datacenter is redeployed, vend that member again and re-record the policy exemptions.

## Time box

165 minutes: 45 for C1 and 120 for C2.
