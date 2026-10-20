---
title: Azure Hybrid Benefit
description: What's on by default, the one rule if you hold no eligible licenses, and how to turn it off.
sidebar:
  order: 2
---

Azure Hybrid Benefit (AHB) lets you use a Windows Server or SQL Server license you already own, with Software Assurance (a Microsoft licensing option that lets you move licenses to Azure), for a lower Azure rate. The kit turns it on everywhere it deploys a Windows Server or SQL Server license, because its cost figures assume it.

## The rule

**If you don't hold eligible licenses:** deploy `vm-app01` with `-NoHybridBenefit` in C0 (and run `Test-Datacenter.ps1` with `-NoHybridBenefit` too), tell your coach, and ask your coach what to do for the SQL Managed Instance in C5. `-NoHybridBenefit` covers `vm-app01` only.

If you do hold eligible licenses, leave AHB on.

## Where it applies

| Resource | AHB setting |
|---|---|
| `vm-app01` (Windows Server license) | `Windows_Server`, on by default. Optional |
| `vm-dev01` (Windows 11 dev VM) | `Windows_Client` (multitenant hosting rights, which Windows 11 on Azure needs). Mandatory, not optional |
| SQL Managed Instance (`licenseType`) | `BasePrice` (AHB applied), never the SQL MI free offer |

## Turning it off to compare costs

If you want to compare costs with and without AHB, turn it off for `vm-app01` only, with `Deploy-Datacenter.ps1 -NoHybridBenefit` or `az vm update -g rg-datacenter -n vm-app01 --license-type None`, or set the managed instance's `licenseType` to `LicenseIncluded`, and redeploy. Leave `vm-dev01` on `Windows_Client`. Turn AHB back on afterward if you hold eligible licenses: the kit's cost figures throughout this site assume it's on.

## Where to go next

See [Cost](../cost/) for the per-member and per-team figures.
