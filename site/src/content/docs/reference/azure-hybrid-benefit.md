---
title: Azure Hybrid Benefit
description: What's on by default, the one rule if you hold no eligible licenses, and how to turn it off.
sidebar:
  order: 2
---

Azure Hybrid Benefit (AHB) lets you use a Windows Server or SQL Server license you already own, with Software Assurance (a Microsoft licensing option that lets you move licenses to Azure), for a lower Azure rate. The kit turns it on everywhere it deploys a Windows Server or SQL Server license, because its cost figures assume it.

## The rule

**If you don't hold eligible licenses:** run the `member` stage with `no-hybrid-benefit` in [Step 3: Datacenter and workstation](../../deploy/member-steps/#31-deploy-your-datacenter-and-onboard-azure-arc), so `vm-app01` is deployed and tested without Hybrid Benefit. Let your team lead know, and ask your coach on day one what to do for the SQL Managed Instance in C5. The input covers `vm-app01` only.

- **In your own repo (member):** `gh workflow run platform.yml -f stage=member -f no-hybrid-benefit=true`
- **In the team lead's repo:** add `-f members=<your index>`: `gh workflow run platform.yml -f stage=member -f members=<your index> -f no-hybrid-benefit=true`

If you do hold eligible licenses, leave AHB on.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01` (Windows Server license) | `Windows_Server`, on by default. Optional |
| `vm-dev01` (Windows 11 dev VM) | `Windows_Client` (multi-tenant hosting rights, which Windows 11 on Azure needs). Mandatory, not optional |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied), never the SQL MI free offer |

## If you need to start over after Arc

After Arc, there is no in-place reset. In your own repo (member), run `teardown`, then `member`; in the team lead's repo, add `-f members=<your index>` to both commands:

```bash
gh workflow run platform.yml -f stage=teardown
gh workflow run platform.yml -f stage=member
```

```bash
gh workflow run platform.yml -f stage=teardown -f members=<your index>
gh workflow run platform.yml -f stage=member -f members=<your index>
```

Member teardown removes `rg-datacenter`, `rg-spoke` and the archetype. If the member was already vended, the team lead must run `vending` again for that member (`-f members=<your index>`). Team leads: never run a full teardown in the lead repo before T+2; to start over, use the named-member form above or ask the event owner for a coach repair. After C5, ask the event owner before member teardown because it removes the archetype, including the SQL Managed Instance, which takes hours to provision again.

## Where to go next

See [Cost](../cost/) for the per-member and per-team figures.
