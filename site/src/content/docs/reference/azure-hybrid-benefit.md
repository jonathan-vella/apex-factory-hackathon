---
title: Azure Hybrid Benefit
description: What's on by default and the rule if you hold no eligible licenses.
sidebar:
  order: 5
---

Azure Hybrid Benefit (AHB) can lower the Azure rate for eligible Windows Server and SQL Server licenses. The kit enables it for `vm-app01` by default. The Windows 11 workstation, `vm-dev01`, requires separate per-user Windows 11 on Azure rights and is not covered by the `no-hybrid-benefit` input.

## The rule

**If you don't hold eligible licenses:** set `no-hybrid-benefit` on the initial `member` stage in [Step 3: Datacenter and workstation](../../deploy/member-steps/#31-deploy-your-datacenter-and-onboard-azure-arc), so `vm-app01` is deployed and tested without Hybrid Benefit. The input covers `vm-app01` only; let your team lead know.

- In your own repo (member profile): `gh workflow run platform.yml -f stage=member -f no-hybrid-benefit=true`
- In the team lead's repo: `gh workflow run platform.yml -f stage=member -f members=<your index> -f no-hybrid-benefit=true`

If you do hold eligible licenses, leave AHB on.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01` (Windows Server license) | `Windows_Server`, on by default. Optional |
| `vm-dev01` (Windows 11 dev VM) | `Windows_Client`. The user needs an eligible per-user Windows 11 license for use on Azure; this is mandatory and separate from Windows Server AHB. |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied), never the SQL MI free offer |

## Windows 11 per-user entitlement

Each user of `vm-dev01` needs an eligible per-user license that grants rights to run Windows 11 on Azure. Qualifying subscriptions include Windows 11 Enterprise E3/E5, Microsoft 365 E3/E5/A3/A5/F3 or Business Premium, Windows VDA E3/E5, and Windows Education A3/A5. See Microsoft's [Windows 11 licensing guidance](https://learn.microsoft.com/azure/virtual-machines/windows/windows-desktop-multitenant-hosting-deployment). The `no-hybrid-benefit` input changes `vm-app01` only; it is not a workaround for missing Windows 11 rights. If you do not have an eligible license, contact your team lead before Step 3.

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
