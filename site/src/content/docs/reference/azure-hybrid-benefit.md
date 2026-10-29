---
title: Azure Hybrid Benefit
description: What's on by default and the rule if you hold no eligible licenses.
sidebar:
  order: 2
---

Azure Hybrid Benefit (AHB) lets you use a Windows Server or SQL Server license you already own, with Software Assurance (a Microsoft licensing option that lets you move licenses to Azure), for a lower Azure rate. The kit turns it on everywhere it deploys a Windows Server or SQL Server license, because its cost figures assume it.

## The rule

**If you don't hold eligible licenses:** set `no-hybrid-benefit` on the initial `member` stage in [Step 3: Datacenter and workstation](../../deploy/member-steps/#31-deploy-your-datacenter-and-onboard-azure-arc), so `vm-app01` is deployed and tested without Hybrid Benefit. The input covers `vm-app01` only; let your team lead know.

- In your own repo (member profile): `gh workflow run platform.yml -f stage=member -f no-hybrid-benefit=true`
- In the team lead's repo: `gh workflow run platform.yml -f stage=member -f members=<your index> -f no-hybrid-benefit=true`

If you do hold eligible licenses, leave AHB on.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01` (Windows Server license) | `Windows_Server`, on by default. Optional |
| `vm-dev01` (Windows 11 dev VM) | `Windows_Client` (multi-tenant hosting rights, which Windows 11 on Azure needs). Mandatory, not optional |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied), never the SQL MI free offer |

## If Arc onboarding needs recovery

**After Arc, before C5:** the `member` stage refuses once `vm-app01` is an Arc machine or its guest agent is off. To recover, run `teardown`, then `member`. In the member's own repo (member profile), run:

```bash
gh workflow run platform.yml -f stage=teardown
gh workflow run platform.yml -f stage=member
```

In the team lead's repo, run the same stages with your index:

```bash
gh workflow run platform.yml -f stage=teardown -f members=<your index>
gh workflow run platform.yml -f stage=member -f members=<your index>
```

Member teardown removes `rg-datacenter`, `rg-spoke` and the archetype, including the SQL Managed Instance. Repeat Step 3 and the `vm-dev01` setup. If you do not hold eligible Windows Server licenses, add `-f no-hybrid-benefit=true` to the `member` command. If you were already vended, the team lead must run `vending` for your index afterward. Before T+2, never run a full, unfiltered teardown in the team lead's repo; pass `-f members=<your index>` or ask your team lead to escalate to the event owner for a coach repair. After C5, do not use this recovery; ask the event owner for a coach repair.

## Where to go next

See [Cost](../cost/) for the per-member and per-team figures.
